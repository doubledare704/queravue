// Package sqldialect describes how a SQL family writes identifiers,
// placeholders, pagination and literals, and which sqlsplit lexer matches it.
// Engines expose their dialect through Provider; nothing outside an engine
// package switches on an engine id. See docs/adr/0008-sql-dialect-layer.md.
package sqldialect

import (
	"fmt"
	"strings"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

// Nulls selects where NULLs sort in an ORDER BY term.
type Nulls int

// Null placements.
const (
	// NullsDefault leaves placement to the server.
	NullsDefault Nulls = iota
	NullsFirst
	NullsLast
)

// Dialect is the SQL syntax of one family. Implementations are stateless.
type Dialect interface {
	// ID is a stable name, e.g. "postgres". For diagnostics and tests only.
	ID() string
	// QuoteIdent quotes one identifier.
	QuoteIdent(name string) string
	// QualifyTable returns the quoted, optionally schema-qualified name.
	QualifyTable(schema, table string) string
	// Placeholder returns the n-th (1-based) bind placeholder.
	Placeholder(n int) string
	// OrderTerm renders one ORDER BY term for an already quoted column.
	OrderTerm(quotedCol string, desc bool, nulls Nulls) string
	// Paginate limits sql (no trailing semicolon) to limit rows. hasOrderBy
	// says whether sql already has an ORDER BY. The result's stable is false
	// when the dialect had to invent an order, so page contents may vary.
	Paginate(sql string, limit uint64, hasOrderBy bool) (out string, stable bool)
	// FormatLiteral renders v as SQL text for previews. Never executed.
	FormatLiteral(v engine.Value) string
	// Lexer is the sqlsplit lexer for this family.
	Lexer() sqlsplit.Dialect
}

// Provider is implemented by a Conn whose engine speaks SQL.
type Provider interface {
	Dialect() Dialect
}

// Of returns the dialect of c, if it provides one.
func Of(c engine.Conn) (Dialect, bool) {
	p, ok := c.(Provider)
	if !ok {
		return nil, false
	}
	d := p.Dialect()
	return d, d != nil
}

// quoteWith quotes name with open/close delimiters, doubling the closer.
func quoteWith(name, open, closer string) string {
	return open + strings.ReplaceAll(name, closer, closer+closer) + closer
}

// orderTermNulls renders "col DIR [NULLS FIRST|LAST]" for engines that
// support the NULLS clause.
func orderTermNulls(col string, desc bool, nulls Nulls) string {
	dir := "ASC"
	if desc {
		dir = "DESC"
	}
	switch nulls {
	case NullsFirst:
		return col + " " + dir + " NULLS FIRST"
	case NullsLast:
		return col + " " + dir + " NULLS LAST"
	}
	return col + " " + dir
}

// limitSuffix appends " LIMIT n".
func limitSuffix(sql string, limit uint64) string {
	if limit == 0 {
		return sql
	}
	return fmt.Sprintf("%s LIMIT %d", sql, limit)
}

// literal formats v the way Postgres and SQLite previews always have.
func literal(v engine.Value) string {
	switch v.Kind {
	case engine.VNull:
		return "NULL"
	case engine.VBool:
		if v.Bool {
			return "TRUE"
		}
		return "FALSE"
	case engine.VInt:
		return fmt.Sprintf("%d", v.Int)
	case engine.VFloat:
		return fmt.Sprintf("%f", v.Float)
	case engine.VDecimal:
		return v.Str
	case engine.VText, engine.VUUID, engine.VJSON:
		return "'" + strings.ReplaceAll(v.Str, "'", "''") + "'"
	case engine.VTimestamptz:
		return "'" + v.Time.UTC().Format("2006-01-02 15:04:05.999999Z07:00") + "'"
	case engine.VBytes:
		return fmt.Sprintf("X'%X'", v.Bytes)
	default:
		return "'" + strings.ReplaceAll(v.Str, "'", "''") + "'"
	}
}
