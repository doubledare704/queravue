package api_test

import (
	"context"
	"errors"
	"io"
	"slices"
	"strings"
	"sync"
	"testing"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/doubledare704/queravue/core/internal/api"
	"github.com/doubledare704/queravue/core/internal/connections"
	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/secrets"
	"github.com/doubledare704/queravue/core/internal/session"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

type loadedTable struct {
	target  engine.LoadTarget
	columns []string
	rows    [][]engine.Value
}

type fakeMockSQLConn struct {
	tables     map[string]engine.TableDetails
	relations  []engine.TableRelation
	keyed      []engine.KeyedColumn
	existing   map[string][]engine.Value
	loaded     []loadedTable
	loadDelay  time.Duration
	batchLimit int
	mu         sync.Mutex
}

func (*fakeMockSQLConn) Ping(context.Context) error { return nil }
func (*fakeMockSQLConn) ServerInfo(context.Context) (engine.ServerInfo, error) {
	return engine.ServerInfo{}, nil
}
func (*fakeMockSQLConn) Close() error                                    { return nil }
func (*fakeMockSQLConn) Dialect() sqldialect.Dialect                     { return sqldialect.Postgres }
func (*fakeMockSQLConn) ListDatabases(context.Context) ([]string, error) { return []string{"app"}, nil }
func (*fakeMockSQLConn) ListSchemas(context.Context, string) ([]string, error) {
	return []string{"public"}, nil
}
func (*fakeMockSQLConn) ListObjects(context.Context, string, string) ([]engine.SchemaObject, error) {
	return nil, nil
}

func (f *fakeMockSQLConn) DescribeTable(_ context.Context, _, _, table string) (engine.TableDetails, error) {
	td, ok := f.tables[table]
	if !ok {
		return engine.TableDetails{}, engine.Errorf(engine.KindNotFound, "postgres", "describe", "table %s not found", table)
	}
	return td, nil
}

func (f *fakeMockSQLConn) ListKeyedColumns(context.Context, string, string) ([]engine.KeyedColumn, error) {
	return f.keyed, nil
}

func (f *fakeMockSQLConn) ListRelations(context.Context, string, string) ([]engine.TableRelation, error) {
	return f.relations, nil
}

func (f *fakeMockSQLConn) Execute(_ context.Context, stmt engine.Statement, sink engine.RowSink) (engine.Summary, error) {
	if err := sink.Columns([]engine.Column{{Name: "id", Kind: engine.VInt}}); err != nil {
		return engine.Summary{}, err
	}
	for tbl, vals := range f.existing {
		if strings.Contains(stmt.SQL, `"`+tbl+`"`) {
			rows := make([][]engine.Value, len(vals))
			for i, v := range vals {
				rows[i] = []engine.Value{v}
			}
			_ = sink.Batch(rows)
			break
		}
	}
	return engine.Summary{HasRows: true}, nil
}

func (f *fakeMockSQLConn) LoadRows(ctx context.Context, target engine.LoadTarget, columns []string, src engine.RowBatchSource) (engine.LoadStats, error) {
	var stats engine.LoadStats
	var collected [][]engine.Value
	for {
		if f.loadDelay > 0 {
			time.Sleep(f.loadDelay)
		}
		batch, err := src.Next(ctx)
		if errors.Is(err, io.EOF) {
			break
		}
		if err != nil {
			if len(collected) > 0 {
				f.mu.Lock()
				f.loaded = append(f.loaded, loadedTable{target: target, columns: columns, rows: collected})
				f.mu.Unlock()
			}
			return stats, err
		}
		collected = append(collected, batch...)
		stats.Rows += uint64(len(batch))
		stats.Batches++
		if f.batchLimit > 0 && int(stats.Batches) >= f.batchLimit {
			f.mu.Lock()
			f.loaded = append(f.loaded, loadedTable{target: target, columns: columns, rows: collected})
			f.mu.Unlock()
			return stats, context.Canceled
		}
	}
	f.mu.Lock()
	f.loaded = append(f.loaded, loadedTable{target: target, columns: columns, rows: collected})
	f.mu.Unlock()
	return stats, nil
}

type fakeMockDocConn struct {
	fakeDocConn
	loadedDocs []string
}

func (f *fakeMockDocConn) SampleFieldPaths(context.Context, string, string, engine.PathSampleOptions) (engine.FieldPathSample, error) {
	return engine.FieldPathSample{
		Sampled: 5,
		Paths: []engine.FieldPathStat{
			{Path: "_id", Frequency: 1, Types: []engine.FieldType{{Type: "objectId", Count: 5}}},
			{Path: "email", Frequency: 1, Types: []engine.FieldType{{Type: "string", Count: 5}}},
			{Path: "profile", Frequency: 1, Types: []engine.FieldType{{Type: "object", Count: 5}}},
			{Path: "profile.city", Frequency: 1, Types: []engine.FieldType{{Type: "string", Count: 5}}},
			{Path: "tags", Frequency: 1, Types: []engine.FieldType{{Type: "array", Count: 5}}},
			{Path: "tags.[]", Frequency: 1, Types: []engine.FieldType{{Type: "string", Count: 10}}},
		},
	}, nil
}

func (f *fakeMockDocConn) LoadDocuments(ctx context.Context, _, _ string, src engine.DocumentBatchSource) (engine.LoadStats, error) {
	var stats engine.LoadStats
	for {
		batch, err := src.Next(ctx)
		if errors.Is(err, io.EOF) {
			break
		}
		if err != nil {
			return stats, err
		}
		f.loadedDocs = append(f.loadedDocs, batch...)
		stats.Rows += uint64(len(batch))
		stats.Batches++
	}
	return stats, nil
}

type runMockRecorder struct {
	grpc.ServerStream
	ctx  context.Context
	sent []*queravuev1.RunMockResponse
}

func (r *runMockRecorder) Context() context.Context {
	if r.ctx != nil {
		return r.ctx
	}
	return context.Background()
}

func (r *runMockRecorder) Send(m *queravuev1.RunMockResponse) error {
	r.sent = append(r.sent, m)
	return nil
}

func newMockEnv(t *testing.T, conn engine.Conn, production bool) (*api.MockDataService, string) {
	t.Helper()
	connID := "test-conn"
	var connSvc *connections.Service
	if production {
		store := connections.NewFileStore(t.TempDir())
		if err := store.Save([]connections.Connection{{
			ID:         connID,
			Name:       "prod-db",
			EngineID:   "fake",
			Production: true,
		}}); err != nil {
			t.Fatal(err)
		}
		reg, err := engine.NewRegistry()
		if err != nil {
			t.Fatal(err)
		}
		connSvc = connections.NewService(reg, store, secrets.NewMemory())
	}

	mgr := session.NewManager(fakeOpener{conn: conn})
	t.Cleanup(mgr.Shutdown)
	sess, err := mgr.Open(context.Background(), connID)
	if err != nil {
		t.Fatal(err)
	}
	return api.NewMockDataService(mgr, connSvc, nil), sess.ID
}

func sampleSQLConn() *fakeMockSQLConn {
	return &fakeMockSQLConn{
		tables: map[string]engine.TableDetails{
			"orgs": {
				Database: "app", Schema: "public", Table: "orgs",
				Columns: []engine.ColumnDef{
					{Name: "id", TypeName: "serial", Kind: engine.VInt, IsPrimaryKey: true, Identity: true},
					{Name: "name", TypeName: "text", Kind: engine.VText},
				},
			},
			"users": {
				Database: "app", Schema: "public", Table: "users",
				Columns: []engine.ColumnDef{
					{Name: "id", TypeName: "serial", Kind: engine.VInt, IsPrimaryKey: true, Identity: true},
					{Name: "org_id", TypeName: "int4", Kind: engine.VInt},
					{Name: "email", TypeName: "text", Kind: engine.VText},
				},
				ForeignKeys: []engine.ForeignKeyDef{
					{Name: "fk_users_org", Columns: []string{"org_id"}, ReferencedTable: "orgs", ReferencedColumns: []string{"id"}},
				},
			},
		},
		keyed: []engine.KeyedColumn{
			{Table: "orgs", Name: "id", TypeName: "int4", PrimaryKeyOrder: 1},
			{Table: "users", Name: "id", TypeName: "int4", PrimaryKeyOrder: 1},
			{Table: "users", Name: "org_id", TypeName: "int4", Nullable: false},
		},
		relations: []engine.TableRelation{
			{
				Table: "users",
				ForeignKeyDef: engine.ForeignKeyDef{
					Name: "fk_users_org", Columns: []string{"org_id"}, ReferencedTable: "orgs", ReferencedColumns: []string{"id"},
				},
			},
		},
	}
}

type mockBareConn struct{}

func (mockBareConn) Ping(context.Context) error { return nil }
func (mockBareConn) ServerInfo(context.Context) (engine.ServerInfo, error) {
	return engine.ServerInfo{}, nil
}
func (mockBareConn) Close() error { return nil }

func TestMockDataServiceSessionAndCapabilities(t *testing.T) {
	svc, sid := newMockEnv(t, mockBareConn{}, false)

	_, err := svc.SuggestMockSpec(context.Background(), &queravuev1.SuggestMockSpecRequest{
		SessionId: "missing",
	})
	if status.Code(err) != codes.NotFound {
		t.Fatalf("missing session code=%v, want NotFound", status.Code(err))
	}

	_, err = svc.SuggestMockSpec(context.Background(), &queravuev1.SuggestMockSpecRequest{
		SessionId: sid,
		Tables:    []*queravuev1.TableRef{{Database: "app", Schema: "public", Table: "users"}},
	})
	if status.Code(err) != codes.FailedPrecondition {
		t.Fatalf("bare conn SuggestMockSpec code=%v, want FailedPrecondition", status.Code(err))
	}

	_, err = svc.PreviewMock(context.Background(), &queravuev1.PreviewMockRequest{
		SessionId: sid,
		Spec: &queravuev1.MockSpec{
			Targets: []*queravuev1.MockTarget{{
				Target: &queravuev1.MockTargetRef{Target: &queravuev1.MockTargetRef_Table{
					Table: &queravuev1.TableRef{Table: "users"},
				}},
				Rows:  5,
				Rules: []*queravuev1.MockColumnRule{{ColumnOrPath: "id", Rule: &queravuev1.MockColumnRule_Sequence{Sequence: &queravuev1.SequenceRule{Start: 1}}}},
			}},
		},
	})
	if status.Code(err) != codes.FailedPrecondition {
		t.Fatalf("bare conn PreviewMock code=%v, want FailedPrecondition", status.Code(err))
	}

	rec := &runMockRecorder{}
	err = svc.RunMock(&queravuev1.RunMockRequest{
		SessionId: sid,
		Spec: &queravuev1.MockSpec{
			Targets: []*queravuev1.MockTarget{{
				Target: &queravuev1.MockTargetRef{Target: &queravuev1.MockTargetRef_Table{
					Table: &queravuev1.TableRef{Table: "users"},
				}},
				Rows:  5,
				Rules: []*queravuev1.MockColumnRule{{ColumnOrPath: "id", Rule: &queravuev1.MockColumnRule_Sequence{Sequence: &queravuev1.SequenceRule{Start: 1}}}},
			}},
		},
	}, rec)
	if status.Code(err) != codes.FailedPrecondition {
		t.Fatalf("bare conn RunMock code=%v, want FailedPrecondition", status.Code(err))
	}
}

func TestMockDataServiceSuggestPreviewAndRunSQLWithFK(t *testing.T) {
	conn := sampleSQLConn()
	svc, sid := newMockEnv(t, conn, false)

	// Pass child first to verify topological ordering puts orgs before users.
	sug, err := svc.SuggestMockSpec(context.Background(), &queravuev1.SuggestMockSpecRequest{
		SessionId: sid,
		Tables: []*queravuev1.TableRef{
			{Database: "app", Schema: "public", Table: "users"},
			{Database: "app", Schema: "public", Table: "orgs"},
		},
		Rows: 25,
	})
	if err != nil {
		t.Fatal(err)
	}
	if sug.GetError() != nil || len(sug.GetCycles()) != 0 {
		t.Fatalf("unexpected error/cycles: err=%v cycles=%v", sug.GetError(), sug.GetCycles())
	}
	if !slices.Contains(sug.GetFakerKinds(), "email") {
		t.Fatalf("faker_kinds missing email: %v", sug.GetFakerKinds())
	}
	targets := sug.GetSpec().GetTargets()
	if len(targets) != 2 || targets[0].GetTarget().GetTable().GetTable() != "orgs" || targets[1].GetTarget().GetTable().GetTable() != "users" {
		t.Fatalf("expected orgs then users, got %+v", targets)
	}

	// Preview default 20 rows and verify nothing written to conn.loaded.
	prevDefault, err := svc.PreviewMock(context.Background(), &queravuev1.PreviewMockRequest{
		SessionId: sid,
		Spec:      sug.GetSpec(),
	})
	if err != nil {
		t.Fatal(err)
	}
	if prevDefault.GetError() != nil {
		t.Fatalf("preview error: %+v", prevDefault.GetError())
	}
	if len(prevDefault.GetPreviews()[0].GetRows().GetRows()) != 20 {
		t.Fatalf("default preview rows = %d, want 20", len(prevDefault.GetPreviews()[0].GetRows().GetRows()))
	}
	if len(conn.loaded) != 0 {
		t.Fatalf("PreviewMock wrote %d tables, want 0", len(conn.loaded))
	}

	// Preview > 200 clamps to 200.
	sug.Spec.Targets[0].Rows = 500
	sug.Spec.Targets[1].Rows = 500
	prevMax, err := svc.PreviewMock(context.Background(), &queravuev1.PreviewMockRequest{
		SessionId: sid,
		Spec:      sug.GetSpec(),
		Rows:      999,
	})
	if err != nil {
		t.Fatal(err)
	}
	if len(prevMax.GetPreviews()[0].GetRows().GetRows()) != 200 {
		t.Fatalf("clamped preview rows = %d, want 200", len(prevMax.GetPreviews()[0].GetRows().GetRows()))
	}

	// Reset rows to 25 and RunMock.
	sug.Spec.Targets[0].Rows = 25
	sug.Spec.Targets[1].Rows = 25
	rec := &runMockRecorder{}
	if err := svc.RunMock(&queravuev1.RunMockRequest{SessionId: sid, Spec: sug.GetSpec()}, rec); err != nil {
		t.Fatal(err)
	}
	var doneCount int
	var sum *queravuev1.MockSummary
	for _, ev := range rec.sent {
		if ev.GetError() != nil {
			t.Fatalf("unexpected run error: %+v", ev.GetError())
		}
		if ev.GetTargetDone() != nil {
			doneCount++
		}
		if ev.GetSummary() != nil {
			sum = ev.GetSummary()
		}
	}
	if doneCount != 2 || sum == nil || sum.GetRows() != 50 {
		t.Fatalf("doneCount=%d sum=%+v, want 2 targets and 50 rows", doneCount, sum)
	}
	if len(conn.loaded) != 2 {
		t.Fatalf("loaded tables = %d, want 2", len(conn.loaded))
	}
	// Verify child FK values (org_id in users) all exist in parent orgs (id).
	orgIDCol := slices.Index(conn.loaded[0].columns, "id")
	userOrgCol := slices.Index(conn.loaded[1].columns, "org_id")
	if orgIDCol < 0 || userOrgCol < 0 {
		t.Fatalf("missing expected columns: orgs=%v users=%v", conn.loaded[0].columns, conn.loaded[1].columns)
	}
	parentIDs := map[int64]bool{}
	for _, r := range conn.loaded[0].rows {
		parentIDs[r[orgIDCol].Int] = true
	}
	for i, r := range conn.loaded[1].rows {
		if !parentIDs[r[userOrgCol].Int] {
			t.Fatalf("users row %d FK org_id=%d not found in parent orgs", i, r[userOrgCol].Int)
		}
	}
}

func TestMockDataServiceMongoSuggestPreviewRun(t *testing.T) {
	conn := &fakeMockDocConn{}
	svc, sid := newMockEnv(t, conn, false)

	sug, err := svc.SuggestMockSpec(context.Background(), &queravuev1.SuggestMockSpecRequest{
		SessionId:   sid,
		Collections: []*queravuev1.CollectionRef{{Database: "shop", Collection: "customers"}},
		Rows:        15,
	})
	if err != nil {
		t.Fatal(err)
	}
	if sug.GetError() != nil || len(sug.GetSpec().GetTargets()) != 1 {
		t.Fatalf("suggest failed: %+v", sug)
	}

	prev, err := svc.PreviewMock(context.Background(), &queravuev1.PreviewMockRequest{
		SessionId: sid,
		Spec:      sug.GetSpec(),
		Rows:      5,
	})
	if err != nil {
		t.Fatal(err)
	}
	if len(prev.GetPreviews()[0].GetDocumentsEjson()) != 5 || len(conn.loadedDocs) != 0 {
		t.Fatalf("preview docs=%d loadedDocs=%d", len(prev.GetPreviews()[0].GetDocumentsEjson()), len(conn.loadedDocs))
	}

	rec := &runMockRecorder{}
	if err := svc.RunMock(&queravuev1.RunMockRequest{SessionId: sid, Spec: sug.GetSpec()}, rec); err != nil {
		t.Fatal(err)
	}
	if len(conn.loadedDocs) != 15 {
		t.Fatalf("loadedDocs = %d, want 15", len(conn.loadedDocs))
	}
	for i, d := range conn.loadedDocs {
		var parsed bson.D
		if err := bson.UnmarshalExtJSON([]byte(d), true, &parsed); err != nil {
			t.Fatalf("doc %d invalid canonical EJSON: %v", i, err)
		}
	}
	for i := range 5 {
		if prev.GetPreviews()[0].GetDocumentsEjson()[i] != conn.loadedDocs[i] {
			t.Fatalf("preview doc %d differs from run doc", i)
		}
	}
}

func TestMockDataServiceProductionConfirmationAndErrors(t *testing.T) {
	conn := sampleSQLConn()
	svc, sid := newMockEnv(t, conn, true)

	spec := &queravuev1.MockSpec{
		Seed: 1,
		Targets: []*queravuev1.MockTarget{{
			Target: &queravuev1.MockTargetRef{Target: &queravuev1.MockTargetRef_Table{
				Table: &queravuev1.TableRef{Database: "app", Schema: "public", Table: "orgs"},
			}},
			Rows: 5,
			Rules: []*queravuev1.MockColumnRule{
				{ColumnOrPath: "name", Rule: &queravuev1.MockColumnRule_Faker{Faker: &queravuev1.FakerRule{Kind: "company"}}},
			},
		}},
	}

	rec := &runMockRecorder{}
	if err := svc.RunMock(&queravuev1.RunMockRequest{SessionId: sid, Spec: spec, Confirmed: false}, rec); err != nil {
		t.Fatal(err)
	}
	if len(rec.sent) != 2 || rec.sent[0].GetError().GetKind() != queravuev1.MockErrorKind_MOCK_ERROR_KIND_CONFIRMATION_REQUIRED {
		t.Fatalf("expected CONFIRMATION_REQUIRED, got %+v", rec.sent)
	}
	if len(conn.loaded) != 0 {
		t.Fatal("unconfirmed production run wrote rows")
	}

	// With confirmed=true it runs.
	rec2 := &runMockRecorder{}
	if err := svc.RunMock(&queravuev1.RunMockRequest{SessionId: sid, Spec: spec, Confirmed: true}, rec2); err != nil {
		t.Fatal(err)
	}
	if len(conn.loaded) != 1 || len(conn.loaded[0].rows) != 5 {
		t.Fatalf("confirmed run loaded %+v", conn.loaded)
	}

	// Unique exhaustion surfaces column name.
	exhaustSpec := &queravuev1.MockSpec{
		Seed: 1,
		Targets: []*queravuev1.MockTarget{{
			Target: &queravuev1.MockTargetRef{Target: &queravuev1.MockTargetRef_Table{
				Table: &queravuev1.TableRef{Database: "app", Schema: "public", Table: "orgs"},
			}},
			Rows: 10,
			Rules: []*queravuev1.MockColumnRule{
				{
					ColumnOrPath: "tiny_code",
					Unique:       true,
					Rule:         &queravuev1.MockColumnRule_IntRange{IntRange: &queravuev1.IntRangeRule{Min: 1, Max: 3}},
				},
			},
		}},
	}
	rec3 := &runMockRecorder{}
	if err := svc.RunMock(&queravuev1.RunMockRequest{SessionId: sid, Spec: exhaustSpec, Confirmed: true}, rec3); err != nil {
		t.Fatal(err)
	}
	if rec3.sent[0].GetError().GetKind() != queravuev1.MockErrorKind_MOCK_ERROR_KIND_UNIQUE_EXHAUSTED ||
		rec3.sent[0].GetError().GetColumn() != "tiny_code" {
		t.Fatalf("expected UNIQUE_EXHAUSTED for tiny_code, got %+v", rec3.sent)
	}
}

func TestMockDataServiceCancelStopsAfterCurrentBatch(t *testing.T) {
	conn := sampleSQLConn()
	conn.batchLimit = 2
	svc, sid := newMockEnv(t, conn, false)

	spec := &queravuev1.MockSpec{
		Seed: 1,
		Targets: []*queravuev1.MockTarget{{
			Target: &queravuev1.MockTargetRef{Target: &queravuev1.MockTargetRef_Table{
				Table: &queravuev1.TableRef{Database: "app", Schema: "public", Table: "orgs"},
			}},
			Rows: 10000,
			Rules: []*queravuev1.MockColumnRule{
				{ColumnOrPath: "id", Rule: &queravuev1.MockColumnRule_Sequence{Sequence: &queravuev1.SequenceRule{Start: 1}}},
			},
		}},
	}
	rec := &runMockRecorder{}
	if err := svc.RunMock(&queravuev1.RunMockRequest{SessionId: sid, Spec: spec}, rec); err != nil {
		t.Fatal(err)
	}
	var gotErr *queravuev1.MockError
	var gotSum *queravuev1.MockSummary
	for _, ev := range rec.sent {
		if ev.GetError() != nil {
			gotErr = ev.GetError()
		}
		if ev.GetSummary() != nil {
			gotSum = ev.GetSummary()
		}
	}
	if gotErr == nil || gotErr.GetKind() != queravuev1.MockErrorKind_MOCK_ERROR_KIND_CANCELED {
		t.Fatalf("expected CANCELED error, got %+v", gotErr)
	}
	if gotSum == nil || gotSum.GetRows() != 4000 {
		t.Fatalf("expected 4000 committed rows from 2 batches, got %+v", gotSum)
	}
}

func TestMockDataServiceExistingKeyLookup(t *testing.T) {
	conn := sampleSQLConn()
	conn.existing = map[string][]engine.Value{
		"orgs": {engine.Int(100), engine.Int(200)},
	}
	svc, sid := newMockEnv(t, conn, false)

	spec := &queravuev1.MockSpec{
		Seed: 11,
		Targets: []*queravuev1.MockTarget{{
			Target: &queravuev1.MockTargetRef{Target: &queravuev1.MockTargetRef_Table{
				Table: &queravuev1.TableRef{Database: "app", Schema: "public", Table: "users"},
			}},
			Rows: 10,
			Rules: []*queravuev1.MockColumnRule{
				{
					ColumnOrPath: "org_id",
					Rule: &queravuev1.MockColumnRule_ForeignKey{
						ForeignKey: &queravuev1.ForeignKeyRule{
							Parent:           &queravuev1.TableRef{Database: "app", Schema: "public", Table: "orgs"},
							ParentColumn:     "id",
							FromExistingRows: true,
						},
					},
				},
			},
		}},
	}
	rec := &runMockRecorder{}
	if err := svc.RunMock(&queravuev1.RunMockRequest{SessionId: sid, Spec: spec}, rec); err != nil {
		t.Fatal(err)
	}
	if len(conn.loaded) != 1 || len(conn.loaded[0].rows) != 10 {
		t.Fatalf("loaded = %+v", conn.loaded)
	}
	for _, r := range conn.loaded[0].rows {
		if r[0].Int != 100 && r[0].Int != 200 {
			t.Fatalf("FK value %d not drawn from existing parent keys {100,200}", r[0].Int)
		}
	}
}

type noGraphSQLConn struct {
	inner *fakeMockSQLConn
}

func (c *noGraphSQLConn) Ping(ctx context.Context) error { return c.inner.Ping(ctx) }
func (c *noGraphSQLConn) ServerInfo(ctx context.Context) (engine.ServerInfo, error) {
	return c.inner.ServerInfo(ctx)
}
func (c *noGraphSQLConn) Close() error                { return c.inner.Close() }
func (c *noGraphSQLConn) Dialect() sqldialect.Dialect { return c.inner.Dialect() }
func (c *noGraphSQLConn) ListDatabases(ctx context.Context) ([]string, error) {
	return c.inner.ListDatabases(ctx)
}
func (c *noGraphSQLConn) ListSchemas(ctx context.Context, db string) ([]string, error) {
	return c.inner.ListSchemas(ctx, db)
}
func (c *noGraphSQLConn) ListObjects(ctx context.Context, db, sc string) ([]engine.SchemaObject, error) {
	return c.inner.ListObjects(ctx, db, sc)
}
func (c *noGraphSQLConn) DescribeTable(ctx context.Context, db, sc, tbl string) (engine.TableDetails, error) {
	return c.inner.DescribeTable(ctx, db, sc, tbl)
}
func (c *noGraphSQLConn) LoadRows(ctx context.Context, t engine.LoadTarget, cols []string, src engine.RowBatchSource) (engine.LoadStats, error) {
	return c.inner.LoadRows(ctx, t, cols, src)
}

func TestMockDataServiceWithoutSchemaGraphPreservesOrderAndSkipsFK(t *testing.T) {
	conn := &noGraphSQLConn{inner: sampleSQLConn()}
	svc, sid := newMockEnv(t, conn, false)

	sug, err := svc.SuggestMockSpec(context.Background(), &queravuev1.SuggestMockSpecRequest{
		SessionId: sid,
		Tables: []*queravuev1.TableRef{
			{Database: "app", Schema: "public", Table: "users"},
			{Database: "app", Schema: "public", Table: "orgs"},
		},
	})
	if err != nil {
		t.Fatal(err)
	}
	targets := sug.GetSpec().GetTargets()
	if len(targets) != 2 || targets[0].GetTarget().GetTable().GetTable() != "users" || targets[1].GetTarget().GetTable().GetTable() != "orgs" {
		t.Fatalf("expected user-picked order users then orgs, got %+v", targets)
	}
	for _, r := range targets[0].GetRules() {
		if r.GetColumnOrPath() == "org_id" && r.GetForeignKey() != nil {
			t.Fatalf("expected no foreign_key rule without schema_graph, got %+v", r)
		}
	}
}

func TestMockDataServiceCycleDetectionAndRunCycleError(t *testing.T) {
	conn := sampleSQLConn()
	conn.relations = append(conn.relations, engine.TableRelation{
		Table: "orgs",
		ForeignKeyDef: engine.ForeignKeyDef{
			Name: "fk_orgs_owner", Columns: []string{"owner_id"}, ReferencedTable: "users", ReferencedColumns: []string{"id"},
		},
	})
	svc, sid := newMockEnv(t, conn, false)

	sug, err := svc.SuggestMockSpec(context.Background(), &queravuev1.SuggestMockSpecRequest{
		SessionId: sid,
		Tables: []*queravuev1.TableRef{
			{Database: "app", Schema: "public", Table: "orgs"},
			{Database: "app", Schema: "public", Table: "users"},
		},
	})
	if err != nil {
		t.Fatal(err)
	}
	if len(sug.GetCycles()) != 1 || len(sug.GetCycles()[0].GetEdges()) != 2 {
		t.Fatalf("expected 1 cycle with 2 edges, got %+v", sug.GetCycles())
	}

	cycleSpec := &queravuev1.MockSpec{
		Seed: 1,
		Targets: []*queravuev1.MockTarget{
			{
				Target: &queravuev1.MockTargetRef{Target: &queravuev1.MockTargetRef_Table{
					Table: &queravuev1.TableRef{Database: "app", Schema: "public", Table: "orgs"},
				}},
				Rows: 5,
				Rules: []*queravuev1.MockColumnRule{
					{ColumnOrPath: "id", Rule: &queravuev1.MockColumnRule_Sequence{Sequence: &queravuev1.SequenceRule{Start: 1}}},
					{
						ColumnOrPath: "owner_id",
						Rule: &queravuev1.MockColumnRule_ForeignKey{
							ForeignKey: &queravuev1.ForeignKeyRule{
								Parent:       &queravuev1.TableRef{Database: "app", Schema: "public", Table: "users"},
								ParentColumn: "id",
							},
						},
					},
				},
			},
			{
				Target: &queravuev1.MockTargetRef{Target: &queravuev1.MockTargetRef_Table{
					Table: &queravuev1.TableRef{Database: "app", Schema: "public", Table: "users"},
				}},
				Rows: 5,
				Rules: []*queravuev1.MockColumnRule{
					{ColumnOrPath: "id", Rule: &queravuev1.MockColumnRule_Sequence{Sequence: &queravuev1.SequenceRule{Start: 1}}},
					{
						ColumnOrPath: "org_id",
						Rule: &queravuev1.MockColumnRule_ForeignKey{
							ForeignKey: &queravuev1.ForeignKeyRule{
								Parent:       &queravuev1.TableRef{Database: "app", Schema: "public", Table: "orgs"},
								ParentColumn: "id",
							},
						},
					},
				},
			},
		},
	}
	rec := &runMockRecorder{}
	if err := svc.RunMock(&queravuev1.RunMockRequest{SessionId: sid, Spec: cycleSpec}, rec); err != nil {
		t.Fatal(err)
	}
	if rec.sent[0].GetError().GetKind() != queravuev1.MockErrorKind_MOCK_ERROR_KIND_CYCLE {
		t.Fatalf("expected CYCLE error, got %+v", rec.sent)
	}
}

func TestMockDataServiceProgressThrottled(t *testing.T) {
	conn := sampleSQLConn()
	conn.loadDelay = 120 * time.Millisecond
	svc, sid := newMockEnv(t, conn, false)

	spec := &queravuev1.MockSpec{
		Seed: 1,
		Targets: []*queravuev1.MockTarget{{
			Target: &queravuev1.MockTargetRef{Target: &queravuev1.MockTargetRef_Table{
				Table: &queravuev1.TableRef{Database: "app", Schema: "public", Table: "orgs"},
			}},
			Rows: 10000,
			Rules: []*queravuev1.MockColumnRule{
				{ColumnOrPath: "id", Rule: &queravuev1.MockColumnRule_Sequence{Sequence: &queravuev1.SequenceRule{Start: 1}}},
			},
		}},
	}
	rec := &runMockRecorder{}
	if err := svc.RunMock(&queravuev1.RunMockRequest{SessionId: sid, Spec: spec}, rec); err != nil {
		t.Fatal(err)
	}
	var progressCount int
	for _, ev := range rec.sent {
		if ev.GetProgress() != nil {
			progressCount++
		}
	}
	// 5 batches * 120ms = ~600ms; throttled to 250ms => 1..3 progress events instead of 5.
	if progressCount == 0 || progressCount >= 5 {
		t.Fatalf("expected throttled progress events (1..4), got %d", progressCount)
	}
}
