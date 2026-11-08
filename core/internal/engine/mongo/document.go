package mongo

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"sort"
	"strings"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"

	"github.com/doubledare704/queravue/core/internal/engine"
)

var _ engine.DocumentStore = (*Conn)(nil)

func (c *Conn) coll(op, db, coll string) (*mongo.Collection, error) {
	cl, err := c.live(op)
	if err != nil {
		return nil, err
	}
	if db == "" {
		db = c.defaultDB
	}
	if db == "" || coll == "" {
		return nil, engine.Errorf(engine.KindInvalidConfig, c.id, op, "database and collection are required")
	}
	return cl.Database(db).Collection(coll), nil
}

func withTimeout(ctx context.Context, ms uint32) (context.Context, context.CancelFunc) {
	if ms == 0 {
		return context.WithCancel(ctx)
	}
	return context.WithTimeout(ctx, time.Duration(ms)*time.Millisecond)
}

func (c *Conn) parseErr(err error) error { return relabel(classify("parse", err, c.secret), c.id) }

// optionalDoc parses relaxed EJSON text; empty text yields nil.
func optionalDoc(text string, in engine.Input) (bson.Raw, error) {
	if strings.TrimSpace(text) == "" {
		return nil, nil
	}
	return parseDocument(text, false, in)
}

// Find implements engine.DocumentStore.
func (c *Conn) Find(ctx context.Context, opt engine.FindOptions, sink engine.DocSink) error {
	coll, err := c.coll("find", opt.Database, opt.Collection)
	if err != nil {
		return err
	}
	filter, err := optionalDoc(opt.Filter, engine.InputFilter)
	if err != nil {
		return c.parseErr(err)
	}
	if filter == nil {
		filter = bson.Raw{5, 0, 0, 0, 0}
	}
	sortDoc, err := optionalDoc(opt.Sort, engine.InputSort)
	if err != nil {
		return c.parseErr(err)
	}
	proj, err := optionalDoc(opt.Projection, engine.InputProjection)
	if err != nil {
		return c.parseErr(err)
	}
	batch := opt.BatchSize
	if batch <= 0 {
		batch = engine.MaxDocBatch
	}
	fo := options.Find().SetBatchSize(int32(min(batch, 5000)))
	if sortDoc != nil {
		fo.SetSort(sortDoc)
	}
	if proj != nil {
		fo.SetProjection(proj)
	}
	if opt.Skip > 0 {
		fo.SetSkip(int64(opt.Skip)) //nolint:gosec // skip is bounded by the int64 range of the server
	}
	if opt.Limit > 0 {
		fo.SetLimit(int64(opt.Limit)) //nolint:gosec // limit is bounded by the int64 range of the server
	}
	ctx, cancel := withTimeout(ctx, opt.MaxTimeMS)
	defer cancel()

	cur, err := coll.Find(ctx, filter, fo)
	if err != nil {
		return c.fail("find", err)
	}
	defer func() {
		cctx, ccancel := context.WithTimeout(context.Background(), 2*time.Second)
		defer ccancel()
		_ = cur.Close(cctx) // kills the server-side cursor
	}()

	docs := make([]engine.Document, 0, batch)
	size := 0
	flush := func() error {
		if len(docs) == 0 {
			return nil
		}
		err := sink.Batch(docs)
		docs, size = docs[:0], 0
		return err
	}
	for cur.Next(ctx) {
		text, err := toEJSON(cur.Current)
		if err != nil {
			return relabel(&engine.Error{Kind: engine.KindServer, Op: "find", Msg: err.Error(), Err: err}, c.id)
		}
		docs = append(docs, text)
		size += len(text)
		if len(docs) >= batch || size >= engine.MaxDocBatchBytes {
			if err := flush(); err != nil {
				if errors.Is(err, engine.ErrStopDocs) {
					return nil
				}
				return err
			}
		}
	}
	if err := cur.Err(); err != nil {
		return c.fail("find", err)
	}
	if err := flush(); err != nil && !errors.Is(err, engine.ErrStopDocs) {
		return err
	}
	return nil
}

