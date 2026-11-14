//go:build duckdb

package duckdb

import (
	"context"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

const seedFile = "../../../../dev/seed/duckdb/01_seed.sql"

type collector struct {
	cols []engine.Column
	rows [][]engine.Value
}

func (c *collector) Columns(cols []engine.Column) error { c.cols = cols; return nil }
func (c *collector) Batch(rows [][]engine.Value) error {
	for _, r := range rows {
		c.rows = append(c.rows, append([]engine.Value(nil), r...))
	}
	return nil
}

func connectTo(t *testing.T, params map[string]string) engine.Conn {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	c, err := New().Connect(ctx, engine.Config{EngineID: ID, Params: params}, engine.Secret{})
	if err != nil {
		t.Fatalf("connect: %v", err)
	}
	t.Cleanup(func() { _ = c.Close() })
	return c
}

func query(t *testing.T, c engine.Conn, sqlText string, params ...engine.Value) (*collector, engine.Summary) {
	t.Helper()
	ex, _ := engine.As[engine.Executor](c)
	got := &collector{}
	sum, err := ex.Execute(context.Background(), engine.Statement{SQL: sqlText, Params: params}, got)
	if err != nil {
		t.Fatalf("execute %q: %v", sqlText, err)
	}
	return got, sum
}

func runScript(t *testing.T, c engine.Conn, script string) {
	t.Helper()
	for _, r := range sqlsplit.Split(sqlsplit.DuckDB, script) {
		query(t, c, script[r.Start:r.End])
	}
}

func seededFile(t *testing.T) (path string, c engine.Conn) {
	t.Helper()
	path = filepath.Join(t.TempDir(), "queravue.duckdb")
	c = connectTo(t, map[string]string{ParamPath: path, ParamCreateIfMissing: "true"})
	script, err := os.ReadFile(seedFile)
	if err != nil {
		t.Fatal(err)
	}
	runScript(t, c, string(script))
	return path, c
}
