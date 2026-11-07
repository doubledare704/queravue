package api_test

import (
	"context"
	"path/filepath"
	"strings"
	"testing"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/doubledare704/queravue/core/internal/api"
	"github.com/doubledare704/queravue/core/internal/connections"
	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/sqlite"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/history"
	"github.com/doubledare704/queravue/core/internal/schema"
	"github.com/doubledare704/queravue/core/internal/secrets"
	"github.com/doubledare704/queravue/core/internal/session"
)

type indexEnv struct {
	indexes *api.IndexService
	stats   *api.StatsService
	design  *api.SchemaDesignService
	schema  *api.SchemaService
	sess    *session.Session
	history *history.Store
}

func setupIndexEnv(t *testing.T, production bool) indexEnv {
	t.Helper()
	dir := t.TempDir()
	mgr := session.NewManager(sqliteOpener{dbPath: filepath.Join(dir, "i.db")})
	t.Cleanup(mgr.Shutdown)
	sess, err := mgr.Open(context.Background(), "test-conn")
	if err != nil {
		t.Fatal(err)
	}
	ex, _ := engine.As[engine.Executor](sess.Conn)
	for _, stmt := range []string{
		`CREATE TABLE orders (id INTEGER PRIMARY KEY, customer INTEGER, note TEXT)`,
		`CREATE INDEX orders_customer ON orders (customer)`,
	} {
		if _, err := ex.Execute(context.Background(), engine.Statement{SQL: stmt}, nilSink{}); err != nil {
			t.Fatal(err)
		}
	}
	hist, err := history.NewStore(":memory:", 100, nil)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = hist.Close() })
	reg, err := engine.NewRegistry(sqlite.New())
	if err != nil {
		t.Fatal(err)
	}
	cache := schema.NewCache()
	store := connections.NewFileStore(dir)
	_ = store.Save([]connections.Connection{{ID: "test-conn", Name: "T", EngineID: "sqlite", Production: production}})
	connSvc := connections.NewService(reg, store, secrets.NewMemory())
	return indexEnv{
		indexes: api.NewIndexService(mgr, connSvc, hist, nil, nil),
		design:  api.NewSchemaDesignService(mgr, connSvc, hist, cache, nil),
		schema:  api.NewSchemaService(mgr, cache),
		stats:   api.NewStatsService(mgr),
		sess:    sess,
		history: hist,
	}
}

func orders() *queravuev1.TableRef { return &queravuev1.TableRef{Table: "orders"} }

func noteIndex() *queravuev1.IndexSpec {
	return &queravuev1.IndexSpec{Name: "orders_note", Keys: []*queravuev1.IndexKey{{Name: "note"}}}
}

func listNames(t *testing.T, e indexEnv) []string {
	t.Helper()
	resp, err := e.indexes.ListIndexes(context.Background(), &queravuev1.ListIndexesRequest{SessionId: e.sess.ID, TableRef: orders()})
	if err != nil || resp.GetError() != nil {
		t.Fatalf("ListIndexes: %v %v", err, resp.GetError())
	}
	var names []string
	for _, ix := range resp.GetIndexes() {
		names = append(names, ix.GetSpec().GetName())
	}
	return names
}

func TestIndexServiceListsIndexes(t *testing.T) {
	e := setupIndexEnv(t, false)
	if got := listNames(t, e); len(got) != 1 || got[0] != "orders_customer" {
		t.Errorf("indexes = %v", got)
	}
}

func TestIndexServiceCreateDryRunChangesNothing(t *testing.T) {
	e := setupIndexEnv(t, false)
	resp, err := e.indexes.CreateIndex(context.Background(), &queravuev1.CreateIndexRequest{
		SessionId: e.sess.ID, TableRef: orders(), Spec: noteIndex(), DryRun: true,
	})
	if err != nil || resp.GetError() != nil {
		t.Fatalf("CreateIndex: %v %v", err, resp.GetError())
	}
	if !resp.GetDryRun() || resp.GetStatement() != `CREATE INDEX "orders_note" ON "orders" ("note");` {
		t.Errorf("response = %+v", resp)
	}
	if got := listNames(t, e); len(got) != 1 {
		t.Errorf("dry run created an index: %v", got)
	}
}

func TestIndexServiceCreateAndDrop(t *testing.T) {
	e := setupIndexEnv(t, false)
	ctx := context.Background()
	created, err := e.indexes.CreateIndex(ctx, &queravuev1.CreateIndexRequest{SessionId: e.sess.ID, TableRef: orders(), Spec: noteIndex()})
	if err != nil || created.GetError() != nil {
		t.Fatalf("CreateIndex: %v %v", err, created.GetError())
	}
	if created.GetIndexName() != "orders_note" {
		t.Errorf("index name = %q", created.GetIndexName())
	}
	if got := listNames(t, e); len(got) != 2 {
		t.Fatalf("indexes after create = %v", got)
	}

	refused, _ := e.indexes.DropIndex(ctx, &queravuev1.DropIndexRequest{SessionId: e.sess.ID, TableRef: orders(), IndexName: "orders_note"})
	if refused.GetError().GetKind() != queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_CONFIRMATION_REQUIRED ||
		refused.GetError().GetOperation() != "drop index orders_note" {
		t.Fatalf("unconfirmed drop: %+v", refused.GetError())
	}
	if got := listNames(t, e); len(got) != 2 {
		t.Fatalf("an unconfirmed drop removed an index: %v", got)
	}

	dropped, err := e.indexes.DropIndex(ctx, &queravuev1.DropIndexRequest{SessionId: e.sess.ID, TableRef: orders(), IndexName: "orders_note", Confirmed: true})
	if err != nil || dropped.GetError() != nil {
		t.Fatalf("DropIndex: %v %v", err, dropped.GetError())
	}
	if got := listNames(t, e); len(got) != 1 {
		t.Errorf("indexes after drop = %v", got)
	}
}

