//go:build duckdb

package duckdb

import (
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/enginetest"
)

// The designer subset is DuckDB-specific (no ALTER ... ADD FOREIGN KEY, no
// DROP CONSTRAINT, no foreign key actions), so ddl_test.go covers it instead.
func TestEngineSuite(t *testing.T) {
	path, seed := seededFile(t)
	_ = seed.Close()
	enginetest.Run(t, enginetest.Target{
		Engine:       New(),
		Config:       engine.Config{EngineID: ID, Params: map[string]string{ParamPath: path}},
		Product:      "DuckDB",
		Database:     "queravue",
		Schema:       "main",
		SkipDesigner: true,
	})
}
