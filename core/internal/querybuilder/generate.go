package querybuilder

import (
	"fmt"
	"strings"

	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

// Generate renders m as a single SELECT statement in dialect d.
func Generate(d sqldialect.Dialect, m *queravuev1.SqlQueryModel) (string, *queravuev1.QueryBuilderError) {
	if d == nil {
		return "", notSQLError()
	}
	if err := validateModel(m); err != nil {
		return "", err
	}
	norm := Normalize(d, m)

	var b strings.Builder
	b.WriteString("SELECT ")
	if norm.Distinct {
		b.WriteString("DISTINCT ")
	}
	if len(norm.Select) == 0 {
		b.WriteByte('*')
	} else {
		for i, item := range norm.Select {
			if i > 0 {
				b.WriteString(", ")
			}
			b.WriteString(renderSelectItem(d, item))
		}
	}
	b.WriteString(" FROM ")
	b.WriteString(renderTableRef(d, norm.From))
	for _, j := range norm.Joins {
		b.WriteByte(' ')
		b.WriteString(renderJoinKind(j.Kind))
		b.WriteString(" JOIN ")
		b.WriteString(renderTableRef(d, j.Table))
		b.WriteString(" ON ")
		b.WriteString(renderCondition(d, j.On))
	}
	if norm.Where != nil {
		b.WriteString(" WHERE ")
		b.WriteString(renderCondition(d, norm.Where))
	}
	if len(norm.GroupBy) > 0 {
		b.WriteString(" GROUP BY ")
		for i, col := range norm.GroupBy {
			if i > 0 {
				b.WriteString(", ")
			}
			b.WriteString(renderColumnRef(d, col))
		}
	}
	if norm.Having != nil {
		b.WriteString(" HAVING ")
		b.WriteString(renderCondition(d, norm.Having))
	}
	if len(norm.OrderBy) > 0 {
		b.WriteString(" ORDER BY ")
		for i, term := range norm.OrderBy {
			if i > 0 {
				b.WriteString(", ")
			}
			b.WriteString(d.OrderTerm(renderOperand(d, term.Expression), term.Descending, toDialectNulls(term.Nulls)))
		}
	}
	sql := applyPagination(d, b.String(), norm.GetLimit(), norm.GetOffset(), len(norm.OrderBy) > 0)
	return sql, nil
}

func validateModel(m *queravuev1.SqlQueryModel) *queravuev1.QueryBuilderError {
	if m == nil || m.From == nil || strings.TrimSpace(m.From.Table) == "" {
		return invalidModelError("FROM table is required")
	}
	for i, j := range m.Joins {
		if j == nil || j.Table == nil || strings.TrimSpace(j.Table.Table) == "" {
			return invalidModelError(fmt.Sprintf("join %d table is required", i+1))
		}
		if j.On == nil {
			return invalidModelError(fmt.Sprintf("join %d ON condition is required", i+1))
		}
		if err := validateCondition(j.On, false); err != nil {
			return err
		}
	}
	for i, item := range m.Select {
		if item == nil {
			return invalidModelError(fmt.Sprintf("select item %d is required", i+1))
		}
		switch expr := item.Expression.(type) {
		case *queravuev1.SqlSelectItem_Column:
			if expr.Column == nil {
				return invalidModelError(fmt.Sprintf("select item %d column is required", i+1))
			}
			if expr.Column.Column == "" && item.Alias != "" {
				return invalidModelError("wildcard select item cannot have an alias")
			}
		case *queravuev1.SqlSelectItem_Aggregate:
			if err := validateAggregate(expr.Aggregate); err != nil {
				return err
			}
		default:
			return invalidModelError(fmt.Sprintf("select item %d expression is required", i+1))
		}
	}
	if m.Where != nil {
		if err := validateCondition(m.Where, false); err != nil {
			return err
		}
	}
	for i, col := range m.GroupBy {
		if col == nil || col.Column == "" {
			return invalidModelError(fmt.Sprintf("GROUP BY column %d name is required", i+1))
		}
	}
	if m.Having != nil {
		if err := validateCondition(m.Having, true); err != nil {
			return err
		}
	}
	for i, term := range m.OrderBy {
		if term == nil || term.Expression == nil {
			return invalidModelError(fmt.Sprintf("ORDER BY term %d expression is required", i+1))
		}
		if term.Expression.GetLiteral() != nil {
			return invalidModelError("ORDER BY expression cannot be a literal")
		}
		if err := validateOperand(term.Expression, true, false); err != nil {
			return err
		}
	}
	return nil
}

func validateAggregate(agg *queravuev1.SqlAggregateExpr) *queravuev1.QueryBuilderError {
	if agg == nil || agg.Function == queravuev1.SqlAggregate_SQL_AGGREGATE_UNSPECIFIED {
		return invalidModelError("aggregate function is required")
	}
	col := agg.GetColumn()
	if col == nil || col.Column == "" {
		if agg.Function != queravuev1.SqlAggregate_SQL_AGGREGATE_COUNT || agg.Distinct || (col != nil && col.TableAlias != "") {
			return invalidModelError("only COUNT(*) supports an empty column")
		}
	}
	return nil
}

func validateCondition(cond *queravuev1.SqlCondition, allowAgg bool) *queravuev1.QueryBuilderError {
	if cond == nil {
		return invalidModelError("condition is required")
	}
	switch n := cond.Node.(type) {
	case *queravuev1.SqlCondition_Comparison:
		cmp := n.Comparison
		if cmp == nil || cmp.Left == nil {
			return invalidModelError("comparison left operand is required")
		}
		if err := validateOperand(cmp.Left, allowAgg, true); err != nil {
			return err
		}
		switch cmp.Op {
		case queravuev1.SqlOperator_SQL_OPERATOR_UNSPECIFIED,
			queravuev1.SqlOperator_SQL_OPERATOR_EQ,
			queravuev1.SqlOperator_SQL_OPERATOR_NE,
			queravuev1.SqlOperator_SQL_OPERATOR_LT,
			queravuev1.SqlOperator_SQL_OPERATOR_LE,
			queravuev1.SqlOperator_SQL_OPERATOR_GT,
			queravuev1.SqlOperator_SQL_OPERATOR_GE,
			queravuev1.SqlOperator_SQL_OPERATOR_LIKE:
			if len(cmp.Operands) != 1 {
				return invalidModelError("comparison requires exactly 1 operand")
			}
		case queravuev1.SqlOperator_SQL_OPERATOR_IN:
			if len(cmp.Operands) < 1 {
				return invalidModelError("IN comparison requires at least 1 operand")
			}
		case queravuev1.SqlOperator_SQL_OPERATOR_BETWEEN:
			if len(cmp.Operands) != 2 {
				return invalidModelError("BETWEEN comparison requires 2 operands")
			}
		case queravuev1.SqlOperator_SQL_OPERATOR_IS_NULL:
			if len(cmp.Operands) != 0 {
				return invalidModelError("IS NULL comparison takes no operands")
			}
		default:
			return invalidModelError("unknown comparison operator")
		}
		for _, op := range cmp.Operands {
			if err := validateOperand(op, allowAgg, true); err != nil {
				return err
			}
		}
		return nil
	case *queravuev1.SqlCondition_Group:
		if n.Group == nil || len(n.Group.Children) == 0 {
			return invalidModelError("condition group requires at least one child")
		}
		for _, child := range n.Group.Children {
			if err := validateCondition(child, allowAgg); err != nil {
				return err
			}
		}
		return nil
	default:
		return invalidModelError("condition node is required")
	}
}

func validateOperand(op *queravuev1.SqlOperand, allowAgg, allowLiteral bool) *queravuev1.QueryBuilderError {
	if op == nil {
		return invalidModelError("operand is required")
	}
	switch k := op.Kind.(type) {
	case *queravuev1.SqlOperand_Column:
		if k.Column == nil || k.Column.Column == "" {
			return invalidModelError("operand column name is required")
		}
	case *queravuev1.SqlOperand_Literal:
		if !allowLiteral {
			return invalidModelError("literal operand is not allowed here")
		}
		if k.Literal == nil || k.Literal.Value == nil {
			return invalidModelError("literal value is required")
		}
	case *queravuev1.SqlOperand_Aggregate:
		if !allowAgg {
			return invalidModelError("aggregate operand is not allowed in this clause")
		}
		return validateAggregate(k.Aggregate)
	default:
		return invalidModelError("operand kind is required")
	}
	return nil
}

func renderTableRef(d sqldialect.Dialect, ref *queravuev1.SqlTableRef) string {
	table := d.QualifyTable(ref.Schema, ref.Table)
	if ref.Alias == "" {
		return table
	}
	if d.Lexer() == sqlsplit.Oracle {
		return table + " " + d.QuoteIdent(ref.Alias)
	}
	return table + " AS " + d.QuoteIdent(ref.Alias)
}

func renderJoinKind(kind queravuev1.SqlJoinKind) string {
	switch kind {
	case queravuev1.SqlJoinKind_SQL_JOIN_KIND_LEFT:
		return "LEFT"
	case queravuev1.SqlJoinKind_SQL_JOIN_KIND_RIGHT:
		return "RIGHT"
	case queravuev1.SqlJoinKind_SQL_JOIN_KIND_FULL:
		return "FULL"
	default:
		return "INNER"
	}
}

func renderSelectItem(d sqldialect.Dialect, item *queravuev1.SqlSelectItem) string {
	var expr string
	switch e := item.Expression.(type) {
	case *queravuev1.SqlSelectItem_Column:
		expr = renderColumnRef(d, e.Column)
	case *queravuev1.SqlSelectItem_Aggregate:
		expr = renderAggregate(d, e.Aggregate)
	}
	if item.Alias == "" {
		return expr
	}
	return expr + " AS " + d.QuoteIdent(item.Alias)
}

func renderColumnRef(d sqldialect.Dialect, col *queravuev1.SqlColumnRef) string {
	if col == nil || (col.TableAlias == "" && col.Column == "") {
		return "*"
	}
	if col.Column == "" {
		return d.QuoteIdent(col.TableAlias) + ".*"
	}
	if col.TableAlias == "" {
		return d.QuoteIdent(col.Column)
	}
	return d.QuoteIdent(col.TableAlias) + "." + d.QuoteIdent(col.Column)
}

func renderAggregate(d sqldialect.Dialect, agg *queravuev1.SqlAggregateExpr) string {
	fn := aggregateName(agg.Function)
	arg := "*"
	if agg.Column != nil && agg.Column.Column != "" {
		arg = renderColumnRef(d, agg.Column)
	}
	if agg.Distinct {
		return fmt.Sprintf("%s(DISTINCT %s)", fn, arg)
	}
	return fmt.Sprintf("%s(%s)", fn, arg)
}

func aggregateName(fn queravuev1.SqlAggregate) string {
	switch fn {
	case queravuev1.SqlAggregate_SQL_AGGREGATE_COUNT:
		return "COUNT"
	case queravuev1.SqlAggregate_SQL_AGGREGATE_SUM:
		return "SUM"
	case queravuev1.SqlAggregate_SQL_AGGREGATE_AVG:
		return "AVG"
	case queravuev1.SqlAggregate_SQL_AGGREGATE_MIN:
		return "MIN"
	case queravuev1.SqlAggregate_SQL_AGGREGATE_MAX:
		return "MAX"
	default:
		return "COUNT"
	}
}

func renderCondition(d sqldialect.Dialect, cond *queravuev1.SqlCondition) string {
	switch n := cond.Node.(type) {
	case *queravuev1.SqlCondition_Comparison:
		return renderComparison(d, n.Comparison)
	case *queravuev1.SqlCondition_Group:
		g := n.Group
		op := " AND "
		if g.Op == queravuev1.SqlBoolOp_SQL_BOOL_OP_OR {
			op = " OR "
		}
		parts := make([]string, len(g.Children))
		for i, child := range g.Children {
			s := renderCondition(d, child)
			if sub := child.GetGroup(); sub != nil && (sub.Negated || sub.Op != g.Op) {
				s = "(" + s + ")"
			}
			parts[i] = s
		}
		joined := strings.Join(parts, op)
		if g.Negated {
			return "NOT (" + joined + ")"
		}
		return joined
	}
	return ""
}

func renderComparison(d sqldialect.Dialect, cmp *queravuev1.SqlComparison) string {
	left := renderOperand(d, cmp.Left)
	switch cmp.Op {
	case queravuev1.SqlOperator_SQL_OPERATOR_IS_NULL:
		if cmp.Negated {
			return left + " IS NOT NULL"
		}
		return left + " IS NULL"
	case queravuev1.SqlOperator_SQL_OPERATOR_LIKE:
		kw := " LIKE "
		if cmp.Negated {
			kw = " NOT LIKE "
		}
		return left + kw + renderOperand(d, cmp.Operands[0])
	case queravuev1.SqlOperator_SQL_OPERATOR_IN:
		vals := make([]string, len(cmp.Operands))
		for i, op := range cmp.Operands {
			vals[i] = renderOperand(d, op)
		}
		kw := " IN ("
		if cmp.Negated {
			kw = " NOT IN ("
		}
		return left + kw + strings.Join(vals, ", ") + ")"
	case queravuev1.SqlOperator_SQL_OPERATOR_BETWEEN:
		kw := " BETWEEN "
		if cmp.Negated {
			kw = " NOT BETWEEN "
		}
		return left + kw + renderOperand(d, cmp.Operands[0]) + " AND " + renderOperand(d, cmp.Operands[1])
	default:
		expr := left + " " + comparisonSymbol(cmp.Op) + " " + renderOperand(d, cmp.Operands[0])
		if cmp.Negated {
			return "NOT (" + expr + ")"
		}
		return expr
	}
}

func comparisonSymbol(op queravuev1.SqlOperator) string {
	switch op {
	case queravuev1.SqlOperator_SQL_OPERATOR_NE:
		return "<>"
	case queravuev1.SqlOperator_SQL_OPERATOR_LT:
		return "<"
	case queravuev1.SqlOperator_SQL_OPERATOR_LE:
		return "<="
	case queravuev1.SqlOperator_SQL_OPERATOR_GT:
		return ">"
	case queravuev1.SqlOperator_SQL_OPERATOR_GE:
		return ">="
	default:
		return "="
	}
}

func renderOperand(d sqldialect.Dialect, op *queravuev1.SqlOperand) string {
	switch k := op.Kind.(type) {
	case *queravuev1.SqlOperand_Column:
		return renderColumnRef(d, k.Column)
	case *queravuev1.SqlOperand_Literal:
		return d.FormatLiteral(literalToEngineValue(k.Literal))
	case *queravuev1.SqlOperand_Aggregate:
		return renderAggregate(d, k.Aggregate)
	}
	return ""
}

func literalToEngineValue(lit *queravuev1.SqlLiteral) engine.Value {
	switch v := lit.Value.(type) {
	case *queravuev1.SqlLiteral_NullValue:
		return engine.Value{Kind: engine.VNull}
	case *queravuev1.SqlLiteral_BoolValue:
		return engine.Value{Kind: engine.VBool, Bool: v.BoolValue}
	case *queravuev1.SqlLiteral_IntValue:
		return engine.Value{Kind: engine.VInt, Int: v.IntValue}
	case *queravuev1.SqlLiteral_DoubleValue:
		return engine.Value{Kind: engine.VFloat, Float: v.DoubleValue}
	case *queravuev1.SqlLiteral_StringValue:
		return engine.Value{Kind: engine.VText, Str: v.StringValue}
	}
	return engine.Value{Kind: engine.VNull}
}

func toDialectNulls(n queravuev1.SqlNulls) sqldialect.Nulls {
	switch n {
	case queravuev1.SqlNulls_SQL_NULLS_FIRST:
		return sqldialect.NullsFirst
	case queravuev1.SqlNulls_SQL_NULLS_LAST:
		return sqldialect.NullsLast
	default:
		return sqldialect.NullsDefault
	}
}

func applyPagination(d sqldialect.Dialect, sql string, limit, offset uint64, hasOrderBy bool) string {
	if limit > 0 {
		paged, _ := d.Paginate(sql, limit, hasOrderBy)
		if offset > 0 {
			if strings.Contains(paged, " OFFSET 0 ROWS FETCH ") {
				return strings.Replace(paged, " OFFSET 0 ROWS FETCH ", fmt.Sprintf(" OFFSET %d ROWS FETCH ", offset), 1)
			}
			if idx := strings.LastIndex(paged, " FETCH FIRST "); idx >= 0 {
				return paged[:idx] + fmt.Sprintf(" OFFSET %d ROWS", offset) + paged[idx:]
			}
			return fmt.Sprintf("%s OFFSET %d", paged, offset)
		}
		return paged
	}
	if offset > 0 {
		probe, stable := d.Paginate("", 1, hasOrderBy)
		switch {
		case !stable:
			return fmt.Sprintf("%s ORDER BY (SELECT NULL) OFFSET %d ROWS", sql, offset)
		case strings.Contains(probe, "OFFSET"), strings.Contains(probe, "FETCH"):
			return fmt.Sprintf("%s OFFSET %d ROWS", sql, offset)
		default:
			return fmt.Sprintf("%s OFFSET %d", sql, offset)
		}
	}
	return sql
}

func invalidModelError(msg string) *queravuev1.QueryBuilderError {
	return &queravuev1.QueryBuilderError{
		Kind:    queravuev1.QueryBuilderErrorKind_QUERY_BUILDER_ERROR_KIND_INVALID_MODEL,
		Message: msg,
	}
}

func notSQLError() *queravuev1.QueryBuilderError {
	return &queravuev1.QueryBuilderError{
		Kind:    queravuev1.QueryBuilderErrorKind_QUERY_BUILDER_ERROR_KIND_NOT_SQL,
		Message: "this connection does not use SQL",
	}
}
