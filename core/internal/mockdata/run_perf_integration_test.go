//go:build integration

package mockdata_test

import (
	"context"
	"errors"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/enginetest"
	"github.com/doubledare704/queravue/core/internal/engine/mongo"
	"github.com/doubledare704/queravue/core/internal/engine/postgres"
	"github.com/doubledare704/queravue/core/internal/mockdata"
)

const (
	mockRunSeed          = 20261127
	mockParentRows       = 10_000
	mockPostgresMaxTime  = 20 * time.Second
	mockMongoMaxTime     = 35 * time.Second
	mockCustomersTable   = "qv_mock_customers"
	mockOrdersTable      = "qv_mock_orders"
	mockCollection       = "qv_mock_orders"
	codeNamespaceMissing = 26
)

func env(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

func faker(column, kind string) mockdata.ColumnRule {
	return mockdata.ColumnRule{ColumnOrPath: column, Kind: mockdata.RuleFaker, FakerKind: kind}
}

func lastTwoYears() mockdata.TimeRangeRule {
	to := time.Date(2026, 11, 27, 0, 0, 0, 0, time.UTC)
	return mockdata.TimeRangeRule{FromMs: to.AddDate(-2, 0, 0).UnixMilli(), ToMs: to.UnixMilli()}
}

func orderStatuses() mockdata.WeightedValuesRule {
	return mockdata.WeightedValuesRule{
		Values:  []engine.Value{engine.Text("new"), engine.Text("paid"), engine.Text("shipped"), engine.Text("returned")},
		Weights: []float64{3, 5, 4, 1},
	}
}

func orderTotal() mockdata.DecimalRangeRule {
	return mockdata.DecimalRangeRule{Min: "1.00", Max: "999.99", Scale: 2}
}

func postgresSpec(orders uint64) mockdata.Spec {
	customers := mockdata.TargetRef{Schema: "public", Name: mockCustomersTable}
	return mockdata.Spec{Seed: mockRunSeed, Targets: []mockdata.TargetSpec{
		{Target: customers, Rows: mockParentRows, Rules: []mockdata.ColumnRule{
			{ColumnOrPath: "id", Kind: mockdata.RuleSequence, Sequence: mockdata.SequenceRule{Start: 1, Step: 1}},
			faker("name", "name"),
			faker("email", "email"),
			faker("city", "city"),
		}},
		{Target: mockdata.TargetRef{Schema: "public", Name: mockOrdersTable}, Rows: orders, Rules: []mockdata.ColumnRule{
			{ColumnOrPath: "id", Kind: mockdata.RuleSequence, Sequence: mockdata.SequenceRule{Start: 1, Step: 1}},
			{ColumnOrPath: "customer_id", Kind: mockdata.RuleForeignKey, ForeignKey: mockdata.ForeignKeyRule{Parent: customers, ParentColumn: "id"}},
			{ColumnOrPath: "status", Kind: mockdata.RuleWeightedValues, WeightedValues: orderStatuses()},
			{ColumnOrPath: "total", Kind: mockdata.RuleDecimalRange, DecimalRange: orderTotal()},
			{ColumnOrPath: "created_at", Kind: mockdata.RuleTimeRange, TimeRange: lastTwoYears()},
			faker("note", "sentence"),
		}},
	}}
}

func mongoSpec(documents uint64) mockdata.Spec {
	return mockdata.Spec{Seed: mockRunSeed, Targets: []mockdata.TargetSpec{{
		Target: mockdata.TargetRef{IsCollection: true, Database: "queravue", Name: mockCollection},
		Rows:   documents,
		Rules: []mockdata.ColumnRule{
			faker("customer", "name"),
			faker("email", "email"),
			{ColumnOrPath: "status", Kind: mockdata.RuleWeightedValues, WeightedValues: orderStatuses()},
			{ColumnOrPath: "total", Kind: mockdata.RuleDecimalRange, DecimalRange: orderTotal()},
			{ColumnOrPath: "created_at", Kind: mockdata.RuleTimeRange, TimeRange: lastTwoYears()},
			{ColumnOrPath: "shipping", Kind: mockdata.RuleDocument, Document: mockdata.DocumentRule{Fields: []mockdata.ColumnRule{
				faker("city", "city"),
				faker("street", "street"),
				faker("zip", "zip"),
			}}},
			{ColumnOrPath: "tags", Kind: mockdata.RuleArray, Array: mockdata.ArrayRule{MinLength: 1, MaxLength: 4, Element: &mockdata.ColumnRule{
				ColumnOrPath: "tag", Kind: mockdata.RuleFaker, FakerKind: "word",
			}}},
			faker("note", "sentence"),
		},
	}}}
}

type runResult struct {
	summary           mockdata.Summary
	elapsed           time.Duration
	baseline, peakMiB float64
}

func (r runResult) rate() float64 { return float64(r.summary.Rows) / r.elapsed.Seconds() }

func runMeasured(ctx context.Context, t *testing.T, conn engine.Conn, spec mockdata.Spec) runResult {
	t.Helper()
	rowLoader, _ := conn.(engine.RowLoader)
	docLoader, _ := conn.(engine.DocumentLoader)
	sampler := enginetest.StartRSSSampler(t)
	start := time.Now()
	summary, err := mockdata.Run(ctx, spec, rowLoader, docLoader, nil, nil)
	elapsed := time.Since(start)
	baseline, peak := sampler.Stop()
	if err != nil {
		t.Fatal(err)
	}
	return runResult{summary: summary, elapsed: elapsed, baseline: baseline, peakMiB: peak}
}

func (r runResult) check(t *testing.T, name, unit string, maxTime time.Duration) {
	t.Helper()
	t.Logf("%s: %d %s in %.2fs, %.0f %s/s, RSS baseline %.1f MiB, peak %.1f MiB (+%.1f)",
		name, r.summary.Rows, unit, r.elapsed.Seconds(), r.rate(), unit, r.baseline, r.peakMiB, r.peakMiB-r.baseline)
	for _, d := range r.summary.Done {
		t.Logf("  %s: %d %s in %d ms", d.Target.Name, d.Rows, unit, d.ElapsedMs)
	}
	if r.elapsed > maxTime {
		t.Errorf("run took %.1fs, over the %.0fs gate", r.elapsed.Seconds(), maxTime.Seconds())
	}
	if r.peakMiB > r.baseline+enginetest.LoadRSSBudgetMiB {
		t.Errorf("RSS peak %.1f MiB exceeds baseline %.1f + %d MiB", r.peakMiB, r.baseline, enginetest.LoadRSSBudgetMiB)
	}
}

type discardSink struct{}

func (discardSink) Columns([]engine.Column) error { return nil }
func (discardSink) Batch([][]engine.Value) error  { return nil }

type firstValueSink struct{ value int64 }

func (*firstValueSink) Columns([]engine.Column) error { return nil }
func (s *firstValueSink) Batch(rows [][]engine.Value) error {
	s.value = rows[0][0].Int
	return nil
}

func scalar(ctx context.Context, t *testing.T, exec engine.Executor, sql string) int64 {
	t.Helper()
	sink := &firstValueSink{}
	if _, err := exec.Execute(ctx, engine.Statement{SQL: sql}, sink); err != nil {
		t.Fatalf("%s: %v", sql, err)
	}
	return sink.value
}

// LOAD_PERF=1 go test -tags=integration -run TestIntegrationMockRun -v ./internal/mockdata/
func TestIntegrationMockRunPostgres(t *testing.T) {
	enginetest.SkipUnlessLoadPerf(t)
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
	defer cancel()
	cfg := engine.Config{EngineID: postgres.IDPostgres, Params: map[string]string{
		postgres.ParamHost: env("PG_HOST", "127.0.0.1"), postgres.ParamPort: env("PG_PORT", "5432"),
		postgres.ParamUser: env("PG_USER", "queravue"), postgres.ParamDatabase: env("PG_DB", "queravue"), postgres.ParamSSLMode: "disable",
	}}
	conn, err := postgres.New(postgres.VariantPostgres).Connect(ctx, cfg, engine.NewSecret(env("PG_PASSWORD", "queravue")))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = conn.Close() })
	exec := conn.(engine.Executor)
	run := func(ctx context.Context, sql string) {
		t.Helper()
		if _, err := exec.Execute(ctx, engine.Statement{SQL: sql}, discardSink{}); err != nil {
			t.Fatalf("%s: %v", sql, err)
		}
	}
	dropTables := func(ctx context.Context) {
		run(ctx, "DROP TABLE IF EXISTS "+mockOrdersTable)
		run(ctx, "DROP TABLE IF EXISTS "+mockCustomersTable)
	}
	dropTables(ctx)
	t.Cleanup(func() { dropTables(context.Background()) })
	run(ctx, `CREATE TABLE `+mockCustomersTable+` (id bigint PRIMARY KEY, name text NOT NULL, email text NOT NULL, city text NOT NULL)`)
	run(ctx, `CREATE TABLE `+mockOrdersTable+` (
		id bigint PRIMARY KEY, customer_id bigint NOT NULL REFERENCES `+mockCustomersTable+`(id),
		status text NOT NULL, total numeric(12,2) NOT NULL, created_at timestamptz NOT NULL, note text NOT NULL)`)

	result := runMeasured(ctx, t, conn, postgresSpec(enginetest.LoadPerfRows))
	result.check(t, "postgres mock run", "rows", mockPostgresMaxTime)

	if got := scalar(ctx, t, exec, "SELECT count(*) FROM "+mockOrdersTable); got != enginetest.LoadPerfRows {
		t.Errorf("%d orders stored, want %d", got, enginetest.LoadPerfRows)
	}
	if got := scalar(ctx, t, exec, "SELECT count(*) FROM "+mockCustomersTable); got != mockParentRows {
		t.Errorf("%d customers stored, want %d", got, mockParentRows)
	}
	orphans := scalar(ctx, t, exec, "SELECT count(*) FROM "+mockOrdersTable+" o LEFT JOIN "+mockCustomersTable+" c ON c.id = o.customer_id WHERE c.id IS NULL")
	if orphans != 0 {
		t.Errorf("%d orders point at a missing customer", orphans)
	}
	if used := scalar(ctx, t, exec, "SELECT count(DISTINCT customer_id) FROM "+mockOrdersTable); used < mockParentRows*9/10 {
		t.Errorf("orders reference only %d of %d customers", used, mockParentRows)
	}
}

