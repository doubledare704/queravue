package sqldialect

import (
	"fmt"
	"strings"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

type mysqlDialect struct{}

// MySQL is the dialect of MySQL, MariaDB and TiDB.
var MySQL Dialect = mysqlDialect{}

func (mysqlDialect) ID() string                  { return "mysql" }
func (mysqlDialect) QuoteIdent(n string) string  { return quoteWith(n, "`", "`") }
func (mysqlDialect) Placeholder(int) string      { return "?" }
func (mysqlDialect) ILike(col, ph string) string { return ilikeLower(col, ph) }
func (d mysqlDialect) QualifyTableIn(_, schema, table string) string {
	return d.QualifyTable(schema, table)
}
func (mysqlDialect) Begin() string           { return "BEGIN;" }
func (mysqlDialect) Lexer() sqlsplit.Dialect { return sqlsplit.MySQL }

// QualifyTable qualifies with the database: in MySQL a schema is a database.
func (d mysqlDialect) QualifyTable(schema, table string) string {
	if schema == "" {
		return d.QuoteIdent(table)
	}
	return d.QuoteIdent(schema) + "." + d.QuoteIdent(table)
}

// OrderTerm emulates NULLS FIRST/LAST, which MySQL lacks, with a leading
// "col IS NULL" term (1 for NULL, so ASC puts NULLs last).
func (d mysqlDialect) OrderTerm(col string, desc bool, nulls Nulls) string {
	dir := "ASC"
	if desc {
		dir = "DESC"
	}
	switch nulls {
	case NullsFirst:
		return fmt.Sprintf("%s IS NULL DESC, %s %s", col, col, dir)
	case NullsLast:
		return fmt.Sprintf("%s IS NULL ASC, %s %s", col, col, dir)
	}
	return col + " " + dir
}

func (mysqlDialect) Paginate(sql string, limit uint64, _ bool) (string, bool) {
	return limitSuffix(sql, limit), true
}

// FormatLiteral escapes backslashes too, as MySQL strings are not
// standard-conforming by default.
func (mysqlDialect) FormatLiteral(v engine.Value) string {
	switch v.Kind {
	case engine.VText, engine.VUUID, engine.VJSON:
		return mysqlString(v.Str)
	case engine.VTimestamptz:
		return "'" + v.Time.UTC().Format("2006-01-02 15:04:05.999999") + "'"
	case engine.VNull, engine.VBool, engine.VInt, engine.VFloat, engine.VDecimal, engine.VBytes:
		return literal(v)
	default:
		return mysqlString(v.Str)
	}
}

func mysqlString(s string) string {
	s = strings.ReplaceAll(s, `\`, `\\`)
	return "'" + strings.ReplaceAll(s, "'", "''") + "'"
}
