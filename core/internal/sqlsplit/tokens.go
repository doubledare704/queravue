package sqlsplit

// TokenKind classifies a Token.
type TokenKind int

// Token kinds.
const (
	TokenSpace TokenKind = iota + 1
	TokenComment
	TokenWord
	TokenQuotedIdent
	TokenString
	TokenNumber
	TokenPunct
)

// Token is a lexical element located by byte offsets into the tokenized text.
type Token struct {
	Kind  TokenKind
	Start int
	End   int
}

// Text returns the token text.
func (t Token) Text(s string) string { return s[t.Start:t.End] }

// Tokenize splits text into tokens that cover it completely: concatenating
// their texts gives text back. Unterminated strings, identifiers and comments
// run to the end of the text. It does not parse SQL.
func Tokenize(d Dialect, text string) []Token {
	s := scanner{d: d, text: text, delim: ";"}
	out := make([]Token, 0, len(text)/4+1)
	for s.pos < len(text) {
		from := s.pos
		kind := s.next()
		out = append(out, Token{Kind: kind, Start: from, End: s.pos})
	}
	return out
}

func (s *scanner) next() TokenKind {
	text := s.text
	c := text[s.pos]
	n := len(text)
	switch {
	case isSpace(c):
		for s.pos < n && isSpace(text[s.pos]) {
			s.pos++
		}
		return TokenSpace
	case c == '-' && s.pos+1 < n && text[s.pos+1] == '-' && (s.d != MySQL || mysqlDashComment(text, s.pos)):
		s.skipLine()
		return TokenComment
	case c == '#' && s.d == MySQL:
		s.skipLine()
		return TokenComment
	case c == '/' && s.pos+1 < n && text[s.pos+1] == '*':
		s.skipBlockComment()
		return TokenComment
	case c == '\'':
		from := s.pos
		if s.skipOracleQuote() {
			return TokenString
		}
		escapes := s.d == MySQL || (s.d == Postgres && from > 0 && (text[from-1] == 'E' || text[from-1] == 'e') &&
			(from < 2 || !isIdentPart(text[from-2])))
		s.skipQuoted('\'', escapes)
		return TokenString
	case c == '"' && s.d == MySQL:
		s.skipQuoted(c, true)
		return TokenString
	case c == '"' || (s.d == SQLite || s.d == MySQL) && c == '`':
		s.skipQuoted(c, false)
		return TokenQuotedIdent
	case (s.d == SQLite || s.d == MSSQL) && c == '[':
		s.skipBracket()
		return TokenQuotedIdent
	case s.d == Postgres && c == '$' && (s.pos == 0 || !isIdentPart(text[s.pos-1])):
		if tag, ok := s.dollarTag(); ok {
			s.skipDollar(tag)
			return TokenString
		}
		s.pos++
		return TokenPunct
	case c >= '0' && c <= '9':
		for s.pos < n && (isIdentPart(text[s.pos]) || text[s.pos] == '.' && s.pos+1 < n && text[s.pos+1] >= '0' && text[s.pos+1] <= '9') {
			s.pos++
		}
		return TokenNumber
	case isIdentStart(c):
		for s.pos < n && isIdentPart(text[s.pos]) {
			s.pos++
		}
		return TokenWord
	}
	s.pos++
	return TokenPunct
}
