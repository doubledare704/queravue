//go:build integration

package mssql

import (
	"context"
	"os"
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

// Uses the mssql service from dev/docker-compose.yml, seeded with
// `docker compose --profile seed up mssql-seed`. Override with MSSQL_HOST,
// MSSQL_PORT, MSSQL_USER, MSSQL_SA_PASSWORD, MSSQL_DB.
func target() enginetest.Target {
	db := env("MSSQL_DB", "queravue")
	return enginetest.Target{
		Engine: New(),
		Config: engine.Config{EngineID: ID, Params: map[string]string{
			ParamHost:     env("MSSQL_HOST", "127.0.0.1"),
			ParamPort:     env("MSSQL_PORT", "1433"),
			ParamUser:     env("MSSQL_USER", "sa"),
			ParamDatabase: db,
			ParamEncrypt:  "required",
			ParamTrust:    "true", // the dev server has a self-signed certificate
		}},
		Secret:   engine.NewSecret(env("MSSQL_SA_PASSWORD", "Queravue_dev1")),
		Product:  "SQL Server",
		Database: db,
		Schema:   "dbo",
	}
}

func TestIntegrationSuiteMSSQL(t *testing.T) {
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

func TestIntegrationCertificateNotTrusted(t *testing.T) {
	tg := target()
	tg.Config.Params[ParamTrust] = "false"
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	_, err := tg.Engine.Connect(ctx, tg.Config, tg.Secret)
	if engine.KindOf(err) != engine.KindTLS {
		t.Fatalf("err = %v (kind %v), want tls", err, engine.KindOf(err))
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

func TestIntegrationTypes(t *testing.T) {
	tg := target()
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	c, err := tg.Engine.Connect(ctx, tg.Config, tg.Secret)
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = c.Close() }()
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
	r := rows.rows[0]
	check := func(col string, want engine.Value) {
		t.Helper()
		got := r[idx[col]]
		if got.Kind != want.Kind || got.Bool != want.Bool || got.Str != want.Str || string(got.Bytes) != string(want.Bytes) || !got.Time.Equal(want.Time) {
			t.Errorf("%s = %+v, want %+v", col, got, want)
		}
	}
	check("guid", engine.UUID("12345678-9ABC-DEF0-0123-456789ABCDEF"))
	check("amount", engine.Decimal("922337203685477.5807"))
	check("price", engine.Decimal("12345678.9012"))
	check("dto", engine.Timestamptz(time.Date(2026, 1, 2, 3, 4, 5, 678_000_000, time.FixedZone("", 2*3600))))
	check("dt2", engine.Timestamptz(time.Date(2026, 1, 2, 3, 4, 5, 678_000_000, time.UTC)))
	check("doc", engine.Text("<a><b>1</b></a>"))
	check("bin", engine.Bytes([]byte{0x00, 0xff, 0x10}))
	check("flag", engine.Bool(true))
	if big := r[idx["big"]]; big.Kind != engine.VText || len([]rune(big.Str)) != 10000 {
		t.Errorf("nvarchar(max) = kind %v, %d runes", big.Kind, len([]rune(big.Str)))
	}
	if ver := r[idx["ver"]]; ver.Kind != engine.VBytes || len(ver.Bytes) != 8 {
		t.Errorf("rowversion = %+v", ver)
	}
	for _, col := range []string{"guid", "amount", "dto", "dt2", "big", "doc", "bin", "flag"} {
		if v := rows.rows[1][idx[col]]; v.Kind != engine.VNull {
			t.Errorf("%s = %+v, want NULL", col, v)
		}
	}
}

// Only the first result set of a batch is returned.
func TestIntegrationFirstResultSetOnly(t *testing.T) {
	tg := target()
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	c, err := tg.Engine.Connect(ctx, tg.Config, tg.Secret)
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = c.Close() }()
	ex, _ := engine.As[engine.Executor](c)
	rows := collectRows{}
	if _, err := ex.Execute(ctx, engine.Statement{SQL: "SELECT 1 AS a; SELECT 2 AS b, 3 AS c"}, &rows); err != nil {
		t.Fatal(err)
	}
	if len(rows.cols) != 1 || rows.cols[0].Name != "a" || len(rows.rows) != 1 {
		t.Errorf("cols = %+v rows = %v", rows.cols, rows.rows)
	}
	again := collectRows{}
	if _, err := ex.Execute(ctx, engine.Statement{SQL: "SELECT 9 AS z"}, &again); err != nil || len(again.rows) != 1 {
		t.Errorf("session unusable after multi-result batch: %v", err)
	}
}
