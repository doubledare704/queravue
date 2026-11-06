package sqldialect

import (
	"fmt"
	"strings"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

type mssqlDialect struct{}

// MSSQL is the dialect of SQL Server (T-SQL).
var MSSQL Dialect = mssqlDialect{}

func (mssqlDialect) ID() string                 { return "mssql" }
func (mssqlDialect) QuoteIdent(n string) string { return quoteWith(n, "[", "]") }
func (mssqlDialect) Placeholder(n int) string   { return fmt.Sprintf("@p%d", n) }
func (mssqlDialect) Begin() string              { return "BEGIN TRANSACTION;" }
func (mssqlDialect) Lexer() sqlsplit.Dialect    { return sqlsplit.MSSQL }

// ILike relies on LOWER: SQL Server has no ILIKE and its default
// collations are case-insensitive anyway.
func (mssqlDialect) ILike(col, ph string) string { return ilikeLower(col, ph) }

func (d mssqlDialect) QualifyTable(schema, table string) string {
	if schema == "" {
		return d.QuoteIdent(table)
	}
	return d.QuoteIdent(schema) + "." + d.QuoteIdent(table)
}

// QualifyTableIn adds the database: [db].[schema].[table]. With no schema it
// uses dbo, as three-part names need one.
func (d mssqlDialect) QualifyTableIn(database, schema, table string) string {
	if database == "" {
		return d.QualifyTable(schema, table)
	}
	if schema == "" {
		schema = "dbo"
	}
	return d.QuoteIdent(database) + "." + d.QuoteIdent(schema) + "." + d.QuoteIdent(table)
}

// OrderTerm emulates NULLS FIRST/LAST, which T-SQL lacks, with a leading
// CASE term. SQL Server sorts NULL as the lowest value.
func (d mssqlDialect) OrderTerm(col string, desc bool, nulls Nulls) string {
	dir := "ASC"
	if desc {
		dir = "DESC"
	}
	switch nulls {
	case NullsFirst:
		return fmt.Sprintf("CASE WHEN %s IS NULL THEN 0 ELSE 1 END, %s %s", col, col, dir)
	case NullsLast:
		return fmt.Sprintf("CASE WHEN %s IS NULL THEN 1 ELSE 0 END, %s %s", col, col, dir)
	}
	return col + " " + dir
}

// Paginate uses OFFSET … FETCH, which needs an ORDER BY. Without one it
// orders by a constant and reports the page order as not stable.
func (mssqlDialect) Paginate(sql string, limit uint64, hasOrderBy bool) (string, bool) {
	if limit == 0 {
		return sql, true
	}
	stable := hasOrderBy
	if !hasOrderBy {
		sql += " ORDER BY (SELECT NULL)"
	}
	return fmt.Sprintf("%s OFFSET 0 ROWS FETCH NEXT %d ROWS ONLY", sql, limit), stable
}

// FormatLiteral writes N'…' strings and 0x… binary literals. Booleans are
// bits (1/0): T-SQL has no TRUE/FALSE.
func (mssqlDialect) FormatLiteral(v engine.Value) string {
	switch v.Kind {
	case engine.VBool:
		if v.Bool {
			return "1"
		}
		return "0"
	case engine.VText, engine.VJSON:
		return "N'" + strings.ReplaceAll(v.Str, "'", "''") + "'"
	case engine.VUUID:
		return "'" + strings.ReplaceAll(v.Str, "'", "''") + "'"
	case engine.VTimestamptz:
		return "'" + v.Time.Format("2006-01-02 15:04:05.9999999 -07:00") + "'"
	case engine.VBytes:
		return fmt.Sprintf("0x%X", v.Bytes)
	case engine.VNull, engine.VInt, engine.VFloat, engine.VDecimal:
		return literal(v)
	default:
		return "N'" + strings.ReplaceAll(v.Str, "'", "''") + "'"
	}
}
