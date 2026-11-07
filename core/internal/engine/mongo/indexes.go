package mongo

import (
	"context"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"

	"github.com/doubledare704/queravue/core/internal/engine"
)

var (
	_ engine.IndexManager  = (*Conn)(nil)
	_ engine.IndexWriter   = (*Conn)(nil)
	_ engine.StatsProvider = (*Conn)(nil)
)

var passThroughIndexOptions = []string{"sparse", "expireAfterSeconds", "hidden", "collation"}

// ListIndexes implements engine.IndexManager.
func (c *Conn) ListIndexes(ctx context.Context, database, _, collection string) ([]engine.IndexInfo, error) {
	coll, err := c.coll("list indexes", database, collection)
	if err != nil {
		return nil, err
	}
	cur, err := coll.Indexes().List(ctx)
	if err != nil {
		return nil, c.fail("list indexes", err)
	}
	defer func() { _ = cur.Close(ctx) }()

	var out []engine.IndexInfo
	for cur.Next(ctx) {
		info, err := decodeIndex(cur.Current)
		if err != nil {
			return nil, relabel(&engine.Error{Kind: engine.KindServer, Op: "list indexes", Msg: err.Error(), Err: err}, c.id)
		}
		out = append(out, info)
	}
	if err := cur.Err(); err != nil {
		return nil, c.fail("list indexes", err)
	}
	sizes := c.indexSizes(ctx, database, collection)
	usage := c.indexUsage(ctx, coll)
	for i := range out {
		name := out[i].Spec.Name
		if n, ok := sizes[name]; ok {
			out[i].SizeBytes = &n
		}
		if u, ok := usage[name]; ok {
			out[i].Usage = u
		} else if usage != nil {
			zero := uint64(0)
			out[i].Usage = engine.IndexUsage{Available: true, Scans: &zero}
		}
	}
	return out, nil
}

func decodeIndex(doc bson.Raw) (engine.IndexInfo, error) {
	var info engine.IndexInfo
	info.Spec.Name = doc.Lookup("name").StringValue()
	info.IsPrimary = info.Spec.Name == "_id_"
	keyDoc, ok := doc.Lookup("key").DocumentOK()
	if !ok {
		return info, errors.New("index has no key document")
	}
	elems, err := keyDoc.Elements()
	if err != nil {
		return info, fmt.Errorf("read index key: %w", err)
	}
	for _, e := range elems {
		switch e.Key() {
		case "_fts":
			info.Spec.Keys = append(info.Spec.Keys, textKeys(doc)...)
		case "_ftsx":
		default:
			info.Spec.Keys = append(info.Spec.Keys, engine.IndexKey{Name: e.Key(), Kind: keyKind(e.Value())})
		}
	}
	if v, ok := doc.Lookup("unique").BooleanOK(); ok {
		info.Spec.Unique = v
	}
	if pf, ok := doc.Lookup("partialFilterExpression").DocumentOK(); ok {
		text, err := toEJSON(pf)
		if err != nil {
			return info, err
		}
		info.Spec.PartialPredicate = text
	}
	for _, opt := range passThroughIndexOptions {
		v, err := doc.LookupErr(opt)
		if err != nil {
			continue
		}
		text, err := valueToEJSON(v)
		if err != nil {
			return info, err
		}
		if info.Spec.Options == nil {
			info.Spec.Options = map[string]string{}
		}
		info.Spec.Options[opt] = text
	}
	return info, nil
}

func textKeys(doc bson.Raw) []engine.IndexKey {
	weights, ok := doc.Lookup("weights").DocumentOK()
	if !ok {
		return []engine.IndexKey{{Name: "$**", Kind: engine.IndexKeyText}}
	}
	elems, _ := weights.Elements()
	keys := make([]engine.IndexKey, 0, len(elems))
	for _, e := range elems {
		keys = append(keys, engine.IndexKey{Name: e.Key(), Kind: engine.IndexKeyText})
	}
	return keys
}

func keyKind(v bson.RawValue) engine.IndexKeyKind {
	if s, ok := v.StringValueOK(); ok {
		switch s {
		case "hashed":
			return engine.IndexKeyHashed
		case "text":
			return engine.IndexKeyText
		case "2dsphere":
			return engine.IndexKeyGeo2DSphere
		}
		return engine.IndexKeyAscending
	}
	if n, ok := number(v); ok && n < 0 {
		return engine.IndexKeyDescending
	}
	return engine.IndexKeyAscending
}

func number(v bson.RawValue) (float64, bool) {
	switch v.Type {
	case bson.TypeInt32:
		return float64(v.Int32()), true
	case bson.TypeInt64:
		return float64(v.Int64()), true
	case bson.TypeDouble:
		return v.Double(), true
	}
	return 0, false
}

