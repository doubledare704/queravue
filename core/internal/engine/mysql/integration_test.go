//go:build integration

package mysql

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

// target for each dev service in dev/docker-compose.yml. Override with
// <PREFIX>_HOST, _PORT, _USER, _PASSWORD, _DB.
func target(v Variant, prefix, port, user, password, product string) enginetest.Target {
	e := New(v)
	db := env(prefix+"_DB", "queravue")
	return enginetest.Target{
		Engine: e,
		Config: engine.Config{EngineID: e.Descriptor().ID, Params: map[string]string{
			ParamHost:     env(prefix+"_HOST", "127.0.0.1"),
			ParamPort:     env(prefix+"_PORT", port),
			ParamUser:     env(prefix+"_USER", user),
			ParamDatabase: db,
			ParamTLS:      "disable",
		}},
		Secret:   engine.NewSecret(env(prefix+"_PASSWORD", password)),
		Product:  product,
		Database: db,
		Schema:   db,
	}
}

func TestIntegrationMySQL(t *testing.T) {
	enginetest.Run(t, target(VariantMySQL, "MYSQL", "3306", "queravue", "queravue", "MySQL"))
}

func TestIntegrationMariaDB(t *testing.T) {
	enginetest.Run(t, target(VariantMariaDB, "MARIADB", "3307", "queravue", "queravue", "MariaDB"))
}

func TestIntegrationTiDB(t *testing.T) {
	enginetest.Run(t, target(VariantTiDB, "TIDB", "4000", "root", "", "TiDB"))
}

func TestIntegrationBadPassword(t *testing.T) {
	tg := target(VariantMySQL, "MYSQL", "3306", "queravue", "queravue", "MySQL")
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	_, err := tg.Engine.Connect(ctx, tg.Config, engine.NewSecret("wrong"))
	if engine.KindOf(err) != engine.KindAuth {
		t.Fatalf("err = %v, want auth", err)
	}
}

func TestIntegrationUnknownDatabase(t *testing.T) {
	tg := target(VariantMySQL, "MYSQL", "3306", "queravue", "queravue", "MySQL")
	tg.Config.Params[ParamDatabase] = "no_such_db"
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	_, err := tg.Engine.Connect(ctx, tg.Config, tg.Secret)
	if k := engine.KindOf(err); k != engine.KindNotFound && k != engine.KindAuth {
		t.Fatalf("err = %v, want not_found (or auth: access is checked first)", err)
	}
}

func TestIntegrationTypes(t *testing.T) {
	tg := target(VariantMySQL, "MYSQL", "3306", "queravue", "queravue", "MySQL")
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
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
	for i, c := range rows.cols {
		idx[c.Name] = i
	}
	r := rows.rows[0]
	check := func(col string, want engine.Value) {
		t.Helper()
		got := r[idx[col]]
		if got.Kind != want.Kind || got.Int != want.Int || got.Str != want.Str || string(got.Bytes) != string(want.Bytes) || !got.Time.Equal(want.Time) {
			t.Errorf("%s = %+v, want %+v", col, got, want)
		}
	}
	check("flag", engine.Int(1))
	check("big_unsigned", engine.Decimal("18446744073709551615"))
	check("price", engine.Decimal("12345678.9012"))
	check("dt", engine.Timestamptz(time.Date(2026, 1, 2, 3, 4, 5, 0, time.UTC)))
	check("ts", engine.Timestamptz(time.Date(2026, 1, 2, 3, 4, 5, 0, time.UTC)))
	check("bits", engine.Bytes([]byte{0xa5}))
	check("doc", engine.JSON(`{"a": [1, 2]}`))
	check("blob_data", engine.Bytes([]byte{0x00, 0xff, 0x10}))
	for _, col := range []string{"dt", "ts", "bits", "doc", "blob_data", "note"} {
		if v := rows.rows[1][idx[col]]; v.Kind != engine.VNull {
			t.Errorf("%s = %+v, want NULL", col, v)
		}
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