func TestIntegrationMockRunMongo(t *testing.T) {
	enginetest.SkipUnlessLoadPerf(t)
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
	defer cancel()
	cfg := engine.Config{EngineID: mongo.ID, Params: map[string]string{
		mongo.ParamHosts: env("MONGO_HOST", "127.0.0.1") + ":" + env("MONGO_PORT", "27017"), mongo.ParamReplicaSet: "rs0", mongo.ParamDirect: "false",
	}}
	conn, err := mongo.New(mongo.VariantMongoDB).Connect(ctx, cfg, engine.Secret{})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = conn.Close() })
	drop := func() {
		_, err := conn.(engine.ShellBackend).RunCommand(context.Background(), "queravue", `{"drop":"`+mockCollection+`"}`)
		var e *engine.Error
		if errors.As(err, &e) && (e.Code == codeNamespaceMissing || strings.Contains(strings.ToLower(e.Msg), "not found")) {
			return
		}
		if err != nil {
			t.Errorf("drop: %v", err)
		}
	}
	drop()
	t.Cleanup(drop)

	result := runMeasured(ctx, t, conn, mongoSpec(enginetest.LoadPerfRows))
	result.check(t, "mongo mock run", "docs", mockMongoMaxTime)

	store := conn.(engine.DocumentStore)
	if n, err := store.Count(ctx, "queravue", mockCollection, `{"_id":{"$exists":true}}`, 0); err != nil || n.N != enginetest.LoadPerfRows {
		t.Errorf("%d documents stored (%v), want %d", n.N, err, enginetest.LoadPerfRows)
	}
	if n, err := store.Count(ctx, "queravue", mockCollection, `{"shipping.city":{"$type":"string"},"tags.0":{"$type":"string"}}`, 0); err != nil || n.N != enginetest.LoadPerfRows {
		t.Errorf("%d documents have a nested shipping city and a tag (%v), want %d", n.N, err, enginetest.LoadPerfRows)
	}
}