func TestIndexServiceDropDryRunNeedsNoConfirmation(t *testing.T) {
	e := setupIndexEnv(t, false)
	resp, _ := e.indexes.DropIndex(context.Background(), &queravuev1.DropIndexRequest{
		SessionId: e.sess.ID, TableRef: orders(), IndexName: "orders_customer", DryRun: true,
	})
	if resp.GetError() != nil || resp.GetStatement() != `DROP INDEX "orders_customer";` {
		t.Errorf("response = %+v", resp)
	}
	if got := listNames(t, e); len(got) != 1 {
		t.Errorf("dry run dropped the index: %v", got)
	}
}

func TestIndexServiceProductionNeedsConfirmationToCreate(t *testing.T) {
	e := setupIndexEnv(t, true)
	ctx := context.Background()
	req := &queravuev1.CreateIndexRequest{SessionId: e.sess.ID, TableRef: orders(), Spec: noteIndex()}
	resp, _ := e.indexes.CreateIndex(ctx, req)
	if resp.GetError().GetKind() != queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_CONFIRMATION_REQUIRED {
		t.Fatalf("error = %+v", resp.GetError())
	}
	if got := listNames(t, e); len(got) != 1 {
		t.Fatalf("a refused create built an index: %v", got)
	}
	req.Confirmed = true
	if resp, _ := e.indexes.CreateIndex(ctx, req); resp.GetError() != nil {
		t.Fatalf("confirmed create: %+v", resp.GetError())
	}
	if got := listNames(t, e); len(got) != 2 {
		t.Errorf("indexes = %v", got)
	}
}

func TestIndexServiceRejectsSpecTheEngineCannotExpress(t *testing.T) {
	e := setupIndexEnv(t, false)
	spec := noteIndex()
	spec.IncludeColumns = []string{"customer"}
	resp, _ := e.indexes.CreateIndex(context.Background(), &queravuev1.CreateIndexRequest{SessionId: e.sess.ID, TableRef: orders(), Spec: spec})
	if resp.GetError().GetKind() != queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_INVALID ||
		!strings.Contains(resp.GetError().GetMessage(), "included columns") {
		t.Errorf("error = %+v", resp.GetError())
	}
}

func TestIndexServiceRecordsAppliedStatementsInHistory(t *testing.T) {
	e := setupIndexEnv(t, false)
	ctx := context.Background()
	_, _ = e.indexes.CreateIndex(ctx, &queravuev1.CreateIndexRequest{SessionId: e.sess.ID, TableRef: orders(), Spec: noteIndex(), DryRun: true})
	_, _ = e.indexes.CreateIndex(ctx, &queravuev1.CreateIndexRequest{SessionId: e.sess.ID, TableRef: orders(), Spec: noteIndex()})
	entries, _, err := e.history.List(ctx, "", "", 10, 0)
	if err != nil {
		t.Fatal(err)
	}
	if len(entries) != 1 || !strings.HasPrefix(entries[0].QueryText, "CREATE INDEX") {
		t.Errorf("history = %+v", entries)
	}
}

func TestIndexServiceUnknownSessionAndMissingTable(t *testing.T) {
	e := setupIndexEnv(t, false)
	_, err := e.indexes.ListIndexes(context.Background(), &queravuev1.ListIndexesRequest{SessionId: "nope", TableRef: orders()})
	if status.Code(err) != codes.NotFound {
		t.Errorf("unknown session: %v", err)
	}
	_, err = e.indexes.ListIndexes(context.Background(), &queravuev1.ListIndexesRequest{SessionId: e.sess.ID})
	if status.Code(err) != codes.InvalidArgument {
		t.Errorf("missing table: %v", err)
	}
	resp, _ := e.indexes.ListIndexes(context.Background(), &queravuev1.ListIndexesRequest{SessionId: e.sess.ID, TableRef: &queravuev1.TableRef{Table: "ghost"}})
	if resp.GetError().GetKind() != queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_NOT_FOUND {
		t.Errorf("ghost table: %+v", resp.GetError())
	}
}

func TestStatsServiceReportsStats(t *testing.T) {
	e := setupIndexEnv(t, false)
	resp, err := e.stats.GetStats(context.Background(), &queravuev1.GetStatsRequest{SessionId: e.sess.ID, TableRef: orders()})
	if err != nil || resp.GetError() != nil {
		t.Fatalf("GetStats: %v %v", err, resp.GetError())
	}
	if len(resp.GetStats().GetExtras()) == 0 {
		t.Errorf("stats = %+v", resp.GetStats())
	}
	missing, _ := e.stats.GetStats(context.Background(), &queravuev1.GetStatsRequest{SessionId: e.sess.ID, TableRef: &queravuev1.TableRef{Table: "ghost"}})
	if missing.GetError().GetKind() != queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_NOT_FOUND {
		t.Errorf("ghost table: %+v", missing.GetError())
	}
}
