package sqldialect

import (
	"fmt"
	"strings"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

type oracleDialect struct{}

// Oracle is the dialect of Oracle Database 12c and later.
var Oracle Dialect = oracleDialect{}

func (oracleDialect) ID() string                  { return "oracle" }
func (oracleDialect) QuoteIdent(n string) string  { return quoteWith(n, `"`, `"`) }
func (oracleDialect) Placeholder(n int) string    { return fmt.Sprintf(":%d", n) }
func (oracleDialect) ILike(col, ph string) string { return ilikeLower(col, ph) }
func (oracleDialect) Lexer() sqlsplit.Dialect     { return sqlsplit.Oracle }

// Begin is explicit because Oracle starts transactions implicitly and the
// engine only holds one open between this statement and COMMIT or ROLLBACK.
func (oracleDialect) Begin() string { return "SET TRANSACTION READ WRITE;" }

func (d oracleDialect) QualifyTable(schema, table string) string {
	if schema == "" {
		return d.QuoteIdent(table)
	}
	return d.QuoteIdent(schema) + "." + d.QuoteIdent(table)
}

func (d oracleDialect) QualifyTableIn(_, schema, table string) string {
	return d.QualifyTable(schema, table)
}

func (oracleDialect) OrderTerm(col string, desc bool, nulls Nulls) string {
	return orderTermNulls(col, desc, nulls)
}

func (oracleDialect) Paginate(sql string, limit uint64, _ bool) (string, bool) {
	if limit == 0 {
		return sql, true
	}
	return fmt.Sprintf("%s FETCH FIRST %d ROWS ONLY", sql, limit), true
}

// FormatLiteral writes booleans as 1/0 (older servers have no BOOLEAN),
// timestamps with a time zone offset and binary as HEXTORAW.
func (oracleDialect) FormatLiteral(v engine.Value) string {
	switch v.Kind {
	case engine.VBool:
		if v.Bool {
			return "1"
		}
		return "0"
	case engine.VTimestamptz:
		return "TIMESTAMP '" + v.Time.Format("2006-01-02 15:04:05.999999999 -07:00") + "'"
	case engine.VBytes:
		return fmt.Sprintf("HEXTORAW('%X')", v.Bytes)
	case engine.VNull, engine.VInt, engine.VFloat, engine.VDecimal:
		return literal(v)
	default:
		return "'" + strings.ReplaceAll(v.Str, "'", "''") + "'"
	}
}

var oracleIndexes = indexSyntax{dialect: Oracle, descending: true, expressions: true, qualifyDropName: true,
	largeTableNote: "CREATE INDEX locks the table against writes while it builds, unless ONLINE is used.",
	onlineSuffix:   " ONLINE",
	onlineNote:     "ONLINE keeps the table writable during the build; it needs Enterprise Edition or a server that includes the feature."}

func (d oracleDialect) CreateIndex(database, schema, table string, spec engine.IndexSpec) (string, []string, error) {
	return oracleIndexes.create(database, schema, table, spec)
}

func (d oracleDialect) DropIndex(database, schema, table, name string) string {
	return oracleIndexes.drop(database, schema, table, name)
}
