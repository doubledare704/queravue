//go:build integration

package clickhouse

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
	rawBytes := []byte{0, 1, 254, 255, '\\', '\''}
	nulls := func(id int64) []engine.Value {
		row := make([]engine.Value, 15)
		row[0] = engine.Int(id)
		row[14] = engine.Array(nil)
		return row
	}
	return enginetest.RowFixture{
		CreateSQL: "CREATE TABLE {table} (" +
			"`id` Int64, `flag` Nullable(Bool), `small` Nullable(Int16), `big` Nullable(Int64), `single` Nullable(Float32), `dbl` Nullable(Float64), " +
			"`amount` Nullable(Decimal(20, 4)), `txt` Nullable(String), `raw` Nullable(String), `ts` Nullable(DateTime64(6, 'UTC')), " +
			"`day` Nullable(Date32), `uid` Nullable(UUID), `tag` LowCardinality(Nullable(String)), `doc` Nullable(String), `arr` Array(Nullable(Int32))" +
			") ENGINE = MergeTree ORDER BY `id`",
		Columns: []string{"id", "flag", "small", "big", "single", "dbl", "amount", "txt", "raw", "ts", "day", "uid", "tag", "doc", "arr"},
		Rows: [][]engine.Value{
			{
				engine.Int(1), engine.Bool(true), engine.Int(-32768), engine.Int(math.MinInt64), engine.Float(1.5), engine.Float(0.30000000000000004),
				engine.Decimal("-12345.6789"), engine.Text("tab\there\nnewline\rreturn \\ backslash 'single' \"double\" é 日本"),
				engine.Bytes(rawBytes), engine.Timestamptz(stamp), engine.Timestamptz(stamp),
				engine.UUID("123e4567-e89b-12d3-a456-426614174000"), engine.Text("tagged"), engine.JSON(doc),
				engine.Array([]engine.Value{engine.Int(1), engine.Null(), engine.Int(-3)}),
			},
			nulls(2),
			{
				engine.Int(3), engine.Bool(false), engine.Int(0), engine.Int(math.MaxInt64), engine.Float(-2.25), engine.Float(-1e300),
				engine.Decimal("0.5000"), engine.Text(""), engine.Bytes([]byte{0xff}), engine.Timestamptz(early), engine.Timestamptz(early),
				engine.UUID("ffffffff-ffff-ffff-ffff-ffffffffffff"), engine.Text(""), engine.JSON(`[]`), engine.Array(nil),
			},
		},
		Want: [][]engine.Value{
			{
				engine.Int(1), engine.Bool(true), engine.Int(-32768), engine.Int(math.MinInt64), engine.Float(1.5), engine.Float(0.30000000000000004),
				engine.Decimal("-12345.6789"), engine.Text("tab\there\nnewline\rreturn \\ backslash 'single' \"double\" é 日本"),
				engine.Text(string(rawBytes)), engine.Timestamptz(stamp), engine.Text("2024-02-29"),
				engine.UUID("123e4567-e89b-12d3-a456-426614174000"), engine.Text("tagged"), engine.Text(doc),
				engine.Array([]engine.Value{engine.Int(1), engine.Null(), engine.Int(-3)}),
			},
			nulls(2),
			{
				engine.Int(3), engine.Bool(false), engine.Int(0), engine.Int(math.MaxInt64), engine.Float(-2.25), engine.Float(-1e300),
				engine.Decimal("0.5"), engine.Text(""), engine.Text("\xff"), engine.Timestamptz(early), engine.Text("1969-07-20"),
				engine.UUID("ffffffff-ffff-ffff-ffff-ffffffffffff"), engine.Text(""), engine.Text(`[]`), engine.Array(nil),
			},
		},
	}
}

func TestIntegrationRowLoaderClickHouse(t *testing.T) {
	violating := engine.Int(-7654321)
	enginetest.RunRowLoader(t, enginetest.RowLoaderTarget{
		Target:  target(),
		Fixture: rowLoaderFixture(),
		KeyedTableSQL: "CREATE TABLE {table} (`id` Int32, `label` String, CONSTRAINT id_positive CHECK `id` > 0) " +
			"ENGINE = MergeTree ORDER BY `id`",
		ViolatingKey:   &violating,
		NoTransactions: true,
	})
}
