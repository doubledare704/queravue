//go:build integration

package clickhouse

import (
	"context"
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/enginetest"
)

func TestIntegrationLoadRowsRefusals(t *testing.T) {
	tg := target()
	conn, err := tg.Engine.Connect(context.Background(), tg.Config, tg.Secret)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = conn.Close() })
	enginetest.Exec(t, conn, "DROP TABLE IF EXISTS qv_load_refusals")
	enginetest.Exec(t, conn, "CREATE TABLE qv_load_refusals (id Int32, label String, pair Tuple(Int32, String)) ENGINE = MergeTree ORDER BY id")
	t.Cleanup(func() { enginetest.Exec(t, conn, "DROP TABLE IF EXISTS qv_load_refusals") })
	target := engine.LoadTarget{Database: tg.Database, Table: "qv_load_refusals"}
	loader := conn.(engine.RowLoader)

	stats, err := loader.LoadRows(context.Background(), target, []string{"pair"}, enginetest.FixedBatches([][]engine.Value{{engine.Text("x")}}))
	if engine.KindOf(err) != engine.KindUnsupported || stats.Rows != 0 {
		t.Errorf("tuple column: stats = %+v, err = %v; want an unsupported error", stats, err)
	}

	stats, err = loader.LoadRows(context.Background(), target, []string{"id", "label"},
		enginetest.FixedBatches([][]engine.Value{{engine.Int(1), engine.Null()}}))
	if engine.KindOf(err) != engine.KindConstraint || stats.Rows != 0 {
		t.Errorf("NULL in a column that is not Nullable: stats = %+v, err = %v; want a constraint error", stats, err)
	}
}
