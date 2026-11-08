//go:build integration

package completion_test

import (
	"context"
	"os"
	"runtime"
	"slices"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/completion"
	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/postgres"
	"github.com/doubledare704/queravue/core/internal/session"
)

type postgresOpener struct{}

func envOr(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

func (postgresOpener) Open(ctx context.Context, _ string) (engine.Conn, engine.Descriptor, error) {
	e := postgres.New(postgres.VariantPostgres)
	cfg := engine.Config{EngineID: postgres.IDPostgres, Params: map[string]string{
		postgres.ParamHost:     envOr("PG_HOST", "127.0.0.1"),
		postgres.ParamPort:     envOr("PG_PORT", "5432"),
		postgres.ParamUser:     envOr("PG_USER", "queravue"),
		postgres.ParamDatabase: envOr("PG_DB", "queravue"),
		postgres.ParamSSLMode:  "disable",
	}}
	c, err := e.Connect(ctx, cfg, engine.NewSecret(envOr("PG_PASSWORD", "queravue")))
	return c, e.Descriptor(), err
}

func heapInUse() uint64 {
	runtime.GC()
	var ms runtime.MemStats
	runtime.ReadMemStats(&ms)
	return ms.HeapAlloc
}

// Needs dev/seed/postgres/large: docker compose -f dev/docker-compose.yml --profile large-schema up postgres-large-seed
func TestIntegrationLargeSchemaWarmAndComplete(t *testing.T) {
	mgr := session.NewManager(postgresOpener{})
	t.Cleanup(mgr.Shutdown)
	sess, err := mgr.Open(context.Background(), "pg")
	if err != nil {
		t.Fatalf("open: %v (are the dev databases up?)", err)
	}
	m := completion.NewManager()
	t.Cleanup(m.Shutdown)

	heapBefore := heapInUse()
	start := time.Now()
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	var last completion.Progress
	if err := m.Watch(ctx, sess, "", func(p completion.Progress) error { last = p; return nil }); err != nil {
		t.Fatal(err)
	}
	warm := time.Since(start)
	if last.Err != nil {
		t.Fatal(last.Err)
	}
	snap := m.Snapshot(sess.ID, "")
	if len(snap.TablesIn("large")) != 500 {
		t.Skipf("schema large has %d tables; load the large seed", len(snap.TablesIn("large")))
	}
	t.Logf("warm-up of %d schemas, %d tables, %d columns: %v", last.SchemasTotal, last.TablesLoaded, last.ColumnsLoaded, warm)
	t.Logf("catalog heap: +%.2f MiB", float64(heapInUse()-heapBefore)/(1<<20))
	if warm > 5*time.Second {
		t.Errorf("warm-up took %v, want under 5s", warm)
	}

	const runs = 300
	for _, sc := range benchScenarios {
		text, cursor := splitCursor(sc.marked)
		req := completion.Request{Dialect: sess.Dialect.Lexer(), Text: text, Cursor: cursor, MaxItems: 200, Schema: "large", Snapshot: snap, Recency: m.Recency(sess.ID)}
		durations := make([]time.Duration, runs)
		for i := range durations {
			begin := time.Now()
			if _, err := completion.Complete(context.Background(), req); err != nil {
				t.Fatal(err)
			}
			durations[i] = time.Since(begin)
		}
		slices.Sort(durations)
		p95 := durations[runs*95/100]
		t.Logf("%-26s p50 %-10v p95 %v", sc.name, durations[runs/2], p95)
		if p95 > 10*time.Millisecond {
			t.Errorf("%s: p95 = %v, budget 10ms", sc.name, p95)
		}
	}

	text, cursor := splitCursor("SELECT c.| FROM customer c JOIN order_line l ON l.owner_id = c.id")
	res, err := completion.Complete(context.Background(), completion.Request{Dialect: sess.Dialect.Lexer(), Text: text, Cursor: cursor, Schema: "large", Snapshot: snap})
	if err != nil || len(res.Items) < 14 || res.Items[0].Label != "amount" {
		t.Errorf("customer columns = %+v, %v", res.Items[:min(3, len(res.Items))], err)
	}
}
