//go:build integration

package mssql

import (
	"context"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/enginetest"
)

// LOAD_PERF=1 go test -tags=integration -run TestIntegrationLoadRowsPerf -v ./internal/engine/mssql/
func TestIntegrationLoadRowsPerfMSSQL(t *testing.T) {
	enginetest.SkipUnlessLoadPerf(t)
	tg := target()
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	conn, err := tg.Engine.Connect(ctx, tg.Config, tg.Secret)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = conn.Close() })
	enginetest.MeasureRowLoad(t, enginetest.RowLoadPerf{
		Conn:      conn,
		Target:    engine.LoadTarget{Database: tg.Database, Schema: tg.Schema, Table: "qv_perf_load"},
		Qualified: "[dbo].[qv_perf_load]",
		CreateSQL: "CREATE TABLE {table} (id BIGINT, name NVARCHAR(100), amount DECIMAL(14,2), created DATETIME2(6), active BIT, payload NVARCHAR(100))",
		Batch:     enginetest.PerfRowBatch(10_000),
	})
}
