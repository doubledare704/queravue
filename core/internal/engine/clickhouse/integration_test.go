//go:build integration

package clickhouse

import (
	"context"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/enginetest"
)

func env(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}

func target() enginetest.Target {
	db := env("CLICKHOUSE_DB", "queravue")
	return enginetest.Target{
		Engine: New(),
		Config: engine.Config{EngineID: ID, Params: map[string]string{
			ParamHost:     env("CLICKHOUSE_HOST", "127.0.0.1"),
			ParamPort:     env("CLICKHOUSE_NATIVE_PORT", "9000"),
			ParamUser:     env("CLICKHOUSE_USER", "queravue"),
			ParamDatabase: db,
		}},
		Secret:        engine.NewSecret(env("CLICKHOUSE_PASSWORD", "queravue")),
		Product:       "ClickHouse",
		Database:      db,
		Schema:        db,
		SkipEdit:      true,
		SkipDesigner:  true,
		NoForeignKeys: true,
	}
}

func TestIntegrationSuiteClickHouse(t *testing.T) {
	enginetest.Run(t, target())
}

func TestIntegrationBadPassword(t *testing.T) {
	tg := target()
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	_, err := tg.Engine.Connect(ctx, tg.Config, engine.NewSecret("wrong"))
	if engine.KindOf(err) != engine.KindAuth {
		t.Fatalf("err = %v, want auth", err)
	}
}

func TestIntegrationUnknownDatabase(t *testing.T) {
	tg := target()
	tg.Config.Params[ParamDatabase] = "no_such_database"
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	_, err := tg.Engine.Connect(ctx, tg.Config, tg.Secret)
	if engine.KindOf(err) != engine.KindNotFound {
		t.Fatalf("err = %v, want not_found", err)
	}
}

func TestIntegrationSyntaxErrorIsSQL(t *testing.T) {
	c, ctx := connect(t)
	ex, _ := engine.As[engine.Executor](c)
	_, err := ex.Execute(ctx, engine.Statement{SQL: "SELEC 1"}, &collectRows{})
	if engine.KindOf(err) != engine.KindSQL {
		t.Fatalf("err = %v, want sql", err)
	}
}

type collectRows struct {
	cols []engine.Column
	rows [][]engine.Value
}

func (c *collectRows) Columns(cols []engine.Column) error { c.cols = cols; return nil }
func (c *collectRows) Batch(rows [][]engine.Value) error {
	for _, r := range rows {
		c.rows = append(c.rows, append([]engine.Value(nil), r...))
	}
	return nil
}

func connect(t *testing.T) (engine.Conn, context.Context) {
	t.Helper()
	tg := target()
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	t.Cleanup(cancel)
	c, err := tg.Engine.Connect(ctx, tg.Config, tg.Secret)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = c.Close() })
	return c, ctx
}

func TestIntegrationTypes(t *testing.T) {
	c, ctx := connect(t)
	ex, _ := engine.As[engine.Executor](c)
	rows := collectRows{}
	if _, err := ex.Execute(ctx, engine.Statement{SQL: "SELECT * FROM type_samples ORDER BY id"}, &rows); err != nil {
		t.Fatal(err)
	}
	if len(rows.rows) != 2 {
		t.Fatalf("rows = %d", len(rows.rows))
	}
	idx := map[string]int{}
	for i, col := range rows.cols {
		idx[col.Name] = i
	}
	full := rows.rows[0]
	check := func(col string, want engine.Value) {
		t.Helper()
		got := full[idx[col]]
		if got.Kind != want.Kind || got.Bool != want.Bool || got.Int != want.Int || got.Str != want.Str || !got.Time.Equal(want.Time) {
			t.Errorf("%s = %+v, want %+v", col, got, want)
		}
	}
	check("flag", engine.Bool(true))
	check("big_unsigned", engine.Decimal("18446744073709551615"))
	check("wide", engine.Decimal("170141183460469231731687303715884105727"))
	check("price", engine.Decimal("12345678.9012"))
	check("maybe", engine.Int(7))
	check("tag", engine.Text("alpha"))
	check("guid", engine.UUID("12345678-9abc-def0-0123-456789abcdef"))
	check("ip4", engine.Text("192.168.0.1"))
	check("ip6", engine.Text("2001:db8::1"))
	check("status", engine.Text("done"))
	check("dt", engine.Timestamptz(time.Date(2026, 1, 2, 1, 4, 5, 678_000_000, time.UTC)))
	if tags := full[idx["tags"]]; tags.Kind != engine.VArray || len(tags.Array) != 2 || tags.Array[0].Str != "x" {
		t.Errorf("tags = %+v", tags)
	}
	if attrs := full[idx["attrs"]]; attrs.Kind != engine.VJSON || attrs.Str != `{"k":2}` {
		t.Errorf("attrs = %+v", attrs)
	}
	if pair := full[idx["pair"]]; pair.Kind != engine.VJSON || !strings.Contains(pair.Str, "one") {
		t.Errorf("pair = %+v", pair)
	}
	for _, col := range []string{"maybe", "note"} {
		if v := rows.rows[1][idx[col]]; v.Kind != engine.VNull {
			t.Errorf("%s = %+v, want NULL", col, v)
		}
	}
	if kind := rows.cols[idx["maybe"]].Kind; kind != engine.VInt {
		t.Errorf("Nullable(Int32) kind = %v", kind)
	}
	if kind := rows.cols[idx["dt"]].Kind; kind != engine.VTimestamptz {
		t.Errorf("DateTime64 kind = %v", kind)
	}
}

