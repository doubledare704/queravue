package querybuilder_test

import (
	"fmt"
	"strings"
	"testing"

	"google.golang.org/protobuf/proto"

	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/querybuilder"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

func tbl(schema, table, alias string) *queravuev1.SqlTableRef {
	return &queravuev1.SqlTableRef{Schema: schema, Table: table, Alias: alias}
}

func col(alias, name string) *queravuev1.SqlColumnRef {
	return &queravuev1.SqlColumnRef{TableAlias: alias, Column: name}
}

func selCol(alias, name, outAlias string) *queravuev1.SqlSelectItem {
	return &queravuev1.SqlSelectItem{
		Expression: &queravuev1.SqlSelectItem_Column{Column: col(alias, name)},
		Alias:      outAlias,
	}
}

func selAgg(fn queravuev1.SqlAggregate, c *queravuev1.SqlColumnRef, distinct bool, outAlias string) *queravuev1.SqlSelectItem {
	return &queravuev1.SqlSelectItem{
		Expression: &queravuev1.SqlSelectItem_Aggregate{
			Aggregate: &queravuev1.SqlAggregateExpr{Function: fn, Column: c, Distinct: distinct},
		},
		Alias: outAlias,
	}
}

func opCol(alias, name string) *queravuev1.SqlOperand {
	return &queravuev1.SqlOperand{Kind: &queravuev1.SqlOperand_Column{Column: col(alias, name)}}
}

func opAgg(fn queravuev1.SqlAggregate, c *queravuev1.SqlColumnRef, distinct bool) *queravuev1.SqlOperand {
	return &queravuev1.SqlOperand{
		Kind: &queravuev1.SqlOperand_Aggregate{
			Aggregate: &queravuev1.SqlAggregateExpr{Function: fn, Column: c, Distinct: distinct},
		},
	}
}

func opInt(v int64) *queravuev1.SqlOperand {
	return &queravuev1.SqlOperand{
		Kind: &queravuev1.SqlOperand_Literal{Literal: &queravuev1.SqlLiteral{Value: &queravuev1.SqlLiteral_IntValue{IntValue: v}}},
	}
}

func opFloat(v float64) *queravuev1.SqlOperand {
	return &queravuev1.SqlOperand{
		Kind: &queravuev1.SqlOperand_Literal{Literal: &queravuev1.SqlLiteral{Value: &queravuev1.SqlLiteral_DoubleValue{DoubleValue: v}}},
	}
}

func opStr(v string) *queravuev1.SqlOperand {
	return &queravuev1.SqlOperand{
		Kind: &queravuev1.SqlOperand_Literal{Literal: &queravuev1.SqlLiteral{Value: &queravuev1.SqlLiteral_StringValue{StringValue: v}}},
	}
}

func opBool(v bool) *queravuev1.SqlOperand {
	return &queravuev1.SqlOperand{
		Kind: &queravuev1.SqlOperand_Literal{Literal: &queravuev1.SqlLiteral{Value: &queravuev1.SqlLiteral_BoolValue{BoolValue: v}}},
	}
}

func opNull() *queravuev1.SqlOperand {
	return &queravuev1.SqlOperand{
		Kind: &queravuev1.SqlOperand_Literal{Literal: &queravuev1.SqlLiteral{Value: &queravuev1.SqlLiteral_NullValue{NullValue: true}}},
	}
}

func cmp(left *queravuev1.SqlOperand, op queravuev1.SqlOperator, neg bool, rights ...*queravuev1.SqlOperand) *queravuev1.SqlCondition {
	return &queravuev1.SqlCondition{
		Node: &queravuev1.SqlCondition_Comparison{
			Comparison: &queravuev1.SqlComparison{Left: left, Op: op, Negated: neg, Operands: rights},
		},
	}
}

func grp(op queravuev1.SqlBoolOp, neg bool, children ...*queravuev1.SqlCondition) *queravuev1.SqlCondition {
	return &queravuev1.SqlCondition{
		Node: &queravuev1.SqlCondition_Group{
			Group: &queravuev1.SqlConditionGroup{Op: op, Negated: neg, Children: children},
		},
	}
}

func join(kind queravuev1.SqlJoinKind, t *queravuev1.SqlTableRef, on *queravuev1.SqlCondition) *queravuev1.SqlJoin {
	return &queravuev1.SqlJoin{Kind: kind, Table: t, On: on}
}

func ord(expr *queravuev1.SqlOperand, desc bool, nulls queravuev1.SqlNulls) *queravuev1.SqlOrderTerm {
	return &queravuev1.SqlOrderTerm{Expression: expr, Descending: desc, Nulls: nulls}
}

func buildCorpus() []struct {
	name  string
	model *queravuev1.SqlQueryModel
} {
	type entry = struct {
		name  string
		model *queravuev1.SqlQueryModel
	}
	var cases []entry
	add := func(name string, m *queravuev1.SqlQueryModel) {
		cases = append(cases, entry{name: name, model: m})
	}

	// 1-10: Basic SELECT & table qualification variants
	add("bare_star", &queravuev1.SqlQueryModel{From: tbl("", "users", "")})
	add("explicit_star", &queravuev1.SqlQueryModel{From: tbl("", "users", ""), Select: []*queravuev1.SqlSelectItem{selCol("", "", "")}})
	add("schema_table", &queravuev1.SqlQueryModel{From: tbl("public", "users", "")})
	add("table_alias", &queravuev1.SqlQueryModel{From: tbl("public", "users", "u")})
	add("distinct_star", &queravuev1.SqlQueryModel{From: tbl("", "users", ""), Distinct: true})
	add("alias_wildcard", &queravuev1.SqlQueryModel{From: tbl("", "users", "u"), Select: []*queravuev1.SqlSelectItem{selCol("u", "", "")}})
	add("single_col", &queravuev1.SqlQueryModel{From: tbl("", "users", ""), Select: []*queravuev1.SqlSelectItem{selCol("", "id", "")}})
	add("multi_cols_with_aliases", &queravuev1.SqlQueryModel{
		From: tbl("", "users", "u"),
		Select: []*queravuev1.SqlSelectItem{
			selCol("u", "id", "user_id"),
			selCol("u", "email", "contact_email"),
			selCol("u", "created_at", ""),
		},
	})
	add("distinct_cols", &queravuev1.SqlQueryModel{
		From:     tbl("", "orders", ""),
		Distinct: true,
		Select:   []*queravuev1.SqlSelectItem{selCol("", "status", ""), selCol("", "currency", "")},
	})
	add("mixed_wildcard_and_col", &queravuev1.SqlQueryModel{
		From: tbl("", "users", "u"),
		Select: []*queravuev1.SqlSelectItem{
			selCol("u", "", ""),
			selCol("u", "id", "uid"),
		},
	})

	// 11-22: Special identifiers, Unicode, spaces, keywords, and quotes in identifiers
	specialIdents := []string{
		"user name", "select", "from", "where", `col"quote`, "col`tick",
		"col[bracket]", "col]close", `col\slash`, "café_crème", "order-items", "tbl$1",
	}
	for i, ident := range specialIdents {
		add(fmt.Sprintf("special_ident_%d", i), &queravuev1.SqlQueryModel{
			From: tbl("my schema", ident, "alias 1"),
			Select: []*queravuev1.SqlSelectItem{
				selCol("alias 1", ident, ident+"_out"),
			},
		})
	}

	// 23-34: All comparison operators and literal types
	add("where_eq_int", &queravuev1.SqlQueryModel{
		From:  tbl("", "users", ""),
		Where: cmp(opCol("", "id"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opInt(42)),
	})
	add("where_eq_neg_int", &queravuev1.SqlQueryModel{
		From:  tbl("", "ledger", ""),
		Where: cmp(opCol("", "delta"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opInt(-9223372036854775808)),
	})
	add("where_ne_int", &queravuev1.SqlQueryModel{
		From:  tbl("", "users", ""),
		Where: cmp(opCol("", "role_id"), queravuev1.SqlOperator_SQL_OPERATOR_NE, false, opInt(0)),
	})
	add("where_lt_float", &queravuev1.SqlQueryModel{
		From:  tbl("", "items", ""),
		Where: cmp(opCol("", "price"), queravuev1.SqlOperator_SQL_OPERATOR_LT, false, opFloat(19.95)),
	})
	add("where_le_neg_float", &queravuev1.SqlQueryModel{
		From:  tbl("", "sensors", ""),
		Where: cmp(opCol("", "temp"), queravuev1.SqlOperator_SQL_OPERATOR_LE, false, opFloat(-0.125)),
	})
	add("where_gt_bool_true", &queravuev1.SqlQueryModel{
		From:  tbl("", "users", ""),
		Where: cmp(opCol("", "active"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opBool(true)),
	})
	add("where_eq_bool_false", &queravuev1.SqlQueryModel{
		From:  tbl("", "users", ""),
		Where: cmp(opCol("", "archived"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opBool(false)),
	})
	add("where_ge_string", &queravuev1.SqlQueryModel{
		From:  tbl("", "events", ""),
		Where: cmp(opCol("", "created_at"), queravuev1.SqlOperator_SQL_OPERATOR_GE, false, opStr("2026-01-01")),
	})
	add("where_eq_string_quotes_backslash", &queravuev1.SqlQueryModel{
		From:  tbl("", "notes", ""),
		Where: cmp(opCol("", "body"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opStr("it's \\'quoted\\' & newline\nok")),
	})
	add("where_eq_empty_string", &queravuev1.SqlQueryModel{
		From:  tbl("", "notes", ""),
		Where: cmp(opCol("", "title"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opStr("")),
	})
	add("where_eq_unicode_string", &queravuev1.SqlQueryModel{
		From:  tbl("", "users", ""),
		Where: cmp(opCol("", "name"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opStr("Привіт 🌍 café")),
	})
	add("where_col_to_col", &queravuev1.SqlQueryModel{
		From:  tbl("", "orders", ""),
		Where: cmp(opCol("", "updated_at"), queravuev1.SqlOperator_SQL_OPERATOR_GT, false, opCol("", "created_at")),
	})

	// 35-46: LIKE, IN, BETWEEN, IS NULL and negated forms
	add("where_like", &queravuev1.SqlQueryModel{
		From:  tbl("", "users", ""),
		Where: cmp(opCol("", "email"), queravuev1.SqlOperator_SQL_OPERATOR_LIKE, false, opStr("%@example.com")),
	})
	add("where_not_like", &queravuev1.SqlQueryModel{
		From:  tbl("", "users", ""),
		Where: cmp(opCol("", "email"), queravuev1.SqlOperator_SQL_OPERATOR_LIKE, true, opStr("spam%")),
	})
	add("where_in_ints", &queravuev1.SqlQueryModel{
		From:  tbl("", "orders", ""),
		Where: cmp(opCol("", "status_id"), queravuev1.SqlOperator_SQL_OPERATOR_IN, false, opInt(1), opInt(2), opInt(5)),
	})
	add("where_not_in_strings", &queravuev1.SqlQueryModel{
		From:  tbl("", "orders", ""),
		Where: cmp(opCol("", "status"), queravuev1.SqlOperator_SQL_OPERATOR_IN, true, opStr("cancelled"), opStr("refunded")),
	})
	add("where_in_single", &queravuev1.SqlQueryModel{
		From:  tbl("", "orders", ""),
		Where: cmp(opCol("", "id"), queravuev1.SqlOperator_SQL_OPERATOR_IN, false, opInt(99)),
	})
	add("where_in_with_null", &queravuev1.SqlQueryModel{
		From:  tbl("", "orders", ""),
		Where: cmp(opCol("", "code"), queravuev1.SqlOperator_SQL_OPERATOR_IN, false, opStr("A"), opNull()),
	})
	add("where_between_ints", &queravuev1.SqlQueryModel{
		From:  tbl("", "orders", ""),
		Where: cmp(opCol("", "total"), queravuev1.SqlOperator_SQL_OPERATOR_BETWEEN, false, opInt(10), opInt(100)),
	})
	add("where_not_between_strings", &queravuev1.SqlQueryModel{
		From:  tbl("", "orders", ""),
		Where: cmp(opCol("", "created_at"), queravuev1.SqlOperator_SQL_OPERATOR_BETWEEN, true, opStr("2025-01-01"), opStr("2025-12-31")),
	})
	add("where_is_null", &queravuev1.SqlQueryModel{
		From:  tbl("", "users", ""),
		Where: cmp(opCol("", "deleted_at"), queravuev1.SqlOperator_SQL_OPERATOR_IS_NULL, false),
	})
	add("where_is_not_null", &queravuev1.SqlQueryModel{
		From:  tbl("", "users", ""),
		Where: cmp(opCol("", "verified_at"), queravuev1.SqlOperator_SQL_OPERATOR_IS_NULL, true),
	})
	add("where_negated_eq", &queravuev1.SqlQueryModel{
		From:  tbl("", "users", ""),
		Where: cmp(opCol("", "id"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, true, opInt(7)),
	})
	add("where_negated_lt", &queravuev1.SqlQueryModel{
		From:  tbl("", "users", ""),
		Where: cmp(opCol("", "age"), queravuev1.SqlOperator_SQL_OPERATOR_LT, true, opInt(18)),
	})

	// 47-56: Condition trees (AND, OR, NOT, nested groups, unspecified defaults)
	add("where_and_two", &queravuev1.SqlQueryModel{
		From: tbl("", "users", ""),
		Where: grp(queravuev1.SqlBoolOp_SQL_BOOL_OP_AND, false,
			cmp(opCol("", "active"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opBool(true)),
			cmp(opCol("", "age"), queravuev1.SqlOperator_SQL_OPERATOR_GE, false, opInt(21)),
		),
	})
	add("where_or_three", &queravuev1.SqlQueryModel{
		From: tbl("", "orders", ""),
		Where: grp(queravuev1.SqlBoolOp_SQL_BOOL_OP_OR, false,
			cmp(opCol("", "status"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opStr("paid")),
			cmp(opCol("", "status"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opStr("shipped")),
			cmp(opCol("", "priority"), queravuev1.SqlOperator_SQL_OPERATOR_GT, false, opInt(5)),
		),
	})
	add("where_or_inside_and", &queravuev1.SqlQueryModel{
		From: tbl("", "orders", ""),
		Where: grp(queravuev1.SqlBoolOp_SQL_BOOL_OP_AND, false,
			cmp(opCol("", "tenant_id"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opInt(3)),
			grp(queravuev1.SqlBoolOp_SQL_BOOL_OP_OR, false,
				cmp(opCol("", "status"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opStr("open")),
				cmp(opCol("", "urgent"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opBool(true)),
			),
		),
	})
	add("where_and_inside_or", &queravuev1.SqlQueryModel{
		From: tbl("", "orders", ""),
		Where: grp(queravuev1.SqlBoolOp_SQL_BOOL_OP_OR, false,
			grp(queravuev1.SqlBoolOp_SQL_BOOL_OP_AND, false,
				cmp(opCol("", "country"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opStr("US")),
				cmp(opCol("", "total"), queravuev1.SqlOperator_SQL_OPERATOR_GT, false, opInt(100)),
			),
			cmp(opCol("", "vip"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opBool(true)),
		),
	})
	add("where_not_group", &queravuev1.SqlQueryModel{
		From: tbl("", "users", ""),
		Where: grp(queravuev1.SqlBoolOp_SQL_BOOL_OP_OR, true,
			cmp(opCol("", "banned"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opBool(true)),
			cmp(opCol("", "deleted_at"), queravuev1.SqlOperator_SQL_OPERATOR_IS_NULL, true),
		),
	})
	add("where_deep_nested_not", &queravuev1.SqlQueryModel{
		From: tbl("", "items", ""),
		Where: grp(queravuev1.SqlBoolOp_SQL_BOOL_OP_AND, false,
			cmp(opCol("", "visible"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opBool(true)),
			grp(queravuev1.SqlBoolOp_SQL_BOOL_OP_AND, true,
				cmp(opCol("", "category"), queravuev1.SqlOperator_SQL_OPERATOR_IN, false, opStr("a"), opStr("b")),
				cmp(opCol("", "stock"), queravuev1.SqlOperator_SQL_OPERATOR_LE, false, opInt(0)),
			),
		),
	})
	add("where_single_child_group_normalizes", &queravuev1.SqlQueryModel{
		From: tbl("", "items", ""),
		Where: grp(queravuev1.SqlBoolOp_SQL_BOOL_OP_UNSPECIFIED, false,
			cmp(opCol("", "id"), queravuev1.SqlOperator_SQL_OPERATOR_UNSPECIFIED, false, opInt(1)),
		),
	})
	add("where_single_child_negated_group_normalizes", &queravuev1.SqlQueryModel{
		From: tbl("", "items", ""),
		Where: grp(queravuev1.SqlBoolOp_SQL_BOOL_OP_AND, true,
			cmp(opCol("", "name"), queravuev1.SqlOperator_SQL_OPERATOR_LIKE, false, opStr("%foo%")),
		),
	})
	add("where_same_op_nested_flattens", &queravuev1.SqlQueryModel{
		From: tbl("", "items", ""),
		Where: grp(queravuev1.SqlBoolOp_SQL_BOOL_OP_AND, false,
			cmp(opCol("", "a"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opInt(1)),
			grp(queravuev1.SqlBoolOp_SQL_BOOL_OP_AND, false,
				cmp(opCol("", "b"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opInt(2)),
				cmp(opCol("", "c"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opInt(3)),
			),
		),
	})
	add("where_between_and_another", &queravuev1.SqlQueryModel{
		From: tbl("", "items", ""),
		Where: grp(queravuev1.SqlBoolOp_SQL_BOOL_OP_AND, false,
			cmp(opCol("", "qty"), queravuev1.SqlOperator_SQL_OPERATOR_BETWEEN, false, opInt(1), opInt(10)),
			cmp(opCol("", "active"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opBool(true)),
		),
	})

	// 57-68: Joins (INNER, LEFT, RIGHT, FULL, UNSPECIFIED, multi-table, compound ON)
	add("inner_join", &queravuev1.SqlQueryModel{
		From:   tbl("public", "orders", "o"),
		Joins:  []*queravuev1.SqlJoin{join(queravuev1.SqlJoinKind_SQL_JOIN_KIND_INNER, tbl("public", "customers", "c"), cmp(opCol("o", "customer_id"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opCol("c", "id")))},
		Select: []*queravuev1.SqlSelectItem{selCol("o", "id", ""), selCol("c", "name", "customer_name")},
	})
	add("unspecified_join_kind", &queravuev1.SqlQueryModel{
		From:  tbl("", "orders", "o"),
		Joins: []*queravuev1.SqlJoin{join(queravuev1.SqlJoinKind_SQL_JOIN_KIND_UNSPECIFIED, tbl("", "customers", "c"), cmp(opCol("o", "customer_id"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opCol("c", "id")))},
	})
	add("left_join", &queravuev1.SqlQueryModel{
		From:  tbl("", "customers", "c"),
		Joins: []*queravuev1.SqlJoin{join(queravuev1.SqlJoinKind_SQL_JOIN_KIND_LEFT, tbl("", "orders", "o"), cmp(opCol("c", "id"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opCol("o", "customer_id")))},
	})
	add("right_join", &queravuev1.SqlQueryModel{
		From:  tbl("", "orders", "o"),
		Joins: []*queravuev1.SqlJoin{join(queravuev1.SqlJoinKind_SQL_JOIN_KIND_RIGHT, tbl("", "customers", "c"), cmp(opCol("o", "customer_id"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opCol("c", "id")))},
	})
	add("full_join", &queravuev1.SqlQueryModel{
		From:  tbl("", "a", ""),
		Joins: []*queravuev1.SqlJoin{join(queravuev1.SqlJoinKind_SQL_JOIN_KIND_FULL, tbl("", "b", ""), cmp(opCol("a", "id"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opCol("b", "id")))},
	})
	add("compound_join_on", &queravuev1.SqlQueryModel{
		From: tbl("", "order_items", "oi"),
		Joins: []*queravuev1.SqlJoin{
			join(queravuev1.SqlJoinKind_SQL_JOIN_KIND_INNER, tbl("", "products", "p"), grp(queravuev1.SqlBoolOp_SQL_BOOL_OP_AND, false,
				cmp(opCol("oi", "sku"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opCol("p", "sku")),
				cmp(opCol("oi", "rev"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opCol("p", "rev")),
				cmp(opCol("p", "deleted_at"), queravuev1.SqlOperator_SQL_OPERATOR_IS_NULL, false),
			)),
		},
	})
	add("three_table_joins", &queravuev1.SqlQueryModel{
		From: tbl("", "customers", "c"),
		Joins: []*queravuev1.SqlJoin{
			join(queravuev1.SqlJoinKind_SQL_JOIN_KIND_LEFT, tbl("", "orders", "o"), cmp(opCol("c", "id"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opCol("o", "customer_id"))),
			join(queravuev1.SqlJoinKind_SQL_JOIN_KIND_INNER, tbl("", "order_items", "oi"), cmp(opCol("o", "id"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opCol("oi", "order_id"))),
			join(queravuev1.SqlJoinKind_SQL_JOIN_KIND_LEFT, tbl("", "products", "p"), cmp(opCol("oi", "product_id"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opCol("p", "id"))),
		},
		Select: []*queravuev1.SqlSelectItem{
			selCol("c", "name", ""),
			selCol("o", "id", "order_id"),
			selCol("p", "title", ""),
		},
	})
	add("self_join", &queravuev1.SqlQueryModel{
		From:   tbl("", "employees", "e"),
		Joins:  []*queravuev1.SqlJoin{join(queravuev1.SqlJoinKind_SQL_JOIN_KIND_LEFT, tbl("", "employees", "m"), cmp(opCol("e", "manager_id"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opCol("m", "id")))},
		Select: []*queravuev1.SqlSelectItem{selCol("e", "name", "employee"), selCol("m", "name", "manager")},
	})
	add("join_with_or_on", &queravuev1.SqlQueryModel{
		From: tbl("", "a", ""),
		Joins: []*queravuev1.SqlJoin{
			join(queravuev1.SqlJoinKind_SQL_JOIN_KIND_LEFT, tbl("", "b", ""), grp(queravuev1.SqlBoolOp_SQL_BOOL_OP_OR, false,
				cmp(opCol("a", "k1"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opCol("b", "k1")),
				cmp(opCol("a", "k2"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opCol("b", "k2")),
			)),
		},
	})
	add("join_with_where_and_order", &queravuev1.SqlQueryModel{
		From:  tbl("", "orders", "o"),
		Joins: []*queravuev1.SqlJoin{join(queravuev1.SqlJoinKind_SQL_JOIN_KIND_INNER, tbl("", "customers", "c"), cmp(opCol("o", "customer_id"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opCol("c", "id")))},
		Where: cmp(opCol("o", "status"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opStr("paid")),
		OrderBy: []*queravuev1.SqlOrderTerm{
			ord(opCol("o", "created_at"), true, queravuev1.SqlNulls_SQL_NULLS_LAST),
		},
	})
	add("join_cross_schema", &queravuev1.SqlQueryModel{
		From:   tbl("sales", "orders", "o"),
		Joins:  []*queravuev1.SqlJoin{join(queravuev1.SqlJoinKind_SQL_JOIN_KIND_INNER, tbl("crm", "accounts", "a"), cmp(opCol("o", "account_id"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opCol("a", "id")))},
		Select: []*queravuev1.SqlSelectItem{selCol("o", "id", ""), selCol("a", "company", "")},
	})
	add("join_with_sqlite_main_schema", &queravuev1.SqlQueryModel{
		From:  tbl("main", "orders", "o"),
		Joins: []*queravuev1.SqlJoin{join(queravuev1.SqlJoinKind_SQL_JOIN_KIND_LEFT, tbl("main", "customers", "c"), cmp(opCol("o", "customer_id"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opCol("c", "id")))},
	})

	// 69-82: Aggregates, GROUP BY, HAVING
	add("count_star", &queravuev1.SqlQueryModel{
		From:   tbl("", "users", ""),
		Select: []*queravuev1.SqlSelectItem{selAgg(queravuev1.SqlAggregate_SQL_AGGREGATE_COUNT, nil, false, "total")},
	})
	add("count_col", &queravuev1.SqlQueryModel{
		From:   tbl("", "users", ""),
		Select: []*queravuev1.SqlSelectItem{selAgg(queravuev1.SqlAggregate_SQL_AGGREGATE_COUNT, col("", "email"), false, "emails")},
	})
	add("count_distinct", &queravuev1.SqlQueryModel{
		From:   tbl("", "orders", ""),
		Select: []*queravuev1.SqlSelectItem{selAgg(queravuev1.SqlAggregate_SQL_AGGREGATE_COUNT, col("", "customer_id"), true, "unique_customers")},
	})
	for _, fn := range []queravuev1.SqlAggregate{
		queravuev1.SqlAggregate_SQL_AGGREGATE_SUM,
		queravuev1.SqlAggregate_SQL_AGGREGATE_AVG,
		queravuev1.SqlAggregate_SQL_AGGREGATE_MIN,
		queravuev1.SqlAggregate_SQL_AGGREGATE_MAX,
	} {
		add("agg_"+fn.String(), &queravuev1.SqlQueryModel{
			From:   tbl("", "orders", ""),
			Select: []*queravuev1.SqlSelectItem{selAgg(fn, col("", "total"), false, "")},
		})
		add("agg_distinct_"+fn.String(), &queravuev1.SqlQueryModel{
			From:   tbl("", "orders", ""),
			Select: []*queravuev1.SqlSelectItem{selAgg(fn, col("", "total"), true, "val")},
		})
	}
	add("group_by_single", &queravuev1.SqlQueryModel{
		From:    tbl("", "orders", ""),
		Select:  []*queravuev1.SqlSelectItem{selCol("", "status", ""), selAgg(queravuev1.SqlAggregate_SQL_AGGREGATE_COUNT, col("", ""), false, "n")},
		GroupBy: []*queravuev1.SqlColumnRef{col("", "status")},
	})
	add("group_by_multi_having", &queravuev1.SqlQueryModel{
		From: tbl("", "orders", "o"),
		Select: []*queravuev1.SqlSelectItem{
			selCol("o", "customer_id", ""),
			selCol("o", "currency", ""),
			selAgg(queravuev1.SqlAggregate_SQL_AGGREGATE_SUM, col("o", "total"), false, "revenue"),
		},
		GroupBy: []*queravuev1.SqlColumnRef{col("o", "customer_id"), col("o", "currency")},
		Having:  cmp(opAgg(queravuev1.SqlAggregate_SQL_AGGREGATE_SUM, col("o", "total"), false), queravuev1.SqlOperator_SQL_OPERATOR_GT, false, opInt(1000)),
	})
	add("having_compound_tree", &queravuev1.SqlQueryModel{
		From:    tbl("", "orders", ""),
		Select:  []*queravuev1.SqlSelectItem{selCol("", "customer_id", ""), selAgg(queravuev1.SqlAggregate_SQL_AGGREGATE_COUNT, nil, false, "cnt")},
		GroupBy: []*queravuev1.SqlColumnRef{col("", "customer_id")},
		Having: grp(queravuev1.SqlBoolOp_SQL_BOOL_OP_AND, false,
			cmp(opAgg(queravuev1.SqlAggregate_SQL_AGGREGATE_COUNT, nil, false), queravuev1.SqlOperator_SQL_OPERATOR_GE, false, opInt(2)),
			cmp(opAgg(queravuev1.SqlAggregate_SQL_AGGREGATE_MAX, col("", "total"), false), queravuev1.SqlOperator_SQL_OPERATOR_LT, false, opFloat(500.5)),
		),
	})
	add("having_count_distinct", &queravuev1.SqlQueryModel{
		From:    tbl("", "events", ""),
		Select:  []*queravuev1.SqlSelectItem{selCol("", "user_id", "")},
		GroupBy: []*queravuev1.SqlColumnRef{col("", "user_id")},
		Having:  cmp(opAgg(queravuev1.SqlAggregate_SQL_AGGREGATE_COUNT, col("", "kind"), true), queravuev1.SqlOperator_SQL_OPERATOR_BETWEEN, false, opInt(2), opInt(5)),
	})
	add("having_min_in", &queravuev1.SqlQueryModel{
		From:    tbl("", "grades", ""),
		Select:  []*queravuev1.SqlSelectItem{selCol("", "student_id", "")},
		GroupBy: []*queravuev1.SqlColumnRef{col("", "student_id")},
		Having:  cmp(opAgg(queravuev1.SqlAggregate_SQL_AGGREGATE_MIN, col("", "score"), false), queravuev1.SqlOperator_SQL_OPERATOR_IN, false, opInt(90), opInt(100)),
	})

	// 83-94: ORDER BY variants (ASC, DESC, NULLS FIRST/LAST, multiple terms, aggregate order)
	add("order_asc_default", &queravuev1.SqlQueryModel{
		From:    tbl("", "users", ""),
		OrderBy: []*queravuev1.SqlOrderTerm{ord(opCol("", "id"), false, queravuev1.SqlNulls_SQL_NULLS_UNSPECIFIED)},
	})
	add("order_desc_default", &queravuev1.SqlQueryModel{
		From:    tbl("", "users", ""),
		OrderBy: []*queravuev1.SqlOrderTerm{ord(opCol("", "id"), true, queravuev1.SqlNulls_SQL_NULLS_UNSPECIFIED)},
	})
	add("order_asc_nulls_first", &queravuev1.SqlQueryModel{
		From:    tbl("", "users", ""),
		OrderBy: []*queravuev1.SqlOrderTerm{ord(opCol("", "deleted_at"), false, queravuev1.SqlNulls_SQL_NULLS_FIRST)},
	})
	add("order_asc_nulls_last", &queravuev1.SqlQueryModel{
		From:    tbl("", "users", ""),
		OrderBy: []*queravuev1.SqlOrderTerm{ord(opCol("", "deleted_at"), false, queravuev1.SqlNulls_SQL_NULLS_LAST)},
	})
	add("order_desc_nulls_first", &queravuev1.SqlQueryModel{
		From:    tbl("", "users", ""),
		OrderBy: []*queravuev1.SqlOrderTerm{ord(opCol("", "deleted_at"), true, queravuev1.SqlNulls_SQL_NULLS_FIRST)},
	})
	add("order_desc_nulls_last", &queravuev1.SqlQueryModel{
		From:    tbl("", "users", ""),
		OrderBy: []*queravuev1.SqlOrderTerm{ord(opCol("", "deleted_at"), true, queravuev1.SqlNulls_SQL_NULLS_LAST)},
	})
	add("order_multi_nulls", &queravuev1.SqlQueryModel{
		From: tbl("", "tasks", "t"),
		OrderBy: []*queravuev1.SqlOrderTerm{
			ord(opCol("t", "priority"), true, queravuev1.SqlNulls_SQL_NULLS_LAST),
			ord(opCol("t", "due_at"), false, queravuev1.SqlNulls_SQL_NULLS_FIRST),
			ord(opCol("t", "id"), false, queravuev1.SqlNulls_SQL_NULLS_UNSPECIFIED),
		},
	})
	add("order_by_aggregate", &queravuev1.SqlQueryModel{
		From:    tbl("", "orders", ""),
		Select:  []*queravuev1.SqlSelectItem{selCol("", "customer_id", ""), selAgg(queravuev1.SqlAggregate_SQL_AGGREGATE_SUM, col("", "total"), false, "sum_total")},
		GroupBy: []*queravuev1.SqlColumnRef{col("", "customer_id")},
		OrderBy: []*queravuev1.SqlOrderTerm{ord(opAgg(queravuev1.SqlAggregate_SQL_AGGREGATE_SUM, col("", "total"), false), true, queravuev1.SqlNulls_SQL_NULLS_LAST)},
	})
	add("order_by_count_star_nulls_first", &queravuev1.SqlQueryModel{
		From:    tbl("", "orders", ""),
		Select:  []*queravuev1.SqlSelectItem{selCol("", "status", ""), selAgg(queravuev1.SqlAggregate_SQL_AGGREGATE_COUNT, nil, false, "cnt")},
		GroupBy: []*queravuev1.SqlColumnRef{col("", "status")},
		OrderBy: []*queravuev1.SqlOrderTerm{ord(opAgg(queravuev1.SqlAggregate_SQL_AGGREGATE_COUNT, nil, false), false, queravuev1.SqlNulls_SQL_NULLS_FIRST)},
	})
	add("order_by_qualified_col", &queravuev1.SqlQueryModel{
		From:    tbl("app", "users", "u"),
		OrderBy: []*queravuev1.SqlOrderTerm{ord(opCol("u", "last_login"), true, queravuev1.SqlNulls_SQL_NULLS_UNSPECIFIED)},
	})
	add("order_by_distinct_agg", &queravuev1.SqlQueryModel{
		From:    tbl("", "events", ""),
		Select:  []*queravuev1.SqlSelectItem{selCol("", "kind", "")},
		GroupBy: []*queravuev1.SqlColumnRef{col("", "kind")},
		OrderBy: []*queravuev1.SqlOrderTerm{ord(opAgg(queravuev1.SqlAggregate_SQL_AGGREGATE_COUNT, col("", "user_id"), true), true, queravuev1.SqlNulls_SQL_NULLS_UNSPECIFIED)},
	})
	add("order_by_avg", &queravuev1.SqlQueryModel{
		From:    tbl("", "reviews", ""),
		Select:  []*queravuev1.SqlSelectItem{selCol("", "product_id", "")},
		GroupBy: []*queravuev1.SqlColumnRef{col("", "product_id")},
		OrderBy: []*queravuev1.SqlOrderTerm{ord(opAgg(queravuev1.SqlAggregate_SQL_AGGREGATE_AVG, col("", "rating"), false), true, queravuev1.SqlNulls_SQL_NULLS_FIRST)},
	})

	// 95-105: Pagination (LIMIT, OFFSET, combined, zero normalization) + full kitchen-sink queries
	add("limit_only_no_order", &queravuev1.SqlQueryModel{
		From:  tbl("", "users", ""),
		Limit: proto.Uint64(25),
	})
	add("limit_with_order", &queravuev1.SqlQueryModel{
		From:    tbl("", "users", ""),
		OrderBy: []*queravuev1.SqlOrderTerm{ord(opCol("", "id"), false, queravuev1.SqlNulls_SQL_NULLS_UNSPECIFIED)},
		Limit:   proto.Uint64(50),
	})
	add("offset_only_no_order", &queravuev1.SqlQueryModel{
		From:   tbl("", "users", ""),
		Offset: proto.Uint64(10),
	})
	add("offset_only_with_order", &queravuev1.SqlQueryModel{
		From:    tbl("", "users", ""),
		OrderBy: []*queravuev1.SqlOrderTerm{ord(opCol("", "id"), true, queravuev1.SqlNulls_SQL_NULLS_UNSPECIFIED)},
		Offset:  proto.Uint64(100),
	})
	add("limit_and_offset_no_order", &queravuev1.SqlQueryModel{
		From:   tbl("", "users", ""),
		Limit:  proto.Uint64(20),
		Offset: proto.Uint64(40),
	})
	add("limit_and_offset_with_order", &queravuev1.SqlQueryModel{
		From:    tbl("", "users", ""),
		OrderBy: []*queravuev1.SqlOrderTerm{ord(opCol("", "created_at"), true, queravuev1.SqlNulls_SQL_NULLS_LAST)},
		Limit:   proto.Uint64(15),
		Offset:  proto.Uint64(30),
	})
	add("limit_zero_and_offset_zero", &queravuev1.SqlQueryModel{
		From:   tbl("", "users", ""),
		Limit:  proto.Uint64(0),
		Offset: proto.Uint64(0),
	})
	add("full_reporting_query_1", &queravuev1.SqlQueryModel{
		Distinct: true,
		From:     tbl("shop", "orders", "o"),
		Joins: []*queravuev1.SqlJoin{
			join(queravuev1.SqlJoinKind_SQL_JOIN_KIND_INNER, tbl("shop", "customers", "c"), cmp(opCol("o", "customer_id"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opCol("c", "id"))),
			join(queravuev1.SqlJoinKind_SQL_JOIN_KIND_LEFT, tbl("shop", "coupons", "cp"), cmp(opCol("o", "coupon_id"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opCol("cp", "id"))),
		},
		Select: []*queravuev1.SqlSelectItem{
			selCol("c", "country", ""),
			selCol("cp", "code", "coupon_code"),
			selAgg(queravuev1.SqlAggregate_SQL_AGGREGATE_COUNT, nil, false, "order_count"),
			selAgg(queravuev1.SqlAggregate_SQL_AGGREGATE_SUM, col("o", "total"), false, "gross_total"),
		},
		Where: grp(queravuev1.SqlBoolOp_SQL_BOOL_OP_AND, false,
			cmp(opCol("o", "status"), queravuev1.SqlOperator_SQL_OPERATOR_IN, false, opStr("paid"), opStr("fulfilled")),
			cmp(opCol("c", "deleted_at"), queravuev1.SqlOperator_SQL_OPERATOR_IS_NULL, false),
			grp(queravuev1.SqlBoolOp_SQL_BOOL_OP_OR, false,
				cmp(opCol("o", "total"), queravuev1.SqlOperator_SQL_OPERATOR_GE, false, opFloat(50.0)),
				cmp(opCol("cp", "code"), queravuev1.SqlOperator_SQL_OPERATOR_LIKE, false, opStr("VIP%")),
			),
		),
		GroupBy: []*queravuev1.SqlColumnRef{col("c", "country"), col("cp", "code")},
		Having:  cmp(opAgg(queravuev1.SqlAggregate_SQL_AGGREGATE_COUNT, nil, false), queravuev1.SqlOperator_SQL_OPERATOR_GT, false, opInt(3)),
		OrderBy: []*queravuev1.SqlOrderTerm{
			ord(opAgg(queravuev1.SqlAggregate_SQL_AGGREGATE_SUM, col("o", "total"), false), true, queravuev1.SqlNulls_SQL_NULLS_LAST),
			ord(opCol("c", "country"), false, queravuev1.SqlNulls_SQL_NULLS_FIRST),
		},
		Limit:  proto.Uint64(50),
		Offset: proto.Uint64(100),
	})
	add("full_reporting_query_2", &queravuev1.SqlQueryModel{
		From: tbl("", "invoices", "i"),
		Joins: []*queravuev1.SqlJoin{
			join(queravuev1.SqlJoinKind_SQL_JOIN_KIND_RIGHT, tbl("", "accounts", "a"), cmp(opCol("i", "account_id"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opCol("a", "id"))),
			join(queravuev1.SqlJoinKind_SQL_JOIN_KIND_FULL, tbl("", "regions", "r"), cmp(opCol("a", "region_id"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opCol("r", "id"))),
		},
		Select: []*queravuev1.SqlSelectItem{
			selCol("r", "name", "region"),
			selAgg(queravuev1.SqlAggregate_SQL_AGGREGATE_AVG, col("i", "amount"), false, "avg_amount"),
			selAgg(queravuev1.SqlAggregate_SQL_AGGREGATE_MIN, col("i", "amount"), false, "min_amount"),
			selAgg(queravuev1.SqlAggregate_SQL_AGGREGATE_MAX, col("i", "amount"), false, "max_amount"),
		},
		Where: grp(queravuev1.SqlBoolOp_SQL_BOOL_OP_AND, true,
			cmp(opCol("i", "voided"), queravuev1.SqlOperator_SQL_OPERATOR_EQ, false, opBool(true)),
			cmp(opCol("a", "tier"), queravuev1.SqlOperator_SQL_OPERATOR_IN, true, opStr("test"), opStr("internal")),
		),
		GroupBy: []*queravuev1.SqlColumnRef{col("r", "name")},
		Having:  cmp(opAgg(queravuev1.SqlAggregate_SQL_AGGREGATE_AVG, col("i", "amount"), false), queravuev1.SqlOperator_SQL_OPERATOR_BETWEEN, false, opInt(10), opInt(5000)),
		OrderBy: []*queravuev1.SqlOrderTerm{ord(opCol("r", "name"), false, queravuev1.SqlNulls_SQL_NULLS_UNSPECIFIED)},
		Limit:   proto.Uint64(10),
	})
	add("where_not_between_and_not_in_and_not_like", &queravuev1.SqlQueryModel{
		From: tbl("", "products", "p"),
		Where: grp(queravuev1.SqlBoolOp_SQL_BOOL_OP_AND, false,
			cmp(opCol("p", "price"), queravuev1.SqlOperator_SQL_OPERATOR_BETWEEN, true, opFloat(1.5), opFloat(9.5)),
			cmp(opCol("p", "sku"), queravuev1.SqlOperator_SQL_OPERATOR_LIKE, true, opStr("OLD_%")),
			cmp(opCol("p", "brand_id"), queravuev1.SqlOperator_SQL_OPERATOR_IN, true, opInt(4), opInt(8)),
			cmp(opCol("p", "discontinued_at"), queravuev1.SqlOperator_SQL_OPERATOR_IS_NULL, false),
		),
	})
	add("select_all_aggregates_together", &queravuev1.SqlQueryModel{
		From: tbl("", "metrics", ""),
		Select: []*queravuev1.SqlSelectItem{
			selAgg(queravuev1.SqlAggregate_SQL_AGGREGATE_COUNT, nil, false, "n"),
			selAgg(queravuev1.SqlAggregate_SQL_AGGREGATE_COUNT, col("", "user_id"), true, "u"),
			selAgg(queravuev1.SqlAggregate_SQL_AGGREGATE_SUM, col("", "val"), false, "s"),
			selAgg(queravuev1.SqlAggregate_SQL_AGGREGATE_AVG, col("", "val"), false, "a"),
			selAgg(queravuev1.SqlAggregate_SQL_AGGREGATE_MIN, col("", "val"), false, "mn"),
			selAgg(queravuev1.SqlAggregate_SQL_AGGREGATE_MAX, col("", "val"), false, "mx"),
		},
	})

	return cases
}

func TestRoundTripCorpusAcrossDialects(t *testing.T) {
	corpus := buildCorpus()
	if len(corpus) < 100 {
		t.Fatalf("corpus size = %d, want >= 100", len(corpus))
	}

	dialects := []sqldialect.Dialect{
		sqldialect.Postgres,
		sqldialect.MySQL,
		sqldialect.MSSQL,
		sqldialect.SQLite,
		sqldialect.Oracle,
		sqldialect.ClickHouse,
		sqldialect.DuckDB,
	}

	for _, d := range dialects {
		t.Run(d.ID(), func(t *testing.T) {
			for _, tc := range corpus {
				t.Run(tc.name, func(t *testing.T) {
					sql1, genErr := querybuilder.Generate(d, tc.model)
					if genErr != nil {
						t.Fatalf("Generate failed: %v", genErr)
					}
					parsed, dropped, parseErr := querybuilder.Parse(d, sql1)
					if parseErr != nil {
						t.Fatalf("Parse(%q) failed: %v (offset=%v)", sql1, parseErr.Message, parseErr.Offset)
					}
					if dropped {
						t.Errorf("unexpected commentsDropped on generated SQL %q", sql1)
					}
					want := querybuilder.Normalize(d, tc.model)
					if !proto.Equal(parsed, want) {
						t.Fatalf("round-trip mismatch for %q:\ngot:  %v\nwant: %v", sql1, parsed, want)
					}
					sql2, regenErr := querybuilder.Generate(d, parsed)
					if regenErr != nil {
						t.Fatalf("regenerate failed: %v", regenErr)
					}
					if sql2 != sql1 {
						t.Fatalf("unstable regeneration:\nsql1: %q\nsql2: %q", sql1, sql2)
					}
				})
			}
		})
	}
}

func TestParseSyntaxVariations(t *testing.T) {
	tests := []struct {
		name    string
		dialect sqldialect.Dialect
		sql     string
		wantSQL string
	}{
		{
			name:    "trailing semicolon and implicit aliases",
			dialect: sqldialect.Postgres,
			sql:     `SELECT u.id uid, u.name FROM public.users u JOIN orders o ON u.id = o.user_id WHERE u.status != 'banned';`,
			wantSQL: `SELECT "u"."id" AS "uid", "u"."name" FROM "public"."users" AS "u" INNER JOIN "orders" AS "o" ON "u"."id" = "o"."user_id" WHERE "u"."status" <> 'banned'`,
		},
		{
			name:    "outer join keywords and NOT prefix",
			dialect: sqldialect.Postgres,
			sql:     `SELECT * FROM a LEFT OUTER JOIN b ON a.id = b.id RIGHT OUTER JOIN c ON b.id = c.id FULL OUTER JOIN d ON c.id = d.id WHERE NOT a.x = 1`,
			wantSQL: `SELECT * FROM "a" LEFT JOIN "b" ON "a"."id" = "b"."id" RIGHT JOIN "c" ON "b"."id" = "c"."id" FULL JOIN "d" ON "c"."id" = "d"."id" WHERE NOT ("a"."x" = 1)`,
		},
		{
			name:    "postgres offset before limit and E string and dollar string",
			dialect: sqldialect.Postgres,
			sql:     `SELECT * FROM logs WHERE msg = E'a\nb' OR tag = $$x'y$$ OFFSET 5 LIMIT 10`,
			wantSQL: `SELECT * FROM "logs" WHERE "msg" = 'a` + "\n" + `b' OR "tag" = 'x''y' LIMIT 10 OFFSET 5`,
		},
		{
			name:    "mysql double quoted string and offset",
			dialect: sqldialect.MySQL,
			sql:     "SELECT * FROM `users` WHERE `name` = \"O'Reilly\" LIMIT 10 OFFSET 20",
			wantSQL: "SELECT * FROM `users` WHERE `name` = 'O''Reilly' LIMIT 10 OFFSET 20",
		},
		{
			name:    "oracle q quote",
			dialect: sqldialect.Oracle,
			sql:     `SELECT * FROM users WHERE note = q'[it's ok]' FETCH NEXT 5 ROWS ONLY`,
			wantSQL: `SELECT * FROM "users" WHERE "note" = 'it''s ok' FETCH FIRST 5 ROWS ONLY`,
		},
		{
			name:    "mssql bracket escapes and N string",
			dialect: sqldialect.MSSQL,
			sql:     `SELECT [a]]b] FROM [dbo].[t] WHERE [s] = N'hi' ORDER BY [a]]b] DESC`,
			wantSQL: `SELECT [a]]b] FROM [dbo].[t] WHERE [s] = N'hi' ORDER BY [a]]b] DESC`,
		},
		{
			name:    "scientific float literal",
			dialect: sqldialect.Postgres,
			sql:     `SELECT * FROM measurements WHERE v > 1.5e-2`,
			wantSQL: `SELECT * FROM "measurements" WHERE "v" > 0.015000`,
		},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			m, dropped, err := querybuilder.Parse(tc.dialect, tc.sql)
			if err != nil {
				t.Fatalf("Parse failed: %v", err)
			}
			if dropped {
				t.Errorf("unexpected commentsDropped")
			}
			got, genErr := querybuilder.Generate(tc.dialect, m)
			if genErr != nil {
				t.Fatalf("Generate failed: %v", genErr)
			}
			if got != tc.wantSQL {
				t.Errorf("got:  %q\nwant: %q", got, tc.wantSQL)
			}
		})
	}
}

func TestCommentsDropped(t *testing.T) {
	tests := []struct {
		name    string
		dialect sqldialect.Dialect
		sql     string
	}{
		{"postgres line and nested block", sqldialect.Postgres, "-- head\nSELECT /* /* nested */ */ * FROM users -- tail"},
		{"mysql hash comment", sqldialect.MySQL, "# lead\nSELECT * FROM `users`"},
		{"clickhouse hash and block", sqldialect.ClickHouse, "/* a */ SELECT * FROM `events` # tail"},
		{"mssql block", sqldialect.MSSQL, "SELECT /* note */ * FROM [users]"},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			m, dropped, err := querybuilder.Parse(tc.dialect, tc.sql)
			if err != nil {
				t.Fatalf("Parse failed: %v", err)
			}
			if !dropped {
				t.Errorf("commentsDropped = false, want true")
			}
			if m == nil || m.From == nil || m.From.Table == "" {
				t.Errorf("unexpected model: %v", m)
			}
		})
	}
}

func TestUnsupportedConstructAndOffset(t *testing.T) {
	tests := []struct {
		name    string
		dialect sqldialect.Dialect
		sql     string
		needle  string
	}{
		{"cte", sqldialect.Postgres, "WITH cte AS (SELECT 1) SELECT * FROM cte", "WITH"},
		{"insert", sqldialect.Postgres, "INSERT INTO users VALUES (1)", "INSERT"},
		{"update", sqldialect.Postgres, "UPDATE users SET name = 'a'", "UPDATE"},
		{"delete", sqldialect.Postgres, "DELETE FROM users", "DELETE"},
		{"distinct_on", sqldialect.Postgres, "SELECT DISTINCT ON (id) id FROM users", "ON"},
		{"select_top", sqldialect.MSSQL, "SELECT TOP 10 * FROM users", "TOP"},
		{"select_expr", sqldialect.Postgres, "SELECT price * qty FROM items", "*"},
		{"select_func", sqldialect.Postgres, "SELECT LOWER(name) FROM users", "LOWER"},
		{"window_over", sqldialect.Postgres, "SELECT COUNT(*) OVER () FROM users", "OVER"},
		{"comma_join", sqldialect.Postgres, "SELECT * FROM a, b", ","},
		{"derived_table", sqldialect.Postgres, "SELECT * FROM (SELECT * FROM a) sub", "("},
		{"cross_join", sqldialect.Postgres, "SELECT * FROM a CROSS JOIN b", "CROSS"},
		{"natural_join", sqldialect.Postgres, "SELECT * FROM a NATURAL JOIN b", "NATURAL"},
		{"join_using", sqldialect.Postgres, "SELECT * FROM a JOIN b USING (id)", "USING"},
		{"ilike", sqldialect.Postgres, "SELECT * FROM users WHERE name ILIKE '%a%'", "ILIKE"},
		{"scalar_subquery", sqldialect.Postgres, "SELECT * FROM users WHERE id = (SELECT max(id) FROM users)", "("},
		{"in_subquery", sqldialect.Postgres, "SELECT * FROM users WHERE id IN (SELECT user_id FROM orders)", "SELECT"},
		{"exists", sqldialect.Postgres, "SELECT * FROM users WHERE EXISTS (SELECT 1 FROM orders)", "EXISTS"},
		{"agg_in_where", sqldialect.Postgres, "SELECT * FROM users WHERE COUNT(*) > 1", "COUNT"},
		{"agg_in_on", sqldialect.Postgres, "SELECT * FROM a JOIN b ON COUNT(*) > 1", "COUNT"},
		{"group_by_rollup", sqldialect.Postgres, "SELECT a FROM t GROUP BY ROLLUP", "ROLLUP"},
		{"group_by_ordinal", sqldialect.Postgres, "SELECT a FROM t GROUP BY 1", "1"},
		{"order_by_ordinal", sqldialect.Postgres, "SELECT a FROM t ORDER BY 1", "1"},
		{"union", sqldialect.Postgres, "SELECT id FROM a UNION SELECT id FROM b", "UNION"},
		{"for_update", sqldialect.Postgres, "SELECT id FROM a FOR UPDATE", "FOR"},
		{"multiple_stmts", sqldialect.Postgres, "SELECT id FROM a; SELECT id FROM b", ";"},
		{"mysql_comma_limit", sqldialect.MySQL, "SELECT * FROM t LIMIT 5, 10", ","},
		{"limit_zero", sqldialect.Postgres, "SELECT * FROM t LIMIT 0", "0"},
		{"unicode_prefix_offset", sqldialect.Postgres, "SELECT id FROM t WHERE name = 'héllo😀' UNION SELECT id FROM t", "UNION"},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			_, _, err := querybuilder.Parse(tc.dialect, tc.sql)
			if err == nil {
				t.Fatalf("expected error for %q", tc.sql)
			}
			if err.Kind != queravuev1.QueryBuilderErrorKind_QUERY_BUILDER_ERROR_KIND_UNSUPPORTED_CONSTRUCT {
				t.Fatalf("kind = %v, want UNSUPPORTED_CONSTRUCT (%s)", err.Kind, err.Message)
			}
			if err.Offset == nil {
				t.Fatalf("expected non-nil Offset")
			}
			wantOffset := strings.Index(tc.sql, tc.needle)
			switch tc.name {
			case "distinct_on":
				wantOffset = strings.Index(tc.sql, "ON (")
			case "in_subquery":
				wantOffset = strings.LastIndex(tc.sql, "SELECT")
			}
			if int(*err.Offset) != wantOffset {
				t.Errorf("offset = %d, want %d (at %q in %q)", *err.Offset, wantOffset, tc.needle, tc.sql)
			}
		})
	}
}

func TestParseErrors(t *testing.T) {
	tests := []struct {
		name    string
		dialect sqldialect.Dialect
		sql     string
	}{
		{"empty", sqldialect.Postgres, "   "},
		{"comments_only", sqldialect.Postgres, "-- only a comment\n/* another */"},
		{"unterminated_string", sqldialect.Postgres, "SELECT * FROM t WHERE a = 'unterminated"},
		{"unterminated_comment", sqldialect.Postgres, "SELECT /* unclosed * FROM t"},
		{"unterminated_ident", sqldialect.Postgres, `SELECT "col FROM t`},
		{"missing_from_table", sqldialect.Postgres, "SELECT * FROM "},
		{"missing_rhs", sqldialect.Postgres, "SELECT * FROM t WHERE a ="},
		{"unclosed_paren", sqldialect.Postgres, "SELECT * FROM t WHERE (a = 1"},
		{"empty_in", sqldialect.Postgres, "SELECT * FROM t WHERE a IN ()"},
		{"bad_limit", sqldialect.Postgres, "SELECT * FROM t LIMIT abc"},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			_, _, err := querybuilder.Parse(tc.dialect, tc.sql)
			if err == nil {
				t.Fatalf("expected parse error for %q", tc.sql)
			}
			if err.Kind != queravuev1.QueryBuilderErrorKind_QUERY_BUILDER_ERROR_KIND_PARSE {
				t.Errorf("kind = %v, want PARSE (%s)", err.Kind, err.Message)
			}
			if err.Offset == nil {
				t.Errorf("expected Offset on PARSE error")
			}
		})
	}
}

func TestGenerateErrors(t *testing.T) {
	if _, err := querybuilder.Generate(nil, &queravuev1.SqlQueryModel{From: tbl("", "users", "")}); err == nil ||
		err.Kind != queravuev1.QueryBuilderErrorKind_QUERY_BUILDER_ERROR_KIND_NOT_SQL {
		t.Errorf("nil dialect error = %v, want NOT_SQL", err)
	}

	invalid := []*queravuev1.SqlQueryModel{
		nil,
		{},
		{From: tbl("", "", "")},
		{From: tbl("", "t", ""), Joins: []*queravuev1.SqlJoin{{Table: tbl("", "b", "")}}},
		{From: tbl("", "t", ""), Select: []*queravuev1.SqlSelectItem{selCol("", "", "bad_alias")}},
		{From: tbl("", "t", ""), Where: cmp(opAgg(queravuev1.SqlAggregate_SQL_AGGREGATE_COUNT, nil, false), queravuev1.SqlOperator_SQL_OPERATOR_GT, false, opInt(1))},
		{From: tbl("", "t", ""), OrderBy: []*queravuev1.SqlOrderTerm{ord(opInt(1), false, 0)}},
		{From: tbl("", "t", ""), Where: grp(queravuev1.SqlBoolOp_SQL_BOOL_OP_AND, false)},
	}
	for i, m := range invalid {
		_, err := querybuilder.Generate(sqldialect.Postgres, m)
		if err == nil || err.Kind != queravuev1.QueryBuilderErrorKind_QUERY_BUILDER_ERROR_KIND_INVALID_MODEL {
			t.Errorf("case %d: got err %v, want INVALID_MODEL", i, err)
		}
	}
}
