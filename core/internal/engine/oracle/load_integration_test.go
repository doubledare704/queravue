//go:build integration

package oracle

import (
	"math"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/enginetest"
)

func rowLoaderFixture() enginetest.RowFixture {
	stamp := time.Date(2024, 2, 29, 23, 59, 59, 123456000, time.UTC)
	early := time.Date(1969, 7, 20, 20, 17, 40, 500000000, time.UTC)
	const doc = `{"a":[1,2,{"b":null}],"s":"x"}`
	nulls := func(id int64) []engine.Value {
		row := make([]engine.Value, 15)
		row[0] = engine.Int(id)
		return row
	}
	return enginetest.RowFixture{
		CreateSQL: `CREATE TABLE {table} (
			"id" NUMBER(10) PRIMARY KEY, "flag" NUMBER(1), "small" NUMBER(5), "big" NUMBER(19), "single" BINARY_FLOAT, "dbl" BINARY_DOUBLE,
			"amount" NUMBER(20,4), "txt" VARCHAR2(400 CHAR), "story" CLOB, "raw" RAW(100), "pic" BLOB,
			"ts" TIMESTAMP(6), "tz" TIMESTAMP(6) WITH TIME ZONE, "doc" JSON, "uid" VARCHAR2(36)
		)`,
		Columns: []string{"id", "flag", "small", "big", "single", "dbl", "amount", "txt", "story", "raw", "pic", "ts", "tz", "doc", "uid"},
		Rows: [][]engine.Value{
			{
				engine.Int(1), engine.Bool(true), engine.Int(-32768), engine.Int(math.MinInt64), engine.Float(1.5), engine.Float(0.30000000000000004),
				engine.Decimal("-12345.6789"), engine.Text("tab\there\nnewline\rreturn \\ backslash 'single' \"double\" é 日本"),
				engine.Text("a longer story with é 日本"), engine.Bytes([]byte{0, 1, 254, 255, '\\', '\''}), engine.Bytes([]byte{9, 8, 7, 0}),
				engine.Timestamptz(stamp), engine.Timestamptz(stamp), engine.JSON(doc), engine.UUID("123e4567-e89b-12d3-a456-426614174000"),
			},
			nulls(2),
			{
				engine.Int(3), engine.Bool(false), engine.Int(0), engine.Int(math.MaxInt64), engine.Float(-2.25), engine.Float(-1e300),
				engine.Decimal("0.5000"), engine.Text("x"), engine.Text("y"),
				engine.Bytes([]byte{0xff}), engine.Bytes([]byte{0xff}), engine.Timestamptz(early), engine.Timestamptz(early),
				engine.JSON(`[]`), engine.UUID("ffffffff-ffff-ffff-ffff-ffffffffffff"),
			},
		},
		Want: [][]engine.Value{
			{
				engine.Int(1), engine.Int(1), engine.Int(-32768), engine.Decimal("-9223372036854775808"), engine.Float(1.5), engine.Float(0.30000000000000004),
				engine.Decimal("-12345.6789"), engine.Text("tab\there\nnewline\rreturn \\ backslash 'single' \"double\" é 日本"),
				engine.Text("a longer story with é 日本"), engine.Bytes([]byte{0, 1, 254, 255, '\\', '\''}), engine.Bytes([]byte{9, 8, 7, 0}),
				engine.Timestamptz(stamp), engine.Timestamptz(stamp), engine.Bytes([]byte(doc)), engine.Text("123e4567-e89b-12d3-a456-426614174000"),
			},
			nulls(2),
			{
				engine.Int(3), engine.Int(0), engine.Int(0), engine.Decimal("9223372036854775807"), engine.Float(-2.25), engine.Float(-1e300),
				engine.Decimal("0.5"), engine.Text("x"), engine.Text("y"),
				engine.Bytes([]byte{0xff}), engine.Bytes([]byte{0xff}), engine.Timestamptz(early), engine.Timestamptz(early),
				engine.Bytes([]byte("[]")), engine.Text("ffffffff-ffff-ffff-ffff-ffffffffffff"),
			},
		},
	}
}

func TestIntegrationRowLoaderOracle(t *testing.T) {
	enginetest.RunRowLoader(t, enginetest.RowLoaderTarget{Target: target(), Fixture: rowLoaderFixture()})
}
