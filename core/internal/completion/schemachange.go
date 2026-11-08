package completion

import (
	"strings"

	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

var schemaChangingWords = map[string]bool{"CREATE": true, "ALTER": true, "DROP": true, "RENAME": true}

// IsSchemaChange reports whether sql starts like a statement that changes
// the schema. It errs on the side of true: a false positive only costs a
// catalog reload.
func IsSchemaChange(d sqlsplit.Dialect, sql string) bool {
	for _, t := range sqlsplit.Tokenize(d, sql) {
		switch t.Kind {
		case sqlsplit.TokenSpace, sqlsplit.TokenComment:
			continue
		case sqlsplit.TokenWord:
			return schemaChangingWords[strings.ToUpper(t.Text(sql))]
		}
		return false
	}
	return false
}
