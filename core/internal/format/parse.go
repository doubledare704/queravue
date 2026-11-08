package format

import (
	"strings"

	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

type nodeKind int

const (
	atomNode nodeKind = iota
	groupNode
	commentNode
)

type token struct {
	text          string
	kind          sqlsplit.TokenKind
	adjacent      bool
	newlineBefore bool
	keyword       bool
}

type node struct {
	kind  nodeKind
	tok   token
	close token
	kids  []node
}

func (n node) upperWord() string {
	if n.kind == atomNode && n.tok.kind == sqlsplit.TokenWord {
		return strings.ToUpper(n.tok.text)
	}
	return ""
}

func (n node) isPunct(text string) bool {
	return n.kind == atomNode && n.tok.kind == sqlsplit.TokenPunct && n.tok.text == text
}

func (n node) isOwnLineComment() bool { return n.kind == commentNode && n.tok.newlineBefore }

func isLineComment(text string) bool { return !strings.HasPrefix(text, "/*") }

func parse(d sqlsplit.Dialect, text string) ([]node, bool) {
	frames := [][]node{nil}
	var opens []token
	sawSpace, sawNewline := false, false
	for _, t := range sqlsplit.Tokenize(d, text) {
		s := t.Text(text)
		if t.Kind == sqlsplit.TokenSpace {
			sawSpace = true
			sawNewline = sawNewline || strings.Contains(s, "\n")
			continue
		}
		tk := token{text: s, kind: t.Kind, adjacent: !sawSpace, newlineBefore: sawNewline}
		sawSpace, sawNewline = false, false
		top := len(frames) - 1
		switch {
		case t.Kind == sqlsplit.TokenComment:
			if trimmed := strings.TrimRight(s, "\r\n"); trimmed != s {
				tk.text = trimmed
				sawSpace, sawNewline = true, true
			}
			frames[top] = append(frames[top], node{kind: commentNode, tok: tk})
		case t.Kind == sqlsplit.TokenPunct && s == "(":
			frames = append(frames, nil)
			opens = append(opens, tk)
		case t.Kind == sqlsplit.TokenPunct && s == ")":
			if top == 0 {
				return nil, false
			}
			kids := frames[top]
			open := opens[len(opens)-1]
			frames, opens = frames[:top], opens[:len(opens)-1]
			frames[top-1] = append(frames[top-1], node{kind: groupNode, tok: open, close: tk, kids: kids})
		default:
			if n := len(frames[top]); n > 0 && mergesIntoOperator(d, frames[top][n-1], tk) {
				frames[top][n-1].tok.text += tk.text
				continue
			}
			frames[top] = append(frames[top], node{kind: atomNode, tok: tk})
		}
	}
	if len(frames) != 1 {
		return nil, false
	}
	return frames[0], true
}

func supported(nodes []node, d sqlsplit.Dialect) bool {
	for _, n := range nodes {
		if n.kind == commentNode {
			continue
		}
		if n.kind == groupNode {
			return isSubquery(n.kids)
		}
		switch n.upperWord() {
		case "SELECT", "WITH", "INSERT", "UPDATE", "DELETE", "VALUES":
			return true
		case "REPLACE":
			return d == sqlsplit.MySQL || d == sqlsplit.SQLite
		}
		return false
	}
	return false
}

func isSubquery(kids []node) bool {
	for _, k := range kids {
		if k.kind == commentNode {
			continue
		}
		switch k.upperWord() {
		case "SELECT", "WITH", "VALUES":
			return true
		}
		return false
	}
	return false
}

const operatorChars = "+-*/<>=~!@#%^&|?:"

// A run of adjacent operator characters is one operator, except that a
// trailing + or - belongs to the next operand unless the run contains one of
// ~ ! @ # % ^ & | ? (PostgreSQL's lexing rule).
func mergesIntoOperator(d sqlsplit.Dialect, prev node, cur token) bool {
	if prev.kind != atomNode || prev.tok.kind != sqlsplit.TokenPunct || cur.kind != sqlsplit.TokenPunct || !cur.adjacent {
		return false
	}
	run, c := prev.tok.text, cur.text
	if len(c) != 1 || !strings.Contains(operatorChars, c) || !strings.Contains(operatorChars, run[len(run)-1:]) {
		return false
	}
	switch {
	case run == ":" || run == "::":
		return c == ":" && run == ":" || c == "=" && run == ":"
	case strings.ContainsAny(run+c, ":?@#"):
		return d == sqlsplit.Postgres && !strings.Contains(run, ":") && c != ":"
	case c == "+" || c == "-":
		return strings.ContainsAny(run, "~!%^&|")
	}
	return true
}
