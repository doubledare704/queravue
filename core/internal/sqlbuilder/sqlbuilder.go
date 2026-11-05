// Package sqlbuilder constructs dialect-specific SQL queries and DML statements.
package sqlbuilder

import (
	"fmt"
	"strings"

	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/results"
)

// Dialect identifies SQL dialect syntax rules.
type Dialect int

const (
	// DialectPostgres formats identifiers and placeholders ($1) for PostgreSQL and CockroachDB.
	DialectPostgres Dialect = iota
	// DialectSQLite formats identifiers and placeholders (?) for SQLite.
	DialectSQLite
)

// QuoteIdent quotes a SQL identifier safely per dialect rules.
func QuoteIdent(s string) string {
	return `"` + strings.ReplaceAll(s, `"`, `""`) + `"`
}

// QualifyTable returns a safely quoted qualified table name.
func QualifyTable(d Dialect, schema, table string) string {
	qTable := QuoteIdent(table)
	if schema == "" || (d == DialectSQLite && schema == "main") {
		return qTable
	}
	return QuoteIdent(schema) + "." + qTable
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
	if b.dialect == DialectPostgres {
		return fmt.Sprintf("$%d", b.idx)
	}
	return "?"
}

func (b *Builder) addParam(v engine.Value) string {
	b.params = append(b.params, v)
	return b.nextPlaceholder()
}

// BuildSelect creates a parameterized SELECT query and returns the SQL text, parameters, and preview SQL.
func BuildSelect(d Dialect, ref *queravuev1.TableRef, filter *queravuev1.TableFilter, sorts []*queravuev1.SortClause, pageSize uint64) (sql string, params []engine.Value, err error) {
	if ref == nil || ref.GetTable() == "" {
		return "", nil, fmt.Errorf("table reference is required")
	}

	b := New(d)
	target := QualifyTable(d, ref.GetSchema(), ref.GetTable())

	var whereClauses []string
	if filter != nil {
		if filter.GetRoot() != nil {
			condSQL, err := b.buildGroup(filter.GetRoot())
			if err != nil {
				return "", nil, err
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
		col := QuoteIdent(s.GetColumn())
		dir := "ASC"
		if s.GetDirection() == queravuev1.SortDirection_SORT_DIRECTION_DESC {
			dir = "DESC"
		}
		nulls := ""
		switch s.GetNulls() {
		case queravuev1.NullsOrder_NULLS_ORDER_FIRST:
			nulls = " NULLS FIRST"
		case queravuev1.NullsOrder_NULLS_ORDER_LAST:
			nulls = " NULLS LAST"
		}
		sortClauses = append(sortClauses, fmt.Sprintf("%s %s%s", col, dir, nulls))
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
	if pageSize > 0 {
		fmt.Fprintf(&sb, " LIMIT %d", pageSize)
	}
	sb.WriteString(";")

	return sb.String(), b.params, nil
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
	col := QuoteIdent(c.GetColumn())

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
		if b.dialect == DialectPostgres {
			return fmt.Sprintf("%s ILIKE %s", col, b.addParam(v)), nil
		}
		return fmt.Sprintf("LOWER(%s) LIKE LOWER(%s)", col, b.addParam(v)), nil
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
	target := QualifyTable(d, ref.GetSchema(), ref.GetTable())

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
				cols = append(cols, QuoteIdent(cv.GetColumn()))
				v := results.ValueFromProto(cv.GetValue())
				phs = append(phs, b.addParam(v))
				previewVals = append(previewVals, formatPreviewValue(v))
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
				col := QuoteIdent(cv.GetColumn())
				v := results.ValueFromProto(cv.GetValue())
				setClauses = append(setClauses, fmt.Sprintf("%s = %s", col, b.addParam(v)))
				previewSets = append(previewSets, fmt.Sprintf("%s = %s", col, formatPreviewValue(v)))
			}
			var whereClauses, previewWheres []string
			for _, cv := range ch.GetKeys() {
				col := QuoteIdent(cv.GetColumn())
				v := results.ValueFromProto(cv.GetValue())
				whereClauses = append(whereClauses, fmt.Sprintf("%s = %s", col, b.addParam(v)))
				previewWheres = append(previewWheres, fmt.Sprintf("%s = %s", col, formatPreviewValue(v)))
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
				col := QuoteIdent(cv.GetColumn())
				v := results.ValueFromProto(cv.GetValue())
				whereClauses = append(whereClauses, fmt.Sprintf("%s = %s", col, b.addParam(v)))
				previewWheres = append(previewWheres, fmt.Sprintf("%s = %s", col, formatPreviewValue(v)))
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

func formatPreviewValue(v engine.Value) string {
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
