//go:build duckdb

package duckdb

import (
	"math"
	"path/filepath"
	"testing"
	"time"

	duckdbdriver "github.com/duckdb/duckdb-go/v2"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/enginetest"
)

func rowLoaderFixture() enginetest.RowFixture {
	stamp := time.Date(2024, 2, 29, 23, 59, 59, 123456000, time.UTC)
	early := time.Date(1969, 7, 20, 20, 17, 40, 500000000, time.UTC)
	const doc = `{"a":[1,2,{"b":null}],"s":"x"}`
	nulls := func(id int64) []engine.Value {
		row := make([]engine.Value, 14)
		row[0] = engine.Int(id)
		return row
	}
	list := engine.Array([]engine.Value{engine.Int(1), engine.Null(), engine.Int(-3)})
	return enginetest.RowFixture{
		CreateSQL: `CREATE TABLE {table} (
			id BIGINT PRIMARY KEY, flag BOOLEAN, small SMALLINT, big BIGINT, single FLOAT, dbl DOUBLE,
			amount DECIMAL(20,4), txt VARCHAR, raw BLOB, ts TIMESTAMPTZ, doc JSON, uid UUID, nums BIGINT[], wide HUGEINT
		)`,
		Columns: []string{"id", "flag", "small", "big", "single", "dbl", "amount", "txt", "raw", "ts", "doc", "uid", "nums", "wide"},
		Rows: [][]engine.Value{
			{
				engine.Int(1), engine.Bool(true), engine.Int(-32768), engine.Int(math.MinInt64), engine.Float(1.5), engine.Float(0.30000000000000004),
				engine.Decimal("-12345.6789"), engine.Text("tab\there\nnewline\rreturn \\ backslash 'single' \"double\" é 日本"),
				engine.Bytes([]byte{0, 1, 254, 255, '\\', '\''}), engine.Timestamptz(stamp), engine.JSON(doc),
				engine.UUID("123e4567-e89b-12d3-a456-426614174000"), list, engine.Decimal("170141183460469231731687303715884105727"),
			},
			nulls(2),
			{
				engine.Int(3), engine.Bool(false), engine.Int(0), engine.Int(math.MaxInt64), engine.Float(-2.25), engine.Float(-1e300),
				engine.Decimal("0.5"), engine.Text(""), engine.Bytes([]byte{0xff}), engine.Timestamptz(early), engine.JSON(`{"k":[]}`),
				engine.UUID("ffffffff-ffff-ffff-ffff-ffffffffffff"), engine.Array(nil), engine.Decimal("-5"),
			},
		},
	}
}

func TestRowLoaderSuite(t *testing.T) {
	path := filepath.Join(t.TempDir(), "load.duckdb")
	enginetest.RunRowLoader(t, enginetest.RowLoaderTarget{
		Target: enginetest.Target{
			Engine: New(),
			Config: engine.Config{EngineID: ID, Params: map[string]string{ParamPath: path, ParamCreateIfMissing: "true"}},
			Schema: "main",
		},
		Fixture: rowLoaderFixture(),
	})
}

func TestDecimalConverterRoundsLikeSQLCasts(t *testing.T) {
	cases := []struct {
		typeName, in string
		want         string
		wantErr      bool
	}{
		{"DECIMAL(10,2)", "1.239", "124", false},
		{"DECIMAL(10,2)", "-1.239", "-124", false},
		{"DECIMAL(10,2)", "1.234", "123", false},
		{"DECIMAL(10,2)", "-1.235", "-124", false},
		{"DECIMAL(10,2)", "7", "700", false},
		{"DECIMAL(4,2)", "99.995", "", true},
		{"DECIMAL(4,2)", "99.994", "9999", false},
	}
	for _, c := range cases {
		convert, err := converterFor(c.typeName)
		if err != nil {
			t.Fatal(err)
		}
		got, err := convert(engine.Decimal(c.in))
		if c.wantErr {
			if err == nil {
				t.Errorf("%s %s: want an out-of-range error", c.typeName, c.in)
			}
			continue
		}
		if err != nil {
			t.Fatalf("%s %s: %v", c.typeName, c.in, err)
		}
		if unscaled := got.(duckdbdriver.Decimal).Value.String(); unscaled != c.want {
			t.Errorf("%s %s: unscaled %s, want %s", c.typeName, c.in, unscaled, c.want)
		}
	}
}
