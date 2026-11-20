package mongosql

import (
	"strings"

	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

type token struct {
	kind  sqlsplit.TokenKind
	start int
	end   int
	text  string
	up    string
}

func (t token) isWord(w string) bool { return t.kind == sqlsplit.TokenWord && t.up == w }

func (t token) isPunct(p string) bool { return t.kind == sqlsplit.TokenPunct && t.text == p }

func (t token) isIdent() bool {
	return t.kind == sqlsplit.TokenWord || t.kind == sqlsplit.TokenQuotedIdent
}

func (t token) identName() string {
	if t.kind != sqlsplit.TokenQuotedIdent {
		return t.text
	}
	quote := t.text[:1]
	return strings.ReplaceAll(t.text[1:len(t.text)-1], quote+quote, quote)
}

func (t token) stringValue() string {
	return strings.ReplaceAll(t.text[1:len(t.text)-1], "''", "'")
}

func lex(sql string) ([]token, *queravuev1.QueryBuilderError) {
	raw := sqlsplit.Tokenize(sqlsplit.MongoSQL, sql)
	out := make([]token, 0, len(raw))
	for _, r := range raw {
		text := r.Text(sql)
		switch r.Kind {
		case sqlsplit.TokenSpace:
			continue
		case sqlsplit.TokenComment:
			if strings.HasPrefix(text, "/*") && (len(text) < 4 || !strings.HasSuffix(text, "*/")) {
				return nil, parseError("unterminated block comment", r.Start)
			}
			continue
		case sqlsplit.TokenQuotedIdent:
			if !isClosedQuote(text) {
				return nil, parseError("unterminated quoted identifier", r.Start)
			}
			if len(text) == 2 {
				return nil, parseError("empty quoted identifier", r.Start)
			}
		case sqlsplit.TokenString:
			if !isClosedQuote(text) {
				return nil, parseError("unterminated string literal", r.Start)
			}
		}
		tok := token{kind: r.Kind, start: r.Start, end: r.End, text: text}
		if r.Kind == sqlsplit.TokenWord {
			tok.up = strings.ToUpper(text)
		}
		out = append(out, tok)
	}
	return mergeOperators(mergeScientificNumbers(out)), nil
}

func isClosedQuote(text string) bool {
	if len(text) < 2 {
		return false
	}
	q := text[0]
	for i := 1; i < len(text); i++ {
		if text[i] != q {
			continue
		}
		if i+1 < len(text) && text[i+1] == q {
			i++
			continue
		}
		return i == len(text)-1
	}
	return false
}

func mergeScientificNumbers(toks []token) []token {
	out := make([]token, 0, len(toks))
	for i := 0; i < len(toks); i++ {
		if i+2 < len(toks) && toks[i].kind == sqlsplit.TokenNumber &&
			(strings.HasSuffix(toks[i].text, "e") || strings.HasSuffix(toks[i].text, "E")) &&
			(toks[i+1].isPunct("+") || toks[i+1].isPunct("-")) &&
			toks[i+2].kind == sqlsplit.TokenNumber &&
			toks[i].end == toks[i+1].start && toks[i+1].end == toks[i+2].start {
			out = append(out, token{
				kind:  sqlsplit.TokenNumber,
				start: toks[i].start,
				end:   toks[i+2].end,
				text:  toks[i].text + toks[i+1].text + toks[i+2].text,
			})
			i += 2
			continue
		}
		out = append(out, toks[i])
	}
	return out
}

var twoCharOperators = map[string]bool{"<=": true, ">=": true, "<>": true, "!=": true, "||": true, "==": true}

func mergeOperators(toks []token) []token {
	out := make([]token, 0, len(toks))
	for i := 0; i < len(toks); i++ {
		if i+1 < len(toks) && toks[i].kind == sqlsplit.TokenPunct && toks[i+1].kind == sqlsplit.TokenPunct &&
			toks[i].end == toks[i+1].start && twoCharOperators[toks[i].text+toks[i+1].text] {
			out = append(out, token{kind: sqlsplit.TokenPunct, start: toks[i].start, end: toks[i+1].end, text: toks[i].text + toks[i+1].text})
			i++
			continue
		}
		out = append(out, toks[i])
	}
	return out
}

func offsetOf(offset int) *uint32 {
	off := uint32(max(offset, 0)) //nolint:gosec // bounded by input string length
	return &off
}

func parseError(msg string, offset int) *queravuev1.QueryBuilderError {
	return &queravuev1.QueryBuilderError{
		Kind:    queravuev1.QueryBuilderErrorKind_QUERY_BUILDER_ERROR_KIND_PARSE,
		Message: msg,
		Offset:  offsetOf(offset),
	}
}

func unsupportedError(msg string, offset int) *queravuev1.QueryBuilderError {
	return &queravuev1.QueryBuilderError{
		Kind:    queravuev1.QueryBuilderErrorKind_QUERY_BUILDER_ERROR_KIND_UNSUPPORTED_CONSTRUCT,
		Message: msg,
		Offset:  offsetOf(offset),
	}
}
