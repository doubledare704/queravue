// Package format rewrites SQL layout for the editor (ADR 0015). It changes
// only whitespace and keyword case; any statement it cannot handle with that
// guarantee is returned unchanged.
package format

import (
	"fmt"
	"strings"

	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

// KeywordCase selects how keywords are written.
type KeywordCase int

// Keyword cases; the zero value is upper case.
const (
	CaseUpper KeywordCase = iota
	CaseLower
	CasePreserve
)

// CommaStyle selects where commas go in lists that span lines.
type CommaStyle int

// Comma styles; the zero value is trailing.
const (
	CommaTrailing CommaStyle = iota
	CommaLeading
)

// Options control the layout. Zero values pick the defaults.
type Options struct {
	KeywordCase  KeywordCase
	IndentWidth  int
	CommaStyle   CommaStyle
	MaxLineWidth int
}

func (o Options) normalized() Options {
	if o.IndentWidth == 0 {
		o.IndentWidth = 2
	}
	o.IndentWidth = min(max(o.IndentWidth, 1), 8)
	if o.MaxLineWidth == 0 {
		o.MaxLineWidth = 100
	}
	o.MaxLineWidth = min(max(o.MaxLineWidth, 40), 400)
	return o
}

// SyntaxError reports text the lexer cannot close, at a byte offset.
type SyntaxError struct {
	Offset  int
	Message string
}

func (e *SyntaxError) Error() string {
	return fmt.Sprintf("format: %s at byte %d", e.Message, e.Offset)
}

// Format formats every statement in text. Statements that are not plain
// SELECT, INSERT, UPDATE, DELETE, VALUES or WITH queries, and statements whose
// formatting would break an invariant, are returned as they were.
func Format(d sqlsplit.Dialect, text string, opts Options) (string, error) {
	if err := checkTerminated(d, text); err != nil {
		return "", err
	}
	opts = opts.normalized()
	var b strings.Builder
	prev := 0
	for _, r := range sqlsplit.Split(d, text) {
		b.WriteString(text[prev:r.Start])
		b.WriteString(formatStatement(d, text[r.Start:r.End], opts))
		prev = r.End
	}
	b.WriteString(text[prev:])
	return b.String(), nil
}

func formatStatement(d sqlsplit.Dialect, stmt string, opts Options) string {
	out, ok := render(d, stmt, opts)
	if !ok || out == stmt || !equivalent(d, stmt, out) {
		return stmt
	}
	if again, ok := render(d, out, opts); !ok || again != out {
		return stmt
	}
	return out
}

func render(d sqlsplit.Dialect, stmt string, opts Options) (string, bool) {
	nodes, ok := parse(d, stmt)
	if !ok || !supported(nodes, d) {
		return "", false
	}
	r := renderer{w: newWriter(opts), o: opts}
	r.statement(nodes, 0)
	return r.w.b.String(), true
}

func checkTerminated(d sqlsplit.Dialect, text string) error {
	for _, t := range sqlsplit.Tokenize(d, text) {
		s := t.Text(text)
		switch t.Kind {
		case sqlsplit.TokenString:
			if strings.HasPrefix(s, "$") {
				continue
			}
			if len(s) < 2 || s[len(s)-1] != quoteOf(s) {
				return &SyntaxError{Offset: t.Start, Message: "unterminated string"}
			}
		case sqlsplit.TokenQuotedIdent:
			closer := s[0]
			if closer == '[' {
				closer = ']'
			}
			if len(s) < 2 || s[len(s)-1] != closer {
				return &SyntaxError{Offset: t.Start, Message: "unterminated quoted identifier"}
			}
		case sqlsplit.TokenComment:
			if strings.HasPrefix(s, "/*") && (len(s) < 4 || !strings.HasSuffix(s, "*/")) {
				return &SyntaxError{Offset: t.Start, Message: "unterminated comment"}
			}
		}
	}
	return nil
}

func quoteOf(s string) byte {
	if i := strings.IndexAny(s, `'"`); i >= 0 {
		return s[i]
	}
	return '\''
}

func equivalent(d sqlsplit.Dialect, a, b string) bool {
	x, y := significant(d, a), significant(d, b)
	if len(x) != len(y) {
		return false
	}
	for i := range x {
		if x[i].kind != y[i].kind {
			return false
		}
		if x[i].kind == sqlsplit.TokenComment {
			if strings.TrimRight(x[i].text, "\r\n") != strings.TrimRight(y[i].text, "\r\n") {
				return false
			}
			continue
		}
		if x[i].text != y[i].text && !onlyKeywordCaseDiffers(x[i], y[i]) {
			return false
		}
	}
	return true
}

type plainToken struct {
	kind sqlsplit.TokenKind
	text string
}

func significant(d sqlsplit.Dialect, text string) []plainToken {
	var out []plainToken
	for _, t := range sqlsplit.Tokenize(d, text) {
		if t.Kind != sqlsplit.TokenSpace {
			out = append(out, plainToken{kind: t.Kind, text: t.Text(text)})
		}
	}
	return out
}

func onlyKeywordCaseDiffers(a, b plainToken) bool {
	return a.kind == sqlsplit.TokenWord && strings.EqualFold(a.text, b.text) && caseChangeable(a.text)
}
