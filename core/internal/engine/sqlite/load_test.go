package sqlite

import (
	"context"
	"io"
	"math"
	"path/filepath"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/enginetest"
)

func TestRowLoaderSuite(t *testing.T) {
	path := filepath.Join(t.TempDir(), "load.db")
	enginetest.RunRowLoader(t, enginetest.RowLoaderTarget{
		Target: enginetest.Target{
			Engine: New(),
			Config: engine.Config{EngineID: ID, Params: map[string]string{ParamPath: path, ParamCreateIfMissing: "true"}},
		},
		Fixture: rowLoaderFixture(),
	})
}

func rowLoaderFixture() enginetest.RowFixture {
	stamp := time.Date(2024, 2, 29, 23, 59, 59, 123456000, time.UTC)
	return enginetest.RowFixture{
		CreateSQL: `CREATE TABLE {table} (id INTEGER PRIMARY KEY, flag BOOLEAN, big INTEGER, dbl REAL, amount TEXT,
			txt TEXT, raw BLOB, ts TIMESTAMP, doc JSON, uid TEXT)`,
		Columns: []string{"id", "flag", "big", "dbl", "amount", "txt", "raw", "ts", "doc", "uid"},
		Rows: [][]engine.Value{
			{
				engine.Int(1), engine.Bool(true), engine.Int(math.MinInt64), engine.Float(0.30000000000000004), engine.Decimal("-12345.6789"),
				engine.Text("tab\there\nnewline \\ backslash \"quoted\" é 日本"), engine.Bytes([]byte{0, 1, 254, 255}), engine.Timestamptz(stamp),
				engine.JSON(`{"a": [1, 2, {"b": null}]}`), engine.UUID("123e4567-e89b-12d3-a456-426614174000"),
			},
			{
				engine.Int(2), engine.Null(), engine.Null(), engine.Null(), engine.Null(),
				engine.Null(), engine.Null(), engine.Null(), engine.Null(), engine.Null(),
			},
			{
				engine.Int(3), engine.Bool(false), engine.Int(math.MaxInt64), engine.Float(-2.25), engine.Decimal("0.5000"),
				engine.Text(""), engine.Bytes([]byte{}), engine.Timestamptz(time.Date(1969, 7, 20, 20, 17, 40, 500000000, time.UTC)),
				engine.JSON(`[]`), engine.UUID("ffffffff-ffff-ffff-ffff-ffffffffffff"),
			},
		},
		Want: [][]engine.Value{
			{
				engine.Int(1), engine.Int(1), engine.Int(math.MinInt64), engine.Float(0.30000000000000004), engine.Text("-12345.6789"),
				engine.Text("tab\there\nnewline \\ backslash \"quoted\" é 日本"), engine.Bytes([]byte{0, 1, 254, 255}), engine.Timestamptz(stamp),
				engine.JSON(`{"a": [1, 2, {"b": null}]}`), engine.Text("123e4567-e89b-12d3-a456-426614174000"),
			},
			{
				engine.Int(2), engine.Null(), engine.Null(), engine.Null(), engine.Null(),
				engine.Null(), engine.Null(), engine.Null(), engine.Null(), engine.Null(),
			},
			{
				engine.Int(3), engine.Int(0), engine.Int(math.MaxInt64), engine.Float(-2.25), engine.Text("0.5000"),
				engine.Text(""), engine.Bytes([]byte{}), engine.Timestamptz(time.Date(1969, 7, 20, 20, 17, 40, 500000000, time.UTC)),
				engine.JSON(`[]`), engine.Text("ffffffff-ffff-ffff-ffff-ffffffffffff"),
			},
		},
	}
}

func TestLoadRowsSplitsBatchesAcrossStatements(t *testing.T) {
	c, err := connect(t, map[string]string{ParamPath: filepath.Join(t.TempDir(), "split.db"), ParamCreateIfMissing: "true"})
	if err != nil {
		t.Fatal(err)
	}
	exec := c.(engine.Executor)
	if _, err := exec.Execute(context.Background(), engine.Statement{SQL: "CREATE TABLE wide (a INT, b INT, c INT)"}, nil); err != nil {
		t.Fatal(err)
	}
	rows := make([][]engine.Value, 1203)
	for i := range rows {
		rows[i] = []engine.Value{engine.Int(int64(i)), engine.Int(1), engine.Int(2)}
	}
	loader := c.(engine.RowLoader)
	stats, err := loader.LoadRows(context.Background(), engine.LoadTarget{Table: "wide"}, []string{"a", "b", "c"}, &oneBatch{rows: rows})
	if err != nil || stats.Rows != 1203 || stats.Batches != 1 {
		t.Fatalf("stats = %+v, err = %v", stats, err)
	}
}

type oneBatch struct {
	rows [][]engine.Value
	done bool
}

func (s *oneBatch) Next(context.Context) ([][]engine.Value, error) {
	if s.done {
		return nil, io.EOF
	}
	s.done = true
	return s.rows, nil
}

func TestLoadRowsCountsOnlyRowsTheTableKept(t *testing.T) {
	c, err := connect(t, map[string]string{ParamPath: filepath.Join(t.TempDir(), "ignore.db"), ParamCreateIfMissing: "true"})
	if err != nil {
		t.Fatal(err)
	}
	if _, err := c.(engine.Executor).Execute(context.Background(),
		engine.Statement{SQL: "CREATE TABLE ignoring (id INTEGER, UNIQUE (id) ON CONFLICT IGNORE)"}, nil); err != nil {
		t.Fatal(err)
	}
	rows := [][]engine.Value{{engine.Int(1)}, {engine.Int(1)}, {engine.Int(2)}}
	stats, err := c.(engine.RowLoader).LoadRows(context.Background(), engine.LoadTarget{Table: "ignoring"}, []string{"id"}, &oneBatch{rows: rows})
	if err != nil || stats.Rows != 2 {
		t.Fatalf("stats = %+v, err = %v; the table kept 2 of 3 rows", stats, err)
	}
}

func TestLoadRowsKeepsTheCallersOpenTransaction(t *testing.T) {
	c, err := connect(t, map[string]string{ParamPath: filepath.Join(t.TempDir(), "open.db"), ParamCreateIfMissing: "true"})
	if err != nil {
		t.Fatal(err)
	}
	run := func(sql string) {
		t.Helper()
		if _, err := c.(engine.Executor).Execute(context.Background(), engine.Statement{SQL: sql}, nil); err != nil {
			t.Fatalf("%s: %v", sql, err)
		}
	}
	run("CREATE TABLE kept (id INTEGER)")
	run("BEGIN")
	run("INSERT INTO kept VALUES (0)")
	stats, loadErr := c.(engine.RowLoader).LoadRows(context.Background(), engine.LoadTarget{Table: "kept"}, []string{"id"},
		&oneBatch{rows: [][]engine.Value{{engine.Int(1)}}})
	run("ROLLBACK")
	if loadErr == nil || stats.Rows != 0 {
		t.Errorf("stats = %+v, err = %v; want the load refused while a transaction is open", stats, loadErr)
	}
}
