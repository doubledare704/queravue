package completion_test

import (
	"context"
	"database/sql"
	"path/filepath"
	"testing"
	"time"

	_ "modernc.org/sqlite"

	"github.com/doubledare704/queravue/core/internal/completion"
	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/sqlite"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/schema"
	"github.com/doubledare704/queravue/core/internal/session"
)

type sqliteOpener struct{ path string }

func (o sqliteOpener) Open(ctx context.Context, _ string) (engine.Conn, engine.Descriptor, error) {
	e := sqlite.New()
	c, err := e.Connect(ctx, engine.Config{EngineID: sqlite.ID, Params: map[string]string{sqlite.ParamPath: o.path}}, engine.Secret{})
	return c, e.Descriptor(), err
}

func seededSession(t *testing.T) (*session.Session, *session.Manager) {
	t.Helper()
	path := filepath.Join(t.TempDir(), "shop.db")
	db, err := sql.Open("sqlite", path)
	if err != nil {
		t.Fatal(err)
	}
	for _, stmt := range []string{
		"CREATE TABLE customers (id INTEGER PRIMARY KEY, name TEXT, email TEXT)",
		"CREATE TABLE orders (id INTEGER PRIMARY KEY, customer_id INTEGER, total NUMERIC)",
		"CREATE VIEW big_orders AS SELECT id, total FROM orders WHERE total > 100",
	} {
		if _, err := db.Exec(stmt); err != nil {
			t.Fatal(err)
		}
	}
	_ = db.Close()
	mgr := session.NewManager(sqliteOpener{path})
	t.Cleanup(mgr.Shutdown)
	sess, err := mgr.Open(context.Background(), "c")
	if err != nil {
		t.Fatal(err)
	}
	return sess, mgr
}

func watchUntilDone(t *testing.T, m *completion.Manager, sess *session.Session) []completion.Progress {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	var seen []completion.Progress
	err := m.Watch(ctx, sess, "", func(p completion.Progress) error {
		seen = append(seen, p)
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	return seen
}

func TestWarmLoadsTablesAndColumnsAndReportsProgress(t *testing.T) {
	sess, _ := seededSession(t)
	m := completion.NewManager()
	t.Cleanup(m.Shutdown)

	seen := watchUntilDone(t, m, sess)
	last := seen[len(seen)-1]
	if !last.Done || last.Err != nil || last.SchemasTotal != 1 || last.SchemasDone != 1 || last.TablesLoaded != 3 || last.ColumnsLoaded != 8 {
		t.Errorf("final progress = %+v", last)
	}
	snap := m.Snapshot(sess.ID, "")
	if snap.State() != completion.StateReady {
		t.Fatalf("state = %v, want ready", snap.State())
	}
	orders := snap.Lookup("", "orders")
	if len(orders) != 1 || len(orders[0].Columns) != 3 || orders[0].Columns[1].Name != "customer_id" {
		t.Errorf("orders = %+v", orders)
	}
	if v := snap.Lookup("", "big_orders"); len(v) != 1 || !v[0].View {
		t.Errorf("big_orders = %+v", v)
	}
}

func TestWarmServesTablesBeforeColumnsAndNeverBlocksCompletion(t *testing.T) {
	sess, _ := seededSession(t)
	m := completion.NewManager()
	t.Cleanup(m.Shutdown)

	res, err := completion.Complete(context.Background(), completion.Request{
		Dialect: sess.Dialect.Lexer(), Text: "SELECT * FROM ", Cursor: 14, Snapshot: m.Snapshot(sess.ID, ""),
	})
	if err != nil || res.State != completion.StateCold || len(res.Items) == 0 {
		t.Fatalf("cold completion = %+v, %v", res, err)
	}
	watchUntilDone(t, m, sess)
	res, err = completion.Complete(context.Background(), completion.Request{
		Dialect: sess.Dialect.Lexer(), Text: "SELECT * FROM ", Cursor: 14, Snapshot: m.Snapshot(sess.ID, ""),
	})
	if err != nil || res.State != completion.StateReady || res.Items[0].Label != "big_orders" {
		t.Errorf("warm completion first = %+v, %v", res.Items[:1], err)
	}
}

func TestStartWarmsOnceAndSharesTheLoad(t *testing.T) {
	sess, _ := seededSession(t)
	m := completion.NewManager()
	t.Cleanup(m.Shutdown)
	m.Start(sess, "")
	m.Start(sess, "")
	seen := watchUntilDone(t, m, sess)
	if !seen[len(seen)-1].Done {
		t.Fatal("warm-up did not finish")
	}
	if got := m.Snapshot(sess.ID, "").State(); got != completion.StateReady {
		t.Errorf("state = %v", got)
	}
}

func TestInvalidateDropsTheCatalog(t *testing.T) {
	sess, _ := seededSession(t)
	m := completion.NewManager()
	t.Cleanup(m.Shutdown)
	watchUntilDone(t, m, sess)
	m.Invalidate(sess.ID)
	if got := m.Snapshot(sess.ID, "").State(); got != completion.StateCold {
		t.Errorf("state after invalidate = %v, want cold", got)
	}
	watchUntilDone(t, m, sess)
	if got := m.Snapshot(sess.ID, "").State(); got != completion.StateReady {
		t.Errorf("state after rewarm = %v, want ready", got)
	}
}

func TestSchemaCacheInvalidationDropsTheCatalog(t *testing.T) {
	sess, _ := seededSession(t)
	m := completion.NewManager()
	t.Cleanup(m.Shutdown)
	cache := schema.NewCache()
	cache.OnInvalidate(m.Invalidate)
	watchUntilDone(t, m, sess)
	cache.Invalidate(sess.ID, &queravuev1.TableRef{Table: "orders"})
	if got := m.Snapshot(sess.ID, "").State(); got != completion.StateCold {
		t.Errorf("state = %v, want cold", got)
	}
}

func TestWarmWaitsForARunningStatement(t *testing.T) {
	sess, _ := seededSession(t)
	m := completion.NewManager()
	t.Cleanup(m.Shutdown)
	_, finish, err := sess.Begin(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	m.Start(sess, "")
	time.Sleep(100 * time.Millisecond)
	if got := m.Snapshot(sess.ID, "").State(); got == completion.StateReady {
		t.Fatal("warm-up ran while a statement held the session")
	}
	finish()
	watchUntilDone(t, m, sess)
	if got := m.Snapshot(sess.ID, "").State(); got != completion.StateReady {
		t.Errorf("state = %v, want ready after the statement ended", got)
	}
}
