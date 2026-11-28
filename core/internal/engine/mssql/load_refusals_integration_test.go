//go:build integration

package mssql

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
	loader := conn.(engine.RowLoader)
	enginetest.Exec(t, conn, "DROP TABLE IF EXISTS qv_load_refusals")
	enginetest.Exec(t, conn, "CREATE TABLE qv_load_refusals (id INT PRIMARY KEY, doc XML)")
	t.Cleanup(func() { enginetest.Exec(t, conn, "DROP TABLE IF EXISTS qv_load_refusals") })
	target := engine.LoadTarget{Database: tg.Database, Schema: tg.Schema, Table: "qv_load_refusals"}
	rows := [][]engine.Value{{engine.Int(1)}}

	stats, err := loader.LoadRows(context.Background(), target, []string{"doc"}, enginetest.FixedBatches([][]engine.Value{{engine.Text("<a/>")}}))
	if engine.KindOf(err) != engine.KindUnsupported || stats.Rows != 0 {
		t.Errorf("xml column: stats = %+v, err = %v; want an unsupported error", stats, err)
	}

	enginetest.Exec(t, conn, "BEGIN TRANSACTION")
	stats, err = loader.LoadRows(context.Background(), target, []string{"id"}, enginetest.FixedBatches(rows))
	enginetest.Exec(t, conn, "ROLLBACK")
	if engine.KindOf(err) != engine.KindUnsupported || stats.Rows != 0 {
		t.Errorf("open transaction: stats = %+v, err = %v; want an unsupported error", stats, err)
	}
}

func TestIntegrationLoadRowsValueFidelityAndSessionSurvivesRejectedRows(t *testing.T) {
	tg := target()
	conn, err := tg.Engine.Connect(context.Background(), tg.Config, tg.Secret)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = conn.Close() })
	loader := conn.(engine.RowLoader)
	enginetest.Exec(t, conn, "DROP TABLE IF EXISTS qv_load_fidelity")
	enginetest.Exec(t, conn, "CREATE TABLE qv_load_fidelity (id INT, amount DECIMAL(12,4), tiny TINYINT, small_amount DECIMAL(5,2), legacy VARCHAR(20))")
	t.Cleanup(func() { enginetest.Exec(t, conn, "DROP TABLE IF EXISTS qv_load_fidelity") })
	target := engine.LoadTarget{Database: tg.Database, Schema: tg.Schema, Table: "qv_load_fidelity"}
	load := func(columns []string, rows ...[]engine.Value) (engine.LoadStats, error) {
		return loader.LoadRows(context.Background(), target, columns, enginetest.FixedBatches(rows))
	}
	read := func(sql string) string {
		var got string
		sink := &firstCell{}
		if _, err := conn.(engine.Executor).Execute(context.Background(), engine.Statement{SQL: sql}, sink); err != nil {
			t.Fatalf("session unusable after the load: %v", err)
		}
		got = sink.text
		return got
	}

	if _, err := load([]string{"id", "amount"}, []engine.Value{engine.Int(1), engine.Int(123)}); err != nil {
		t.Fatal(err)
	}
	if got := read("SELECT CAST(amount AS VARCHAR(20)) FROM qv_load_fidelity WHERE id = 1"); got != "123.0000" {
		t.Errorf("an integer loaded into DECIMAL(12,4) reads back as %q, want 123.0000", got)
	}

	stats, err := load([]string{"id", "legacy"}, []engine.Value{engine.Int(2), engine.Text("café")})
	if engine.KindOf(err) != engine.KindInvalidConfig || stats.Rows != 0 {
		t.Errorf("non-ASCII into VARCHAR: stats = %+v, err = %v; want an invalid-config error", stats, err)
	}

	for name, rows := range map[string][][]engine.Value{
		"a late out-of-range TINYINT": {{engine.Int(10), engine.Int(1)}, {engine.Int(11), engine.Int(2)}, {engine.Int(12), engine.Int(999)}},
		"a late decimal overflow":     {{engine.Int(20), engine.Decimal("1.00")}, {engine.Int(21), engine.Decimal("2.00")}, {engine.Int(22), engine.Decimal("123456.00")}},
	} {
		column := "tiny"
		if name == "a late decimal overflow" {
			column = "small_amount"
		}
		if stats, err := load([]string{"id", column}, rows...); err == nil || stats.Rows != 0 {
			t.Errorf("%s: stats = %+v, err = %v; want a rejected batch", name, stats, err)
		}
		if got := read("SELECT CAST(COUNT(*) AS VARCHAR(20)) FROM qv_load_fidelity WHERE id >= 10"); got != "0" {
			t.Errorf("%s left %s rows behind", name, got)
		}
	}
}

type firstCell struct{ text string }

func (*firstCell) Columns([]engine.Column) error { return nil }
func (s *firstCell) Batch(rows [][]engine.Value) error {
	if s.text == "" && len(rows) > 0 {
		s.text = rows[0][0].Str
	}
	return nil
}