// Count implements engine.DocumentStore.
func (c *Conn) Count(ctx context.Context, db, collection, filter string, maxTimeMS uint32) (engine.Count, error) {
	coll, err := c.coll("count", db, collection)
	if err != nil {
		return engine.Count{}, err
	}
	f, err := optionalDoc(filter, engine.InputFilter)
	if err != nil {
		return engine.Count{}, c.parseErr(err)
	}
	ctx, cancel := withTimeout(ctx, maxTimeMS)
	defer cancel()
	if len(f) <= 5 {
		n, err := coll.EstimatedDocumentCount(ctx)
		if err == nil {
			return engine.Count{N: uint64(n)}, nil //nolint:gosec // counts are non-negative
		}
		var cmd mongo.CommandError
		if !errors.As(err, &cmd) { // views and some variants reject the estimate; fall back
			return engine.Count{}, c.fail("count", err)
		}
		f = bson.Raw{5, 0, 0, 0, 0}
	}
	n, err := coll.CountDocuments(ctx, f)
	if err != nil {
		return engine.Count{}, c.fail("count", err)
	}
	return engine.Count{N: uint64(n), Exact: true}, nil //nolint:gosec // counts are non-negative
}

// Insert implements engine.DocumentStore.
func (c *Conn) Insert(ctx context.Context, db, collection string, docs []engine.Document, _ engine.WriteOptions) ([]engine.Document, error) {
	coll, err := c.coll("insert", db, collection)
	if err != nil {
		return nil, err
	}
	raws := make([]any, len(docs))
	for i, d := range docs {
		r, err := parseDocument(d, true, engine.InputDocument)
		if err != nil {
			var e *engine.Error
			if errors.As(err, &e) {
				e.DocumentIndex, e.HasIndex = i, true
			}
			return nil, c.parseErr(err)
		}
		raws[i] = r
	}
	if len(raws) == 0 {
		return nil, nil
	}
	res, err := coll.InsertMany(ctx, raws)
	var ids []engine.Document
	if res != nil {
		for _, id := range res.InsertedIDs {
			if s, e := anyToEJSON(id); e == nil {
				ids = append(ids, s)
			}
		}
	}
	if err != nil {
		return ids, c.fail("insert", err)
	}
	return ids, nil
}

func anyToEJSON(v any) (string, error) {
	doc, err := bson.Marshal(bson.D{{Key: "v", Value: v}})
	if err != nil {
		return "", fmt.Errorf("mongo: encode value: %w", err)
	}
	return valueToEJSON(bson.Raw(doc).Lookup("v"))
}

// guard builds the filter for a guarded write: _id plus equality on every
// plain top-level field of the expected document. The exact comparison is
// done separately (checkExpected); this narrows the window in which another
// writer can slip in between the check and the write.
func guard(id bson.RawValue, expected bson.Raw) bson.D {
	f := bson.D{{Key: "_id", Value: id}}
	if expected == nil {
		return f
	}
	elems, err := expected.Elements()
	if err != nil {
		return f
	}
	for _, e := range elems {
		k := e.Key()
		if k == "_id" || strings.HasPrefix(k, "$") || strings.Contains(k, ".") {
			continue
		}
		f = append(f, bson.E{Key: k, Value: e.Value()})
	}
	return f
}

// current returns the stored document for id as canonical EJSON, or nil.
func (c *Conn) current(ctx context.Context, coll *mongo.Collection, id bson.RawValue) (*string, error) {
	raw, err := coll.FindOne(ctx, bson.D{{Key: "_id", Value: id}}).Raw()
	if errors.Is(err, mongo.ErrNoDocuments) {
		return nil, nil
	}
	if err != nil {
		return nil, fmt.Errorf("mongo: read current document: %w", err)
	}
	s, err := toEJSON(raw)
	if err != nil {
		return nil, err
	}
	return &s, nil
}

// checkExpected compares the stored document to expected byte for byte (field
// order and BSON types count, so an Int32 turned Int64 by another writer is a
// conflict). It returns a KindConflict error carrying the stored document.
func (c *Conn) checkExpected(ctx context.Context, coll *mongo.Collection, id bson.RawValue, expected bson.Raw) error {
	raw, err := coll.FindOne(ctx, bson.D{{Key: "_id", Value: id}}).Raw()
	if errors.Is(err, mongo.ErrNoDocuments) {
		return c.conflict(ctx, coll, id)
	}
	if err != nil {
		return c.fail("replace", err)
	}
	if !bytes.Equal(raw, expected) {
		s, _ := toEJSON(raw)
		return &engine.Error{Kind: engine.KindConflict, Engine: c.id, Op: "write", Current: &s,
			Msg: "document changed on server"}
	}
	return nil
}

func (c *Conn) conflict(ctx context.Context, coll *mongo.Collection, id bson.RawValue) error {
	cur, err := c.current(ctx, coll, id)
	if err != nil {
		return c.fail("write", err)
	}
	msg := "document changed on server"
	if cur == nil {
		msg = "document was deleted on server"
	}
	return &engine.Error{Kind: engine.KindConflict, Engine: c.id, Op: "write", Current: cur, Msg: msg}
}

