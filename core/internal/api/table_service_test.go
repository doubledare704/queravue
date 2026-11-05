package api_test

import (
	"context"
	"path/filepath"
	"testing"

	"github.com/doubledare704/queravue/core/internal/api"
	"github.com/doubledare704/queravue/core/internal/connections"
	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/sqlite"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/history"
	"github.com/doubledare704/queravue/core/internal/results"
	"github.com/doubledare704/queravue/core/internal/secrets"
	"github.com/doubledare704/queravue/core/internal/session"
)

type sqliteOpener struct {
	dbPath string
}

func (o sqliteOpener) Open(ctx context.Context, _ string) (engine.Conn, engine.Descriptor, error) {
	e := sqlite.New()
	conn, err := e.Connect(ctx, engine.Config{
		EngineID: "sqlite",
		Params: map[string]string{
			sqlite.ParamPath:            o.dbPath,
			sqlite.ParamCreateIfMissing: "true",
		},
	}, engine.Secret{})
	return conn, e.Descriptor(), err
}

func setupTableTestEnv(t *testing.T, isProd bool) (*api.TableService, *session.Session, *history.Store) {
	t.Helper()
	dir := t.TempDir()
	dbPath := filepath.Join(dir, "test.db")

	opener := sqliteOpener{dbPath: dbPath}
	mgr := session.NewManager(opener)
	t.Cleanup(mgr.Shutdown)

	sess, err := mgr.Open(context.Background(), "test-conn")
	if err != nil {
		t.Fatalf("open session: %v", err)
	}

	// Create test tables in SQLite:
	// 1. users: id (PK), name, age
	// 2. audit_logs: message (no PK)
	ex, _ := engine.As[engine.Executor](sess.Conn)
	ctx := context.Background()
	for _, stmt := range []string{
		"CREATE TABLE users (id INTEGER PRIMARY KEY, name TEXT NOT NULL, age INTEGER);",
		"INSERT INTO users (id, name, age) VALUES (1, 'Alice', 30), (2, 'Bob', 25);",
		"CREATE TABLE audit_logs (message TEXT NOT NULL);",
		"INSERT INTO audit_logs (message) VALUES ('log 1');",
	} {
		_, err := ex.Execute(ctx, engine.Statement{SQL: stmt}, nilSink{})
		if err != nil {
			t.Fatalf("setup sql %q: %v", stmt, err)
		}
	}

	resMgr, err := results.NewManager(dir, 0, nil)
	if err != nil {
		t.Fatalf("new results manager: %v", err)
	}
	t.Cleanup(resMgr.Shutdown)

	histStore, err := history.NewStore(":memory:", 100, nil)
	if err != nil {
		t.Fatalf("new history store: %v", err)
	}
	t.Cleanup(func() { _ = histStore.Close() })

	// Connection service with a connection profile
	reg, err := engine.NewRegistry(sqlite.New())
	if err != nil {
		t.Fatalf("new registry: %v", err)
	}
	connStore := connections.NewFileStore(dir)
	_ = connStore.Save([]connections.Connection{{
		ID:         "test-conn",
		Name:       "Test Conn",
		EngineID:   "sqlite",
		Production: isProd,
	}})
	connSvc := connections.NewService(reg, connStore, secrets.NewMemory())

	svc := api.NewTableService(mgr, resMgr, connSvc, histStore, nil)
	return svc, sess, histStore
}

type nilSink struct{}

func (nilSink) Columns([]engine.Column) error { return nil }
func (nilSink) Batch([][]engine.Value) error  { return nil }

