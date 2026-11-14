package completion

import (
	"slices"
	"strings"
	"testing"

	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

func TestDuckDBWordLists(t *testing.T) {
	for _, kw := range []string{"QUALIFY", "PIVOT", "SUMMARIZE", "GROUP BY ALL", "OR REPLACE", "HUGEINT"} {
		if !slices.Contains(keywordsOf(sqlsplit.DuckDB), kw) {
			t.Errorf("keywords lack %s", kw)
		}
	}
	for _, kw := range keywordsOf(sqlsplit.DuckDB) {
		if strings.Contains(kw, "_") && kw != strings.ToUpper(kw) {
			t.Errorf("keyword %q keeps an underscore it should not", kw)
		}
	}
	for _, fn := range []string{"read_parquet", "read_csv", "list_transform", "struct_pack", "regexp_matches"} {
		if !slices.Contains(functionsOf(sqlsplit.DuckDB), fn) {
			t.Errorf("functions lack %s", fn)
		}
	}
}

func TestDuckDBIdentifierQuoting(t *testing.T) {
	for name, want := range map[string]bool{"customers": false, "Mixed": false, "has space": true, "select": true, "qualify": true, "a-b": true} {
		if got := needsQuoting(sqlsplit.DuckDB, name); got != want {
			t.Errorf("needsQuoting(%q) = %v, want %v", name, got, want)
		}
	}
	if got := quoteIdent(sqlsplit.DuckDB, `we"ird`); got != `"we""ird"` {
		t.Errorf("quoteIdent = %s", got)
	}
}
