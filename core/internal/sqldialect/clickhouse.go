package sqldialect

import (
	"errors"
	"fmt"
	"strings"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

type clickhouseDialect struct{}

// ClickHouse is the dialect of ClickHouse.
var ClickHouse Dialect = clickhouseDialect{}

var errClickHouseIndexes = errors.New("ClickHouse has no secondary index management; sorting keys and data-skipping indexes belong to the table engine definition")

func (clickhouseDialect) ID() string { return "clickhouse" }
func (clickhouseDialect) QuoteIdent(n string) string {
	return quoteWith(strings.ReplaceAll(n, `\`, `\\`), "`", "`")
}
func (clickhouseDialect) Placeholder(int) string      { return "?" }
func (clickhouseDialect) Begin() string               { return "BEGIN TRANSACTION" }
func (clickhouseDialect) Lexer() sqlsplit.Dialect     { return sqlsplit.ClickHouse }
func (clickhouseDialect) ILike(col, ph string) string { return col + " ILIKE " + ph }

func (d clickhouseDialect) QualifyTable(schema, table string) string {
	if schema == "" {
		return d.QuoteIdent(table)
	}
	return d.QuoteIdent(schema) + "." + d.QuoteIdent(table)
}

func (d clickhouseDialect) QualifyTableIn(database, schema, table string) string {
	if schema == "" {
		schema = database
	}
	return d.QualifyTable(schema, table)
}

func (clickhouseDialect) OrderTerm(col string, desc bool, nulls Nulls) string {
	return orderTermNulls(col, desc, nulls)
}

func (clickhouseDialect) Paginate(sql string, limit uint64, _ bool) (string, bool) {
	return limitSuffix(sql, limit), true
}

func (clickhouseDialect) FormatLiteral(v engine.Value) string {
	switch v.Kind {
	case engine.VText, engine.VUUID, engine.VJSON:
		return mysqlString(v.Str)
	case engine.VTimestamptz:
		return "'" + v.Time.UTC().Format("2006-01-02 15:04:05.999999") + "'"
	case engine.VBytes:
		return fmt.Sprintf("unhex('%X')", v.Bytes)
	case engine.VNull, engine.VBool, engine.VInt, engine.VFloat, engine.VDecimal:
		return literal(v)
	default:
		return mysqlString(v.Str)
	}
}

func (clickhouseDialect) CreateIndex(string, string, string, engine.IndexSpec) (string, []string, error) {
	return "", nil, errClickHouseIndexes
}

func (d clickhouseDialect) DropIndex(database, schema, table, name string) string {
	return "ALTER TABLE " + d.QualifyTableIn(database, schema, table) + " DROP INDEX " + d.QuoteIdent(name)
}
