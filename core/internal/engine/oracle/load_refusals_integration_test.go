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
