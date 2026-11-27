//go:build integration

package postgres

import (
	"math"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/enginetest"
)

func rowLoaderFixture(nestedArrays bool) enginetest.RowFixture {
	nulls := make([]engine.Value, 18)
	nulls[0] = engine.Int(2)
	text := func(vals ...string) engine.Value {
		out := make([]engine.Value, len(vals))
		for i, s := range vals {
			out[i] = engine.Text(s)
		}
		return engine.Array(out)
	}
	fixture := enginetest.RowFixture{
		CreateSQL: `CREATE TABLE {table} (
			id bigint PRIMARY KEY, flag boolean, small smallint, regular integer, big bigint,
			single real, dbl double precision, amount numeric(20,4), txt text, vc varchar(100),
			raw bytea, ts timestamptz, doc json, docb jsonb, uid uuid, ints integer[], texts text[], day date)`,
		Columns: []string{"id", "flag", "small", "regular", "big", "single", "dbl", "amount", "txt", "vc", "raw", "ts", "doc", "docb", "uid", "ints", "texts", "day"},
		Rows: [][]engine.Value{
			{
				engine.Int(1), engine.Bool(true), engine.Int(-32768), engine.Int(2147483647), engine.Int(math.MinInt64),
				engine.Float(1.5), engine.Float(0.30000000000000004), engine.Decimal("-12345.6789"), engine.Text("plain"), engine.Text("varchar"),
				engine.Bytes([]byte{0, 1, 254, 255}), engine.Timestamptz(time.Date(2024, 2, 29, 23, 59, 59, 123456000, time.UTC)),
				engine.JSON(`{"a": [1, 2, {"b": null}], "s": "x"}`), engine.JSON(`{"k": "v"}`), engine.UUID("123e4567-e89b-12d3-a456-426614174000"),
				engine.Array([]engine.Value{engine.Int(1), engine.Null(), engine.Int(3)}), text("a", "b"), engine.Text("2024-02-29"),
			},
			nulls,
			{
				engine.Int(3), engine.Bool(false), engine.Int(0), engine.Int(0), engine.Int(math.MaxInt64),
				engine.Float(-2.25), engine.Float(math.MaxFloat64), engine.Decimal("0.5000"), engine.Text("tab\there\nnewline\rreturn \\ backslash \\N not null \"quoted\" é 日本"), engine.Text(""),
				engine.Bytes([]byte{0, '\\', '\n', '\t', '"'}), engine.Timestamptz(time.Date(1969, 7, 20, 20, 17, 40, 500000000, time.UTC)),
				engine.JSON(`[]`), engine.JSON(`"string"`), engine.UUID("ffffffff-ffff-ffff-ffff-ffffffffffff"),
				engine.Array([]engine.Value{engine.Int(7), engine.Int(8)}),
				text("a,b", `q"uote`, `back\slash`, "{brace}", "NULL", ""), engine.Text("0001-01-01"),
			},
			{
				engine.Int(4), engine.Null(), engine.Null(), engine.Null(), engine.Null(), engine.Null(), engine.Null(), engine.Null(),
				engine.Null(), engine.Null(), engine.Null(), engine.Null(), engine.Null(), engine.Null(), engine.Null(),
				engine.Array(nil), engine.Array([]engine.Value{engine.Null()}), engine.Null(),
			},
		},
	}
	if nestedArrays {
		fixture.Rows[2][15] = engine.Array([]engine.Value{
			engine.Array([]engine.Value{engine.Int(1), engine.Int(2)}),
			engine.Array([]engine.Value{engine.Int(3), engine.Int(4)}),
		})
	}
	return fixture
}

func TestIntegrationRowLoaderPostgres(t *testing.T) {
	params, secret := pgParams()
	enginetest.RunRowLoader(t, enginetest.RowLoaderTarget{
		Target: enginetest.Target{
			Engine:   New(VariantPostgres),
			Config:   engine.Config{EngineID: IDPostgres, Params: params},
			Secret:   secret,
			Database: params[ParamDatabase],
			Schema:   "public",
		},
		Fixture: rowLoaderFixture(true),
	})
}

func TestIntegrationRowLoaderCockroach(t *testing.T) {
	get := func(k, def string) string {
		if v := envOr(k); v != "" {
			return v
		}
		return def
	}
	db := get("CRDB_DB", "queravue")
	enginetest.RunRowLoader(t, enginetest.RowLoaderTarget{
		Target: enginetest.Target{
			Engine: New(VariantCockroach),
			Config: engine.Config{EngineID: IDCockroach, Params: map[string]string{
				ParamHost:     get("CRDB_HOST", "127.0.0.1"),
				ParamPort:     get("CRDB_PORT", "26257"),
				ParamUser:     get("CRDB_USER", "root"),
				ParamDatabase: db,
				ParamSSLMode:  "disable",
			}},
			Secret:   engine.NewSecret(get("CRDB_PASSWORD", "")),
			Database: db,
			Schema:   "public",
		},
		Fixture: rowLoaderFixture(false),
	})
}
