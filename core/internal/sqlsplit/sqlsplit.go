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
	// MySQL (also MariaDB and TiDB): backslash escapes in '...' and "..."
	// strings, backtick identifiers, # and "-- " line comments, and the
	// DELIMITER client command.
	MySQL
	// MSSQL (SQL Server): [ident] with ]] escapes, N'...' strings, nested
	// block comments, the GO batch separator (a line of its own, optional
	// count), and CREATE/ALTER PROCEDURE, FUNCTION, TRIGGER and VIEW bodies,
	// which run to the end of the batch.
	MSSQL
	// ClickHouse: backslash escapes in '...', backtick and "..." identifiers,
	// # and -- line comments, no DELIMITER command.
	ClickHouse
	// Oracle: q'[...]' alternative quoting, and PL/SQL blocks (BEGIN, DECLARE,
	// CREATE PROCEDURE, FUNCTION, PACKAGE, TRIGGER, TYPE BODY), which run to a
	// "/" on a line of its own. The slash ends any statement.
	Oracle
)

func (d Dialect) backslashEscapes() bool { return d == MySQL || d == ClickHouse }

func (d Dialect) hashComments() bool { return d == MySQL || d == ClickHouse }

func (d Dialect) backtickIdents() bool { return d == MySQL || d == ClickHouse || d == SQLite }

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
	s := scanner{d: d, text: text, delim: ";"}
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
	d     Dialect
	text  string
	pos   int
	delim string // statement terminator; ";" unless a DELIMITER command changed it
}

// atDelim reports whether the terminator starts at s.pos.
func (s *scanner) atDelim() bool {
	return strings.HasPrefix(s.text[s.pos:], s.delim)
}

// mysqlDelimiterCmd handles a DELIMITER client command at s.pos (only valid
// before the first token of a statement). It returns true if one was consumed.
func (s *scanner) mysqlDelimiterCmd() bool {
	const kw = "delimiter"
	t := s.text[s.pos:]
	if len(t) <= len(kw) || !strings.EqualFold(t[:len(kw)], kw) || (t[len(kw)] != ' ' && t[len(kw)] != '\t') {
		return false
	}
	end := strings.IndexByte(t, '\n')
	if end < 0 {
		end = len(t)
	}
	arg := strings.TrimSpace(t[len(kw):end])
	if arg == "" {
		return false
	}
	if f := strings.Fields(arg); len(f) > 0 {
		arg = f[0]
	}
	s.delim = arg
	s.pos += end
	return true
}

// mysqlDashComment reports whether "--" at pos starts a comment: MySQL
// requires whitespace (or end of input) after the dashes.
func mysqlDashComment(text string, pos int) bool {
	return pos+2 >= len(text) || isSpace(text[pos+2])
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
	batchBody  bool // MSSQL: statement body runs to the next GO, ';' does not end it
}

