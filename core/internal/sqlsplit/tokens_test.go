package sqlsplit_test

import (
	"strings"
	"testing"

	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

func kinds(d sqlsplit.Dialect, text string) []sqlsplit.TokenKind {
	var out []sqlsplit.TokenKind
	for _, t := range sqlsplit.Tokenize(d, text) {
		if t.Kind != sqlsplit.TokenSpace {
			out = append(out, t.Kind)
		}
	}
	return out
}

func TestTokenizeClassifiesTokens(t *testing.T) {
	const (
		w = sqlsplit.TokenWord
		p = sqlsplit.TokenPunct
		s = sqlsplit.TokenString
		q = sqlsplit.TokenQuotedIdent
		n = sqlsplit.TokenNumber
		c = sqlsplit.TokenComment
	)
	tests := []struct {
		name string
		d    sqlsplit.Dialect
		text string
		want []sqlsplit.TokenKind
	}{
		{"postgres select", sqlsplit.Postgres, `SELECT "a b", 'x''y', 12.5 FROM t -- tail`, []sqlsplit.TokenKind{w, q, p, s, p, n, w, w, c}},
		{"postgres dollar quote", sqlsplit.Postgres, `SELECT $$a;b$$`, []sqlsplit.TokenKind{w, s}},
		{"postgres cast", sqlsplit.Postgres, `a::int`, []sqlsplit.TokenKind{w, p, p, w}},
		{"mysql backtick and double quote string", sqlsplit.MySQL, "SELECT `a`, \"s\" # c", []sqlsplit.TokenKind{w, q, p, s, c}},
		{"mssql bracket", sqlsplit.MSSQL, `SELECT [a]]b] FROM [dbo].[t]`, []sqlsplit.TokenKind{w, q, w, q, p, q}},
		{"sqlite bracket", sqlsplit.SQLite, `SELECT [a] /* x */`, []sqlsplit.TokenKind{w, q, c}},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			got := kinds(tc.d, tc.text)
			if len(got) != len(tc.want) {
				t.Fatalf("kinds = %v, want %v", got, tc.want)
			}
			for i := range got {
				if got[i] != tc.want[i] {
					t.Fatalf("kinds = %v, want %v", got, tc.want)
				}
			}
		})
	}
}

func TestTokenizeCoversTextExactly(t *testing.T) {
	texts := []string{"", "SELECT 'unterminated", "/* open", `"open`, "é ü ñ select", "a\r\n\tb", "$1 + $tag$x$tag$"}
	for _, d := range []sqlsplit.Dialect{sqlsplit.Postgres, sqlsplit.SQLite, sqlsplit.MySQL, sqlsplit.MSSQL} {
		for _, text := range texts {
			var b strings.Builder
			for _, tok := range sqlsplit.Tokenize(d, text) {
				b.WriteString(tok.Text(text))
			}
			if b.String() != text {
				t.Errorf("dialect %d: tokens rebuild %q, want %q", d, b.String(), text)
			}
		}
	}
}

func FuzzTokenizeCoversText(f *testing.F) {
	for _, seed := range []string{"SELECT 1", "'a", "/*", "$$", "[x", "é"} {
		f.Add(seed)
	}
	f.Fuzz(func(t *testing.T, text string) {
		for _, d := range []sqlsplit.Dialect{sqlsplit.Postgres, sqlsplit.SQLite, sqlsplit.MySQL, sqlsplit.MSSQL} {
			pos := 0
			for _, tok := range sqlsplit.Tokenize(d, text) {
				if tok.Start != pos || tok.End <= tok.Start {
					t.Fatalf("token %+v does not continue at %d", tok, pos)
				}
				pos = tok.End
			}
			if pos != len(text) {
				t.Fatalf("tokens end at %d, text has %d bytes", pos, len(text))
			}
		}
	})
}
