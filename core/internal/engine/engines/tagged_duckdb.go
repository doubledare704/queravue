//go:build duckdb

package engines

import (
	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/duckdb"
)

func taggedEngines() []engine.Engine { return []engine.Engine{duckdb.New()} }
