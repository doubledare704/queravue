package completion_test

import (
	"testing"

	"github.com/doubledare704/queravue/core/internal/completion"
	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

func TestIsSchemaChange(t *testing.T) {
	tests := []struct {
		sql  string
		want bool
	}{
		{"CREATE TABLE t (id int)", true},
		{"  -- note\n alter table t add column c int", true},
		{"/* x */ DROP INDEX i", true},
		{"RENAME TABLE a TO b", true},
		{"SELECT 1", false},
		{"INSERT INTO t VALUES (1)", false},
		{"", false},
		{"(CREATE", false},
		{"'CREATE'", false},
	}
	for _, tc := range tests {
		if got := completion.IsSchemaChange(sqlsplit.Postgres, tc.sql); got != tc.want {
			t.Errorf("IsSchemaChange(%q) = %v, want %v", tc.sql, got, tc.want)
		}
	}
}
