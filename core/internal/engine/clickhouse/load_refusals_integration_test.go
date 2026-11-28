//go:build integration

package clickhouse

import (
	"context"
	"strings"
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
	enginetest.Exec(t, conn, "CREATE TABLE qv_load_refusals (id Int32, label String, pair Tuple(Int32, String), huge UInt128) ENGINE = MergeTree ORDER BY id")
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

func TestIntegrationLoadRowsErrorDoesNotQuoteRejectedValue(t *testing.T) {
	tg := target()
	conn, err := tg.Engine.Connect(context.Background(), tg.Config, tg.Secret)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = conn.Close() })
	enginetest.Exec(t, conn, "DROP TABLE IF EXISTS qv_load_redaction")
	enginetest.Exec(t, conn, "CREATE TABLE qv_load_redaction (id Int32, huge UInt128) ENGINE = MergeTree ORDER BY id")
	t.Cleanup(func() { enginetest.Exec(t, conn, "DROP TABLE IF EXISTS qv_load_redaction") })

	const tooBig = "9999999999999999999999999999999999999999999999999"
	stats, err := conn.(engine.RowLoader).LoadRows(context.Background(), engine.LoadTarget{Database: tg.Database, Table: "qv_load_redaction"},
		[]string{"id", "huge"}, enginetest.FixedBatches([][]engine.Value{{engine.Int(1), engine.Decimal(tooBig)}}))
	if err == nil || stats.Rows != 0 {
		t.Fatalf("stats = %+v, err = %v; want a rejected value", stats, err)
	}
	if strings.Contains(err.Error(), "99999") {
		t.Errorf("error quotes the rejected value: %v", err)
	}
}
