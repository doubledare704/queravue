package sqlbuilder_test

import (
	"strings"
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/sqlbuilder"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

// bracketDialect proves sqlbuilder takes every syntax decision from the
// dialect: [x] idents, @pN placeholders, FETCH pagination.
type bracketDialect struct{ sqldialect.Dialect }

func (bracketDialect) QuoteIdent(n string) string { return "[" + n + "]" }
func (d bracketDialect) QualifyTable(s, t string) string {
	return "[" + s + "].[" + t + "]"
}
func (bracketDialect) Placeholder(n int) string { return "@p" + string(rune('0'+n)) }
func (bracketDialect) Paginate(sql string, _ uint64, has bool) (string, bool) {
	if !has {
		sql += " ORDER BY (SELECT NULL)"
	}
	return sql + " OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY", has
}
func (bracketDialect) ILike(c, p string) string { return c + " LIKE " + p }
func (bracketDialect) Lexer() sqlsplit.Dialect  { return sqlsplit.Postgres }

func TestBuildSelectUsesDialect(t *testing.T) {
	ref := &queravuev1.TableRef{Schema: "dbo", Table: "t"}
	filter := &queravuev1.TableFilter{Root: &queravuev1.FilterGroup{Conditions: []*queravuev1.FilterCondition{{
		Column: "a", Op: queravuev1.FilterOp_FILTER_OP_EQUALS,
		Values: []*queravuev1.Value{{Kind: &queravuev1.Value_IntValue{IntValue: 1}}},
	}}}}
	sql, params, stable, err := sqlbuilder.BuildSelectOrdered(bracketDialect{sqldialect.Postgres}, ref, filter, nil, 5)
	if err != nil {
		t.Fatal(err)
	}
	want := "SELECT * FROM [dbo].[t] WHERE [a] = @p1 ORDER BY (SELECT NULL) OFFSET 0 ROWS FETCH NEXT 5 ROWS ONLY;"
	if sql != want {
		t.Errorf("sql = %q\nwant  %q", sql, want)
	}
	if stable || len(params) != 1 || params[0].Kind != engine.VInt {
		t.Errorf("stable=%v params=%v", stable, params)
	}
	if !strings.HasSuffix(sql, ";") {
		t.Error("missing terminator")
	}
}