func (st *stmtState) word(d Dialect, w string) {
	up := strings.ToUpper(w)
	if len(st.words) < 8 {
		st.words = append(st.words, up)
		st.blockStart = bodyStatement(d, st.words)
		if (d == MSSQL || d == Oracle) && st.blockStart {
			st.batchBody = true
		}
	}
	if d == MSSQL || d == Oracle {
		return
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
	if d == MSSQL {
		return mssqlBodyStatement(w)
	}
	if d == Oracle {
		return oracleBodyStatement(w)
	}
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

// mssqlBodyStatement reports whether the leading words start a CREATE or
// ALTER of an object whose body may hold semicolons.
func mssqlBodyStatement(w []string) bool {
	if len(w) < 2 || (w[0] != "CREATE" && w[0] != "ALTER") {
		return false
	}
	i := 1
	if i+1 < len(w) && w[i] == "OR" && w[i+1] == "ALTER" {
		i += 2
	}
	if i >= len(w) {
		return false
	}
	switch w[i] {
	case "PROC", "PROCEDURE", "FUNCTION", "TRIGGER", "VIEW":
		return true
	}
	return false
}

var oracleCreateModifiers = map[string]bool{
	"OR": true, "REPLACE": true, "EDITIONABLE": true, "NONEDITIONABLE": true, "FORCE": true, "NOFORCE": true,
}

// oracleBodyStatement reports whether the leading words start a PL/SQL block
// or a stored unit whose body holds semicolons.
func oracleBodyStatement(w []string) bool {
	if len(w) == 0 {
		return false
	}
	if w[0] == "BEGIN" || w[0] == "DECLARE" {
		return true
	}
	if w[0] != "CREATE" {
		return false
	}
	i := 1
	for i < len(w) && oracleCreateModifiers[w[i]] {
		i++
	}
	if i >= len(w) {
		return false
	}
	switch w[i] {
	case "PROCEDURE", "FUNCTION", "PACKAGE", "TRIGGER":
		return true
	case "TYPE":
		return i+1 < len(w) && w[i+1] == "BODY"
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
		if s.d == MySQL && start < 0 && !inWord && s.mysqlDelimiterCmd() {
			continue
		}
		if s.d == MSSQL && (c == 'g' || c == 'G') && s.mssqlGoLine() {
			flushWord(s.pos)
			endStmt(s.pos)
			continue
		}
		if s.d == Oracle && c == '/' && s.oracleSlashLine() {
			flushWord(s.pos)
			s.pos++
			endStmt(s.pos)
			continue
		}
		switch {
		case isSpace(c):
			flushWord(s.pos)
			s.pos++
		case s.atDelim():
			flushWord(s.pos)
			s.pos += len(s.delim)
			if st.inBlock > 0 || st.batchBody {
				markTok(s.pos-len(s.delim), s.pos)
				continue
			}
			endStmt(s.pos)
		case c == '-' && s.pos+1 < n && text[s.pos+1] == '-' && (s.d != MySQL || mysqlDashComment(text, s.pos)):
			flushWord(s.pos)
			s.skipLine()
		case c == '#' && s.d.hashComments():
			flushWord(s.pos)
			s.skipLine()
		case c == '/' && s.pos+1 < n && text[s.pos+1] == '*':
			flushWord(s.pos)
			s.skipBlockComment()
		case c == '\'':
			flushWord(s.pos)
			from := s.pos
			if s.skipOracleQuote() {
				markTok(from, s.pos)
				st.prevWord = ""
				continue
			}
			escapes := s.d.backslashEscapes() || (s.d == Postgres && from > 0 && (text[from-1] == 'E' || text[from-1] == 'e') &&
				(from < 2 || !isIdentPart(text[from-2])))
			s.skipQuoted('\'', escapes)
			markTok(from, s.pos)
			st.prevWord = ""
		case c == '"' || (s.d.backtickIdents() && c == '`'):
			flushWord(s.pos)
			from := s.pos
			s.skipQuoted(c, s.d == MySQL && c == '"')
			markTok(from, s.pos)
			st.prevWord = ""
		case (s.d == SQLite || s.d == MSSQL) && c == '[':
			flushWord(s.pos)
			from := s.pos
			s.skipBracket()
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
		case (s.d == Postgres || s.d == MSSQL) && strings.HasPrefix(s.text[s.pos:], "/*"):
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

// skipBracket skips a [bracketed identifier] starting at s.pos. In MSSQL a
// doubled ]] is an escaped bracket.
func (s *scanner) skipBracket() {
	s.pos++
	for s.pos < len(s.text) {
		if s.text[s.pos] == ']' {
			if s.d == MSSQL && s.pos+1 < len(s.text) && s.text[s.pos+1] == ']' {
				s.pos += 2
				continue
			}
			s.pos++
			return
		}
		s.pos++
	}
}

// mssqlGoLine reports whether the text at s.pos is a GO batch separator: the
// word GO alone on its line, with an optional repeat count and trailing
// comment. If so it advances s.pos to the end of the line.
func (s *scanner) mssqlGoLine() bool {
	t := s.text
	// Only whitespace may precede GO on its line.
	for i := s.pos - 1; i >= 0 && t[i] != '\n'; i-- {
		if t[i] != ' ' && t[i] != '\t' && t[i] != '\r' {
			return false
		}
	}
	if s.pos+2 > len(t) || !strings.EqualFold(t[s.pos:s.pos+2], "go") {
		return false
	}
	i := s.pos + 2
	skipBlanks := func() {
		for i < len(t) && (t[i] == ' ' || t[i] == '\t') {
			i++
		}
	}
	if i < len(t) && !isSpace(t[i]) && t[i] != '-' {
		return false // e.g. "gone"
	}
	skipBlanks()
	for i < len(t) && t[i] >= '0' && t[i] <= '9' {
		i++
	}
	skipBlanks()
	if i < len(t) && t[i] == '-' && i+1 < len(t) && t[i+1] == '-' {
		for i < len(t) && t[i] != '\n' {
			i++
		}
	}
	if i < len(t) && t[i] != '\n' && t[i] != '\r' {
		return false
	}
	s.pos = i
	return true
}

// oracleSlashLine reports whether the text at s.pos is a "/" alone on its
// line, apart from blanks.
func (s *scanner) oracleSlashLine() bool {
	t := s.text
	for i := s.pos - 1; i >= 0 && t[i] != '\n'; i-- {
		if t[i] != ' ' && t[i] != '\t' && t[i] != '\r' {
			return false
		}
	}
	for i := s.pos + 1; i < len(t) && t[i] != '\n'; i++ {
		if t[i] != ' ' && t[i] != '\t' && t[i] != '\r' {
			return false
		}
	}
	return true
}

var oracleQuoteClosers = map[byte]byte{'[': ']', '{': '}', '(': ')', '<': '>'}

// skipOracleQuote skips a q'[...]' or nq'[...]' literal when the quote at
// s.pos opens one, and reports whether it did.
func (s *scanner) skipOracleQuote() bool {
	t := s.text
	if s.d != Oracle || s.pos < 1 || s.pos+1 >= len(t) {
		return false
	}
	prefix := t[s.pos-1]
	if prefix != 'q' && prefix != 'Q' {
		return false
	}
	from := s.pos - 1
	if from > 0 && (t[from-1] == 'n' || t[from-1] == 'N') {
		from--
	}
	if from > 0 && isIdentPart(t[from-1]) {
		return false
	}
	open := t[s.pos+1]
	if isSpace(open) || open == '\'' {
		return false
	}
	closer, paired := oracleQuoteClosers[open]
	if !paired {
		closer = open
	}
	for i := s.pos + 2; i+1 < len(t); i++ {
		if t[i] == closer && t[i+1] == '\'' {
			s.pos = i + 2
			return true
		}
	}
	s.pos = len(t)
	return true
}
