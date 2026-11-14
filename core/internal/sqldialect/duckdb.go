package sqldialect

import (
	"fmt"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

type duckdbDialect struct{}

// DuckDB is the dialect of DuckDB.
var DuckDB Dialect = duckdbDialect{}

func (duckdbDialect) ID() string                  { return "duckdb" }
func (duckdbDialect) QuoteIdent(n string) string  { return quoteWith(n, `"`, `"`) }
func (duckdbDialect) Placeholder(int) string      { return "?" }
func (duckdbDialect) Begin() string               { return "BEGIN TRANSACTION;" }
func (duckdbDialect) Lexer() sqlsplit.Dialect     { return sqlsplit.DuckDB }
func (duckdbDialect) ILike(col, ph string) string { return col + " ILIKE " + ph }

func (d duckdbDialect) QualifyTable(schema, table string) string {
	if schema == "" {
		return d.QuoteIdent(table)
	}
	return d.QuoteIdent(schema) + "." + d.QuoteIdent(table)
}

// QualifyTableIn adds the attached database, which DuckDB spells catalog.
func (d duckdbDialect) QualifyTableIn(database, schema, table string) string {
	if database == "" {
		return d.QualifyTable(schema, table)
	}
	if schema == "" {
		schema = "main"
	}
	return d.QuoteIdent(database) + "." + d.QuoteIdent(schema) + "." + d.QuoteIdent(table)
}

func (duckdbDialect) OrderTerm(col string, desc bool, nulls Nulls) string {
	return orderTermNulls(col, desc, nulls)
}

func (duckdbDialect) Paginate(sql string, limit uint64, _ bool) (string, bool) {
	return limitSuffix(sql, limit), true
}

func (duckdbDialect) FormatLiteral(v engine.Value) string {
	if v.Kind == engine.VBytes {
		return "'" + duckdbBlobEscape(v.Bytes) + "'::BLOB"
	}
	return literal(v)
}

func duckdbBlobEscape(b []byte) string {
	out := make([]byte, 0, len(b)*4)
	for _, c := range b {
		out = append(out, fmt.Sprintf(`\x%02X`, c)...)
	}
	return string(out)
}

var duckdbIndexes = indexSyntax{dialect: DuckDB,
	largeTableNote: "DuckDB indexes (ART) speed up point lookups, not scans, and a table with an index cannot be altered afterwards."}

func (duckdbDialect) CreateIndex(database, schema, table string, spec engine.IndexSpec) (string, []string, error) {
	return duckdbIndexes.create(database, schema, table, spec)
}

func (d duckdbDialect) DropIndex(database, schema, _, name string) string {
	qualified := d.QuoteIdent(name)
	if schema != "" || database != "" {
		if schema == "" {
			schema = "main"
		}
		qualified = d.QuoteIdent(schema) + "." + qualified
		if database != "" {
			qualified = d.QuoteIdent(database) + "." + qualified
		}
	}
	return "DROP INDEX " + qualified + ";"
}