// prepareWrite parses the id and, when guarded, the expected document.
func (c *Conn) prepareWrite(id string, w engine.WriteOptions) (bson.RawValue, bson.Raw, error) {
	idv, err := parseValue(id, engine.InputDocument)
	if err != nil {
		return bson.RawValue{}, nil, c.parseErr(err)
	}
	var exp bson.Raw
	if w.Expected != nil {
		if exp, err = parseDocument(*w.Expected, true, engine.InputDocument); err != nil {
			return bson.RawValue{}, nil, c.parseErr(err)
		}
	}
	return idv, exp, nil
}

// finishWrite turns the result of a FindOneAnd* call into a document or error.
func (c *Conn) finishWrite(ctx context.Context, coll *mongo.Collection, id bson.RawValue, guarded bool, res *mongo.SingleResult) (engine.Document, error) {
	raw, err := res.Raw()
	switch {
	case err == nil:
		return toEJSON(raw)
	case errors.Is(err, mongo.ErrNoDocuments):
		if guarded {
			return "", c.conflict(ctx, coll, id)
		}
		return "", engine.Errorf(engine.KindNotFound, c.id, "write", "document not found")
	default:
		return "", c.fail("write", err)
	}
}

// Replace implements engine.DocumentStore.
func (c *Conn) Replace(ctx context.Context, db, collection string, id, doc engine.Document, w engine.WriteOptions) (engine.Document, error) {
	coll, err := c.coll("replace", db, collection)
	if err != nil {
		return "", err
	}
	idv, exp, err := c.prepareWrite(id, w)
	if err != nil {
		return "", err
	}
	repl, err := parseDocument(doc, true, engine.InputDocument)
	if err != nil {
		return "", c.parseErr(err)
	}
	if v, lerr := repl.LookupErr("_id"); lerr == nil && !v.Equal(idv) {
		return "", engine.Errorf(engine.KindParse, c.id, "replace", "the document _id differs from the target _id; _id cannot be changed")
	}
	if exp != nil {
		if err := c.checkExpected(ctx, coll, idv, exp); err != nil {
			return "", err
		}
	}
	res := coll.FindOneAndReplace(ctx, guard(idv, exp), repl, options.FindOneAndReplace().SetReturnDocument(options.After))
	return c.finishWrite(ctx, coll, idv, exp != nil, res)
}

// UpdateFields implements engine.DocumentStore.
func (c *Conn) UpdateFields(ctx context.Context, db, collection string, id, set engine.Document, unset []string, w engine.WriteOptions) (engine.Document, error) {
	coll, err := c.coll("update", db, collection)
	if err != nil {
		return "", err
	}
	idv, exp, err := c.prepareWrite(id, w)
	if err != nil {
		return "", err
	}
	update := bson.D{}
	if strings.TrimSpace(set) != "" {
		s, err := parseDocument(set, true, engine.InputDocument)
		if err != nil {
			return "", c.parseErr(err)
		}
		if len(s) > 5 {
			update = append(update, bson.E{Key: "$set", Value: s})
		}
	}
	if len(unset) > 0 {
		u := bson.D{}
		for _, p := range unset {
			u = append(u, bson.E{Key: p, Value: ""})
		}
		update = append(update, bson.E{Key: "$unset", Value: u})
	}
	if len(update) == 0 {
		return "", engine.Errorf(engine.KindParse, c.id, "update", "nothing to update")
	}
	if exp != nil {
		if err := c.checkExpected(ctx, coll, idv, exp); err != nil {
			return "", err
		}
	}
	res := coll.FindOneAndUpdate(ctx, guard(idv, exp), update, options.FindOneAndUpdate().SetReturnDocument(options.After))
	return c.finishWrite(ctx, coll, idv, exp != nil, res)
}

// Delete implements engine.DocumentStore.
func (c *Conn) Delete(ctx context.Context, db, collection string, ids []engine.Document, _ engine.WriteOptions) (uint64, error) {
	coll, err := c.coll("delete", db, collection)
	if err != nil {
		return 0, err
	}
	vals := make(bson.A, len(ids))
	for i, id := range ids {
		v, err := parseValue(id, engine.InputDocument)
		if err != nil {
			var e *engine.Error
			if errors.As(err, &e) {
				e.DocumentIndex, e.HasIndex = i, true
			}
			return 0, c.parseErr(err)
		}
		vals[i] = v
	}
	if len(vals) == 0 {
		return 0, nil
	}
	res, err := coll.DeleteMany(ctx, bson.D{{Key: "_id", Value: bson.D{{Key: "$in", Value: vals}}}})
	if err != nil {
		return 0, c.fail("delete", err)
	}
	return uint64(res.DeletedCount), nil //nolint:gosec // counts are non-negative
}

