//go:build duckdb

package duckdb

import (
	"context"
	"path/filepath"
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/enginetest"
)

// LOAD_PERF=1 CGO_ENABLED=1 go test -tags duckdb -run TestLoadRowsPerf -v ./internal/engine/duckdb/
func TestLoadRowsPerf(t *testing.T) {
	enginetest.SkipUnlessLoadPerf(t)
	cfg := engine.Config{EngineID: ID, Params: map[string]string{ParamPath: filepath.Join(t.TempDir(), "perf.duckdb"), ParamCreateIfMissing: "true"}}
	conn, err := New().Connect(context.Background(), cfg, engine.Secret{})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = conn.Close() })
	// DuckDB runs in this process, so the rows it keeps count toward RSS until a checkpoint writes them out.
	if _, err := conn.(engine.Executor).Execute(context.Background(), engine.Statement{SQL: "SET checkpoint_threshold='4MB'"}, nil); err != nil {
		t.Fatal(err)
	}
	enginetest.MeasureRowLoad(t, enginetest.RowLoadPerf{
		Conn:      conn,
		Target:    engine.LoadTarget{Schema: "main", Table: "qv_perf_load"},
		Qualified: "main.qv_perf_load",
		CreateSQL: "CREATE TABLE {table} (id BIGINT, name VARCHAR, amount DECIMAL(14,2), created TIMESTAMPTZ, active BOOLEAN, payload VARCHAR)",
		Batch:     enginetest.PerfRowBatch(10_000),
	})
}
