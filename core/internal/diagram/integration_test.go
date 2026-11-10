//go:build integration

package diagram_test

import (
	"context"
	"os"
	"slices"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/diagram"
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

// Needs dev/seed/postgres/large: docker compose -f dev/docker-compose.yml --profile large-schema up postgres-large-seed
func TestIntegrationLargeSchemaGraphLoadsWithinBudget(t *testing.T) {
	mgr := session.NewManager(postgresOpener{})
	t.Cleanup(mgr.Shutdown)
	sess, err := mgr.Open(context.Background(), "pg")
	if err != nil {
		t.Fatalf("open: %v (are the dev databases up?)", err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()

	const runs = 30
	durations := make([]time.Duration, runs)
	var graph *diagram.Graph
	for i := range durations {
		start := time.Now()
		if graph, err = diagram.Load(ctx, sess, "", "large"); err != nil {
			t.Fatal(err)
		}
		durations[i] = time.Since(start)
	}
	if len(graph.Tables) != 500 {
		t.Skipf("schema large has %d tables; load the large seed", len(graph.Tables))
	}
	columns, relations, keyless := 0, 0, 0
	for _, table := range graph.Tables {
		columns += len(table.Columns)
		relations += len(table.Relations)
		if !slices.ContainsFunc(table.Columns, func(c engine.KeyedColumn) bool { return c.PrimaryKeyOrder == 1 }) {
			keyless++
		}
	}
	if relations != 480 || keyless != 0 || columns < 7000 {
		t.Errorf("graph has %d columns, %d relations, %d tables without a key; want about 7,500, 480 and 0", columns, relations, keyless)
	}
	slices.Sort(durations)
	p50, p95 := durations[runs/2], durations[runs*95/100]
	t.Logf("500 tables, %d columns, %d relations: p50 %v, p95 %v", columns, relations, p50, p95)
	if p95 > 200*time.Millisecond {
		t.Errorf("p95 = %v, budget 200ms", p95)
	}
}
