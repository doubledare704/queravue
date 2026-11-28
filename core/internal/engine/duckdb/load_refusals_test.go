//go:build duckdb

package duckdb

import (
	"context"
	"path/filepath"
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/enginetest"
)

func TestLoadRowsRefusalsAndNotNull(t *testing.T) {
	cfg := engine.Config{EngineID: ID, Params: map[string]string{ParamPath: filepath.Join(t.TempDir(), "refusals.duckdb"), ParamCreateIfMissing: "true"}}
	conn, err := New().Connect(context.Background(), cfg, engine.Secret{})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = conn.Close() })
	enginetest.Exec(t, conn, "CREATE TABLE refusals (id BIGINT NOT NULL, pair STRUCT(a INTEGER, b VARCHAR))")
	target := engine.LoadTarget{Schema: "main", Table: "refusals"}
	loader := conn.(engine.RowLoader)

	_, err = loader.LoadRows(context.Background(), target, []string{"pair"}, enginetest.FixedBatches([][]engine.Value{{engine.Text("x")}}))
	if engine.KindOf(err) != engine.KindUnsupported {
		t.Errorf("struct column: err = %v; want an unsupported error", err)
	}

	_, err = loader.LoadRows(context.Background(), target, []string{"id"}, enginetest.FixedBatches([][]engine.Value{{engine.Null()}}))
	if engine.KindOf(err) != engine.KindConstraint {
		t.Errorf("NULL in a NOT NULL column: err = %v; want a constraint error", err)
	}

	enginetest.Exec(t, conn, "BEGIN TRANSACTION")
	stats, err := loader.LoadRows(context.Background(), target, []string{"id"}, enginetest.FixedBatches([][]engine.Value{{engine.Int(1)}}))
	enginetest.Exec(t, conn, "ROLLBACK")
	if engine.KindOf(err) != engine.KindUnsupported || stats.Rows != 0 {
		t.Errorf("open transaction: stats = %+v, err = %v; want an unsupported error", stats, err)
	}
}
