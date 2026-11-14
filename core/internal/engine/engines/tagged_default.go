//go:build !duckdb

package engines

import "github.com/doubledare704/queravue/core/internal/engine"

func taggedEngines() []engine.Engine { return nil }
