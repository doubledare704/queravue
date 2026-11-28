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
