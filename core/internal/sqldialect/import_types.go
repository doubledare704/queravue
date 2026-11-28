package sqldialect

import "github.com/doubledare704/queravue/core/internal/engine"

var importColumnTypes = map[string]map[engine.ValueKind]string{
	"postgres": {engine.VBool: "boolean", engine.VInt: "bigint", engine.VFloat: "double precision", engine.VDecimal: "numeric",
		engine.VText: "text", engine.VBytes: "bytea", engine.VTimestamptz: "timestamptz", engine.VJSON: "jsonb", engine.VUUID: "uuid", engine.VArray: "jsonb"},
	"mysql": {engine.VBool: "BOOLEAN", engine.VInt: "BIGINT", engine.VFloat: "DOUBLE", engine.VDecimal: "DECIMAL(38,10)",
		engine.VText: "TEXT", engine.VBytes: "LONGBLOB", engine.VTimestamptz: "DATETIME(6)", engine.VJSON: "JSON", engine.VUUID: "CHAR(36)", engine.VArray: "JSON"},
	"mssql": {engine.VBool: "BIT", engine.VInt: "BIGINT", engine.VFloat: "FLOAT", engine.VDecimal: "DECIMAL(38,10)",
		engine.VText: "NVARCHAR(MAX)", engine.VBytes: "VARBINARY(MAX)", engine.VTimestamptz: "DATETIMEOFFSET", engine.VJSON: "NVARCHAR(MAX)", engine.VUUID: "UNIQUEIDENTIFIER", engine.VArray: "NVARCHAR(MAX)"},
	"oracle": {engine.VBool: "NUMBER(1)", engine.VInt: "NUMBER(19)", engine.VFloat: "BINARY_DOUBLE", engine.VDecimal: "NUMBER(38,10)",
		engine.VText: "CLOB", engine.VBytes: "BLOB", engine.VTimestamptz: "TIMESTAMP WITH TIME ZONE", engine.VJSON: "CLOB", engine.VUUID: "VARCHAR2(36)", engine.VArray: "CLOB"},
	"sqlite": {engine.VBool: "INTEGER", engine.VInt: "INTEGER", engine.VFloat: "REAL", engine.VDecimal: "NUMERIC",
		engine.VText: "TEXT", engine.VBytes: "BLOB", engine.VTimestamptz: "TEXT", engine.VJSON: "TEXT", engine.VUUID: "TEXT", engine.VArray: "TEXT"},
	"clickhouse": {engine.VBool: "Bool", engine.VInt: "Int64", engine.VFloat: "Float64", engine.VDecimal: "Decimal(38,10)",
		engine.VText: "String", engine.VBytes: "String", engine.VTimestamptz: "DateTime64(6)", engine.VJSON: "String", engine.VUUID: "UUID", engine.VArray: "String"},
	"duckdb": {engine.VBool: "BOOLEAN", engine.VInt: "BIGINT", engine.VFloat: "DOUBLE", engine.VDecimal: "DECIMAL(38,10)",
		engine.VText: "VARCHAR", engine.VBytes: "BLOB", engine.VTimestamptz: "TIMESTAMPTZ", engine.VJSON: "VARCHAR", engine.VUUID: "UUID", engine.VArray: "VARCHAR"},
}

// ImportColumnType is the native type a new table column of kind gets when its
// rows come from a file. Unknown dialects and kinds get "TEXT".
func ImportColumnType(d Dialect, kind engine.ValueKind) string {
	if name, ok := importColumnTypes[d.ID()][kind]; ok {
		return name
	}
	return "TEXT"
}
