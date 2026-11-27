//go:build integration

package mysql

import (
	"math"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/enginetest"
)

func rowLoaderFixture(nativeJSON bool) enginetest.RowFixture {
	stamp := time.Date(2024, 2, 29, 23, 59, 59, 123456000, time.UTC)
	early := time.Date(1969, 7, 20, 20, 17, 40, 500000000, time.UTC)
	const doc = `{"a": [1, 2, {"b": null}], "s": "x"}`
	storedDoc := engine.Text(doc)
	if nativeJSON {
		storedDoc = engine.JSON(doc)
	}
	nulls := func(id int64) []engine.Value {
		row := make([]engine.Value, 13)
		row[0] = engine.Int(id)
		return row
	}
	return enginetest.RowFixture{
		CreateSQL: `CREATE TABLE {table} (
			id BIGINT PRIMARY KEY, flag TINYINT(1), small SMALLINT, big BIGINT, single FLOAT, dbl DOUBLE,
			amount DECIMAL(20,4), txt TEXT, vc VARCHAR(100), raw BLOB, ts DATETIME(6), doc JSON, uid CHAR(36)
		) DEFAULT CHARSET utf8mb4`,
		Columns: []string{"id", "flag", "small", "big", "single", "dbl", "amount", "txt", "vc", "raw", "ts", "doc", "uid"},
		Rows: [][]engine.Value{
			{
				engine.Int(1), engine.Bool(true), engine.Int(-32768), engine.Int(math.MinInt64), engine.Float(1.5), engine.Float(0.30000000000000004),
				engine.Decimal("-12345.6789"), engine.Text("tab\there\nnewline\rreturn \\ backslash 'single' \"double\" é 日本"), engine.Text("varchar"),
				engine.Bytes([]byte{0, 1, 254, 255, '\\', '\''}), engine.Timestamptz(stamp), engine.JSON(doc),
				engine.UUID("123e4567-e89b-12d3-a456-426614174000"),
			},
			nulls(2),
			{
				engine.Int(3), engine.Bool(false), engine.Int(0), engine.Int(math.MaxInt64), engine.Float(-2.25), engine.Float(-1e300),
				engine.Decimal("0.5000"), engine.Text(""), engine.Text(""),
				engine.Bytes([]byte{0xff}), engine.Timestamptz(early), engine.JSON(`[]`),
				engine.UUID("ffffffff-ffff-ffff-ffff-ffffffffffff"),
			},
		},
		Want: [][]engine.Value{
			{
				engine.Int(1), engine.Int(1), engine.Int(-32768), engine.Int(math.MinInt64), engine.Float(1.5), engine.Float(0.30000000000000004),
				engine.Decimal("-12345.6789"), engine.Text("tab\there\nnewline\rreturn \\ backslash 'single' \"double\" é 日本"), engine.Text("varchar"),
				engine.Bytes([]byte{0, 1, 254, 255, '\\', '\''}), engine.Timestamptz(stamp), storedDoc,
				engine.Text("123e4567-e89b-12d3-a456-426614174000"),
			},
			nulls(2),
			{
				engine.Int(3), engine.Int(0), engine.Int(0), engine.Int(math.MaxInt64), engine.Float(-2.25), engine.Float(-1e300),
				engine.Decimal("0.5000"), engine.Text(""), engine.Text(""),
				engine.Bytes([]byte{0xff}), engine.Timestamptz(early), jsonOrText(nativeJSON, `[]`),
				engine.Text("ffffffff-ffff-ffff-ffff-ffffffffffff"),
			},
		},
	}
}

func jsonOrText(native bool, s string) engine.Value {
	if native {
		return engine.JSON(s)
	}
	return engine.Text(s)
}

func rowLoaderTarget(v Variant, prefix, port, user, password, product string, nativeJSON bool) enginetest.RowLoaderTarget {
	return enginetest.RowLoaderTarget{
		Target:  target(v, prefix, port, user, password, product),
		Fixture: rowLoaderFixture(nativeJSON),
	}
}

func TestIntegrationRowLoaderMySQL(t *testing.T) {
	enginetest.RunRowLoader(t, rowLoaderTarget(VariantMySQL, "MYSQL", "3306", "queravue", "queravue", "MySQL", true))
}

func TestIntegrationRowLoaderMariaDB(t *testing.T) {
	enginetest.RunRowLoader(t, rowLoaderTarget(VariantMariaDB, "MARIADB", "3307", "queravue", "queravue", "MariaDB", false))
}

func TestIntegrationRowLoaderTiDB(t *testing.T) {
	enginetest.RunRowLoader(t, rowLoaderTarget(VariantTiDB, "TIDB", "4000", "root", "", "TiDB", true))
}
