// Package sqlbuilder constructs dialect-specific SQL queries and DML statements.
package sqlbuilder

import (
	"fmt"
	"strings"

	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/results"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

// Dialect is the SQL syntax of the target engine; see package sqldialect.
type Dialect = sqldialect.Dialect

// Built-in dialects, kept for callers that name them directly.
var (
	// DialectPostgres is the PostgreSQL and CockroachDB dialect.
	DialectPostgres = sqldialect.Postgres
	// DialectSQLite is the SQLite dialect.
	DialectSQLite = sqldialect.SQLite
)

// QuoteIdent quotes an identifier with ANSI double quotes.
//
// Deprecated: use Dialect.QuoteIdent so the engine's quoting applies.
func QuoteIdent(s string) string { return sqldialect.Postgres.QuoteIdent(s) }

// QualifyTable returns a safely quoted qualified table name.
func QualifyTable(d Dialect, schema, table string) string {
	return d.QualifyTable(schema, table)
}

// Builder generates parameterized SQL queries and human-readable previews.
type Builder struct {
	dialect Dialect
	params  []engine.Value
	idx     int
}

// New returns a fresh Builder for the dialect.
func New(d Dialect) *Builder {
	return &Builder{dialect: d}
}

func (b *Builder) nextPlaceholder() string {
	b.idx++
	return b.dialect.Placeholder(b.idx)
}

func (b *Builder) addParam(v engine.Value) string {
	b.params = append(b.params, v)
	return b.nextPlaceholder()
}

// BuildSelect creates a parameterized SELECT query and returns the SQL text, parameters, and preview SQL.
func BuildSelect(d Dialect, ref *queravuev1.TableRef, filter *queravuev1.TableFilter, sorts []*queravuev1.SortClause, pageSize uint64) (sql string, params []engine.Value, err error) {
	sql, params, _, err = BuildSelectOrdered(d, ref, filter, sorts, pageSize)
	return sql, params, err
}

// BuildSelectOrdered is BuildSelect that also reports whether the row order
// is stable. It is false when the dialect had to invent an ORDER BY to
// paginate, so repeated pages may differ.
func BuildSelectOrdered(d Dialect, ref *queravuev1.TableRef, filter *queravuev1.TableFilter, sorts []*queravuev1.SortClause, pageSize uint64) (sql string, params []engine.Value, orderStable bool, err error) {
	if ref == nil || ref.GetTable() == "" {
		return "", nil, false, fmt.Errorf("table reference is required")
	}

	b := New(d)
	target := d.QualifyTable(ref.GetSchema(), ref.GetTable())

	var whereClauses []string
	if filter != nil {
		if filter.GetRoot() != nil {
			condSQL, err := b.buildGroup(filter.GetRoot())
			if err != nil {
				return "", nil, false, err
			}
			if condSQL != "" {
				whereClauses = append(whereClauses, condSQL)
			}
		}
		rawWhere := strings.TrimSpace(filter.GetRawWhere())
		if rawWhere != "" {
			whereClauses = append(whereClauses, "("+rawWhere+")")
		}
	}

	var sortClauses []string
	for _, s := range sorts {
		if s == nil || s.GetColumn() == "" {
			continue
		}
		nulls := sqldialect.NullsDefault
		switch s.GetNulls() {
		case queravuev1.NullsOrder_NULLS_ORDER_FIRST:
			nulls = sqldialect.NullsFirst
		case queravuev1.NullsOrder_NULLS_ORDER_LAST:
			nulls = sqldialect.NullsLast
		}
		desc := s.GetDirection() == queravuev1.SortDirection_SORT_DIRECTION_DESC
		sortClauses = append(sortClauses, d.OrderTerm(d.QuoteIdent(s.GetColumn()), desc, nulls))
	}

	var sb strings.Builder
	fmt.Fprintf(&sb, "SELECT * FROM %s", target)
	if len(whereClauses) > 0 {
		sb.WriteString(" WHERE ")
		sb.WriteString(strings.Join(whereClauses, " AND "))
	}
	if len(sortClauses) > 0 {
		sb.WriteString(" ORDER BY ")
		sb.WriteString(strings.Join(sortClauses, ", "))
	}
	out, stable := d.Paginate(sb.String(), pageSize, len(sortClauses) > 0)

	return out + ";", b.params, stable, nil
}

func (b *Builder) buildGroup(g *queravuev1.FilterGroup) (string, error) {
	if g == nil {
		return "", nil
	}

	var parts []string
	for _, c := range g.GetConditions() {
		condSQL, err := b.buildCondition(c)
		if err != nil {
			return "", err
		}
		if condSQL != "" {
			parts = append(parts, condSQL)
		}
	}

	for _, sub := range g.GetGroups() {
		subSQL, err := b.buildGroup(sub)
		if err != nil {
			return "", err
		}
		if subSQL != "" {
			parts = append(parts, subSQL)
		}
	}

	if len(parts) == 0 {
		return "", nil
	}
	if len(parts) == 1 {
		return parts[0], nil
	}

	op := " AND "
	if g.GetOp() == queravuev1.LogicalOp_LOGICAL_OP_OR {
		op = " OR "
	}
	return "(" + strings.Join(parts, op) + ")", nil
}

func (b *Builder) buildCondition(c *queravuev1.FilterCondition) (string, error) {
	if c == nil || c.GetColumn() == "" {
		return "", nil
	}
	col := b.dialect.QuoteIdent(c.GetColumn())

	switch c.GetOp() {
	case queravuev1.FilterOp_FILTER_OP_IS_NULL:
		return col + " IS NULL", nil
	case queravuev1.FilterOp_FILTER_OP_IS_NOT_NULL:
		return col + " IS NOT NULL", nil
	case queravuev1.FilterOp_FILTER_OP_EQUALS:
		v, err := singleValue(c)
		if err != nil {
			return "", err
		}
		return fmt.Sprintf("%s = %s", col, b.addParam(v)), nil
	case queravuev1.FilterOp_FILTER_OP_NOT_EQUALS:
		v, err := singleValue(c)
		if err != nil {
			return "", err
		}
		return fmt.Sprintf("%s != %s", col, b.addParam(v)), nil
	case queravuev1.FilterOp_FILTER_OP_LESS_THAN:
		v, err := singleValue(c)
		if err != nil {
			return "", err
		}
		return fmt.Sprintf("%s < %s", col, b.addParam(v)), nil
	case queravuev1.FilterOp_FILTER_OP_LESS_THAN_OR_EQUAL:
		v, err := singleValue(c)
		if err != nil {
			return "", err
		}
		return fmt.Sprintf("%s <= %s", col, b.addParam(v)), nil
	case queravuev1.FilterOp_FILTER_OP_GREATER_THAN:
		v, err := singleValue(c)
		if err != nil {
			return "", err
		}
		return fmt.Sprintf("%s > %s", col, b.addParam(v)), nil
	case queravuev1.FilterOp_FILTER_OP_GREATER_THAN_OR_EQUAL:
		v, err := singleValue(c)
		if err != nil {
			return "", err
		}
		return fmt.Sprintf("%s >= %s", col, b.addParam(v)), nil
	case queravuev1.FilterOp_FILTER_OP_LIKE:
		v, err := singleValue(c)
		if err != nil {
			return "", err
		}
		return fmt.Sprintf("%s LIKE %s", col, b.addParam(v)), nil
	case queravuev1.FilterOp_FILTER_OP_ILIKE:
		v, err := singleValue(c)
		if err != nil {
			return "", err
		}
		return b.dialect.ILike(col, b.addParam(v)), nil
	case queravuev1.FilterOp_FILTER_OP_BETWEEN:
		vals := c.GetValues()
		if len(vals) < 2 {
			return "", fmt.Errorf("BETWEEN operator requires 2 values for column %q", c.GetColumn())
		}
		v1 := results.ValueFromProto(vals[0])
		v2 := results.ValueFromProto(vals[1])
		p1 := b.addParam(v1)
		p2 := b.addParam(v2)
		return fmt.Sprintf("%s BETWEEN %s AND %s", col, p1, p2), nil
	case queravuev1.FilterOp_FILTER_OP_IN:
		vals := c.GetValues()
		if len(vals) == 0 {
			return "1 = 0", nil // empty IN is always false
		}
		var phs []string
		for _, v := range vals {
			phs = append(phs, b.addParam(results.ValueFromProto(v)))
		}
		return fmt.Sprintf("%s IN (%s)", col, strings.Join(phs, ", ")), nil
	default:
		return "", fmt.Errorf("unsupported filter operator: %v", c.GetOp())
	}
}

func singleValue(c *queravuev1.FilterCondition) (engine.Value, error) {
	vals := c.GetValues()
	if len(vals) == 0 {
		return engine.Null(), nil
	}
	return results.ValueFromProto(vals[0]), nil
}

// StatementPlan holds an executable parameterized statement and its preview.
type StatementPlan struct {
	Statement  engine.Statement
	PreviewSQL string
}

// BuildApplyChanges builds parameterized statements and a formatted preview for table mutations.
func BuildApplyChanges(d Dialect, ref *queravuev1.TableRef, changes []*queravuev1.RowChange) ([]StatementPlan, string, error) {
	if ref == nil || ref.GetTable() == "" {
		return nil, "", fmt.Errorf("table reference is required")
	}
	target := d.QualifyTable(ref.GetSchema(), ref.GetTable())

	var plans []StatementPlan
	var previewLines []string
	previewLines = append(previewLines, "BEGIN;")

	for i, ch := range changes {
		if ch == nil {
			continue
		}
		b := New(d)
		switch ch.GetType() {
		case queravuev1.RowChangeType_ROW_CHANGE_TYPE_INSERT:
			if len(ch.GetValues()) == 0 {
				continue
			}
			var cols, phs, previewVals []string
			for _, cv := range ch.GetValues() {
				cols = append(cols, d.QuoteIdent(cv.GetColumn()))
				v := results.ValueFromProto(cv.GetValue())
				phs = append(phs, b.addParam(v))
				previewVals = append(previewVals, d.FormatLiteral(v))
			}
			sql := fmt.Sprintf("INSERT INTO %s (%s) VALUES (%s);", target, strings.Join(cols, ", "), strings.Join(phs, ", "))
			preview := fmt.Sprintf("INSERT INTO %s (%s) VALUES (%s);", target, strings.Join(cols, ", "), strings.Join(previewVals, ", "))
			plans = append(plans, StatementPlan{
				Statement:  engine.Statement{SQL: sql, Params: b.params},
				PreviewSQL: preview,
			})
			previewLines = append(previewLines, preview)

		case queravuev1.RowChangeType_ROW_CHANGE_TYPE_UPDATE:
			if len(ch.GetKeys()) == 0 {
				return nil, "", fmt.Errorf("change %d: UPDATE requires primary key values", i)
			}
			if len(ch.GetValues()) == 0 {
				continue
			}
			var setClauses, previewSets []string
			for _, cv := range ch.GetValues() {
				col := d.QuoteIdent(cv.GetColumn())
				v := results.ValueFromProto(cv.GetValue())
				setClauses = append(setClauses, fmt.Sprintf("%s = %s", col, b.addParam(v)))
				previewSets = append(previewSets, fmt.Sprintf("%s = %s", col, d.FormatLiteral(v)))
			}
			var whereClauses, previewWheres []string
			for _, cv := range ch.GetKeys() {
				col := d.QuoteIdent(cv.GetColumn())
				v := results.ValueFromProto(cv.GetValue())
				whereClauses = append(whereClauses, fmt.Sprintf("%s = %s", col, b.addParam(v)))
				previewWheres = append(previewWheres, fmt.Sprintf("%s = %s", col, d.FormatLiteral(v)))
			}
			sql := fmt.Sprintf("UPDATE %s SET %s WHERE %s;", target, strings.Join(setClauses, ", "), strings.Join(whereClauses, " AND "))
			preview := fmt.Sprintf("UPDATE %s SET %s WHERE %s;", target, strings.Join(previewSets, ", "), strings.Join(previewWheres, " AND "))
			plans = append(plans, StatementPlan{
				Statement:  engine.Statement{SQL: sql, Params: b.params},
				PreviewSQL: preview,
			})
			previewLines = append(previewLines, preview)

		case queravuev1.RowChangeType_ROW_CHANGE_TYPE_DELETE:
			if len(ch.GetKeys()) == 0 {
				return nil, "", fmt.Errorf("change %d: DELETE requires primary key values", i)
			}
			var whereClauses, previewWheres []string
			for _, cv := range ch.GetKeys() {
				col := d.QuoteIdent(cv.GetColumn())
				v := results.ValueFromProto(cv.GetValue())
				whereClauses = append(whereClauses, fmt.Sprintf("%s = %s", col, b.addParam(v)))
				previewWheres = append(previewWheres, fmt.Sprintf("%s = %s", col, d.FormatLiteral(v)))
			}
			sql := fmt.Sprintf("DELETE FROM %s WHERE %s;", target, strings.Join(whereClauses, " AND "))
			preview := fmt.Sprintf("DELETE FROM %s WHERE %s;", target, strings.Join(previewWheres, " AND "))
			plans = append(plans, StatementPlan{
				Statement:  engine.Statement{SQL: sql, Params: b.params},
				PreviewSQL: preview,
			})
			previewLines = append(previewLines, preview)
		}
	}

	previewLines = append(previewLines, "COMMIT;")
	fullPreview := strings.Join(previewLines, "\n")
	return plans, fullPreview, nil
}
