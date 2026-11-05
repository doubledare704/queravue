package sqlbuilder_test

import (
	"strings"
	"testing"

	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/sqlbuilder"
)

func TestQuoteIdent(t *testing.T) {
	tests := []struct {
		input string
		want  string
	}{
		{"users", `"users"`},
		{`user"name`, `"user""name"`},
		{"table; DROP TABLE users; --", `"table; DROP TABLE users; --"`},
		{"mixedCase", `"mixedCase"`},
		{"with spaces", `"with spaces"`},
		{"café", `"café"`},
		{"пользователи", `"пользователи"`},
	}
	for _, tt := range tests {
		got := sqlbuilder.QuoteIdent(tt.input)
		if got != tt.want {
			t.Errorf("QuoteIdent(%q) = %q, want %q", tt.input, got, tt.want)
		}
	}
}

func TestQualifyTable(t *testing.T) {
	tests := []struct {
		dialect sqlbuilder.Dialect
		schema  string
		table   string
		want    string
	}{
		{sqlbuilder.DialectPostgres, "public", "users", `"public"."users"`},
		{sqlbuilder.DialectPostgres, "", "users", `"users"`},
		{sqlbuilder.DialectSQLite, "main", "users", `"users"`},
		{sqlbuilder.DialectSQLite, "attached", "users", `"attached"."users"`},
	}
	for _, tt := range tests {
		got := sqlbuilder.QualifyTable(tt.dialect, tt.schema, tt.table)
		if got != tt.want {
			t.Errorf("QualifyTable(%v, %q, %q) = %q, want %q", tt.dialect, tt.schema, tt.table, got, tt.want)
		}
	}
}

func TestBuildSelect_TableDriven(t *testing.T) {
	valStr := func(s string) *queravuev1.Value {
		return &queravuev1.Value{Kind: &queravuev1.Value_TextValue{TextValue: s}}
	}
	valInt := func(i int64) *queravuev1.Value {
		return &queravuev1.Value{Kind: &queravuev1.Value_IntValue{IntValue: i}}
	}

	tests := []struct {
		name       string
		dialect    sqlbuilder.Dialect
		ref        *queravuev1.TableRef
		filter     *queravuev1.TableFilter
		sorts      []*queravuev1.SortClause
		pageSize   uint64
		wantSQLSub []string
		wantParams int
	}{
		{
			name:       "basic select without filter",
			dialect:    sqlbuilder.DialectPostgres,
			ref:        &queravuev1.TableRef{Schema: "public", Table: "users"},
			wantSQLSub: []string{`SELECT * FROM "public"."users";`},
			wantParams: 0,
		},
		{
			name:    "injection in identifier",
			dialect: sqlbuilder.DialectPostgres,
			ref:     &queravuev1.TableRef{Schema: "public", Table: `users"; DROP TABLE users; --`},
			wantSQLSub: []string{
				`SELECT * FROM "public"."users""; DROP TABLE users; --";`,
			},
			wantParams: 0,
		},
		{
			name:    "injection in value parameter",
			dialect: sqlbuilder.DialectPostgres,
			ref:     &queravuev1.TableRef{Schema: "public", Table: "users"},
			filter: &queravuev1.TableFilter{
				Root: &queravuev1.FilterGroup{
					Op: queravuev1.LogicalOp_LOGICAL_OP_AND,
					Conditions: []*queravuev1.FilterCondition{
						{
							Column: "name",
							Op:     queravuev1.FilterOp_FILTER_OP_EQUALS,
							Values: []*queravuev1.Value{valStr(`' OR '1'='1`)},
						},
					},
				},
			},
			wantSQLSub: []string{
				`SELECT * FROM "public"."users" WHERE "name" = $1;`,
			},
			wantParams: 1,
		},
		{
			name:    "sqlite dialect uses ? placeholders and handles ILIKE",
			dialect: sqlbuilder.DialectSQLite,
			ref:     &queravuev1.TableRef{Schema: "main", Table: "customers"},
			filter: &queravuev1.TableFilter{
				Root: &queravuev1.FilterGroup{
					Op: queravuev1.LogicalOp_LOGICAL_OP_AND,
					Conditions: []*queravuev1.FilterCondition{
						{
							Column: "email",
							Op:     queravuev1.FilterOp_FILTER_OP_ILIKE,
							Values: []*queravuev1.Value{valStr(`%@example.com`)},
						},
					},
				},
			},
			wantSQLSub: []string{
				`SELECT * FROM "customers" WHERE LOWER("email") LIKE LOWER(?);`,
			},
			wantParams: 1,
		},
		{
			name:    "nested groups AND/OR and BETWEEN and IN",
			dialect: sqlbuilder.DialectPostgres,
			ref:     &queravuev1.TableRef{Schema: "public", Table: "products"},
			filter: &queravuev1.TableFilter{
				Root: &queravuev1.FilterGroup{
					Op: queravuev1.LogicalOp_LOGICAL_OP_OR,
					Conditions: []*queravuev1.FilterCondition{
						{
							Column: "price",
							Op:     queravuev1.FilterOp_FILTER_OP_BETWEEN,
							Values: []*queravuev1.Value{valInt(10), valInt(50)},
						},
					},
					Groups: []*queravuev1.FilterGroup{
						{
							Op: queravuev1.LogicalOp_LOGICAL_OP_AND,
							Conditions: []*queravuev1.FilterCondition{
								{
									Column: "category",
									Op:     queravuev1.FilterOp_FILTER_OP_IN,
									Values: []*queravuev1.Value{valStr("A"), valStr("B")},
								},
								{
									Column: "deleted_at",
									Op:     queravuev1.FilterOp_FILTER_OP_IS_NULL,
								},
							},
						},
					},
				},
				RawWhere: "status != 'archived'",
			},
			wantSQLSub: []string{
				`SELECT * FROM "public"."products" WHERE`,
				`"price" BETWEEN $1 AND $2`,
				`"category" IN ($3, $4)`,
				`"deleted_at" IS NULL`,
				`(status != 'archived')`,
			},
			wantParams: 4,
		},
		{
			name:    "multi-column sort and limit",
			dialect: sqlbuilder.DialectPostgres,
			ref:     &queravuev1.TableRef{Schema: "public", Table: "orders"},
			sorts: []*queravuev1.SortClause{
				{Column: "created_at", Direction: queravuev1.SortDirection_SORT_DIRECTION_DESC, Nulls: queravuev1.NullsOrder_NULLS_ORDER_LAST},
				{Column: "id", Direction: queravuev1.SortDirection_SORT_DIRECTION_ASC, Nulls: queravuev1.NullsOrder_NULLS_ORDER_FIRST},
			},
			pageSize: 500,
			wantSQLSub: []string{
				`ORDER BY "created_at" DESC NULLS LAST, "id" ASC NULLS FIRST`,
				`LIMIT 500;`,
			},
			wantParams: 0,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			sql, params, err := sqlbuilder.BuildSelect(tt.dialect, tt.ref, tt.filter, tt.sorts, tt.pageSize)
			if err != nil {
				t.Fatalf("unexpected error: %v", err)
			}
			for _, sub := range tt.wantSQLSub {
				if !strings.Contains(sql, sub) {
					t.Errorf("SQL %q does not contain expected substring %q", sql, sub)
				}
			}
			if len(params) != tt.wantParams {
				t.Errorf("got %d params, want %d", len(params), tt.wantParams)
			}
		})
	}
}