func TestTableService_ApplyChanges_DryRun(t *testing.T) {
	svc, sess, _ := setupTableTestEnv(t, false)
	ctx := context.Background()

	resp, err := svc.ApplyChanges(ctx, &queravuev1.ApplyChangesRequest{
		SessionId: sess.ID,
		TableRef:  &queravuev1.TableRef{Table: "users"},
		Changes: []*queravuev1.RowChange{
			{
				Type: queravuev1.RowChangeType_ROW_CHANGE_TYPE_INSERT,
				Values: []*queravuev1.ColumnValue{
					{Column: "id", Value: &queravuev1.Value{Kind: &queravuev1.Value_IntValue{IntValue: 3}}},
					{Column: "name", Value: &queravuev1.Value{Kind: &queravuev1.Value_TextValue{TextValue: "Charlie"}}},
				},
			},
		},
		DryRun: true,
	})
	if err != nil {
		t.Fatalf("ApplyChanges: %v", err)
	}

	if !resp.GetSuccess() {
		t.Fatalf("ApplyChanges failed: %s", resp.GetErrorMessage())
	}
	if !resp.GetDryRun() {
		t.Errorf("expected DryRun=true")
	}
	if resp.GetGeneratedSql() == "" {
		t.Errorf("expected non-empty generated SQL")
	}

	// Verify row was NOT inserted during dry run
	ex, _ := engine.As[engine.Executor](sess.Conn)
	sum, err := ex.Execute(ctx, engine.Statement{SQL: "SELECT * FROM users WHERE id = 3;"}, nilSink{})
	if err != nil {
		t.Fatal(err)
	}
	if sum.HasRows && sum.RowsAffected != 0 {
		t.Errorf("dry run inserted rows")
	}
}

func TestTableService_ApplyChanges_CommitAndRollback(t *testing.T) {
	svc, sess, _ := setupTableTestEnv(t, false)
	ctx := context.Background()

	// 1. Successful commit
	resp, err := svc.ApplyChanges(ctx, &queravuev1.ApplyChangesRequest{
		SessionId: sess.ID,
		TableRef:  &queravuev1.TableRef{Table: "users"},
		Changes: []*queravuev1.RowChange{
			{
				Type: queravuev1.RowChangeType_ROW_CHANGE_TYPE_UPDATE,
				Keys: []*queravuev1.ColumnValue{
					{Column: "id", Value: &queravuev1.Value{Kind: &queravuev1.Value_IntValue{IntValue: 1}}},
				},
				Values: []*queravuev1.ColumnValue{
					{Column: "age", Value: &queravuev1.Value{Kind: &queravuev1.Value_IntValue{IntValue: 35}}},
				},
			},
		},
		DryRun: false,
	})
	if err != nil {
		t.Fatalf("ApplyChanges commit: %v", err)
	}
	if !resp.GetSuccess() {
		t.Fatalf("commit failed: %s", resp.GetErrorMessage())
	}
	if resp.GetRowsAffected() != 1 {
		t.Errorf("rows affected = %d, want 1", resp.GetRowsAffected())
	}

	// 2. Rollback on error in transaction
	// Statement 1 succeeds (update id 2 age to 99), statement 2 fails (duplicate PK id 1)
	failResp, err := svc.ApplyChanges(ctx, &queravuev1.ApplyChangesRequest{
		SessionId: sess.ID,
		TableRef:  &queravuev1.TableRef{Table: "users"},
		Changes: []*queravuev1.RowChange{
			{
				Type: queravuev1.RowChangeType_ROW_CHANGE_TYPE_UPDATE,
				Keys: []*queravuev1.ColumnValue{
					{Column: "id", Value: &queravuev1.Value{Kind: &queravuev1.Value_IntValue{IntValue: 2}}},
				},
				Values: []*queravuev1.ColumnValue{
					{Column: "age", Value: &queravuev1.Value{Kind: &queravuev1.Value_IntValue{IntValue: 99}}},
				},
			},
			{
				Type: queravuev1.RowChangeType_ROW_CHANGE_TYPE_INSERT,
				Values: []*queravuev1.ColumnValue{
					{Column: "id", Value: &queravuev1.Value{Kind: &queravuev1.Value_IntValue{IntValue: 1}}}, // Duplicate PK!
					{Column: "name", Value: &queravuev1.Value{Kind: &queravuev1.Value_TextValue{TextValue: "Duplicate"}}},
				},
			},
		},
		DryRun: false,
	})
	if err != nil {
		t.Fatalf("ApplyChanges call returned err: %v", err)
	}
	if failResp.GetSuccess() {
		t.Fatal("expected failure due to duplicate PK")
	}

	// Verify rollback: Bob's age should STILL be 25, NOT 99!
	classSink := &collectSink{}
	ex, _ := engine.As[engine.Executor](sess.Conn)
	_, err = ex.Execute(ctx, engine.Statement{SQL: "SELECT age FROM users WHERE id = 2;"}, classSink)
	if err != nil {
		t.Fatal(err)
	}
	if len(classSink.rows) != 1 || classSink.rows[0][0].Int != 25 {
		t.Errorf("Bob's age = %v, want 25 (transaction should have rolled back)", classSink.rows)
	}
}

