//go:build integration

package mongo

import (
	"context"
	"errors"
	"fmt"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
)

// Smoke tests for the wire-compatible variants. They run against servers we
// cannot always start locally, so each is gated by an environment variable
// holding a full connection URI and is skipped when it is unset:
//
//	QV_DOCDB_URI   DocumentDB: `make test-docdb` sets it for the compose
//	               service (documentdb.io, DocumentDB Local); an Amazon
//	               DocumentDB cluster URI works too.
//	QV_COSMOS_URI  Azure Cosmos DB for MongoDB (RU or vCore) account URI. No
//	               Docker image speaks the Mongo API on Apple Silicon (the
//	               vNext emulator is NoSQL-only), so this one is run by hand.
//
// QV_*_DB overrides the scratch database (default "queravue_smoke"). The URI
// may hold credentials; the tests never log it.

func TestSmokeDocumentDB(t *testing.T) {
	smoke(t, "QV_DOCDB_URI", VariantDocumentDB)
}

func TestSmokeCosmosDB(t *testing.T) {
	smoke(t, "QV_COSMOS_URI", VariantCosmos)
}

func smoke(t *testing.T, envVar string, v Variant) {
	uri := os.Getenv(envVar)
	if uri == "" {
		t.Skipf("%s not set", envVar)
	}
	e := New(v)
	cfg, sec, err := e.ParseURI(uri)
	if err != nil {
		t.Fatalf("%s: %v", envVar, err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()
	conn, err := e.Connect(ctx, cfg, sec)
	if err != nil {
		t.Fatalf("connect: %v", err)
	}
	defer func() { _ = conn.Close() }()
	c := conn.(*Conn)

	// 1. Connect + server identity. Recorded in docs/engines/*.md.
	info, err := c.ServerInfo(ctx)
	if err != nil {
		t.Fatalf("server info: %v", err)
	}
	t.Logf("server: %s (buildInfo version %s)", info.Product, info.Version)

	// 2. List databases (must not fail even if the user may not list them).
	dbs, err := c.ListDatabases(ctx)
	if err != nil {
		t.Fatalf("list databases: %v", err)
	}
	t.Logf("databases visible: %d", len(dbs))

	db := env(strings.Replace(envVar, "_URI", "_DB", 1), "queravue_smoke")
	coll := fmt.Sprintf("smoke_%d", time.Now().UnixNano())
	t.Cleanup(func() {
		dctx, dcancel := context.WithTimeout(context.Background(), 20*time.Second)
		defer dcancel()
		if cl, err := c.live("cleanup"); err == nil {
			_ = cl.Database(db).Collection(coll).Drop(dctx)
		}
	})

	// 3. CRUD round trip through the document path.
	ids, err := c.Insert(ctx, db, coll, []engine.Document{
		`{"_id":{"$numberInt":"1"},"name":"alpha","n":{"$numberLong":"5"},"when":{"$date":{"$numberLong":"1700000000000"}}}`,
		`{"_id":{"$numberInt":"2"},"name":"beta","tags":["x","y"],"nested":{"k":{"$numberDouble":"1.5"}}}`,
	}, engine.WriteOptions{})
	if err != nil || len(ids) != 2 {
		t.Fatalf("insert = %v, %v", ids, err)
	}

	objs, err := c.ListObjects(ctx, db, "")
	if err != nil {
		t.Fatalf("list objects: %v", err)
	}
	found := false
	for _, o := range objs {
		found = found || o.Name == coll
	}
	if !found {
		t.Errorf("collection %s missing from %d listed objects", coll, len(objs))
	}

	var all []string
	if err := c.Find(ctx, engine.FindOptions{Database: db, Collection: coll, Sort: `{"_id":1}`}, collectInto(&all)); err != nil {
		t.Fatalf("find: %v", err)
	}
	if len(all) != 2 || !strings.Contains(all[0], `"n":{"$numberLong":"5"}`) || !strings.Contains(all[0], `"$date"`) {
		t.Fatalf("find returned %v (types must survive the server)", all)
	}
	var filtered []string
	if err := c.Find(ctx, engine.FindOptions{Database: db, Collection: coll, Filter: `{"name":"beta"}`, Projection: `{"name":1}`}, collectInto(&filtered)); err != nil || len(filtered) != 1 {
		t.Fatalf("filter+projection = %v, %v", filtered, err)
	}
	if n, err := c.Count(ctx, db, coll, `{}`, 10000); err != nil || n.N != 2 {
		t.Fatalf("count = %+v, %v", n, err)
	}

	edited := strings.Replace(all[0], `"alpha"`, `"alpha2"`, 1)
	if _, err := c.Replace(ctx, db, coll, ids[0], edited, engine.WriteOptions{Expected: &all[0]}); err != nil {
		t.Fatalf("replace with expected: %v", err)
	}
	if _, err := c.UpdateFields(ctx, db, coll, ids[0], `{"extra.deep":{"$numberInt":"1"}}`, []string{"when"}, engine.WriteOptions{}); err != nil {
		t.Fatalf("update fields: %v", err)
	}
	_, err = c.Replace(ctx, db, coll, ids[0], `{"name":"stale"}`, engine.WriteOptions{Expected: &edited})
	var ce *engine.Error
	if !errors.As(err, &ce) || ce.Kind != engine.KindConflict || ce.Current == nil {
		t.Fatalf("stale replace = %v, want conflict carrying the current document", err)
	}

	// 4. SampleFields: $sample is not available everywhere. Either path is
	// acceptable; which one ran is a finding for the docs.
	fs, err := c.SampleFields(ctx, db, coll, 100)
	if err != nil {
		t.Fatalf("sample fields: %v", err)
	}
	t.Logf("sample fields: %d fields, sampled %d, fallback=%v", len(fs.Fields), fs.Sampled, fs.UsedFallback)

	// 5. Indexes and stats. Listing and creating must work; usage and
	// collStats may be rejected, which must surface as an unsupported error.
	if _, _, err := c.CreateIndex(ctx, db, "", coll, engine.IndexSpec{Name: "smoke_name", Keys: []engine.IndexKey{{Name: "name"}}}, false); err != nil {
		t.Fatalf("create index: %v", err)
	}
	indexes, err := c.ListIndexes(ctx, db, "", coll)
	if err != nil {
		t.Fatalf("list indexes: %v", err)
	}
	var created *engine.IndexInfo
	for i := range indexes {
		if indexes[i].Spec.Name == "smoke_name" {
			created = &indexes[i]
		}
	}
	if created == nil {
		t.Fatalf("smoke_name missing from %d listed indexes", len(indexes))
	}
	t.Logf("index usage available=%v, size reported=%v", created.Usage.Available, created.SizeBytes != nil)
	if _, err := c.TableStats(ctx, db, "", coll); err != nil {
		var se *engine.Error
		if !errors.As(err, &se) || se.Kind != engine.KindUnsupported {
			t.Fatalf("collStats = %v, want success or an unsupported error", err)
		}
		t.Logf("collStats unsupported: %v", err)
	}
	if _, err := c.DropIndex(ctx, db, "", coll, "smoke_name", false); err != nil {
		t.Fatalf("drop index: %v", err)
	}

	if n, err := c.Delete(ctx, db, coll, ids, engine.WriteOptions{}); err != nil || n != 2 {
		t.Fatalf("delete = %d, %v", n, err)
	}
}
