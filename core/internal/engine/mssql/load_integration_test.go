//go:build integration

package mssql

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
	nulls := func(id int64) []engine.Value {
		row := make([]engine.Value, 13)
		row[0] = engine.Int(id)
		return row
	}
	return enginetest.RowFixture{
		CreateSQL: `CREATE TABLE {table} (
			id BIGINT PRIMARY KEY, flag BIT, small SMALLINT, big BIGINT, single REAL, dbl FLOAT,
			amount DECIMAL(20,4), txt NVARCHAR(MAX), vc VARCHAR(100), raw VARBINARY(MAX),
			ts DATETIME2(6), tz DATETIMEOFFSET(6), uid UNIQUEIDENTIFIER
		)`,
		Columns: []string{"id", "flag", "small", "big", "single", "dbl", "amount", "txt", "vc", "raw", "ts", "tz", "uid"},
		Rows: [][]engine.Value{
			{
				engine.Int(1), engine.Bool(true), engine.Int(-32768), engine.Int(math.MinInt64), engine.Float(1.5), engine.Float(0.30000000000000004),
				engine.Decimal("-12345.6789"), engine.Text("tab\there\nnewline\rreturn \\ backslash 'single' \"double\" é 日本"), engine.Text("plain ascii"),
				engine.Bytes([]byte{0, 1, 254, 255, '\\', '\''}), engine.Timestamptz(stamp), engine.Timestamptz(stamp),
				engine.UUID("123e4567-e89b-12d3-a456-426614174000"),
			},
			nulls(2),
			{
				engine.Int(3), engine.Bool(false), engine.Int(0), engine.Int(math.MaxInt64), engine.Float(-2.25), engine.Float(-1e300),
				engine.Decimal("0.5000"), engine.Text(""), engine.Text(""),
				engine.Bytes([]byte{0xff}), engine.Timestamptz(early), engine.Timestamptz(early),
				engine.UUID("ffffffff-ffff-ffff-ffff-ffffffffffff"),
			},
		},
		Want: [][]engine.Value{
			{
				engine.Int(1), engine.Bool(true), engine.Int(-32768), engine.Int(math.MinInt64), engine.Float(1.5), engine.Float(0.30000000000000004),
				engine.Decimal("-12345.6789"), engine.Text("tab\there\nnewline\rreturn \\ backslash 'single' \"double\" é 日本"), engine.Text("plain ascii"),
				engine.Bytes([]byte{0, 1, 254, 255, '\\', '\''}), engine.Timestamptz(stamp), engine.Timestamptz(stamp),
				engine.UUID("123E4567-E89B-12D3-A456-426614174000"),
			},
			nulls(2),
			{
				engine.Int(3), engine.Bool(false), engine.Int(0), engine.Int(math.MaxInt64), engine.Float(-2.25), engine.Float(-1e300),
				engine.Decimal("0.5000"), engine.Text(""), engine.Text(""),
				engine.Bytes([]byte{0xff}), engine.Timestamptz(early), engine.Timestamptz(early),
				engine.UUID("FFFFFFFF-FFFF-FFFF-FFFF-FFFFFFFFFFFF"),
			},
		},
	}
}

func TestIntegrationRowLoaderMSSQL(t *testing.T) {
	enginetest.RunRowLoader(t, enginetest.RowLoaderTarget{Target: target(), Fixture: rowLoaderFixture()})
}
