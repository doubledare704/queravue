package duckdb

import (
	"strings"

	"github.com/doubledare704/queravue/core/internal/engine"
)

// kindOfType maps a DuckDB type name, as duckdb_columns() and result columns
// report it, to the kind of value the column carries.
func kindOfType(typeName string) engine.ValueKind {
	t := strings.ToUpper(strings.TrimSpace(typeName))
	switch {
	case strings.HasSuffix(t, "]"):
		return engine.VArray
	case strings.HasPrefix(t, "STRUCT"), strings.HasPrefix(t, "MAP"):
		return engine.VJSON
	case strings.HasPrefix(t, "DECIMAL"), strings.HasPrefix(t, "NUMERIC"):
		return engine.VDecimal
	case t == "BOOLEAN", t == "BOOL":
		return engine.VBool
	case t == "UBIGINT", t == "HUGEINT", t == "UHUGEINT", t == "BIGNUM", t == "VARINT":
		return engine.VDecimal
	case strings.HasSuffix(t, "INT"), strings.HasSuffix(t, "INTEGER"):
		return engine.VInt
	case t == "FLOAT", t == "DOUBLE", t == "REAL":
		return engine.VFloat
	case t == "TIMESTAMP WITH TIME ZONE", t == "TIMESTAMPTZ":
		return engine.VTimestamptz
	case t == "BLOB", t == "BYTEA", t == "BINARY", t == "VARBINARY":
		return engine.VBytes
	case t == "UUID":
		return engine.VUUID
	case t == "JSON":
		return engine.VJSON
	}
	return engine.VText
}

func isIdentity(columnDefault string) bool {
	return strings.HasPrefix(strings.ToLower(strings.TrimSpace(columnDefault)), "nextval(")
}