func TestBuildApplyChanges(t *testing.T) {
	valStr := func(s string) *queravuev1.Value {
		return &queravuev1.Value{Kind: &queravuev1.Value_TextValue{TextValue: s}}
	}
	valInt := func(i int64) *queravuev1.Value {
		return &queravuev1.Value{Kind: &queravuev1.Value_IntValue{IntValue: i}}
	}

	changes := []*queravuev1.RowChange{
		{
			Type: queravuev1.RowChangeType_ROW_CHANGE_TYPE_INSERT,
			Values: []*queravuev1.ColumnValue{
				{Column: "name", Value: valStr("Alice")},
				{Column: "age", Value: valInt(30)},
			},
		},
		{
			Type: queravuev1.RowChangeType_ROW_CHANGE_TYPE_UPDATE,
			Keys: []*queravuev1.ColumnValue{
				{Column: "id", Value: valInt(1)},
			},
			Values: []*queravuev1.ColumnValue{
				{Column: "age", Value: valInt(31)},
			},
		},
		{
			Type: queravuev1.RowChangeType_ROW_CHANGE_TYPE_DELETE,
			Keys: []*queravuev1.ColumnValue{
				{Column: "id", Value: valInt(2)},
			},
		},
	}

	ref := &queravuev1.TableRef{Schema: "public", Table: "users"}
	plans, preview, err := sqlbuilder.BuildApplyChanges(sqlbuilder.DialectPostgres, ref, changes)
	if err != nil {
		t.Fatalf("unexpected error: %v", err)
	}

	if len(plans) != 3 {
		t.Fatalf("got %d plans, want 3", len(plans))
	}

	// Verify parameterized plans
	if !strings.HasPrefix(plans[0].Statement.SQL, `INSERT INTO "public"."users" ("name", "age") VALUES ($1, $2);`) {
		t.Errorf("plan 0 SQL = %q", plans[0].Statement.SQL)
	}
	if len(plans[0].Statement.Params) != 2 {
		t.Errorf("plan 0 params = %d, want 2", len(plans[0].Statement.Params))
	}

	if !strings.HasPrefix(plans[1].Statement.SQL, `UPDATE "public"."users" SET "age" = $1 WHERE "id" = $2;`) {
		t.Errorf("plan 1 SQL = %q", plans[1].Statement.SQL)
	}

	if !strings.HasPrefix(plans[2].Statement.SQL, `DELETE FROM "public"."users" WHERE "id" = $1;`) {
		t.Errorf("plan 2 SQL = %q", plans[2].Statement.SQL)
	}

	// Verify human preview
	if !strings.Contains(preview, "BEGIN;") || !strings.Contains(preview, "COMMIT;") {
		t.Errorf("preview missing transaction boundaries:\n%s", preview)
	}
	if !strings.Contains(preview, `'Alice'`) || !strings.Contains(preview, `30`) {
		t.Errorf("preview missing literal values:\n%s", preview)
	}
}
