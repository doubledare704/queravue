package completion

import (
	"strings"

	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

func isQuotedIdent(text string) bool {
	return text != "" && (text[0] == '"' || text[0] == '`' || text[0] == '[')
}

// unquoteIdent returns the identifier a token spells, without its quotes.
// An unterminated quoted identifier yields what has been typed so far.
func unquoteIdent(text string) string {
	if !isQuotedIdent(text) {
		return text
	}
	open := text[0]
	closer := open
	if open == '[' {
		closer = ']'
	}
	body := text[1:]
	if n := len(body); n > 0 && body[n-1] == closer && !endsWithEscapedCloser(body, closer) {
		body = body[:n-1]
	}
	return strings.ReplaceAll(body, string([]byte{closer, closer}), string(closer))
}

func endsWithEscapedCloser(body string, closer byte) bool {
	n := 0
	for i := len(body) - 1; i >= 0 && body[i] == closer; i-- {
		n++
	}
	return n%2 == 0
}

func isSimpleIdent(name string) bool {
	if name == "" {
		return false
	}
	for i := 0; i < len(name); i++ {
		c := name[i]
		switch {
		case c == '_', c >= 'a' && c <= 'z', c >= 'A' && c <= 'Z':
		case c >= '0' && c <= '9' && i > 0:
		default:
			return false
		}
	}
	return true
}

func needsQuoting(d sqlsplit.Dialect, name string) bool {
	if !isSimpleIdent(name) {
		return true
	}
	if d == sqlsplit.Oracle && name != strings.ToUpper(name) {
		return true
	}
	if d == sqlsplit.Postgres && name != strings.ToLower(name) {
		return true
	}
	return reservedWords(d)[strings.ToUpper(name)]
}

func quoteIdent(d sqlsplit.Dialect, name string) string {
	switch d {
	case sqlsplit.MySQL:
		return "`" + strings.ReplaceAll(name, "`", "``") + "`"
	case sqlsplit.MSSQL:
		return "[" + strings.ReplaceAll(name, "]", "]]") + "]"
	case sqlsplit.SQLite, sqlsplit.Postgres, sqlsplit.Oracle:
	}
	return `"` + strings.ReplaceAll(name, `"`, `""`) + `"`
}

// identForInsert returns name quoted only when the dialect requires it.
func identForInsert(d sqlsplit.Dialect, name string) string {
	if needsQuoting(d, name) {
		return quoteIdent(d, name)
	}
	return name
}