func TestTableService_ReadOnlyTable_Rejected(t *testing.T) {
	svc, sess, _ := setupTableTestEnv(t, false)
	ctx := context.Background()

	// audit_logs has NO primary key
	resp, err := svc.ApplyChanges(ctx, &queravuev1.ApplyChangesRequest{
		SessionId: sess.ID,
		TableRef:  &queravuev1.TableRef{Table: "audit_logs"},
		Changes: []*queravuev1.RowChange{
			{
				Type: queravuev1.RowChangeType_ROW_CHANGE_TYPE_INSERT,
				Values: []*queravuev1.ColumnValue{
					{Column: "message", Value: &queravuev1.Value{Kind: &queravuev1.Value_TextValue{TextValue: "new log"}}},
				},
			},
		},
	})
	if err != nil {
		t.Fatal(err)
	}
	if resp.GetSuccess() {
		t.Fatal("expected edits on table without PK to be rejected")
	}
	if resp.GetErrorMessage() == "" {
		t.Error("expected explanation message why table is read-only")
	}
}

func TestTableService_ProductionConnection_RequiresConfirm(t *testing.T) {
	svc, sess, _ := setupTableTestEnv(t, true) // isProd = true
	ctx := context.Background()

	// Try without confirmation
	resp, err := svc.ApplyChanges(ctx, &queravuev1.ApplyChangesRequest{
		SessionId: sess.ID,
		TableRef:  &queravuev1.TableRef{Table: "users"},
		Changes: []*queravuev1.RowChange{
			{
				Type: queravuev1.RowChangeType_ROW_CHANGE_TYPE_DELETE,
				Keys: []*queravuev1.ColumnValue{
					{Column: "id", Value: &queravuev1.Value{Kind: &queravuev1.Value_IntValue{IntValue: 1}}},
				},
			},
		},
		DryRun:            false,
		ConfirmProduction: false,
	})
	if err != nil {
		t.Fatal(err)
	}
	if resp.GetSuccess() {
		t.Fatal("expected production mutation without confirmation to fail")
	}

	// Try with confirmation
	respConfirmed, err := svc.ApplyChanges(ctx, &queravuev1.ApplyChangesRequest{
		SessionId: sess.ID,
		TableRef:  &queravuev1.TableRef{Table: "users"},
		Changes: []*queravuev1.RowChange{
			{
				Type: queravuev1.RowChangeType_ROW_CHANGE_TYPE_DELETE,
				Keys: []*queravuev1.ColumnValue{
					{Column: "id", Value: &queravuev1.Value{Kind: &queravuev1.Value_IntValue{IntValue: 1}}},
				},
			},
		},
		DryRun:            false,
		ConfirmProduction: true,
	})
	if err != nil {
		t.Fatal(err)
	}
	if !respConfirmed.GetSuccess() {
		t.Fatalf("expected mutation to succeed with confirmation: %s", respConfirmed.GetErrorMessage())
	}
}

type collectSink struct {
	rows [][]engine.Value
}

func (c *collectSink) Columns([]engine.Column) error { return nil }
func (c *collectSink) Batch(batch [][]engine.Value) error {
	c.rows = append(c.rows, batch...)
	return nil
}
