package mongosql

import (
	"fmt"
	"strconv"
	"unicode/utf8"

	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

var writeStatements = map[string]bool{
	"INSERT": true, "UPDATE": true, "DELETE": true, "MERGE": true, "REPLACE": true, "UPSERT": true,
	"CREATE": true, "DROP": true, "ALTER": true, "TRUNCATE": true, "RENAME": true, "GRANT": true, "REVOKE": true,
}

var reservedWords = map[string]bool{
	"SELECT": true, "DISTINCT": true, "ALL": true, "FROM": true, "WHERE": true, "GROUP": true, "BY": true,
	"HAVING": true, "ORDER": true, "LIMIT": true, "OFFSET": true, "FETCH": true, "FOR": true, "WINDOW": true,
	"UNION": true, "INTERSECT": true, "EXCEPT": true, "MINUS": true, "INTO": true,
	"JOIN": true, "INNER": true, "LEFT": true, "RIGHT": true, "FULL": true, "OUTER": true, "CROSS": true,
	"NATURAL": true, "LATERAL": true, "ON": true, "USING": true, "AS": true,
	"AND": true, "OR": true, "NOT": true, "IN": true, "IS": true, "LIKE": true, "ILIKE": true, "BETWEEN": true,
	"ESCAPE": true, "ASC": true, "DESC": true, "NULLS": true, "NULL": true, "TRUE": true, "FALSE": true,
	"CASE": true, "WHEN": true, "THEN": true, "ELSE": true, "END": true, "EXISTS": true, "OVER": true,
	"SIMILAR": true, "REGEXP": true, "RLIKE": true,
}

var aggregateNames = map[string]bool{"COUNT": true, "SUM": true, "AVG": true, "MIN": true, "MAX": true}

type parser struct {
	sql  string
	toks []token
	pos  int
}

func parse(sql string) (*statement, *queravuev1.QueryBuilderError) {
	toks, err := lex(sql)
	if err != nil {
		return nil, err
	}
	if len(toks) > 0 && toks[len(toks)-1].isPunct(";") {
		toks = toks[:len(toks)-1]
	}
	if len(toks) == 0 {
		return nil, parseError("empty SQL statement", 0)
	}
	for _, tok := range toks {
		if tok.isPunct(";") {
			return nil, unsupportedError("multiple statements are not supported", tok.start)
		}
	}
	p := &parser{sql: sql, toks: toks}
	return p.parseStatement()
}

func (p *parser) atEnd() bool { return p.pos >= len(p.toks) }

func (p *parser) peek() token {
	if p.atEnd() {
		return token{start: len(p.sql), end: len(p.sql)}
	}
	return p.toks[p.pos]
}

func (p *parser) peekAt(n int) token {
	if p.pos+n >= len(p.toks) {
		return token{start: len(p.sql), end: len(p.sql)}
	}
	return p.toks[p.pos+n]
}

func (p *parser) next() token {
	tok := p.peek()
	if !p.atEnd() {
		p.pos++
	}
	return tok
}

func (p *parser) acceptWord(w string) bool {
	if p.peek().isWord(w) {
		p.pos++
		return true
	}
	return false
}

func (p *parser) acceptPunct(s string) bool {
	if p.peek().isPunct(s) {
		p.pos++
		return true
	}
	return false
}

func (p *parser) expectWord(w string) *queravuev1.QueryBuilderError {
	if p.acceptWord(w) {
		return nil
	}
	return p.unexpected("expected " + w)
}

func (p *parser) expectPunct(s string) *queravuev1.QueryBuilderError {
	if p.acceptPunct(s) {
		return nil
	}
	return p.unexpected(fmt.Sprintf("expected %q", s))
}

func (p *parser) unexpected(want string) *queravuev1.QueryBuilderError {
	if p.atEnd() {
		return parseError(want+", got end of statement", len(p.sql))
	}
	return parseError(fmt.Sprintf("%s, got %q", want, p.peek().text), p.peek().start)
}

func (p *parser) parseStatement() (*statement, *queravuev1.QueryBuilderError) {
	first := p.peek()
	switch {
	case first.isWord("SELECT"):
	case first.isWord("WITH"):
		return nil, unsupportedError("WITH (common table expressions) is not supported", first.start)
	case first.isPunct("("):
		return nil, unsupportedError("a parenthesized query is not supported", first.start)
	case first.kind == sqlsplit.TokenWord && writeStatements[first.up]:
		return nil, unsupportedError(fmt.Sprintf("SQL mode is read-only: %s is not supported", first.up), first.start)
	default:
		return nil, unsupportedError("only a single SELECT statement is supported", first.start)
	}
	p.pos++

	st := &statement{}
	if tok := p.peek(); tok.isWord("DISTINCT") {
		p.pos++
		if p.peek().isWord("ON") {
			return nil, unsupportedError("DISTINCT ON is not supported", p.peek().start)
		}
		st.distinct, st.distinctOffset = true, tok.start
	} else {
		p.acceptWord("ALL")
	}
	if p.peek().isWord("TOP") {
		return nil, unsupportedError("SELECT TOP is not supported; use LIMIT", p.peek().start)
	}

	items, err := p.parseSelectList()
	if err != nil {
		return nil, err
	}
	st.items = items

	if p.peek().isWord("INTO") {
		return nil, unsupportedError("SELECT INTO is not supported", p.peek().start)
	}
	if p.atEnd() {
		return nil, unsupportedError("SELECT without FROM is not supported", len(p.sql))
	}
	if err := p.expectWord("FROM"); err != nil {
		return nil, err
	}
	if st.from, err = p.parseTableRef(); err != nil {
		return nil, err
	}
	if p.peek().isPunct(",") {
		return nil, unsupportedError("comma joins are not supported; use JOIN ... ON", p.peek().start)
	}
	if st.joins, err = p.parseJoins(); err != nil {
		return nil, err
	}
	if p.acceptWord("WHERE") {
		if st.where, err = p.parseExpr(); err != nil {
			return nil, err
		}
	}
	if tok := p.peek(); tok.isWord("GROUP") {
		p.pos++
		if err := p.expectWord("BY"); err != nil {
			return nil, err
		}
		st.groupByOffset = tok.start
		if st.groupBy, err = p.parseExprList(); err != nil {
			return nil, err
		}
	}
	if tok := p.peek(); tok.isWord("HAVING") {
		p.pos++
		st.havingOffset = tok.start
		if st.having, err = p.parseExpr(); err != nil {
			return nil, err
		}
	}
	if p.acceptWord("ORDER") {
		if err := p.expectWord("BY"); err != nil {
			return nil, err
		}
		if st.orderBy, err = p.parseOrderBy(); err != nil {
			return nil, err
		}
	}
	if err := p.parseLimitOffset(st); err != nil {
		return nil, err
	}
	return st, p.parseTrailing()
}

func (p *parser) parseTrailing() *queravuev1.QueryBuilderError {
	if p.atEnd() {
		return nil
	}
	tok := p.peek()
	switch tok.up {
	case "UNION", "INTERSECT", "EXCEPT", "MINUS":
		return unsupportedError(tok.up+" is not supported", tok.start)
	case "FOR":
		return unsupportedError("locking clauses (FOR ...) are not supported", tok.start)
	case "FETCH":
		return unsupportedError("FETCH is not supported; use LIMIT", tok.start)
	case "WINDOW":
		return unsupportedError("window functions are not supported", tok.start)
	case "GROUP", "HAVING", "WHERE", "ORDER", "LIMIT", "OFFSET":
		return parseError(tok.up+" is out of order", tok.start)
	}
	return p.unexpected("unexpected text after the statement")
}

func (p *parser) parseSelectList() ([]selectItem, *queravuev1.QueryBuilderError) {
	var items []selectItem
	for {
		item, err := p.parseSelectItem()
		if err != nil {
			return nil, err
		}
		items = append(items, item)
		if !p.acceptPunct(",") {
			return items, nil
		}
	}
}

func (p *parser) parseSelectItem() (selectItem, *queravuev1.QueryBuilderError) {
	start := p.peek()
	if p.acceptPunct("*") {
		return selectItem{star: true, offset: start.start}, nil
	}
	if qualifier, ok := p.qualifiedStar(); ok {
		return selectItem{star: true, expr: qualifier, offset: start.start}, nil
	}
	if start.isWord("FROM") || p.atEnd() {
		return selectItem{}, p.unexpected("expected a column")
	}
	e, err := p.parseExpr()
	if err != nil {
		return selectItem{}, err
	}
	alias, err := p.parseAlias()
	if err != nil {
		return selectItem{}, err
	}
	return selectItem{expr: e, alias: alias, offset: start.start}, nil
}

func (p *parser) qualifiedStar() (fieldRef, bool) {
	save := p.pos
	ref := fieldRef{offset: p.peek().start}
	for p.peek().isIdent() && p.peekAt(1).isPunct(".") {
		ref.parts = append(ref.parts, p.next().identName())
		p.pos++
		if p.acceptPunct("*") {
			return ref, true
		}
	}
	p.pos = save
	return fieldRef{}, false
}

func (p *parser) parseAlias() (string, *queravuev1.QueryBuilderError) {
	if p.acceptWord("AS") {
		if !p.peek().isIdent() {
			return "", p.unexpected("expected an alias")
		}
		return p.next().identName(), nil
	}
	tok := p.peek()
	if tok.kind == sqlsplit.TokenQuotedIdent || tok.kind == sqlsplit.TokenWord && !reservedWords[tok.up] {
		p.pos++
		return tok.identName(), nil
	}
	return "", nil
}

func (p *parser) parseTableRef() (tableRef, *queravuev1.QueryBuilderError) {
	tok := p.peek()
	if tok.isPunct("(") {
		return tableRef{}, unsupportedError("subqueries are not supported", tok.start)
	}
	if !tok.isIdent() || tok.kind == sqlsplit.TokenWord && reservedWords[tok.up] {
		return tableRef{}, p.unexpected("expected a collection name")
	}
	if p.peekAt(1).isPunct("(") {
		return tableRef{}, unsupportedError("table functions are not supported", tok.start)
	}
	ref := tableRef{name: p.next().identName(), offset: tok.start}
	for p.acceptPunct(".") {
		if !p.peek().isIdent() {
			return tableRef{}, p.unexpected("expected a collection name")
		}
		ref.name += "." + p.next().identName()
	}
	alias, err := p.parseAlias()
	if err != nil {
		return tableRef{}, err
	}
	ref.alias = alias
	return ref, nil
}

func (p *parser) parseJoins() ([]join, *queravuev1.QueryBuilderError) {
	var joins []join
	for {
		tok := p.peek()
		var kind joinKind
		switch {
		case tok.isWord("JOIN"):
			kind = joinInner
		case tok.isWord("INNER") && p.peekAt(1).isWord("JOIN"):
			kind = joinInner
			p.pos++
		case tok.isWord("LEFT"):
			kind = joinLeft
			p.pos++
			p.acceptWord("OUTER")
			if !p.peek().isWord("JOIN") {
				return nil, p.unexpected("expected JOIN")
			}
		case tok.isWord("RIGHT"), tok.isWord("FULL"), tok.isWord("CROSS"), tok.isWord("NATURAL"):
			return nil, unsupportedError(tok.up+" JOIN is not supported; use INNER or LEFT JOIN", tok.start)
		default:
			return joins, nil
		}
		p.pos++
		table, err := p.parseTableRef()
		if err != nil {
			return nil, err
		}
		if p.peek().isWord("USING") {
			return nil, unsupportedError("JOIN ... USING is not supported; use ON", p.peek().start)
		}
		if err := p.expectWord("ON"); err != nil {
			return nil, err
		}
		on, err := p.parseExpr()
		if err != nil {
			return nil, err
		}
		joins = append(joins, join{kind: kind, table: table, on: on, offset: tok.start})
	}
}

func (p *parser) parseExprList() ([]expr, *queravuev1.QueryBuilderError) {
	var list []expr
	for {
		e, err := p.parseExpr()
		if err != nil {
			return nil, err
		}
		list = append(list, e)
		if !p.acceptPunct(",") {
			return list, nil
		}
	}
}

func (p *parser) parseOrderBy() ([]orderItem, *queravuev1.QueryBuilderError) {
	var items []orderItem
	for {
		start := p.peek().start
		e, err := p.parseExpr()
		if err != nil {
			return nil, err
		}
		item := orderItem{expr: e, offset: start}
		if p.acceptWord("DESC") {
			item.descending = true
		} else {
			p.acceptWord("ASC")
		}
		if p.peek().isWord("NULLS") {
			return nil, unsupportedError("NULLS FIRST/LAST is not supported; MongoDB sorts null and missing values first", p.peek().start)
		}
		items = append(items, item)
		if !p.acceptPunct(",") {
			return items, nil
		}
	}
}

func (p *parser) parseLimitOffset(st *statement) *queravuev1.QueryBuilderError {
	seenLimit, seenOffset := false, false
	for {
		tok := p.peek()
		switch {
		case tok.isWord("LIMIT") && !seenLimit:
			p.pos++
			seenLimit = true
			if p.peek().isWord("ALL") {
				return unsupportedError("LIMIT ALL is not supported; leave LIMIT out", p.peek().start)
			}
			first, err := p.parseCount()
			if err != nil {
				return err
			}
			if p.acceptPunct(",") {
				if seenOffset {
					return parseError("OFFSET given twice", tok.start)
				}
				seenOffset = true
				st.offset = first
				if first, err = p.parseCount(); err != nil {
					return err
				}
			}
			st.limit, st.limitOffset = &first, tok.start
		case tok.isWord("OFFSET") && !seenOffset:
			p.pos++
			seenOffset = true
			n, err := p.parseCount()
			if err != nil {
				return err
			}
			st.offset = n
			if !p.acceptWord("ROWS") {
				p.acceptWord("ROW")
			}
		default:
			return nil
		}
	}
}

func (p *parser) parseCount() (uint64, *queravuev1.QueryBuilderError) {
	tok := p.peek()
	if tok.kind != sqlsplit.TokenNumber || !isIntegerText(tok.text) {
		if tok.isPunct("?") || tok.isPunct("$") || tok.isPunct(":") || tok.isPunct("@") {
			return 0, unsupportedError("parameter placeholders are not supported", tok.start)
		}
		return 0, p.unexpected("expected a non-negative integer")
	}
	p.pos++
	n, err := strconv.ParseInt(tok.text, 10, 64)
	if err != nil {
		return 0, parseError(fmt.Sprintf("%s does not fit in 64 bits", tok.text), tok.start)
	}
	return uint64(n), nil //nolint:gosec // ParseInt of digits only is non-negative
}

func (p *parser) parseExpr() (expr, *queravuev1.QueryBuilderError) { return p.parseOr() }

func (p *parser) parseOr() (expr, *queravuev1.QueryBuilderError) {
	return p.parseLogical("OR", false, p.parseAnd)
}

func (p *parser) parseAnd() (expr, *queravuev1.QueryBuilderError) {
	return p.parseLogical("AND", true, p.parseNot)
}

func (p *parser) parseLogical(keyword string, and bool, operand func() (expr, *queravuev1.QueryBuilderError)) (expr, *queravuev1.QueryBuilderError) {
	start := p.peek().start
	first, err := operand()
	if err != nil {
		return nil, err
	}
	if !p.peek().isWord(keyword) {
		return first, nil
	}
	node := logical{and: and, operands: []expr{first}, offset: start}
	for p.acceptWord(keyword) {
		next, err := operand()
		if err != nil {
			return nil, err
		}
		node.operands = append(node.operands, next)
	}
	return node, nil
}

func (p *parser) parseNot() (expr, *queravuev1.QueryBuilderError) {
	tok := p.peek()
	if !tok.isWord("NOT") {
		return p.parsePredicate()
	}
	p.pos++
	if p.peek().isWord("EXISTS") {
		return nil, unsupportedError("EXISTS subqueries are not supported", p.peek().start)
	}
	operand, err := p.parseNot()
	if err != nil {
		return nil, err
	}
	return negation{operand: operand, offset: tok.start}, nil
}

var comparisonOperators = map[string]string{"=": "=", "<>": "<>", "!=": "<>", "<": "<", "<=": "<=", ">": ">", ">=": ">="}

func (p *parser) parsePredicate() (expr, *queravuev1.QueryBuilderError) {
	start := p.peek().start
	left, err := p.parseAdditive()
	if err != nil {
		return nil, err
	}
	tok := p.peek()
	if op, ok := comparisonOperators[tok.text]; ok && tok.kind == sqlsplit.TokenPunct {
		p.pos++
		if next := p.peek(); next.isWord("ANY") || next.isWord("ALL") || next.isWord("SOME") {
			return nil, unsupportedError(next.up+" subqueries are not supported", next.start)
		}
		right, err := p.parseAdditive()
		if err != nil {
			return nil, err
		}
		return comparison{op: op, left: left, right: right, offset: start}, nil
	}
	if tok.isPunct("==") {
		return nil, parseError(`"==" is not SQL; use "="`, tok.start)
	}
	if tok.isWord("IS") {
		return p.parseIs(left, start)
	}
	negated := false
	if tok.isWord("NOT") {
		next := p.peekAt(1)
		if !next.isWord("IN") && !next.isWord("BETWEEN") && !next.isWord("LIKE") && !next.isWord("ILIKE") {
			return left, nil
		}
		negated = true
		p.pos++
		tok = p.peek()
	}
	switch {
	case tok.isWord("IN"):
		p.pos++
		return p.parseIn(left, negated, start)
	case tok.isWord("BETWEEN"):
		p.pos++
		return p.parseBetween(left, negated, start)
	case tok.isWord("LIKE"), tok.isWord("ILIKE"):
		p.pos++
		return p.parseLike(left, negated, tok.isWord("ILIKE"), start)
	case tok.isWord("SIMILAR"), tok.isWord("REGEXP"), tok.isWord("RLIKE"), tok.isPunct("~"):
		return nil, unsupportedError(fmt.Sprintf("%s is not supported; use LIKE", tok.text), tok.start)
	}
	return left, nil
}

func (p *parser) parseIs(left expr, start int) (expr, *queravuev1.QueryBuilderError) {
	p.pos++
	negated := p.acceptWord("NOT")
	tok := p.peek()
	if tok.isWord("NULL") {
		p.pos++
		return nullCheck{operand: left, negated: negated, offset: start}, nil
	}
	if p.atEnd() {
		return nil, p.unexpected("expected NULL")
	}
	return nil, unsupportedError(fmt.Sprintf("IS %s is not supported; only IS [NOT] NULL", tok.text), tok.start)
}

func (p *parser) parseIn(left expr, negated bool, start int) (expr, *queravuev1.QueryBuilderError) {
	if err := p.expectPunct("("); err != nil {
		return nil, err
	}
	if p.peek().isWord("SELECT") {
		return nil, unsupportedError("subqueries are not supported", p.peek().start)
	}
	if p.peek().isPunct(")") {
		return nil, parseError("IN needs at least one value", p.peek().start)
	}
	values, err := p.parseExprList()
	if err != nil {
		return nil, err
	}
	if err := p.expectPunct(")"); err != nil {
		return nil, err
	}
	return inList{operand: left, values: values, negated: negated, offset: start}, nil
}

func (p *parser) parseBetween(left expr, negated bool, start int) (expr, *queravuev1.QueryBuilderError) {
	if p.peek().isWord("SYMMETRIC") || p.peek().isWord("ASYMMETRIC") {
		return nil, unsupportedError("BETWEEN "+p.peek().up+" is not supported", p.peek().start)
	}
	low, err := p.parseAdditive()
	if err != nil {
		return nil, err
	}
	if err := p.expectWord("AND"); err != nil {
		return nil, err
	}
	high, err := p.parseAdditive()
	if err != nil {
		return nil, err
	}
	return between{operand: left, low: low, high: high, negated: negated, offset: start}, nil
}

func (p *parser) parseLike(left expr, negated, caseInsensitive bool, start int) (expr, *queravuev1.QueryBuilderError) {
	tok := p.peek()
	if tok.kind != sqlsplit.TokenString {
		if p.atEnd() {
			return nil, p.unexpected("expected a pattern")
		}
		return nil, unsupportedError("the LIKE pattern must be a string literal", tok.start)
	}
	p.pos++
	node := likeMatch{operand: left, pattern: tok.stringValue(), escape: '\\', caseInsensitive: caseInsensitive, negated: negated, offset: start}
	if escTok := p.peek(); escTok.isWord("ESCAPE") {
		p.pos++
		esc := p.peek()
		if esc.kind != sqlsplit.TokenString {
			return nil, p.unexpected("expected a one-character string after ESCAPE")
		}
		p.pos++
		value := esc.stringValue()
		switch utf8.RuneCountInString(value) {
		case 0:
			node.escape = 0
		case 1:
			node.escape, _ = utf8.DecodeRuneInString(value)
		default:
			return nil, parseError("ESCAPE needs a single character", esc.start)
		}
	}
	return node, nil
}

func (p *parser) parseAdditive() (expr, *queravuev1.QueryBuilderError) {
	return p.parseArithmetic(p.parseMultiplicative, "+", "-")
}

func (p *parser) parseMultiplicative() (expr, *queravuev1.QueryBuilderError) {
	return p.parseArithmetic(p.parseUnary, "*", "/")
}

func (p *parser) parseArithmetic(operand func() (expr, *queravuev1.QueryBuilderError), ops ...string) (expr, *queravuev1.QueryBuilderError) {
	start := p.peek().start
	left, err := operand()
	if err != nil {
		return nil, err
	}
	for {
		tok := p.peek()
		if tok.isPunct("%") || tok.isPunct("||") {
			return nil, unsupportedError(fmt.Sprintf("the %s operator is not supported", tok.text), tok.start)
		}
		if tok.kind != sqlsplit.TokenPunct || (tok.text != ops[0] && tok.text != ops[1]) {
			return left, nil
		}
		p.pos++
		right, err := operand()
		if err != nil {
			return nil, err
		}
		left = arithmetic{op: tok.text, left: left, right: right, offset: start}
	}
}

func (p *parser) parseUnary() (expr, *queravuev1.QueryBuilderError) {
	tok := p.peek()
	if (tok.isPunct("-") || tok.isPunct("+")) && p.peekAt(1).kind == sqlsplit.TokenNumber {
		p.pos++
		num := p.next()
		sign := ""
		if tok.text == "-" {
			sign = "-"
		}
		return p.numberLiteral(sign+num.text, tok.start)
	}
	if tok.isPunct("-") || tok.isPunct("+") {
		return nil, unsupportedError("unary "+tok.text+" is only supported on number literals", tok.start)
	}
	return p.parsePrimary()
}

func (p *parser) numberLiteral(text string, offset int) (expr, *queravuev1.QueryBuilderError) {
	v, err := relaxedNumber(text)
	if err != nil {
		return nil, parseError(err.Error(), offset)
	}
	return literal{value: v, offset: offset}, nil
}

func (p *parser) parsePrimary() (expr, *queravuev1.QueryBuilderError) {
	tok := p.peek()
	switch tok.kind {
	case sqlsplit.TokenString:
		p.pos++
		return literal{value: tok.stringValue(), offset: tok.start}, nil
	case sqlsplit.TokenNumber:
		p.pos++
		return p.numberLiteral(tok.text, tok.start)
	case sqlsplit.TokenQuotedIdent:
		return p.parseFieldRef()
	case sqlsplit.TokenWord:
		return p.parseWord()
	}
	switch {
	case tok.isPunct("("):
		return p.parseParenthesized()
	case tok.isPunct("?"), tok.isPunct("$"), tok.isPunct(":"), tok.isPunct("@"):
		return nil, unsupportedError("parameter placeholders are not supported", tok.start)
	}
	return nil, p.unexpected("expected an expression")
}

func (p *parser) parseParenthesized() (expr, *queravuev1.QueryBuilderError) {
	p.pos++
	if p.peek().isWord("SELECT") {
		return nil, unsupportedError("subqueries are not supported", p.peek().start)
	}
	inner, err := p.parseExpr()
	if err != nil {
		return nil, err
	}
	if p.peek().isPunct(",") {
		return nil, unsupportedError("row values are not supported", p.peek().start)
	}
	if err := p.expectPunct(")"); err != nil {
		return nil, err
	}
	return inner, nil
}

func (p *parser) parseWord() (expr, *queravuev1.QueryBuilderError) {
	tok := p.peek()
	next := p.peekAt(1)
	switch tok.up {
	case "TRUE", "FALSE":
		p.pos++
		return literal{value: tok.up == "TRUE", offset: tok.start}, nil
	case "NULL":
		p.pos++
		return literal{isNull: true, offset: tok.start}, nil
	case "CASE", "CAST", "EXISTS", "INTERVAL":
		return nil, unsupportedError(tok.up+" is not supported", tok.start)
	case "DATE", "TIMESTAMP":
		if next.kind == sqlsplit.TokenString {
			return p.parseDateLiteral()
		}
	}
	if next.isPunct("(") {
		switch {
		case tok.up == "OBJECTID" || tok.up == "NUMBERLONG" || tok.up == "NUMBERDECIMAL":
			return p.parseTypedCall()
		case aggregateNames[tok.up]:
			return p.parseAggregate()
		}
		return nil, unsupportedError(fmt.Sprintf("function %s is not supported", tok.text), tok.start)
	}
	if reservedWords[tok.up] {
		return nil, p.unexpected("expected an expression")
	}
	return p.parseFieldRef()
}

func (p *parser) parseFieldRef() (expr, *queravuev1.QueryBuilderError) {
	ref := fieldRef{offset: p.peek().start}
	for {
		tok := p.peek()
		if !tok.isIdent() {
			return nil, p.unexpected("expected a field name")
		}
		p.pos++
		ref.parts = append(ref.parts, tok.identName())
		if !p.peek().isPunct(".") {
			return ref, nil
		}
		p.pos++
	}
}

func (p *parser) parseDateLiteral() (expr, *queravuev1.QueryBuilderError) {
	kw := p.next()
	str := p.next()
	var (
		v   any
		err error
	)
	if kw.up == "DATE" {
		v, err = dateLiteral(str.stringValue())
	} else {
		v, err = timestampLiteral(str.stringValue())
	}
	if err != nil {
		return nil, parseError(err.Error(), str.start)
	}
	return literal{value: v, offset: kw.start}, nil
}

func (p *parser) parseTypedCall() (expr, *queravuev1.QueryBuilderError) {
	fn := p.next()
	p.pos++
	arg := p.peek()
	text := ""
	switch {
	case arg.kind == sqlsplit.TokenString:
		text = arg.stringValue()
		p.pos++
	case fn.up != "OBJECTID" && arg.kind == sqlsplit.TokenNumber:
		text = arg.text
		p.pos++
	case fn.up != "OBJECTID" && arg.isPunct("-") && p.peekAt(1).kind == sqlsplit.TokenNumber:
		p.pos++
		text = "-" + p.next().text
	default:
		return nil, p.unexpected(fmt.Sprintf("%s needs a literal argument", fn.up))
	}
	if err := p.expectPunct(")"); err != nil {
		return nil, err
	}
	var (
		v   any
		err error
	)
	switch fn.up {
	case "OBJECTID":
		v, err = objectID(text)
	case "NUMBERLONG":
		v, err = numberLong(text)
	default:
		v, err = numberDecimal(text)
	}
	if err != nil {
		return nil, parseError(err.Error(), arg.start)
	}
	return literal{value: v, offset: fn.start}, nil
}

func (p *parser) parseAggregate() (expr, *queravuev1.QueryBuilderError) {
	fn := p.next()
	p.pos++
	call := aggregateCall{name: fn.up, offset: fn.start}
	if p.acceptPunct("*") {
		if fn.up != "COUNT" {
			return nil, parseError(fn.up+"(*) is not valid; only COUNT(*)", fn.start)
		}
		call.star = true
	} else {
		call.distinct = p.acceptWord("DISTINCT")
		arg, err := p.parseExpr()
		if err != nil {
			return nil, err
		}
		call.arg = arg
	}
	if err := p.expectPunct(")"); err != nil {
		return nil, err
	}
	if p.peek().isWord("OVER") {
		return nil, unsupportedError("window functions are not supported", p.peek().start)
	}
	if p.peek().isWord("FILTER") && p.peekAt(1).isPunct("(") {
		return nil, unsupportedError("aggregate FILTER clauses are not supported", p.peek().start)
	}
	return call, nil
}
