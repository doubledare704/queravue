package mongo

import (
	"context"
	"sort"
	"strings"
	"sync"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"

	"github.com/doubledare704/queravue/core/internal/engine"
)

var _ engine.SchemaInspector = (*Conn)(nil)

// ListDatabases implements engine.SchemaInspector. Servers that refuse
// listDatabases to restricted users fall back to the configured database.
func (c *Conn) ListDatabases(ctx context.Context) ([]string, error) {
	cl, err := c.live("list databases")
	if err != nil {
		return nil, err
	}
	names, err := cl.ListDatabaseNames(ctx, bson.D{})
	if err != nil {
		if c.defaultDB != "" && engine.KindOf(classify("list databases", err, c.secret)) == engine.KindAuth {
			return []string{c.defaultDB}, nil
		}
		return nil, c.fail("list databases", err)
	}
	sort.Strings(names)
	return names, nil
}

// ListSchemas implements engine.SchemaInspector. MongoDB has no schema level
// (ADR 0009), so it returns none.
func (c *Conn) ListSchemas(context.Context, string) ([]string, error) { return nil, nil }

// ListObjects implements engine.SchemaInspector: collections, views and time
// series of a database, including system.* collections (the API layer hides
// them unless asked). Estimated document counts are fetched concurrently with
// a short timeout; -1 means unknown.
func (c *Conn) ListObjects(ctx context.Context, database, _ string) ([]engine.SchemaObject, error) {
	cl, err := c.live("list objects")
	if err != nil {
		return nil, err
	}
	if database == "" {
		database = c.defaultDB
	}
	db := cl.Database(database)
	specs, err := db.ListCollectionSpecifications(ctx, bson.D{})
	if err != nil {
		return nil, c.fail("list objects", err)
	}
	out := make([]engine.SchemaObject, len(specs))
	for i, s := range specs {
		o := engine.SchemaObject{Name: s.Name, Type: engine.ObjectTypeCollection, EstimatedRows: -1}
		switch s.Type {
		case "view":
			o.Type = engine.ObjectTypeView
		case "timeseries":
			o.Type = engine.ObjectTypeTimeSeries
		}
		if v, err := s.Options.LookupErr("capped"); err == nil {
			o.Capped, _ = v.BooleanOK()
		}
		out[i] = o
	}
	sort.Slice(out, func(i, j int) bool { return out[i].Name < out[j].Name })

	sem := make(chan struct{}, 8)
	var wg sync.WaitGroup
	for i := range out {
		if out[i].Type == engine.ObjectTypeView {
			continue
		}
		wg.Add(1)
		sem <- struct{}{}
		go func(o *engine.SchemaObject) {
			defer wg.Done()
			defer func() { <-sem }()
			defer func() { _ = recover() }() // a driver panic must not take the core down
			cctx, cancel := context.WithTimeout(ctx, 2*time.Second)
			defer cancel()
			if n, err := db.Collection(o.Name).EstimatedDocumentCount(cctx); err == nil {
				o.EstimatedRows = n
			}
		}(&out[i])
	}
	wg.Wait()
	return out, nil
}

// DescribeTable implements engine.SchemaInspector. Collections have no fixed
// columns; fields come from DocumentStore.SampleFields.
func (c *Conn) DescribeTable(ctx context.Context, database, _, name string) (engine.TableDetails, error) {
	objs, err := c.ListObjects(ctx, database, "")
	if err != nil {
		return engine.TableDetails{}, err
	}
	for _, o := range objs {
		if o.Name == name {
			return engine.TableDetails{Database: database, Table: name, Type: o.Type, EstimatedRows: o.EstimatedRows,
				CanEdit: o.Type != engine.ObjectTypeView && !strings.HasPrefix(name, "system.")}, nil
		}
	}
	return engine.TableDetails{}, engine.Errorf(engine.KindNotFound, c.id, "describe", "collection %q not found", name)
}
