package format

import (
	"strings"
	"unicode/utf8"

	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

const (
	tightChars    = ":$?@#[]\\"
	sentinelChars = ",();."
)

type emitted struct {
	text      string
	kind      sqlsplit.TokenKind
	keyword   bool
	unarySign bool
	comment   bool
}

type writer struct {
	opts      Options
	b         strings.Builder
	col       int
	pending   bool
	level     int
	lineStart bool
	last      emitted
	has       bool
	forced    bool
}

func newWriter(opts Options) *writer { return &writer{opts: opts, lineStart: true} }

func (w *writer) scratch() *writer {
	return &writer{opts: w.opts, col: w.column(), lineStart: w.lineStart || w.pending, last: w.last, has: w.has}
}

func (w *writer) newline(level int) {
	w.pending = true
	w.level = level
}

func (w *writer) column() int {
	if w.pending {
		return w.level * w.opts.IndentWidth
	}
	return w.col
}

func (w *writer) put(s string) {
	w.b.WriteString(s)
	w.col += utf8.RuneCountInString(s)
	w.lineStart = false
}

func (w *writer) flush() {
	if !w.pending {
		return
	}
	if w.b.Len() > 0 {
		w.b.WriteByte('\n')
	}
	indent := strings.Repeat(" ", w.level*w.opts.IndentWidth)
	w.b.WriteString(indent)
	w.col = len(indent)
	w.pending = false
	w.lineStart = true
}

func (w *writer) atom(t token) {
	w.flush()
	keyword := t.kind == sqlsplit.TokenWord && (t.keyword || isKeyword(t.text)) && !w.afterDot()
	sign := t.kind == sqlsplit.TokenPunct && (t.text == "-" || t.text == "+")
	unary := sign && (w.unaryContext() || w.exponentSign(t))
	if !w.lineStart && w.has && w.needSpace(t, unary) {
		w.put(" ")
	}
	w.put(w.cased(t, keyword))
	w.last = emitted{text: t.text, kind: t.kind, keyword: keyword, unarySign: unary}
	w.has = true
}

func (w *writer) comment(t token, level int) {
	if t.newlineBefore {
		w.newline(level)
	}
	w.flush()
	if !w.lineStart && w.has {
		w.put(" ")
	}
	w.put(t.text)
	w.last = emitted{text: t.text, kind: sqlsplit.TokenComment, comment: true}
	w.has = true
	if isLineComment(t.text) || t.newlineBefore {
		w.newline(level)
	}
}

func (w *writer) flatComment(t token) {
	if t.newlineBefore || isLineComment(t.text) {
		w.forced = true
	}
	w.comment(token{text: t.text, kind: t.kind}, w.level)
	w.pending = false
}

func (w *writer) cased(t token, keyword bool) string {
	if !keyword {
		return t.text
	}
	switch w.opts.KeywordCase {
	case CaseLower:
		return strings.ToLower(t.text)
	case CasePreserve:
		return t.text
	}
	return strings.ToUpper(t.text)
}

func isTight(text string) bool {
	return text == "::" || len(text) == 1 && strings.Contains(tightChars, text)
}

func isOp(kind sqlsplit.TokenKind, text string) bool {
	return kind == sqlsplit.TokenPunct && !isTight(text) && (len(text) != 1 || !strings.Contains(sentinelChars, text))
}

func (w *writer) unaryContext() bool {
	p := w.last
	switch {
	case !w.has:
		return true
	case p.comment:
		return false
	case p.kind == sqlsplit.TokenPunct:
		return p.text == "(" || p.text == "," || isOp(p.kind, p.text)
	case p.kind == sqlsplit.TokenWord && p.keyword:
		return !operandKeywords[strings.ToUpper(p.text)]
	}
	return false
}

func (w *writer) exponentSign(t token) bool {
	p := w.last
	if p.kind != sqlsplit.TokenNumber || !t.adjacent || len(p.text) < 2 {
		return false
	}
	last := p.text[len(p.text)-1]
	return (last == 'e' || last == 'E') && !strings.HasPrefix(strings.ToLower(p.text), "0x")
}

func (w *writer) needSpace(c token, unary bool) bool {
	p := w.last
	cp := c.kind == sqlsplit.TokenPunct
	switch {
	case p.comment:
		return !cp || !strings.Contains(sentinelChars, c.text)
	case w.exponentSign(c):
		return false
	case p.unarySign:
		return false
	case cp && c.text != "(" && strings.Contains(sentinelChars, c.text):
		return false
	case p.kind == sqlsplit.TokenPunct && (p.text == "(" || p.text == "."):
		return false
	case cp && c.text == "(":
		return w.spaceBeforeParen(c)
	case c.kind == sqlsplit.TokenString && c.adjacent && p.kind == sqlsplit.TokenWord:
		return false
	case unary:
		return true
	case isOp(c.kind, c.text) || isOp(p.kind, p.text):
		return true
	case isTight(c.text) && cp || isTight(p.text) && p.kind == sqlsplit.TokenPunct:
		return !c.adjacent
	}
	return true
}

func (w *writer) spaceBeforeParen(c token) bool {
	if !c.adjacent {
		return true
	}
	p := w.last
	switch p.kind {
	case sqlsplit.TokenWord:
		return p.keyword && !functionLikeKeywords[strings.ToUpper(p.text)]
	case sqlsplit.TokenQuotedIdent:
		return false
	case sqlsplit.TokenPunct:
		return p.text != ")" && p.text != "]"
	}
	return true
}

func (w *writer) afterDot() bool {
	return w.has && w.last.kind == sqlsplit.TokenPunct && w.last.text == "."
}