// SampleFields implements engine.DocumentStore.
func (c *Conn) SampleFields(ctx context.Context, db, collection string, n uint32) (engine.FieldSample, error) {
	coll, err := c.coll("sample", db, collection)
	if err != nil {
		return engine.FieldSample{}, err
	}
	ctx, cancel := context.WithTimeout(ctx, 15*time.Second)
	defer cancel()
	cur, fallback, err := c.openSample(ctx, coll, n)
	if err != nil {
		return engine.FieldSample{}, err
	}
	defer closeCursor(cur)

	type acc struct {
		docs  uint32
		types map[string]uint32
	}
	fields := map[string]*acc{}
	var order []string
	var sampled uint32
	for cur.Next(ctx) {
		sampled++
		elems, err := cur.Current.Elements()
		if err != nil {
			continue
		}
		for _, e := range elems {
			a := fields[e.Key()]
			if a == nil {
				a = &acc{types: map[string]uint32{}}
				fields[e.Key()] = a
				order = append(order, e.Key())
			}
			a.docs++
			a.types[typeAlias(e.Value().Type)]++
		}
	}
	if err := cur.Err(); err != nil {
		return engine.FieldSample{}, c.fail("sample", err)
	}
	out := engine.FieldSample{Sampled: sampled, UsedFallback: fallback}
	for _, name := range order {
		a := fields[name]
		fs := engine.FieldStat{Name: name, Frequency: float64(a.docs) / float64(max(sampled, 1))}
		for t, k := range a.types {
			fs.Types = append(fs.Types, engine.FieldType{Type: t, Count: k})
		}
		sort.Slice(fs.Types, func(i, j int) bool {
			if fs.Types[i].Count != fs.Types[j].Count {
				return fs.Types[i].Count > fs.Types[j].Count
			}
			return fs.Types[i].Type < fs.Types[j].Type
		})
		out.Fields = append(out.Fields, fs)
	}
	sort.SliceStable(out.Fields, func(i, j int) bool {
		a, b := out.Fields[i], out.Fields[j]
		if (a.Name == "_id") != (b.Name == "_id") {
			return a.Name == "_id"
		}
		if a.Frequency != b.Frequency {
			return a.Frequency > b.Frequency
		}
		return a.Name < b.Name
	})
	return out, nil
}

func (c *Conn) openSample(ctx context.Context, coll *mongo.Collection, n uint32) (*mongo.Cursor, bool, error) {
	if n == 0 {
		n = 100
	}
	n = min(n, 1000)
	cur, err := coll.Aggregate(ctx, mongo.Pipeline{{{Key: "$sample", Value: bson.D{{Key: "size", Value: int64(n)}}}}})
	if err == nil {
		return cur, false, nil
	}
	switch engine.KindOf(classify("sample", err, c.secret)) {
	case engine.KindAuth, engine.KindNetwork, engine.KindTimeout, engine.KindCanceled, engine.KindTLS:
		return nil, false, c.fail("sample", err)
	}
	cur, err = coll.Find(ctx, bson.D{}, options.Find().SetLimit(int64(n)))
	if err != nil {
		return nil, false, c.fail("sample", err)
	}
	return cur, true, nil
}

func closeCursor(cur *mongo.Cursor) {
	cctx, cancel := context.WithTimeout(context.Background(), 2*time.Second)
	defer cancel()
	_ = cur.Close(cctx)
}

// typeAlias returns the $type alias of a BSON type.
func typeAlias(t bson.Type) string {
	switch t {
	case bson.TypeDouble:
		return "double"
	case bson.TypeString:
		return "string"
	case bson.TypeEmbeddedDocument:
		return "object"
	case bson.TypeArray:
		return "array"
	case bson.TypeBinary:
		return "binData"
	case bson.TypeUndefined:
		return "undefined"
	case bson.TypeObjectID:
		return "objectId"
	case bson.TypeBoolean:
		return "bool"
	case bson.TypeDateTime:
		return "date"
	case bson.TypeNull:
		return "null"
	case bson.TypeRegex:
		return "regex"
	case bson.TypeDBPointer:
		return "dbPointer"
	case bson.TypeJavaScript:
		return "javascript"
	case bson.TypeSymbol:
		return "symbol"
	case bson.TypeCodeWithScope:
		return "javascriptWithScope"
	case bson.TypeInt32:
		return "int"
	case bson.TypeTimestamp:
		return "timestamp"
	case bson.TypeInt64:
		return "long"
	case bson.TypeDecimal128:
		return "decimal"
	case bson.TypeMinKey:
		return "minKey"
	case bson.TypeMaxKey:
		return "maxKey"
	}
	return "unknown"
}
