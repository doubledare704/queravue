package api_test

import (
	"context"
	"path/filepath"
	"testing"

	"github.com/doubledare704/queravue/core/internal/api"
	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/schema"
	"github.com/doubledare704/queravue/core/internal/session"
)

func TestSchemaService_SQLite(t *testing.T) {
	dir := t.TempDir()
	dbPath := filepath.Join(dir, "schema_test.db")

	opener := sqliteOpener{dbPath: dbPath}
	mgr := session.NewManager(opener)
	t.Cleanup(mgr.Shutdown)

	sess, err := mgr.Open(context.Background(), "schema-conn")
	if err != nil {
		t.Fatalf("open session: %v", err)
	}

	ex, _ := engine.As[engine.Executor](sess.Conn)
	ctx := context.Background()

	// Create tables, views, indexes, foreign keys
	initStatements := []string{
		`CREATE TABLE authors (
			id INTEGER PRIMARY KEY,
			name TEXT NOT NULL
		);`,
		`CREATE TABLE books (
			id INTEGER PRIMARY KEY,
			author_id INTEGER NOT NULL,
			title TEXT NOT NULL,
			isbn TEXT,
			FOREIGN KEY (author_id) REFERENCES authors(id)
		);`,
		`CREATE UNIQUE INDEX idx_books_isbn ON books(isbn);`,
		`CREATE VIEW book_summaries AS SELECT b.id, b.title, a.name AS author FROM books b JOIN authors a ON a.id = b.author_id;`,
	}
	for _, sql := range initStatements {
		if _, err := ex.Execute(ctx, engine.Statement{SQL: sql}, nilSink{}); err != nil {
			t.Fatalf("exec %q: %v", sql, err)
		}
	}

	cache := schema.NewCache()
	svc := api.NewSchemaService(mgr, cache)

	// 1. ListDatabases
	dbResp, err := svc.ListDatabases(ctx, &queravuev1.ListDatabasesRequest{SessionId: sess.ID})
	if err != nil {
		t.Fatalf("ListDatabases: %v", err)
	}
	if len(dbResp.GetDatabases()) == 0 || dbResp.GetDatabases()[0] != "main" {
		t.Errorf("databases = %v, want ['main']", dbResp.GetDatabases())
	}

	// 2. ListSchemas
	schemasResp, err := svc.ListSchemas(ctx, &queravuev1.ListSchemasRequest{SessionId: sess.ID, Database: "main"})
	if err != nil {
		t.Fatalf("ListSchemas: %v", err)
	}
	if len(schemasResp.GetSchemas()) == 0 || schemasResp.GetSchemas()[0] != "main" {
		t.Errorf("schemas = %v, want ['main']", schemasResp.GetSchemas())
	}

	// 3. ListObjects
	objResp, err := svc.ListObjects(ctx, &queravuev1.ListObjectsRequest{SessionId: sess.ID, Database: "main", Schema: "main"})
	if err != nil {
		t.Fatalf("ListObjects: %v", err)
	}
	objs := objResp.GetObjects()
	if len(objs) < 3 {
		t.Fatalf("got %d objects, want at least 3", len(objs))
	}
	names := make(map[string]queravuev1.SchemaObjectType)
	for _, o := range objs {
		names[o.GetName()] = o.GetType()
	}
	if names["authors"] != queravuev1.SchemaObjectType_SCHEMA_OBJECT_TYPE_TABLE {
		t.Errorf("authors type = %v, want TABLE", names["authors"])
	}
	if names["books"] != queravuev1.SchemaObjectType_SCHEMA_OBJECT_TYPE_TABLE {
		t.Errorf("books type = %v, want TABLE", names["books"])
	}
	if names["book_summaries"] != queravuev1.SchemaObjectType_SCHEMA_OBJECT_TYPE_VIEW {
		t.Errorf("book_summaries type = %v, want VIEW", names["book_summaries"])
	}

	// 4. GetTableDetails on table with PK and FK
	detailsResp, err := svc.GetTableDetails(ctx, &queravuev1.GetTableDetailsRequest{
		SessionId: sess.ID,
		TableRef:  &queravuev1.TableRef{Schema: "main", Table: "books"},
	})
	if err != nil {
		t.Fatalf("GetTableDetails: %v", err)
	}
	if !detailsResp.GetCanEdit() {
		t.Errorf("books should be editable (has PK)")
	}
	if len(detailsResp.GetColumns()) != 4 {
		t.Errorf("got %d columns, want 4", len(detailsResp.GetColumns()))
	}
	if len(detailsResp.GetForeignKeys()) != 1 {
		t.Errorf("got %d FKs, want 1", len(detailsResp.GetForeignKeys()))
	} else {
		fk := detailsResp.GetForeignKeys()[0]
		if fk.GetReferencedTable() != "authors" {
			t.Errorf("referenced table = %q, want authors", fk.GetReferencedTable())
		}
	}

	// 5. GetTableDetails on view -> should be read-only
	viewDetails, err := svc.GetTableDetails(ctx, &queravuev1.GetTableDetailsRequest{
		SessionId: sess.ID,
		TableRef:  &queravuev1.TableRef{Schema: "main", Table: "book_summaries"},
	})
	if err != nil {
		t.Fatalf("GetTableDetails on view: %v", err)
	}
	if viewDetails.GetCanEdit() {
		t.Errorf("view should NOT be editable")
	}

	// 6. Test caching and refresh
	// Check that cache has objects
	if _, ok := cache.GetObjects(sess.ID, "main", "main"); !ok {
		t.Errorf("expected objects to be cached")
	}
	// Refresh schema
	_, err = svc.RefreshSchema(ctx, &queravuev1.RefreshSchemaRequest{
		SessionId: sess.ID,
		TableRef:  &queravuev1.TableRef{Table: "books"},
	})
	if err != nil {
		t.Fatalf("RefreshSchema: %v", err)
	}
	if _, ok := cache.GetTableDetails(sess.ID, "", "", "books"); ok {
		t.Errorf("expected books details to be evicted after refresh")
	}
}