func counter(v bson.RawValue) (uint64, bool) {
	n, ok := number(v)
	if !ok || n < 0 {
		return 0, false
	}
	return uint64(n), true
}

// Best effort: collStats is rejected by some servers and variants.
func (c *Conn) indexSizes(ctx context.Context, database, collection string) map[string]uint64 {
	raw, err := c.collStats(ctx, database, collection)
	if err != nil {
		return nil
	}
	sizes, ok := raw.Lookup("indexSizes").DocumentOK()
	if !ok {
		return nil
	}
	out := map[string]uint64{}
	elems, _ := sizes.Elements()
	for _, e := range elems {
		if n, ok := counter(e.Value()); ok {
			out[e.Key()] = n
		}
	}
	return out
}

// Best effort: $indexStats is rejected by some servers and variants. A nil map means unavailable.
func (c *Conn) indexUsage(ctx context.Context, coll *mongo.Collection) map[string]engine.IndexUsage {
	cur, err := coll.Aggregate(ctx, mongo.Pipeline{{{Key: "$indexStats", Value: bson.D{}}}})
	if err != nil {
		return nil
	}
	defer func() { _ = cur.Close(ctx) }()
	usage := map[string]engine.IndexUsage{}
	for cur.Next(ctx) {
		name, ok := cur.Current.Lookup("name").StringValueOK()
		if !ok {
			continue
		}
		u := engine.IndexUsage{Available: true}
		if acc, ok := cur.Current.Lookup("accesses").DocumentOK(); ok {
			if ops, ok := counter(acc.Lookup("ops")); ok {
				u.Scans = &ops
			}
			if ms, ok := acc.Lookup("since").DateTimeOK(); ok {
				t := time.UnixMilli(ms).UTC()
				u.TrackingSince = &t
			}
		}
		usage[name] = u
	}
	if cur.Err() != nil {
		return nil
	}
	return usage
}

// TableStats implements engine.StatsProvider; the collection is passed as the table.
func (c *Conn) TableStats(ctx context.Context, database, _, collection string) (engine.TableStats, error) {
	raw, err := c.collStats(ctx, database, collection)
	if err != nil {
		return engine.TableStats{}, err
	}
	var st engine.TableStats
	if n, ok := number(raw.Lookup("count")); ok {
		v := int64(n)
		st.EstimatedRows = &v
	}
	if n, ok := counter(raw.Lookup("storageSize")); ok {
		st.DataBytes = &n
	}
	if n, ok := counter(raw.Lookup("totalIndexSize")); ok {
		st.IndexBytes = &n
	}
	if n, ok := counter(raw.Lookup("totalSize")); ok {
		st.TotalBytes = &n
	}
	add := func(key, label, value string) {
		st.Extras = append(st.Extras, engine.StatEntry{Key: key, Label: label, Value: value})
	}
	if n, ok := counter(raw.Lookup("size")); ok {
		add("size", "Uncompressed data size", strconv.FormatUint(n, 10))
	}
	if n, ok := counter(raw.Lookup("avgObjSize")); ok {
		add("avg_obj_size", "Average document size", strconv.FormatUint(n, 10))
	}
	if n, ok := counter(raw.Lookup("nindexes")); ok {
		add("nindexes", "Indexes", strconv.FormatUint(n, 10))
	}
	if n, ok := counter(raw.Lookup("freeStorageSize")); ok {
		add("free_storage_size", "Reusable storage", strconv.FormatUint(n, 10))
	}
	if b, ok := raw.Lookup("capped").BooleanOK(); ok && b {
		add("capped", "Capped", "yes")
	}
	return st, nil
}

func (c *Conn) collStats(ctx context.Context, database, collection string) (bson.Raw, error) {
	cl, err := c.live("table stats")
	if err != nil {
		return nil, err
	}
	if database == "" {
		database = c.defaultDB
	}
	if database == "" || collection == "" {
		return nil, engine.Errorf(engine.KindInvalidConfig, c.id, "table stats", "database and collection are required")
	}
	raw, err := cl.Database(database).RunCommand(ctx, bson.D{{Key: "collStats", Value: collection}}).Raw()
	if err != nil {
		return nil, c.fail("table stats", err)
	}
	return raw, nil
}

