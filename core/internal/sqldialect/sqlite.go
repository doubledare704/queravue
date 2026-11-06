package sqldialect

import (
	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

type sqliteDialect struct{}

// SQLite is the dialect of SQLite.
var SQLite Dialect = sqliteDialect{}

func (sqliteDialect) ID() string                          { return "sqlite" }
func (sqliteDialect) QuoteIdent(n string) string          { return quoteWith(n, `"`, `"`) }
func (sqliteDialect) Placeholder(int) string              { return "?" }
func (sqliteDialect) FormatLiteral(v engine.Value) string { return literal(v) }
func (sqliteDialect) ILike(col, ph string) string         { return ilikeLower(col, ph) }
func (d sqliteDialect) QualifyTableIn(_, schema, table string) string {
	return d.QualifyTable(schema, table)
}
func (sqliteDialect) Begin() string           { return "BEGIN;" }
func (sqliteDialect) Lexer() sqlsplit.Dialect { return sqlsplit.SQLite }

// QualifyTable omits the default "main" schema.
func (d sqliteDialect) QualifyTable(schema, table string) string {
	if schema == "" || schema == "main" {
		return d.QuoteIdent(table)
	}
	return d.QuoteIdent(schema) + "." + d.QuoteIdent(table)
}

func (sqliteDialect) OrderTerm(col string, desc bool, nulls Nulls) string {
	return orderTermNulls(col, desc, nulls)
}

func (sqliteDialect) Paginate(sql string, limit uint64, _ bool) (string, bool) {
	return limitSuffix(sql, limit), true
}
