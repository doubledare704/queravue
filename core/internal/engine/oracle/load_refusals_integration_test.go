//go:build integration

package oracle

import (
	"context"
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/enginetest"
)

func TestIntegrationLoadRowsRefusesOpenTransaction(t *testing.T) {
	tg := target()
	conn, err := tg.Engine.Connect(context.Background(), tg.Config, tg.Secret)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = conn.Close() })
	enginetest.Exec(t, conn, `DROP TABLE IF EXISTS "qv_load_refusals"`)
	enginetest.Exec(t, conn, `CREATE TABLE "qv_load_refusals" ("id" NUMBER(10) PRIMARY KEY)`)
	t.Cleanup(func() { enginetest.Exec(t, conn, `DROP TABLE IF EXISTS "qv_load_refusals"`) })

	enginetest.Exec(t, conn, "SET TRANSACTION READ WRITE")
	stats, err := conn.(engine.RowLoader).LoadRows(context.Background(),
		engine.LoadTarget{Schema: tg.Schema, Table: "qv_load_refusals"}, []string{"id"},
		enginetest.FixedBatches([][]engine.Value{{engine.Int(1)}}))
	enginetest.Exec(t, conn, "ROLLBACK")
	if engine.KindOf(err) != engine.KindUnsupported || stats.Rows != 0 {
		t.Errorf("stats = %+v, err = %v; want an unsupported error", stats, err)
	}
}

func TestIntegrationLoadRowsFloatsOutsideNumberRange(t *testing.T) {
	tg := target()
	conn, err := tg.Engine.Connect(context.Background(), tg.Config, tg.Secret)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = conn.Close() })
	enginetest.Exec(t, conn, `DROP TABLE IF EXISTS "qv_load_floats"`)
	enginetest.Exec(t, conn, `CREATE TABLE "qv_load_floats" ("id" NUMBER(10) PRIMARY KEY, "dbl" BINARY_DOUBLE)`)
	t.Cleanup(func() { enginetest.Exec(t, conn, `DROP TABLE IF EXISTS "qv_load_floats"`) })

	values := []float64{1e-200, -1e-200, 1e-125, -1e-126, 1e300, -1e300}
	rows := make([][]engine.Value, len(values))
	for i, f := range values {
		rows[i] = []engine.Value{engine.Int(int64(i)), engine.Float(f)}
	}
	if _, err := conn.(engine.RowLoader).LoadRows(context.Background(), engine.LoadTarget{Schema: tg.Schema, Table: "qv_load_floats"},
		[]string{"id", "dbl"}, enginetest.FixedBatches(rows)); err != nil {
		t.Fatal(err)
	}
	sink := &floatColumn{}
	if _, err := conn.(engine.Executor).Execute(context.Background(), engine.Statement{SQL: `SELECT "dbl" FROM "qv_load_floats" ORDER BY "id"`}, sink); err != nil {
		t.Fatal(err)
	}
	for i, want := range values {
		if i >= len(sink.values) || sink.values[i] != want {
			t.Errorf("value %d reads back as %v, want %v", i, sink.values, values)
			break
		}
	}
}

type floatColumn struct{ values []float64 }

func (*floatColumn) Columns([]engine.Column) error { return nil }
func (s *floatColumn) Batch(rows [][]engine.Value) error {
	for _, row := range rows {
		s.values = append(s.values, row[0].Float)
	}
	return nil
}
