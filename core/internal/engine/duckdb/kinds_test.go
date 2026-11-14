package duckdb

import (
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func TestKindOfType(t *testing.T) {
	tests := map[string]engine.ValueKind{
		"BOOLEAN":                       engine.VBool,
		"TINYINT":                       engine.VInt,
		"INTEGER":                       engine.VInt,
		"BIGINT":                        engine.VInt,
		"UINTEGER":                      engine.VInt,
		"UBIGINT":                       engine.VDecimal,
		"HUGEINT":                       engine.VDecimal,
		"UHUGEINT":                      engine.VDecimal,
		"DECIMAL(18,3)":                 engine.VDecimal,
		"FLOAT":                         engine.VFloat,
		"DOUBLE":                        engine.VFloat,
		"VARCHAR":                       engine.VText,
		"ENUM('a', 'b')":                engine.VText,
		"INTERVAL":                      engine.VText,
		"DATE":                          engine.VText,
		"TIMESTAMP":                     engine.VText,
		"TIMESTAMP WITH TIME ZONE":      engine.VTimestamptz,
		"BLOB":                          engine.VBytes,
		"UUID":                          engine.VUUID,
		"JSON":                          engine.VJSON,
		"INTEGER[]":                     engine.VArray,
		"INTEGER[3]":                    engine.VArray,
		"STRUCT(a INTEGER)[]":           engine.VArray,
		"STRUCT(a INTEGER, b UUID)":     engine.VJSON,
		"MAP(VARCHAR, INTEGER)":         engine.VJSON,
		"UNION(num INTEGER, s VARCHAR)": engine.VText,
	}
	for typeName, want := range tests {
		if got := kindOfType(typeName); got != want {
			t.Errorf("kindOfType(%q) = %v, want %v", typeName, got, want)
		}
	}
}

func TestIsIdentity(t *testing.T) {
	for dflt, want := range map[string]bool{"nextval('customers_id_seq')": true, "NEXTVAL('\"s\"')": true, "now()": false, "0": false} {
		if got := isIdentity(dflt); got != want {
			t.Errorf("isIdentity(%q) = %v", dflt, got)
		}
	}
}
