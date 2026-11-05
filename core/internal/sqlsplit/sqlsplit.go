// Package sqlsplit splits SQL scripts into statements, per dialect, and maps
// offsets between Go byte offsets and the UTF-16 code units used on the wire.
//
// The scanner understands what hides semicolons: quoted strings and
// identifiers, comments, PostgreSQL dollar quotes and E” escapes, and
// trigger or BEGIN ATOMIC bodies. It does not parse SQL.
package sqlsplit

import (
	"strings"
	"unicode/utf8"
)

// Dialect selects the lexical rules.
type Dialect int

// Supported dialects.
const (
	// Postgres: dollar quotes, nested block comments, E'' escapes,
	// BEGIN ATOMIC bodies.
	Postgres Dialect = iota + 1
	// SQLite: CREATE TRIGGER ... BEGIN ... END bodies, [x] and `x` identifiers.
	SQLite
)

// Range locates one statement as byte offsets into the scanned text.
type Range struct {
	// Start is the first byte of the statement (after leading space and comments).
	Start int
	// End is one past the last byte of the statement, excluding the terminating
	// semicolon and trailing space or comments.
	End int
	// TermEnd is one past the terminating semicolon, or End when the statement
	// has none (last statement).
	TermEnd int
}

// Text returns the statement text.
func (r Range) Text(s string) string { return s[r.Start:r.End] }

// Split returns the statements of text in order. Chunks holding only
// whitespace and comments are skipped. It never panics on malformed input:
// unterminated strings and comments run to the end of the text.
func Split(d Dialect, text string) []Range {
	s := scanner{d: d, text: text}
	return s.run()
}

// At returns the index of the statement the cursor (a byte offset) belongs
// to. A cursor inside a statement or right after its semicolon selects that
// statement; a cursor in the gap between statements selects the previous one
// (the user just finished typing it), or the next one if there is no previous.
func At(ranges []Range, cursor int) (int, bool) {
	if len(ranges) == 0 {
		return 0, false
	}
	for i, r := range ranges {
		if cursor < r.Start {
			if i == 0 {
				return 0, true
			}
			return i - 1, true
		}
		if cursor <= r.TermEnd {
			return i, true
		}
	}
	return len(ranges) - 1, true
}

// Overlapping returns the statements that overlap the byte range [start, end).
// A statement qualifies if any part of it lies inside the range.
func Overlapping(ranges []Range, start, end int) []int {
	var out []int
	for i, r := range ranges {
		if r.End > start && r.Start < end {
			out = append(out, i)
		}
	}
	return out
}

type scanner struct {
	d    Dialect
	text string
	pos  int
}

func isIdentStart(c byte) bool {
	return c == '_' || c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z' || c >= 0x80
}

func isIdentPart(c byte) bool { return isIdentStart(c) || c >= '0' && c <= '9' || c == '$' }

func isSpace(c byte) bool {
	return c == ' ' || c == '\t' || c == '\n' || c == '\r' || c == '\f' || c == '\v'
}

// stmtState tracks what the current statement is, to detect body blocks.
type stmtState struct {
	words      []string // first few words, upper-case
	prevWord   string
	inBlock    int  // BEGIN ... END nesting that hides semicolons
	caseDepth  int  // CASE ... END inside a block
	blockStart bool // statement kind allows a body block
}

func (st *stmtState) word(d Dialect, w string) {
	up := strings.ToUpper(w)
	if len(st.words) < 8 {
		st.words = append(st.words, up)
		st.blockStart = bodyStatement(d, st.words)
	}
	switch {
	case st.blockStart && up == "BEGIN" && st.inBlock == 0 && d == SQLite:
		st.inBlock = 1
	case st.blockStart && up == "ATOMIC" && st.prevWord == "BEGIN" && st.inBlock == 0 && d == Postgres:
		st.inBlock = 1
	case st.inBlock > 0 && up == "CASE":
		st.caseDepth++
	case st.inBlock > 0 && up == "END":
		if st.caseDepth > 0 {
			st.caseDepth--
		} else {
			st.inBlock--
		}
	}
	st.prevWord = up
}

// bodyStatement reports whether the leading words start a statement that can
// contain a semicolon-bearing body.
func bodyStatement(d Dialect, w []string) bool {
	i := 0
	if len(w) == 0 || w[0] != "CREATE" {
		return false
	}
	i++
	skip := func(names ...string) {
		for i < len(w) {
			ok := false
			for _, n := range names {
				if w[i] == n {
					ok = true
				}
			}
			if !ok {
				return
			}
			i++
		}
	}
	switch d {
	case SQLite:
		skip("TEMP", "TEMPORARY")
		return i < len(w) && w[i] == "TRIGGER"
	case Postgres:
		skip("OR", "REPLACE")
		return i < len(w) && (w[i] == "FUNCTION" || w[i] == "PROCEDURE")
	}
	return false
}