func TestIntegrationDateTime64KeepsZone(t *testing.T) {
	c, ctx := connect(t)
	ex, _ := engine.As[engine.Executor](c)
	rows := collectRows{}
	if _, err := ex.Execute(ctx, engine.Statement{SQL: "SELECT dt FROM type_samples WHERE id = 1"}, &rows); err != nil {
		t.Fatal(err)
	}
	if name, _ := rows.rows[0][0].Time.Zone(); name != "EET" {
		t.Errorf("zone = %q, want the column zone Europe/Kyiv (EET in January)", name)
	}
}

func TestIntegrationSchemaShowsEnginesAndKeys(t *testing.T) {
	c, ctx := connect(t)
	si, _ := engine.As[engine.SchemaInspector](c)
	objs, err := si.ListObjects(ctx, "queravue", "queravue")
	if err != nil {
		t.Fatal(err)
	}
	want := map[string]struct {
		kind        engine.ObjectType
		tableEngine string
	}{
		"customers":                   {engine.ObjectTypeTable, "MergeTree"},
		"orders_by_customer":          {engine.ObjectTypeTable, "SummingMergeTree"},
		"orders_by_customer_mv":       {engine.ObjectTypeMaterializedView, "MaterializedView"},
		"customer_order_summary_view": {engine.ObjectTypeView, "View"},
	}
	got := map[string]engine.SchemaObject{}
	for _, o := range objs {
		got[o.Name] = o
		if strings.HasPrefix(o.Name, ".inner") {
			t.Errorf("inner table %q listed", o.Name)
		}
	}
	for name, w := range want {
		if o := got[name]; o.Type != w.kind || o.TableEngine != w.tableEngine {
			t.Errorf("%s = %+v, want %v on %s", name, o, w.kind, w.tableEngine)
		}
	}
	d, err := si.DescribeTable(ctx, "queravue", "queravue", "type_samples")
	if err != nil {
		t.Fatal(err)
	}
	if d.TableEngine != "MergeTree" || d.CanEdit || d.EditDisabledReason == "" {
		t.Errorf("type_samples = %+v", d)
	}
	byName := map[string]engine.IndexDef{}
	for _, ix := range d.Indexes {
		byName[ix.Name] = ix
	}
	if ix := byName["sorting key"]; len(ix.Columns) != 1 || ix.Columns[0] != "id" {
		t.Errorf("sorting key = %+v", ix)
	}
	if ix := byName["partition key"]; len(ix.Columns) != 1 || ix.Columns[0] != "toYYYYMM(dt)" {
		t.Errorf("partition key = %+v", ix)
	}
}

func TestIntegrationCancelReachesServer(t *testing.T) {
	c, ctx := connect(t)
	ex, _ := engine.As[engine.Executor](c)
	const marker = "qv_cancel_probe_marker"
	runCtx, cancel := context.WithCancel(ctx)
	done := make(chan error, 1)
	go func() {
		_, err := ex.Execute(runCtx, engine.Statement{
			SQL: "SELECT sleepEachRow(0.01) /* " + marker + " */ FROM numbers(100000) SETTINGS max_block_size = 1",
		}, &collectRows{})
		done <- err
	}()
	if !waitForProcess(t, ctx, c, marker, true) {
		t.Fatal("query never appeared in system.processes")
	}
	cancel()
	if err := <-done; engine.KindOf(err) != engine.KindCanceled {
		t.Fatalf("err = %v, want canceled", err)
	}
	if !waitForProcess(t, ctx, c, marker, false) {
		t.Fatal("query still running on the server after cancel")
	}
}

func waitForProcess(t *testing.T, ctx context.Context, c engine.Conn, marker string, present bool) bool {
	t.Helper()
	ex, _ := engine.As[engine.Executor](c)
	for range 50 {
		rows := collectRows{}
		sql := "SELECT count() FROM system.processes WHERE query LIKE '%" + marker + "%' AND query NOT LIKE '%system.processes%'"
		if _, err := ex.Execute(ctx, engine.Statement{SQL: sql}, &rows); err != nil {
			t.Fatal(err)
		}
		if (rows.rows[0][0].Int > 0) == present {
			return true
		}
		time.Sleep(100 * time.Millisecond)
	}
	return false
}

func TestIntegrationDDLAndInsertReportNoRows(t *testing.T) {
	c, ctx := connect(t)
	ex, _ := engine.As[engine.Executor](c)
	for _, sql := range []string{
		"DROP TABLE IF EXISTS qv_exec_probe",
		"CREATE TABLE qv_exec_probe (a UInt8) ENGINE = Memory",
		"INSERT INTO qv_exec_probe VALUES (1), (2)",
	} {
		sum, err := ex.Execute(ctx, engine.Statement{SQL: sql}, &collectRows{})
		if err != nil || sum.HasRows {
			t.Fatalf("%s: sum %+v err %v", sql, sum, err)
		}
	}
	rows := collectRows{}
	if _, err := ex.Execute(ctx, engine.Statement{SQL: "SELECT a FROM qv_exec_probe WHERE a > ?", Params: []engine.Value{engine.Int(1)}}, &rows); err != nil || len(rows.rows) != 1 {
		t.Fatalf("param query: %v rows %d", err, len(rows.rows))
	}
	_, _ = ex.Execute(ctx, engine.Statement{SQL: "DROP TABLE qv_exec_probe"}, &collectRows{})
}
