package completion

import (
	"slices"
	"testing"

	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

func TestOracleIdentifierQuoting(t *testing.T) {
	for name, want := range map[string]bool{
		"EMPLOYEES": false, "employees": true, "Mixed": true, "ORDER": true, "LEVEL": true, "HAS SPACE": true, "A$B": true,
	} {
		if got := needsQuoting(sqlsplit.Oracle, name); got != want {
			t.Errorf("needsQuoting(%q) = %v, want %v", name, got, want)
		}
	}
	if got := identForInsert(sqlsplit.Oracle, "customers"); got != `"customers"` {
		t.Errorf("identForInsert = %s", got)
	}
	if got := identForInsert(sqlsplit.Oracle, "CUSTOMERS"); got != "CUSTOMERS" {
		t.Errorf("identForInsert = %s", got)
	}
}

func TestOracleWordLists(t *testing.T) {
	for _, kw := range []string{"ROWNUM", "MINUS", "CONNECT"} {
		if !slices.Contains(keywordsOf(sqlsplit.Oracle), kw) {
			t.Errorf("keywords lack %s", kw)
		}
	}
	for _, fn := range []string{"NVL", "DECODE", "TO_CHAR", "LISTAGG"} {
		if !slices.Contains(functionsOf(sqlsplit.Oracle), fn) {
			t.Errorf("functions lack %s", fn)
		}
	}
}
