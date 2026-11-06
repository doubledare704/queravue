package sqldialect_test

import (
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

func TestDialects(t *testing.T) {
	ts := time.Date(2026, 1, 2, 3, 4, 5, 0, time.UTC)
	tests := []struct {
		name string
		d    sqldialect.Dialect

		quote, qualified, ph2, order, page, lit string
		stable                                  bool
	}{
		{"postgres", sqldialect.Postgres, `"a""b"`, `"s"."t"`, "$2", `"c" DESC NULLS LAST`, `SELECT 1 LIMIT 10`, `'it''s'`, true},
		{"sqlite-main", sqldialect.SQLite, `"a""b"`, `"t"`, "?", `"c" DESC NULLS LAST`, `SELECT 1 LIMIT 10`, `'it''s'`, true},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := tt.d.QuoteIdent(`a"b`); got != tt.quote {
				t.Errorf("QuoteIdent = %s, want %s", got, tt.quote)
			}
			schema := "s"
			if tt.name == "sqlite-main" {
				schema = "main"
			}
			if got := tt.d.QualifyTable(schema, "t"); got != tt.qualified {
				t.Errorf("QualifyTable = %s, want %s", got, tt.qualified)
			}
			if got := tt.d.Placeholder(2); got != tt.ph2 {
				t.Errorf("Placeholder = %s, want %s", got, tt.ph2)
			}
			if got := tt.d.OrderTerm(`"c"`, true, sqldialect.NullsLast); got != tt.order {
				t.Errorf("OrderTerm = %s, want %s", got, tt.order)
			}
			got, stable := tt.d.Paginate("SELECT 1", 10, false)
			if got != tt.page || stable != tt.stable {
				t.Errorf("Paginate = %q,%v want %q,%v", got, stable, tt.page, tt.stable)
			}
			if got := tt.d.FormatLiteral(engine.Text("it's")); got != tt.lit {
				t.Errorf("FormatLiteral = %s, want %s", got, tt.lit)
			}
			if got := tt.d.FormatLiteral(engine.Timestamptz(ts)); got != `'2026-01-02 03:04:05Z'` {
				t.Errorf("timestamp literal = %s", got)
			}
		})
	}
}

func TestOfWithoutProvider(t *testing.T) {
	if _, ok := sqldialect.Of(nil); ok {
		t.Fatal("nil conn must not provide a dialect")
	}
}
