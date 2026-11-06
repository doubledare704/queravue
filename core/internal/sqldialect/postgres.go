package sqldialect

import (
	"fmt"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

type postgres struct{}

// Postgres is the dialect of PostgreSQL and wire-compatible servers
// (CockroachDB).
var Postgres Dialect = postgres{}

func (postgres) ID() string                          { return "postgres" }
func (postgres) QuoteIdent(n string) string          { return quoteWith(n, `"`, `"`) }
func (postgres) Placeholder(n int) string            { return fmt.Sprintf("$%d", n) }
func (postgres) FormatLiteral(v engine.Value) string { return literal(v) }
func (postgres) Lexer() sqlsplit.Dialect             { return sqlsplit.Postgres }

func (d postgres) QualifyTable(schema, table string) string {
	if schema == "" {
		return d.QuoteIdent(table)
	}
	return d.QuoteIdent(schema) + "." + d.QuoteIdent(table)
}

func (postgres) OrderTerm(col string, desc bool, nulls Nulls) string {
	return orderTermNulls(col, desc, nulls)
}

func (postgres) Paginate(sql string, limit uint64, _ bool) (string, bool) {
	return limitSuffix(sql, limit), true
}
