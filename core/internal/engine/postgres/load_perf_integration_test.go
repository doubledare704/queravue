//go:build integration

package postgres

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/enginetest"
)

const perfRowsPerBatch = 10_000

func perfRowBatch() [][]engine.Value {
	stamp := time.Date(2024, 2, 29, 12, 0, 0, 0, time.UTC)
	rows := make([][]engine.Value, perfRowsPerBatch)
	for i := range rows {
		rows[i] = []engine.Value{
			engine.Int(int64(i)), engine.Text(fmt.Sprintf("customer %d", i)), engine.Decimal(fmt.Sprintf("%d.%02d", i, i%100)),
			engine.Timestamptz(stamp.Add(time.Duration(i) * time.Second)), engine.Bool(i%2 == 0),
			engine.Text("a payload of about forty characters"),
		}
	}
	return rows
}

// LOAD_PERF=1 go test -tags=integration -run TestIntegrationLoadRowsPerf -v ./internal/engine/postgres/
func TestIntegrationLoadRowsPerfPostgres(t *testing.T) {
	enginetest.SkipUnlessLoadPerf(t)
	params, secret := pgParams()
	perfLoadRows(t, New(VariantPostgres), engine.Config{EngineID: IDPostgres, Params: params}, secret, params[ParamDatabase])
}

func TestIntegrationLoadRowsPerfCockroach(t *testing.T) {
	enginetest.SkipUnlessLoadPerf(t)
	cfg := engine.Config{EngineID: IDCockroach, Params: map[string]string{
		ParamHost: "127.0.0.1", ParamPort: "26257", ParamUser: "root", ParamDatabase: "queravue", ParamSSLMode: "disable",
	}}
	perfLoadRows(t, New(VariantCockroach), cfg, engine.Secret{}, "queravue")
}

func perfLoadRows(t *testing.T, e *Engine, cfg engine.Config, secret engine.Secret, database string) {
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
	defer cancel()
	conn, err := e.Connect(ctx, cfg, secret)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = conn.Close() })
	exec := conn.(engine.Executor)
	run := func(sql string) {
		if _, err := exec.Execute(ctx, engine.Statement{SQL: sql}, discardSink{}); err != nil {
			t.Fatalf("%s: %v", sql, err)
		}
	}
	run("DROP TABLE IF EXISTS qv_perf_load")
	t.Cleanup(func() {
		_, _ = exec.Execute(context.Background(), engine.Statement{SQL: "DROP TABLE IF EXISTS qv_perf_load"}, discardSink{})
	})
	run("CREATE TABLE qv_perf_load (id bigint, name text, amount numeric(14,2), created timestamptz, active boolean, payload text)")

	columns := []string{"id", "name", "amount", "created", "active", "payload"}
	src := enginetest.NewRepeatingRowSource(perfRowBatch(), enginetest.LoadPerfRows)
	sampler := enginetest.StartRSSSampler(t)
	start := time.Now()
	stats, err := conn.(engine.RowLoader).LoadRows(ctx, engine.LoadTarget{Database: database, Schema: "public", Table: "qv_perf_load"}, columns, src)
	elapsed := time.Since(start)
	baseline, peak := sampler.Stop()
	if err != nil {
		t.Fatal(err)
	}
	rate := float64(stats.Rows) / elapsed.Seconds()
	t.Logf("%s: %d rows in %d batches, %.2fs, %.0f rows/s, RSS baseline %.1f MiB, peak %.1f MiB (+%.1f)",
		e.Descriptor().ID, stats.Rows, stats.Batches, elapsed.Seconds(), rate, baseline, peak, peak-baseline)

	var counted int64
	sink := &countSink{}
	if _, err := exec.Execute(ctx, engine.Statement{SQL: "SELECT count(*) FROM qv_perf_load"}, sink); err != nil {
		t.Fatal(err)
	}
	counted = sink.first
	if counted != enginetest.LoadPerfRows {
		t.Errorf("%d rows stored, want %d", counted, enginetest.LoadPerfRows)
	}
	if e.Descriptor().ID == IDPostgres && rate < enginetest.LoadPostgresMinRate {
		t.Errorf("%.0f rows/s is below the %d rows/s gate", rate, enginetest.LoadPostgresMinRate)
	}
	if peak > baseline+enginetest.LoadRSSBudgetMiB {
		t.Errorf("RSS peak %.1f MiB exceeds baseline %.1f + %d MiB", peak, baseline, enginetest.LoadRSSBudgetMiB)
	}
}

type discardSink struct{}

func (discardSink) Columns([]engine.Column) error { return nil }
func (discardSink) Batch([][]engine.Value) error  { return nil }

type countSink struct{ first int64 }

func (*countSink) Columns([]engine.Column) error { return nil }
func (s *countSink) Batch(rows [][]engine.Value) error {
	s.first = rows[0][0].Int
	return nil
}
