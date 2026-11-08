package completion

import (
	"strings"

	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

// Clause says which part of a statement the cursor is in.
type Clause int

// Clauses.
const (
	ClauseNone Clause = iota
	ClauseSelect
	ClauseFrom
	ClauseOn
	ClauseWhere
	ClauseGroupBy
	ClauseOrderBy
	ClauseHaving
	ClauseInsertTarget
	ClauseInsertColumns
	ClauseUpdateTarget
	ClauseUpdateSet
	ClauseValues
	ClauseReturning
	ClauseLimit
)

// tableRef is a table, CTE or derived table in a FROM-like position.
type tableRef struct {
	schema  string
	name    string
	alias   string
	derived *derivedTable
}

// visibleName is what a qualifier must equal to refer to the table.
func (t tableRef) visibleName() string {
	if t.alias != "" {
		return t.alias
	}
	return t.name
}

type selectItem struct {
	name string
	star bool
	from string
}

// derivedTable is a subquery or CTE used as a table.
type derivedTable struct {
	explicit []string
	items    []selectItem
	inner    []tableRef
}

type cte struct {
	name    string
	derived *derivedTable
}

// Context is what the analyzer learned about the cursor position.
type Context struct {
	// Suppress is true inside string literals and comments, where nothing completes.
	Suppress bool
	Clause   Clause
	// Prefix is the identifier typed so far, unquoted.
	Prefix string
	// Quoted is true when the typed identifier started with a quote.
	Quoted bool
	// ReplaceStart and ReplaceEnd are byte offsets of the text a pick replaces.
	ReplaceStart, ReplaceEnd int
	// Qualifier holds the identifier parts before a dot, unquoted.
	Qualifier []string
	// Scope lists the tables of the cursor's query, innermost first, then outer queries.
	Scope []tableRef
	// CTEs lists the common table expressions visible at the cursor.
	CTEs []cte
	// SelectNames are output names of the cursor query's select list.
	SelectNames []string
	// AtTable is true when the cursor is where a table name belongs.
	AtTable bool
	// Tokens are the lexer tokens of the analyzed text, whitespace and comments included.
	Tokens []sqlsplit.Token
}

type sigToken struct {
	kind  sqlsplit.TokenKind
	start int
	end   int
	text  string
	up    string
}

func (t sigToken) isIdent() bool {
	return t.kind == sqlsplit.TokenWord || t.kind == sqlsplit.TokenQuotedIdent
}

func (t sigToken) isPunct(p string) bool { return t.kind == sqlsplit.TokenPunct && t.text == p }

func (t sigToken) isWord(w string) bool { return t.kind == sqlsplit.TokenWord && t.up == w }

type span struct {
	clause Clause
	at     int
}

type groupKind int

const (
	groupExpr groupKind = iota
	groupInsertColumns
	groupValues
)

type block struct {
	parent   *block
	from, to int
	open     int
	isQuery  bool
	group    groupKind
	spans    []span
	tables   []tableRef
	children []*block
	ctes     []cte
}

type parser struct {
	d   sqlsplit.Dialect
	sig []sigToken
}

// Analyze inspects text around the byte offset cursor.
func Analyze(d sqlsplit.Dialect, text string, cursor int) Context {
	cursor = max(0, min(cursor, len(text)))
	tokens := sqlsplit.Tokenize(d, text)
	ctx := Context{ReplaceStart: cursor, ReplaceEnd: cursor, Tokens: tokens}
	var sig []sigToken
	for _, t := range tokens {
		if t.Kind == sqlsplit.TokenSpace {
			continue
		}
		if cursorInsideLiteral(text, t, cursor) {
			ctx.Suppress = true
			return ctx
		}
		if t.Kind == sqlsplit.TokenComment {
			continue
		}
		raw := t.Text(text)
		st := sigToken{kind: t.Kind, start: t.Start, end: t.End, text: raw}
		if t.Kind == sqlsplit.TokenWord {
			st.up = strings.ToUpper(raw)
		}
		sig = append(sig, st)
	}

	typing := -1
	for i, t := range sig {
		if t.isIdent() && t.start < cursor && cursor <= t.end {
			typing = i
			break
		}
	}
	if typing >= 0 {
		t := sig[typing]
		ctx.Quoted = isQuotedIdent(t.text)
		ctx.Prefix = unquoteIdent(text[t.start:cursor])
		ctx.ReplaceStart, ctx.ReplaceEnd = t.start, t.end
	}

	before := typing
	if typing < 0 {
		before = 0
		for before < len(sig) && sig[before].end <= cursor {
			before++
		}
	}
	for q := before - 1; q >= 1 && sig[q].isPunct("."); q -= 2 {
		if !sig[q-1].isIdent() {
			break
		}
		ctx.Qualifier = append([]string{unquoteIdent(sig[q-1].text)}, ctx.Qualifier...)
	}

	if typing >= 0 {
		sig = append(sig[:typing:typing], sig[typing+1:]...)
	}
	cursorIdx := 0
	for cursorIdx < len(sig) && sig[cursorIdx].end <= cursor {
		cursorIdx++
	}

	p := parser{d: d, sig: sig}
	root := &block{from: 0, to: len(sig), isQuery: true}
	first := &block{parent: root, from: 0, to: len(sig), isQuery: true}
	root.children = append(root.children, first)
	p.parseInto(first, 0, len(sig))
	p.describe(&ctx, root, cursorIdx)
	return ctx
}

func (p *parser) matchParen(open, limit int) int {
	depth := 0
	for i := open; i < limit; i++ {
		switch {
		case p.sig[i].isPunct("("):
			depth++
		case p.sig[i].isPunct(")"):
			depth--
			if depth == 0 {
				return i
			}
		}
	}
	return limit
}

func (p *parser) word(i int) string {
	if i < 0 || i >= len(p.sig) {
		return ""
	}
	return p.sig[i].up
}

var wordsEndingTableRef = map[string]bool{
	"WHERE": true, "GROUP": true, "ORDER": true, "HAVING": true, "LIMIT": true, "OFFSET": true, "UNION": true,
	"INTERSECT": true, "EXCEPT": true, "JOIN": true, "INNER": true, "LEFT": true, "RIGHT": true, "FULL": true,
	"CROSS": true, "NATURAL": true, "ON": true, "USING": true, "SET": true, "VALUES": true, "RETURNING": true,
	"WINDOW": true, "FETCH": true, "FOR": true, "OUTPUT": true, "WITH": true, "STRAIGHT_JOIN": true, "OUTER": true,
	"PIVOT": true, "UNPIVOT": true, "LATERAL": true, "ONLY": true, "SELECT": true, "FROM": true, "INTO": true,
}

// parseInto fills b from sig[from:to), splitting at set operators.
func (p *parser) parseInto(b *block, from, to int) {
	i := from
	if p.word(i) == "WITH" {
		i = p.parseCTEs(b, i+1, to)
	}
	expectTable := false
	for i < to {
		t := p.sig[i]
		switch {
		case t.isPunct("("):
			end := p.matchParen(i, to)
			child := &block{parent: b, from: i + 1, to: end, open: i, isQuery: p.startsQuery(i+1, end)}
			child.group = p.groupKindAt(b, i)
			p.parseInto(child, i+1, end)
			b.children = append(b.children, child)
			if expectTable && child.isQuery {
				ref := tableRef{derived: p.derive(child)}
				i = p.alias(&ref, end+1, to)
				b.tables = append(b.tables, ref)
				expectTable = false
				continue
			}
			i = min(end+1, to)
			continue
		case t.kind != sqlsplit.TokenWord && t.kind != sqlsplit.TokenQuotedIdent:
			if t.isPunct(",") && len(b.spans) > 0 {
				switch b.spans[len(b.spans)-1].clause {
				case ClauseFrom, ClauseUpdateTarget:
					expectTable = true
				}
			}
			i++
			continue
		}
		if t.kind == sqlsplit.TokenWord {
			switch t.up {
			case "UNION", "INTERSECT", "EXCEPT":
				b.to = i
				next := &block{parent: b.parent, from: i + 1, to: to, isQuery: true}
				if b.parent != nil {
					b.parent.children = append(b.parent.children, next)
				}
				p.parseInto(next, i+1, to)
				return
			case "SELECT":
				b.spans = append(b.spans, span{ClauseSelect, i})
				expectTable = false
				i++
				continue
			case "FROM":
				b.spans = append(b.spans, span{ClauseFrom, i})
				expectTable = true
				i++
				continue
			case "JOIN", "STRAIGHT_JOIN":
				b.spans = append(b.spans, span{ClauseFrom, i})
				expectTable = true
				i++
				continue
			case "APPLY":
				b.spans = append(b.spans, span{ClauseFrom, i})
				expectTable = true
				i++
				continue
			case "ON":
				if next := p.word(i + 1); next == "CONFLICT" || next == "DUPLICATE" {
					b.spans = append(b.spans, span{ClauseNone, i})
				} else {
					b.spans = append(b.spans, span{ClauseOn, i})
				}
				expectTable = false
				i++
				continue
			case "USING":
				b.spans = append(b.spans, span{ClauseOn, i})
				expectTable = false
				i++
				continue
			case "WHERE":
				b.spans = append(b.spans, span{ClauseWhere, i})
				expectTable = false
				i++
				continue
			case "GROUP":
				b.spans = append(b.spans, span{ClauseGroupBy, i})
				expectTable = false
				i++
				continue
			case "ORDER":
				b.spans = append(b.spans, span{ClauseOrderBy, i})
				expectTable = false
				i++
				continue
			case "HAVING":
				b.spans = append(b.spans, span{ClauseHaving, i})
				expectTable = false
				i++
				continue
			case "LIMIT", "OFFSET", "FETCH":
				b.spans = append(b.spans, span{ClauseLimit, i})
				expectTable = false
				i++
				continue
			case "INSERT", "REPLACE":
				if p.word(i+1) == "INTO" || p.word(i+1) == "OR" {
					j := i + 1
					for j < to && p.word(j) != "INTO" && j < i+4 {
						j++
					}
					if p.word(j) == "INTO" {
						b.spans = append(b.spans, span{ClauseInsertTarget, i})
						expectTable = true
						i = j + 1
						continue
					}
				}
			case "UPDATE":
				prev := p.word(i - 1)
				if prev != "FOR" && prev != "KEY" && prev != "DO" && prev != "ON" {
					b.spans = append(b.spans, span{ClauseUpdateTarget, i})
					expectTable = true
					i++
					continue
				}
				b.spans = append(b.spans, span{ClauseNone, i})
				i++
				continue
			case "SET":
				if i > b.from {
					b.spans = append(b.spans, span{ClauseUpdateSet, i})
				}
				expectTable = false
				i++
				continue
			case "VALUES":
				b.spans = append(b.spans, span{ClauseValues, i})
				expectTable = false
				i++
				continue
			case "RETURNING", "OUTPUT":
				b.spans = append(b.spans, span{ClauseReturning, i})
				expectTable = false
				i++
				continue
			}
		}
		if expectTable && !wordsEndingTableRef[t.up] {
			ref := tableRef{}
			j := p.qualifiedName(&ref, i, to)
			if p.sig2(j).isPunct("(") && lastClause(b.spans, j) != ClauseInsertTarget {
				end := p.matchParen(j, to)
				ref.derived = &derivedTable{}
				ref.schema = ""
				j = end + 1
			}
			j = p.alias(&ref, j, to)
			if ref.name != "" || ref.derived != nil {
				b.tables = append(b.tables, ref)
			}
			expectTable = false
			i = max(j, i+1)
			continue
		}
		i++
	}
}

func (p *parser) sig2(i int) sigToken {
	if i < 0 || i >= len(p.sig) {
		return sigToken{}
	}
	return p.sig[i]
}

func (p *parser) startsQuery(from, to int) bool {
	if from >= to {
		return false
	}
	w := p.word(from)
	return w == "SELECT" || w == "WITH"
}

func (p *parser) groupKindAt(parent *block, open int) groupKind {
	if len(parent.spans) == 0 {
		return groupExpr
	}
	last := parent.spans[len(parent.spans)-1]
	switch last.clause {
	case ClauseInsertTarget:
		if open > last.at+1 {
			return groupInsertColumns
		}
	case ClauseValues:
		return groupValues
	}
	return groupExpr
}

// qualifiedName reads name or schema.name (or db.schema.name) starting at i.
func (p *parser) qualifiedName(ref *tableRef, i, to int) int {
	var parts []string
	trailingDot := false
	for i < to && p.sig[i].isIdent() {
		parts = append(parts, unquoteIdent(p.sig[i].text))
		i++
		trailingDot = false
		if i < to && p.sig[i].isPunct(".") {
			i++
			trailingDot = true
			continue
		}
		break
	}
	if len(parts) == 0 || trailingDot {
		return i
	}
	ref.name = parts[len(parts)-1]
	if len(parts) >= 2 {
		ref.schema = parts[len(parts)-2]
	}
	return i
}

// alias reads an optional [AS] alias at i.
func (p *parser) alias(ref *tableRef, i, to int) int {
	if i < to && p.sig[i].isWord("AS") {
		i++
	}
	if i < to && p.sig[i].isIdent() && !wordsEndingTableRef[p.sig[i].up] {
		ref.alias = unquoteIdent(p.sig[i].text)
		i++
		if i < to && p.sig[i].isPunct("(") && ref.derived != nil {
			end := p.matchParen(i, to)
			ref.derived.explicit = p.identList(i+1, end)
			i = end + 1
		}
	}
	return min(i, to)
}

func (p *parser) identList(from, to int) []string {
	var out []string
	for i := from; i < to; i++ {
		if p.sig[i].isIdent() {
			out = append(out, unquoteIdent(p.sig[i].text))
		}
	}
	return out
}

// parseCTEs reads the WITH list starting after the WITH keyword and returns
// the index of the first token after it.
func (p *parser) parseCTEs(b *block, i, to int) int {
	if p.word(i) == "RECURSIVE" {
		i++
	}
	for i < to && p.sig[i].isIdent() {
		c := cte{name: unquoteIdent(p.sig[i].text), derived: &derivedTable{}}
		i++
		if i < to && p.sig[i].isPunct("(") && !p.startsQuery(i+1, to) {
			end := p.matchParen(i, to)
			c.derived.explicit = p.identList(i+1, end)
			i = min(end+1, to)
		}
		if p.word(i) == "AS" {
			i++
		}
		for p.word(i) == "NOT" || p.word(i) == "MATERIALIZED" {
			i++
		}
		if i < to && p.sig[i].isPunct("(") {
			end := p.matchParen(i, to)
			child := &block{parent: b, from: i + 1, to: end, open: i, isQuery: p.startsQuery(i+1, end)}
			p.parseInto(child, i+1, end)
			b.children = append(b.children, child)
			inner := p.derive(child)
			c.derived.items, c.derived.inner = inner.items, inner.inner
			i = min(end+1, to)
		}
		b.ctes = append(b.ctes, c)
		if i < to && p.sig[i].isPunct(",") {
			i++
			continue
		}
		break
	}
	return i
}

func (p *parser) derive(b *block) *derivedTable {
	return &derivedTable{items: p.selectItems(b), inner: b.tables}
}

func (p *parser) selectItems(b *block) []selectItem {
	start, end := -1, b.to
	for i, s := range b.spans {
		if s.clause == ClauseSelect && start < 0 {
			start = s.at + 1
			if i+1 < len(b.spans) {
				end = b.spans[i+1].at
			}
		}
	}
	if start < 0 {
		return nil
	}
	var items []selectItem
	depth, from := 0, start
	flush := func(to int) {
		if it, ok := p.itemName(from, to); ok {
			items = append(items, it)
		}
		from = to + 1
	}
	for i := start; i < end; i++ {
		switch {
		case p.sig[i].isPunct("("):
			depth++
		case p.sig[i].isPunct(")"):
			depth--
		case p.sig[i].isPunct(",") && depth == 0:
			flush(i)
		}
	}
	flush(end)
	return items
}

var notAliases = map[string]bool{"END": true, "NULL": true, "TRUE": true, "FALSE": true, "ASC": true, "DESC": true, "DISTINCT": true}

func (p *parser) itemName(from, to int) (selectItem, bool) {
	for from < to && (p.sig[from].isWord("DISTINCT") || p.sig[from].isWord("ALL")) {
		from++
	}
	n := to - from
	if n <= 0 {
		return selectItem{}, false
	}
	last := p.sig[to-1]
	if n == 1 && last.isPunct("*") {
		return selectItem{star: true}, true
	}
	if n == 3 && last.isPunct("*") && p.sig[to-2].isPunct(".") && p.sig[from].isIdent() {
		return selectItem{star: true, from: unquoteIdent(p.sig[from].text)}, true
	}
	if n >= 3 && p.sig[to-2].isWord("AS") && last.isIdent() {
		return selectItem{name: unquoteIdent(last.text)}, true
	}
	if !last.isIdent() || notAliases[last.up] {
		return selectItem{}, false
	}
	if n == 1 || p.sig[to-2].isPunct(".") {
		return selectItem{name: unquoteIdent(last.text)}, true
	}
	prev := p.sig[to-2]
	if prev.isIdent() || prev.isPunct(")") || prev.kind == sqlsplit.TokenNumber || prev.kind == sqlsplit.TokenString {
		return selectItem{name: unquoteIdent(last.text)}, true
	}
	return selectItem{}, false
}

// describe walks from root to the block holding the cursor and fills ctx.
func (p *parser) describe(ctx *Context, root *block, cursorIdx int) {
	chain := []*block{root}
	for cur := root; ; {
		var next *block
		for _, c := range cur.children {
			if c.from <= cursorIdx && cursorIdx <= c.to {
				next = c
				break
			}
		}
		if next == nil {
			break
		}
		chain = append(chain, next)
		cur = next
	}
	inner := chain[len(chain)-1]
	query := inner
	for query.parent != nil && !query.isQuery {
		query = query.parent
	}
	ctx.Clause = p.clauseFor(inner, cursorIdx)
	ctx.AtTable = p.atTableName(ctx.Clause, cursorIdx)
	if inner.group == groupInsertColumns && !inner.isQuery {
		ctx.Scope = append(ctx.Scope, inner.parent.tables...)
	}
	for q := query; q != nil; q = q.parent {
		if q.isQuery {
			ctx.Scope = append(ctx.Scope, q.tables...)
		}
	}
	for _, b := range chain {
		ctx.CTEs = append(ctx.CTEs, b.ctes...)
	}
	for _, it := range p.selectItems(query) {
		if !it.star && it.name != "" {
			ctx.SelectNames = append(ctx.SelectNames, it.name)
		}
	}
}

func (p *parser) clauseFor(inner *block, cursorIdx int) Clause {
	if !inner.isQuery {
		switch inner.group {
		case groupInsertColumns:
			return ClauseInsertColumns
		case groupValues:
			return ClauseValues
		}
		return p.clauseAtOpen(inner)
	}
	return lastClause(inner.spans, cursorIdx)
}

func (p *parser) clauseAtOpen(inner *block) Clause {
	parent := inner.parent
	if parent == nil {
		return ClauseNone
	}
	if !parent.isQuery {
		return p.clauseAtOpen(parent)
	}
	return lastClause(parent.spans, inner.open)
}

func lastClause(spans []span, idx int) Clause {
	c := ClauseNone
	for _, s := range spans {
		if s.at < idx {
			c = s.clause
		}
	}
	return c
}

var tableIntroducers = map[string]bool{
	"FROM": true, "JOIN": true, "INTO": true, "UPDATE": true, "ONLY": true, "LATERAL": true, "APPLY": true,
	"STRAIGHT_JOIN": true, "TABLE": true,
}

func (p *parser) atTableName(clause Clause, cursorIdx int) bool {
	if cursorIdx == 0 || cursorIdx > len(p.sig) {
		return false
	}
	prev := p.sig[cursorIdx-1]
	if prev.kind == sqlsplit.TokenWord && tableIntroducers[prev.up] {
		return true
	}
	return prev.isPunct(",") && (clause == ClauseFrom || clause == ClauseUpdateTarget)
}

// cursorInsideLiteral reports whether the cursor is inside a string or
// comment token, including at the end of one that is not closed.
func cursorInsideLiteral(text string, t sqlsplit.Token, cursor int) bool {
	if t.Kind != sqlsplit.TokenString && t.Kind != sqlsplit.TokenComment {
		return false
	}
	if cursor <= t.Start || cursor > t.End {
		return false
	}
	if cursor < t.End {
		return true
	}
	raw := t.Text(text)
	if t.Kind == sqlsplit.TokenComment {
		if strings.HasPrefix(raw, "/*") {
			return len(raw) < 4 || !strings.HasSuffix(raw, "*/")
		}
		return !strings.HasSuffix(raw, "\n")
	}
	if raw[0] == '$' {
		tag := raw[:strings.IndexByte(raw[1:], '$')+2]
		return len(raw) < 2*len(tag) || !strings.HasSuffix(raw, tag)
	}
	return len(raw) < 2 || raw[len(raw)-1] != raw[0]
}
