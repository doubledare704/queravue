package sqldialect

import (
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func TestImportColumnTypeCoversEveryDialectAndKind(t *testing.T) {
	kinds := []engine.ValueKind{engine.VBool, engine.VInt, engine.VFloat, engine.VDecimal, engine.VText, engine.VBytes, engine.VTimestamptz, engine.VJSON, engine.VUUID, engine.VArray}
	for id, types := range importColumnTypes {
		for _, kind := range kinds {
			if types[kind] == "" {
				t.Errorf("%s has no type for kind %d", id, kind)
			}
		}
	}
	if got := ImportColumnType(Postgres, engine.VInt); got != "bigint" {
		t.Errorf("postgres int = %q", got)
	}
	if got := ImportColumnType(Postgres, engine.VNull); got != "TEXT" {
		t.Errorf("unknown kind = %q, want TEXT", got)
	}
}