func (s *scanner) run() []Range {
	var out []Range
	text := s.text
	n := len(text)
	var (
		st       stmtState
		start    = -1
		lastTok  int
		inWord   bool
		wordFrom int
	)
	flushWord := func(end int) {
		if inWord {
			if wordFrom == 0 || text[wordFrom-1] != '.' {
				st.word(s.d, text[wordFrom:end])
			}
			inWord = false
		}
	}
	markTok := func(from, to int) {
		if start < 0 {
			start = from
		}
		lastTok = to
	}
	endStmt := func(termEnd int) {
		if start >= 0 {
			out = append(out, Range{Start: start, End: lastTok, TermEnd: termEnd})
		}
		start = -1
		st = stmtState{}
	}

	for s.pos < n {
		c := text[s.pos]
		switch {
		case isSpace(c):
			flushWord(s.pos)
			s.pos++
		case c == '-' && s.pos+1 < n && text[s.pos+1] == '-':
			flushWord(s.pos)
			s.skipLine()
		case c == '/' && s.pos+1 < n && text[s.pos+1] == '*':
			flushWord(s.pos)
			s.skipBlockComment()
		case c == ';':
			flushWord(s.pos)
			s.pos++
			if st.inBlock > 0 {
				markTok(s.pos-1, s.pos)
				continue
			}
			endStmt(s.pos)
		case c == '\'':
			flushWord(s.pos)
			from := s.pos
			escapes := s.d == Postgres && from > 0 && (text[from-1] == 'E' || text[from-1] == 'e') &&
				(from < 2 || !isIdentPart(text[from-2]))
			s.skipQuoted('\'', escapes)
			markTok(from, s.pos)
			st.prevWord = ""
		case c == '"' || (s.d == SQLite && c == '`'):
			flushWord(s.pos)
			from := s.pos
			s.skipQuoted(c, false)
			markTok(from, s.pos)
			st.prevWord = ""
		case s.d == SQLite && c == '[':
			flushWord(s.pos)
			from := s.pos
			if i := strings.IndexByte(text[s.pos:], ']'); i >= 0 {
				s.pos += i + 1
			} else {
				s.pos = n
			}
			markTok(from, s.pos)
			st.prevWord = ""
		case s.d == Postgres && c == '$' && (s.pos == 0 || !isIdentPart(text[s.pos-1])):
			flushWord(s.pos)
			from := s.pos
			if tag, ok := s.dollarTag(); ok {
				s.skipDollar(tag)
			} else {
				s.pos++
			}
			markTok(from, s.pos)
			st.prevWord = ""
		default:
			if isIdentStart(c) && !inWord && (s.pos == 0 || !isIdentPart(text[s.pos-1])) {
				inWord = true
				wordFrom = s.pos
			} else if !isIdentPart(c) {
				flushWord(s.pos)
			}
			// advance by one rune for non-ASCII so ranges stay on boundaries
			size := 1
			if c >= 0x80 {
				_, size = utf8.DecodeRuneInString(text[s.pos:])
			}
			markTok(s.pos, s.pos+size)
			s.pos += size
		}
	}
	flushWord(n)
	endStmt(lastTok)
	return out
}

func (s *scanner) skipLine() {
	i := strings.IndexByte(s.text[s.pos:], '\n')
	if i < 0 {
		s.pos = len(s.text)
		return
	}
	s.pos += i + 1
}

func (s *scanner) skipBlockComment() {
	depth := 1
	s.pos += 2
	for s.pos < len(s.text) {
		switch {
		case s.d == Postgres && strings.HasPrefix(s.text[s.pos:], "/*"):
			depth++
			s.pos += 2
		case strings.HasPrefix(s.text[s.pos:], "*/"):
			depth--
			s.pos += 2
			if depth == 0 {
				return
			}
		default:
			s.pos++
		}
	}
}

// skipQuoted skips a quoted run starting at the opening quote. A doubled
// quote is an escaped quote; with backslash set, \x escapes the next byte.
func (s *scanner) skipQuoted(q byte, backslash bool) {
	s.pos++
	for s.pos < len(s.text) {
		c := s.text[s.pos]
		switch {
		case backslash && c == '\\':
			s.pos += 2
		case c == q:
			if s.pos+1 < len(s.text) && s.text[s.pos+1] == q {
				s.pos += 2
				continue
			}
			s.pos++
			return
		default:
			s.pos++
		}
	}
	s.pos = len(s.text)
}

// dollarTag reports the full opening tag ("$$" or "$name$") at s.pos.
func (s *scanner) dollarTag() (string, bool) {
	t := s.text[s.pos:]
	if len(t) < 2 {
		return "", false
	}
	if t[1] == '$' {
		return "$$", true
	}
	if !isIdentStart(t[1]) {
		return "", false
	}
	for i := 2; i < len(t); i++ {
		if t[i] == '$' {
			return t[:i+1], true
		}
		if !isIdentPart(t[i]) || t[i] == '$' {
			return "", false
		}
	}
	return "", false
}

func (s *scanner) skipDollar(tag string) {
	s.pos += len(tag)
	if i := strings.Index(s.text[s.pos:], tag); i >= 0 {
		s.pos += i + len(tag)
		return
	}
	s.pos = len(s.text)
}
