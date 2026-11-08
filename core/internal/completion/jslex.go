package completion

import "strings"

type jsKind int

const (
	jsIdent jsKind = iota + 1
	jsString
	jsNumber
	jsPunct
	jsRegex
)

type jsToken struct {
	kind       jsKind
	text       string
	start, end int
	open       bool
}

type jsLexed struct {
	tokens    []jsToken
	inComment bool
}

func lexJS(text string) jsLexed {
	var out jsLexed
	i := 0
	for i < len(text) {
		c := text[i]
		switch {
		case c == ' ' || c == '\t' || c == '\n' || c == '\r':
			i++
		case c == '/' && i+1 < len(text) && text[i+1] == '/':
			j := strings.IndexByte(text[i:], '\n')
			if j < 0 {
				out.inComment = true
				return out
			}
			i += j + 1
		case c == '/' && i+1 < len(text) && text[i+1] == '*':
			j := strings.Index(text[i+2:], "*/")
			if j < 0 {
				out.inComment = true
				return out
			}
			i += j + 4
		case c == '\'' || c == '"' || c == '`':
			end, open := scanJSString(text, i)
			out.tokens = append(out.tokens, jsToken{kind: jsString, text: text[i:end], start: i, end: end, open: open})
			i = end
		case c == '/' && regexAllowed(out.tokens):
			end, open := scanJSRegex(text, i)
			out.tokens = append(out.tokens, jsToken{kind: jsRegex, text: text[i:end], start: i, end: end, open: open})
			i = end
		case isJSIdentStart(c):
			j := i + 1
			for j < len(text) && isJSIdentPart(text[j]) {
				j++
			}
			out.tokens = append(out.tokens, jsToken{kind: jsIdent, text: text[i:j], start: i, end: j})
			i = j
		case c >= '0' && c <= '9':
			j := i + 1
			for j < len(text) && (isJSIdentPart(text[j]) || text[j] == '.') {
				j++
			}
			out.tokens = append(out.tokens, jsToken{kind: jsNumber, text: text[i:j], start: i, end: j})
			i = j
		default:
			out.tokens = append(out.tokens, jsToken{kind: jsPunct, text: text[i : i+1], start: i, end: i + 1})
			i++
		}
	}
	return out
}

func isJSIdentStart(c byte) bool {
	return c == '_' || c == '$' || c >= 0x80 || c >= 'a' && c <= 'z' || c >= 'A' && c <= 'Z'
}

func isJSIdentPart(c byte) bool { return isJSIdentStart(c) || c >= '0' && c <= '9' }

func scanJSString(text string, start int) (end int, open bool) {
	quote := text[start]
	for i := start + 1; i < len(text); i++ {
		switch text[i] {
		case '\\':
			i++
		case quote:
			return i + 1, false
		}
	}
	return len(text), true
}

const regexPrecedingPunct = "(,:[{=!&|?;"

func regexAllowed(prev []jsToken) bool {
	if len(prev) == 0 {
		return true
	}
	last := prev[len(prev)-1]
	return last.kind == jsPunct && strings.Contains(regexPrecedingPunct, last.text)
}

func scanJSRegex(text string, start int) (end int, open bool) {
	inClass := false
	for i := start + 1; i < len(text); i++ {
		switch text[i] {
		case '\\':
			i++
		case '[':
			inClass = true
		case ']':
			inClass = false
		case '/':
			if !inClass {
				j := i + 1
				for j < len(text) && isJSIdentPart(text[j]) {
					j++
				}
				return j, false
			}
		case '\n':
			return i, true
		}
	}
	return len(text), true
}

func unquoteJS(text string) string {
	if text == "" {
		return text
	}
	body := text[1:]
	if n := len(body); n > 0 && body[n-1] == text[0] {
		body = body[:n-1]
	}
	return body
}
