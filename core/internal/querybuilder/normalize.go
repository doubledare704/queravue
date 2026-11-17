// Package querybuilder generates and parses the visual SQL query builder subset.
package querybuilder

import (
	"strconv"

	"google.golang.org/protobuf/proto"

	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

// Normalize returns a canonical clone of m for dialect d so equivalent models compare equal.
func Normalize(d sqldialect.Dialect, m *queravuev1.SqlQueryModel) *queravuev1.SqlQueryModel {
	if m == nil {
		return nil
	}
	out := proto.Clone(m).(*queravuev1.SqlQueryModel)
	boolsAsInts := d != nil && d.FormatLiteral(engine.Value{Kind: engine.VBool, Bool: true}) == "1"

	normalizeTableRef(d, out.From)
	for _, j := range out.Joins {
		if j == nil {
			continue
		}
		if j.Kind == queravuev1.SqlJoinKind_SQL_JOIN_KIND_UNSPECIFIED {
			j.Kind = queravuev1.SqlJoinKind_SQL_JOIN_KIND_INNER
		}
		normalizeTableRef(d, j.Table)
		j.On = normalizeCondition(j.On, boolsAsInts)
	}
	if len(out.Select) == 1 && isBareWildcardItem(out.Select[0]) {
		out.Select = nil
	} else {
		for _, item := range out.Select {
			normalizeSelectItem(item)
		}
	}
	out.Where = normalizeCondition(out.Where, boolsAsInts)
	out.Having = normalizeCondition(out.Having, boolsAsInts)
	for _, term := range out.OrderBy {
		if term != nil {
			normalizeOperand(term.Expression, boolsAsInts)
		}
	}
	if out.Limit != nil && *out.Limit == 0 {
		out.Limit = nil
	}
	if out.Offset != nil && *out.Offset == 0 {
		out.Offset = nil
	}
	return out
}

func normalizeTableRef(d sqldialect.Dialect, ref *queravuev1.SqlTableRef) {
	if ref == nil || ref.Schema == "" || d == nil {
		return
	}
	// Dialects that omit a default schema (such as SQLite "main") cannot preserve it in SQL.
	if d.QualifyTable(ref.Schema, ref.Table) == d.QuoteIdent(ref.Table) {
		ref.Schema = ""
	}
}

func isBareWildcardItem(item *queravuev1.SqlSelectItem) bool {
	if item == nil || item.Alias != "" {
		return false
	}
	col := item.GetColumn()
	return col != nil && col.TableAlias == "" && col.Column == ""
}

func normalizeSelectItem(item *queravuev1.SqlSelectItem) {
	if item == nil {
		return
	}
	if agg := item.GetAggregate(); agg != nil && agg.Column == nil {
		agg.Column = &queravuev1.SqlColumnRef{}
	}
}

func normalizeCondition(cond *queravuev1.SqlCondition, boolsAsInts bool) *queravuev1.SqlCondition {
	if cond == nil {
		return nil
	}
	switch n := cond.Node.(type) {
	case *queravuev1.SqlCondition_Comparison:
		if n.Comparison == nil {
			return nil
		}
		if n.Comparison.Op == queravuev1.SqlOperator_SQL_OPERATOR_UNSPECIFIED {
			n.Comparison.Op = queravuev1.SqlOperator_SQL_OPERATOR_EQ
		}
		normalizeOperand(n.Comparison.Left, boolsAsInts)
		for _, op := range n.Comparison.Operands {
			normalizeOperand(op, boolsAsInts)
		}
		return cond
	case *queravuev1.SqlCondition_Group:
		g := n.Group
		if g == nil {
			return nil
		}
		if g.Op == queravuev1.SqlBoolOp_SQL_BOOL_OP_UNSPECIFIED {
			g.Op = queravuev1.SqlBoolOp_SQL_BOOL_OP_AND
		}
		flat := make([]*queravuev1.SqlCondition, 0, len(g.Children))
		for _, child := range g.Children {
			nc := normalizeCondition(child, boolsAsInts)
			if nc == nil {
				continue
			}
			if sub := nc.GetGroup(); sub != nil && !sub.Negated && sub.Op == g.Op {
				flat = append(flat, sub.Children...)
			} else {
				flat = append(flat, nc)
			}
		}
		g.Children = flat
		if len(g.Children) == 1 {
			only := g.Children[0]
			if g.Negated {
				negateCondition(only)
			}
			return only
		}
		return cond
	}
	return cond
}

func negateCondition(cond *queravuev1.SqlCondition) {
	switch n := cond.Node.(type) {
	case *queravuev1.SqlCondition_Comparison:
		if n.Comparison != nil {
			n.Comparison.Negated = !n.Comparison.Negated
		}
	case *queravuev1.SqlCondition_Group:
		if n.Group != nil {
			n.Group.Negated = !n.Group.Negated
		}
	}
}

func normalizeOperand(op *queravuev1.SqlOperand, boolsAsInts bool) {
	if op == nil {
		return
	}
	switch k := op.Kind.(type) {
	case *queravuev1.SqlOperand_Aggregate:
		if k.Aggregate != nil && k.Aggregate.Column == nil {
			k.Aggregate.Column = &queravuev1.SqlColumnRef{}
		}
	case *queravuev1.SqlOperand_Literal:
		if k.Literal == nil {
			return
		}
		if _, ok := k.Literal.Value.(*queravuev1.SqlLiteral_NullValue); ok {
			k.Literal.Value = &queravuev1.SqlLiteral_NullValue{NullValue: true}
			return
		}
		if boolsAsInts {
			if bv, ok := k.Literal.Value.(*queravuev1.SqlLiteral_BoolValue); ok {
				v := int64(0)
				if bv.BoolValue {
					v = 1
				}
				k.Literal.Value = &queravuev1.SqlLiteral_IntValue{IntValue: v}
			}
		}
		if dv, ok := k.Literal.Value.(*queravuev1.SqlLiteral_DoubleValue); ok {
			// Match %f formatting precision used by sqldialect.FormatLiteral.
			if rounded, err := strconv.ParseFloat(strconv.FormatFloat(dv.DoubleValue, 'f', 6, 64), 64); err == nil {
				dv.DoubleValue = rounded
			}
		}
	}
}