// CreateIndex implements engine.IndexWriter.
func (c *Conn) CreateIndex(ctx context.Context, database, _, collection string, spec engine.IndexSpec, dryRun bool) (string, string, error) {
	coll, err := c.coll("create index", database, collection)
	if err != nil {
		return "", "", err
	}
	name := spec.Name
	if name == "" {
		name = defaultIndexName(spec.Keys)
	}
	keys, err := indexKeyDoc(spec.Keys)
	if err != nil {
		return "", "", engine.Errorf(engine.KindInvalidConfig, c.id, "create index", "%v", err)
	}
	opts, err := indexOptionsDoc(name, spec)
	if err != nil {
		return "", "", c.parseErr(err)
	}
	statement, err := createIndexStatement(coll, keys, opts)
	if err != nil {
		return "", "", c.fail("create index", err)
	}
	if dryRun {
		return statement, name, nil
	}
	index := append(bson.D{{Key: "key", Value: keys}}, opts...)
	cmd := bson.D{{Key: "createIndexes", Value: collection}, {Key: "indexes", Value: bson.A{index}}}
	if err := coll.Database().RunCommand(ctx, cmd).Err(); err != nil {
		return statement, "", c.fail("create index", err)
	}
	return statement, name, nil
}

// DropIndex implements engine.IndexWriter.
func (c *Conn) DropIndex(ctx context.Context, database, _, collection, name string, dryRun bool) (string, error) {
	coll, err := c.coll("drop index", database, collection)
	if err != nil {
		return "", err
	}
	if name == "_id_" {
		return "", engine.Errorf(engine.KindInvalidConfig, c.id, "drop index", "the _id index cannot be dropped")
	}
	statement := fmt.Sprintf("db.getSiblingDB(%s).getCollection(%s).dropIndex(%s)",
		strconv.Quote(coll.Database().Name()), strconv.Quote(collection), strconv.Quote(name))
	if dryRun {
		return statement, nil
	}
	cmd := bson.D{{Key: "dropIndexes", Value: collection}, {Key: "index", Value: name}}
	if err := coll.Database().RunCommand(ctx, cmd).Err(); err != nil {
		return statement, c.fail("drop index", err)
	}
	return statement, nil
}

func indexKeyDoc(keys []engine.IndexKey) (bson.D, error) {
	if len(keys) == 0 {
		return nil, errors.New("an index needs at least one key")
	}
	doc := make(bson.D, 0, len(keys))
	for _, k := range keys {
		if k.Name == "" || k.IsExpression {
			return nil, errors.New("a Mongo index key must be a field path")
		}
		var v any
		switch k.Kind {
		case engine.IndexKeyAscending:
			v = int32(1)
		case engine.IndexKeyDescending:
			v = int32(-1)
		case engine.IndexKeyHashed:
			v = "hashed"
		case engine.IndexKeyText:
			v = "text"
		case engine.IndexKeyGeo2DSphere:
			v = "2dsphere"
		}
		doc = append(doc, bson.E{Key: k.Name, Value: v})
	}
	return doc, nil
}

func defaultIndexName(keys []engine.IndexKey) string {
	parts := make([]string, 0, len(keys)*2)
	for _, k := range keys {
		suffix := "1"
		switch k.Kind {
		case engine.IndexKeyAscending:
		case engine.IndexKeyDescending:
			suffix = "-1"
		case engine.IndexKeyHashed:
			suffix = "hashed"
		case engine.IndexKeyText:
			suffix = "text"
		case engine.IndexKeyGeo2DSphere:
			suffix = "2dsphere"
		}
		parts = append(parts, k.Name, suffix)
	}
	return strings.Join(parts, "_")
}

func indexOptionsDoc(name string, spec engine.IndexSpec) (bson.D, error) {
	opts := bson.D{{Key: "name", Value: name}}
	if spec.Unique {
		opts = append(opts, bson.E{Key: "unique", Value: true})
	}
	if spec.PartialPredicate != "" {
		pf, err := parseDocument(spec.PartialPredicate, false, engine.InputFilter)
		if err != nil {
			return nil, err
		}
		opts = append(opts, bson.E{Key: "partialFilterExpression", Value: pf})
	}
	for _, opt := range passThroughIndexOptions {
		text, ok := spec.Options[opt]
		if !ok {
			continue
		}
		v, err := parseValue(text, engine.InputDocument)
		if err != nil {
			return nil, err
		}
		opts = append(opts, bson.E{Key: opt, Value: v})
	}
	return opts, nil
}

func createIndexStatement(coll *mongo.Collection, keys, opts bson.D) (string, error) {
	keyText, err := bson.MarshalExtJSON(keys, false, false)
	if err != nil {
		return "", fmt.Errorf("render index keys: %w", err)
	}
	optionText, err := bson.MarshalExtJSON(opts, false, false)
	if err != nil {
		return "", fmt.Errorf("render index options: %w", err)
	}
	return fmt.Sprintf("db.getSiblingDB(%s).getCollection(%s).createIndex(%s, %s)",
		strconv.Quote(coll.Database().Name()), strconv.Quote(coll.Name()), keyText, optionText), nil
}
