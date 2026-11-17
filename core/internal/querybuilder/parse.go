package querybuilder

import (
	"fmt"
	"strconv"
	"strings"

	"google.golang.org/protobuf/proto"

	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
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

// Parse parses one SELECT statement in dialect d into a normalized SqlQueryModel.
func Parse(d sqldialect.Dialect, sql string) (*queravuev1.SqlQueryModel, bool, *queravuev1.QueryBuilderError) {
	if d == nil {
		return nil, false, notSQLError()
	}
	toks, commentsDropped, err := lexTokens(d.Lexer(), sql)
	if err != nil {
		return nil, commentsDropped, err
	}
	if len(toks) == 0 {
		return nil, commentsDropped, parseError("empty SQL statement", 0)
	}
	if toks[len(toks)-1].isPunct(";") {
		toks = toks[:len(toks)-1]
	}
	for _, tok := range toks {
		if tok.isPunct(";") {
			return nil, commentsDropped, unsupportedError("multiple statements are not supported", tok.start)
		}
	}
	if len(toks) == 0 {
		return nil, commentsDropped, parseError("empty SQL statement", 0)
	}
	p := &parser{dialect: d, lexer: d.Lexer(), sql: sql, toks: toks}
	model, err := p.parseQuery()
	if err != nil {
		return nil, commentsDropped, err
	}
	return Normalize(d, model), commentsDropped, nil
}

func lexTokens(lexer sqlsplit.Dialect, sql string) ([]token, bool, *queravuev1.QueryBuilderError) {
	raw := sqlsplit.Tokenize(lexer, sql)
	out := make([]token, 0, len(raw))
	commentsDropped := false

	for _, r := range raw {
		text := r.Text(sql)
		switch r.Kind {
		case sqlsplit.TokenSpace:
			continue
		case sqlsplit.TokenComment:
			commentsDropped = true
			if strings.HasPrefix(text, "/*") && !isBlockCommentClosed(lexer, text) {
				return nil, commentsDropped, parseError("unterminated block comment", r.Start)
			}
			continue
		case sqlsplit.TokenQuotedIdent:
			if !isQuotedIdentClosed(lexer, text) {
				return nil, commentsDropped, parseError("unterminated quoted identifier", r.Start)
			}
		case sqlsplit.TokenString:
			hasPrefix := len(out) > 0 && out[len(out)-1].kind == sqlsplit.TokenWord && out[len(out)-1].end == r.Start
			var prefixUp string
			if hasPrefix {
				prefixUp = out[len(out)-1].up
			}
			if !isStringClosed(lexer, text, prefixUp) {
				return nil, commentsDropped, parseError("unterminated string literal", r.Start)
			}
			if merged, ok := tryMergePrefixedString(lexer, out, r, text); ok {
				out[len(out)-1] = merged
				continue
			}
		}
		tok := token{kind: r.Kind, start: r.Start, end: r.End, text: text}
		if r.Kind == sqlsplit.TokenWord {
			tok.up = strings.ToUpper(text)
		}
		out = append(out, tok)
	}

	out = mergeScientificNumbers(out)
	return out, commentsDropped, nil
}

func tryMergePrefixedString(lexer sqlsplit.Dialect, out []token, r sqlsplit.Token, text string) (token, bool) {
	if len(out) == 0 {
		return token{}, false
	}
	prev := out[len(out)-1]
	if prev.kind != sqlsplit.TokenWord || prev.end != r.Start {
		return token{}, false
	}
	switch {
	case lexer == sqlsplit.MSSQL && prev.up == "N":
	case (lexer == sqlsplit.Postgres || lexer == sqlsplit.DuckDB) && prev.up == "E":
	case lexer == sqlsplit.Oracle && (prev.up == "Q" || prev.up == "NQ"):
	default:
		return token{}, false
	}
	return token{kind: sqlsplit.TokenString, start: prev.start, end: r.End, text: prev.text + text}, true
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

func isBlockCommentClosed(lexer sqlsplit.Dialect, text string) bool {
	if strings.HasPrefix(text, "--") || strings.HasPrefix(text, "#") {
		return true
	}
	if !strings.HasPrefix(text, "/*") {
		return true
	}
	nested := lexer == sqlsplit.Postgres || lexer == sqlsplit.DuckDB || lexer == sqlsplit.MSSQL
	depth := 1
	i := 2
	for i < len(text) {
		switch {
		case nested && strings.HasPrefix(text[i:], "/*"):
			depth++
			i += 2
		case strings.HasPrefix(text[i:], "*/"):
			depth--
			i += 2
			if depth == 0 {
				return i == len(text)
			}
		default:
			i++
		}
	}
	return false
}

func isQuotedIdentClosed(lexer sqlsplit.Dialect, text string) bool {
	if len(text) < 2 {
		return false
	}
	open := text[0]
	if open == '[' {
		for i := 1; i < len(text); i++ {
			if text[i] == ']' {
				if lexer == sqlsplit.MSSQL && i+1 < len(text) && text[i+1] == ']' {
					i++
					continue
				}
				return i == len(text)-1
			}
		}
		return false
	}
	for i := 1; i < len(text); i++ {
		if text[i] == open {
			if i+1 < len(text) && text[i+1] == open {
				i++
				continue
			}
			return i == len(text)-1
		}
	}
	return false
}

func isStringClosed(lexer sqlsplit.Dialect, text, prefixUp string) bool {
	if len(text) < 2 {
		return false
	}
	if (lexer == sqlsplit.Postgres || lexer == sqlsplit.DuckDB) && text[0] == '$' {
		second := strings.IndexByte(text[1:], '$')
		if second < 0 {
			return false
		}
		tag := text[:second+2]
		return len(text) >= 2*len(tag) && strings.HasSuffix(text, tag)
	}
	if lexer == sqlsplit.Oracle && (prefixUp == "Q" || prefixUp == "NQ") && text[0] == '\'' {
		if len(text) < 4 {
			return false
		}
		open := text[1]
		closer := oracleQuoteCloser(open)
		return text[len(text)-2] == closer && text[len(text)-1] == '\''
	}
	q := text[0]
	backslash := lexer == sqlsplit.MySQL || lexer == sqlsplit.ClickHouse ||
		((lexer == sqlsplit.Postgres || lexer == sqlsplit.DuckDB) && prefixUp == "E")
	for i := 1; i < len(text); i++ {
		c := text[i]
		if backslash && c == '\\' {
			i++
			continue
		}
		if c == q {
			if i+1 < len(text) && text[i+1] == q {
				i++
				continue
			}
			return i == len(text)-1
		}
	}
	return false
}

func oracleQuoteCloser(open byte) byte {
	switch open {
	case '[':
		return ']'
	case '{':
		return '}'
	case '(':
		return ')'
	case '<':
		return '>'
	default:
		return open
	}
}

type parser struct {
	dialect sqldialect.Dialect
	lexer   sqlsplit.Dialect
	sql     string
	toks    []token
	pos     int
}

func (p *parser) atEnd() bool { return p.pos >= len(p.toks) }

func (p *parser) peek() token {
	if p.pos >= len(p.toks) {
		return token{}
	}
	return p.toks[p.pos]
}

func (p *parser) peekAt(offset int) (token, bool) {
	idx := p.pos + offset
	if idx < 0 || idx >= len(p.toks) {
		return token{}, false
	}
	return p.toks[idx], true
}

func (p *parser) eofOffset() int { return len(p.sql) }

func (p *parser) curOffset() int {
	if p.atEnd() {
		return p.eofOffset()
	}
	return p.peek().start
}

func (p *parser) parseQuery() (*queravuev1.SqlQueryModel, *queravuev1.QueryBuilderError) {
	first := p.peek()
	if !first.isWord("SELECT") {
		return nil, unsupportedError("only single SELECT statements are supported", first.start)
	}
	p.pos++

	model := &queravuev1.SqlQueryModel{}
	if p.peek().isWord("DISTINCT") {
		p.pos++
		if p.peek().isWord("ON") {
			return nil, unsupportedError("DISTINCT ON is not supported", p.peek().start)
		}
		model.Distinct = true
	} else if p.peek().isWord("ALL") {
		return nil, unsupportedError("SELECT ALL is not supported", p.peek().start)
	}
	if p.peek().isWord("TOP") {
		return nil, unsupportedError("SELECT TOP is not supported; use LIMIT or OFFSET/FETCH", p.peek().start)
	}

	items, err := p.parseSelectList()
	if err != nil {
		return nil, err
	}
	model.Select = items

	if p.peek().isWord("INTO") {
		return nil, unsupportedError("SELECT INTO is not supported", p.peek().start)
	}
	if p.atEnd() {
		return nil, unsupportedError("SELECT without FROM is not supported", p.eofOffset())
	}
	if !p.peek().isWord("FROM") {
		return nil, unsupportedError(fmt.Sprintf("expected FROM, got %q", p.peek().text), p.curOffset())
	}
	p.pos++

	from, err := p.parseTableRef()
	if err != nil {
		return nil, err
	}
	model.From = from

	if p.peek().isPunct(",") {
		return nil, unsupportedError("comma joins are not supported; use explicit JOIN ... ON", p.peek().start)
	}

	joins, err := p.parseJoins()
	if err != nil {
		return nil, err
	}
	model.Joins = joins

	if p.peek().isWord("WHERE") {
		p.pos++
		where, err := p.parseCondition(false)
		if err != nil {
			return nil, err
		}
		model.Where = where
	}

	if p.peek().isWord("GROUP") {
		groupBy, err := p.parseGroupBy()
		if err != nil {
			return nil, err
		}
		model.GroupBy = groupBy
	}

	if p.peek().isWord("HAVING") {
		p.pos++
		having, err := p.parseCondition(true)
		if err != nil {
			return nil, err
		}
		model.Having = having
	}

	if p.peek().isWord("ORDER") {
		orderBy, err := p.parseOrderBy()
		if err != nil {
			return nil, err
		}
		model.OrderBy = orderBy
	}

	limit, offset, err := p.parseLimitOffset()
	if err != nil {
		return nil, err
	}
	if limit > 0 {
		model.Limit = proto.Uint64(limit)
	}
	if offset > 0 {
		model.Offset = proto.Uint64(offset)
	}

	if !p.atEnd() {
		rem := p.peek()
		return nil, unsupportedError(fmt.Sprintf("unsupported trailing SQL %q", rem.text), rem.start)
	}
	return model, nil
}

func (p *parser) parseSelectList() ([]*queravuev1.SqlSelectItem, *queravuev1.QueryBuilderError) {
	if p.atEnd() || p.peek().isWord("FROM") {
		return nil, parseError("expected select expression", p.curOffset())
	}
	var items []*queravuev1.SqlSelectItem
	for {
		item, err := p.parseSelectItem()
		if err != nil {
			return nil, err
		}
		items = append(items, item)
		if !p.peek().isPunct(",") {
			break
		}
		p.pos++
		if p.atEnd() || p.peek().isWord("FROM") {
			return nil, parseError("expected select expression after ','", p.curOffset())
		}
	}
	return items, nil
}

func (p *parser) parseSelectItem() (*queravuev1.SqlSelectItem, *queravuev1.QueryBuilderError) {
	tok := p.peek()
	if tok.isPunct("*") {
		p.pos++
		if p.peek().isWord("AS") || isImplicitAlias(p.peek()) {
			return nil, unsupportedError("wildcard select item cannot have an alias", p.peek().start)
		}
		return &queravuev1.SqlSelectItem{
			Expression: &queravuev1.SqlSelectItem_Column{Column: &queravuev1.SqlColumnRef{}},
		}, nil
	}

	if !tok.isIdent() {
		return nil, unsupportedError("unsupported expression in SELECT list", tok.start)
	}

	if _, ok := parseAggregateKeyword(tok); ok && p.peekTokenIsPunct(1, "(") {
		agg, err := p.parseAggregateExpr()
		if err != nil {
			return nil, err
		}
		if p.peek().isWord("OVER") || p.peek().isWord("FILTER") {
			return nil, unsupportedError("window and filter clauses on aggregates are not supported", p.peek().start)
		}
		if isSelectExprOp(p.peek()) {
			return nil, unsupportedError("expressions in SELECT list are not supported", p.peek().start)
		}
		alias, err := p.parseOptionalAlias(selectTerminators)
		if err != nil {
			return nil, err
		}
		return &queravuev1.SqlSelectItem{
			Expression: &queravuev1.SqlSelectItem_Aggregate{Aggregate: agg},
			Alias:      alias,
		}, nil
	}

	if p.peekTokenIsPunct(1, "(") {
		return nil, unsupportedError(fmt.Sprintf("function %s is not supported", tok.text), tok.start)
	}

	if tok.kind == sqlsplit.TokenWord && (tok.up == "CASE" || tok.up == "EXISTS" || tok.up == "TRUE" || tok.up == "FALSE" || tok.up == "NULL") {
		return nil, unsupportedError(fmt.Sprintf("unsupported expression %s in SELECT list", tok.text), tok.start)
	}

	if p.peekTokenIsPunct(1, ".") {
		if t2, ok := p.peekAt(2); ok && t2.isPunct("*") {
			tableAlias := p.unquote(tok)
			p.pos += 3
			if p.peek().isWord("AS") || isImplicitAlias(p.peek()) {
				return nil, unsupportedError("wildcard select item cannot have an alias", p.peek().start)
			}
			return &queravuev1.SqlSelectItem{
				Expression: &queravuev1.SqlSelectItem_Column{
					Column: &queravuev1.SqlColumnRef{TableAlias: tableAlias},
				},
			}, nil
		}
	}

	col, err := p.parseColumnRef()
	if err != nil {
		return nil, err
	}
	if isSelectExprOp(p.peek()) {
		return nil, unsupportedError("expressions in SELECT list are not supported", p.peek().start)
	}
	alias, err := p.parseOptionalAlias(selectTerminators)
	if err != nil {
		return nil, err
	}
	return &queravuev1.SqlSelectItem{
		Expression: &queravuev1.SqlSelectItem_Column{Column: col},
		Alias:      alias,
	}, nil
}

func (p *parser) peekTokenIsPunct(offset int, punct string) bool {
	t, ok := p.peekAt(offset)
	return ok && t.isPunct(punct)
}

func isSelectExprOp(tok token) bool {
	if tok.kind == sqlsplit.TokenPunct {
		switch tok.text {
		case "+", "-", "*", "/", "%", "|", "&", "^", ":", "=", "<", ">", "!":
			return true
		}
	}
	return tok.kind == sqlsplit.TokenWord && (tok.up == "AND" || tok.up == "OR" || tok.up == "IS" || tok.up == "IN" || tok.up == "LIKE" || tok.up == "BETWEEN")
}

func (p *parser) parseOptionalAlias(terminators map[string]bool) (string, *queravuev1.QueryBuilderError) {
	if p.peek().isWord("AS") {
		p.pos++
		if p.atEnd() || !p.peek().isIdent() {
			return "", parseError("expected alias after AS", p.curOffset())
		}
		alias := p.unquote(p.peek())
		p.pos++
		return alias, nil
	}
	tok := p.peek()
	if tok.kind == sqlsplit.TokenQuotedIdent {
		p.pos++
		return p.unquote(tok), nil
	}
	if tok.kind == sqlsplit.TokenWord && !terminators[tok.up] && !clauseKeywords[tok.up] {
		p.pos++
		return tok.text, nil
	}
	return "", nil
}

func isImplicitAlias(tok token) bool {
	if tok.kind == sqlsplit.TokenQuotedIdent {
		return true
	}
	return tok.kind == sqlsplit.TokenWord && !selectTerminators[tok.up] && !clauseKeywords[tok.up]
}

var selectTerminators = map[string]bool{
	"FROM": true, "INTO": true, "WHERE": true, "GROUP": true, "HAVING": true,
	"ORDER": true, "LIMIT": true, "OFFSET": true, "FETCH": true,
	"UNION": true, "INTERSECT": true, "EXCEPT": true, "MINUS": true,
}

var tableTerminators = map[string]bool{
	"JOIN": true, "INNER": true, "LEFT": true, "RIGHT": true, "FULL": true,
	"CROSS": true, "NATURAL": true, "STRAIGHT_JOIN": true, "LATERAL": true,
	"ON": true, "USING": true, "WHERE": true, "GROUP": true, "HAVING": true,
	"ORDER": true, "LIMIT": true, "OFFSET": true, "FETCH": true,
	"UNION": true, "INTERSECT": true, "EXCEPT": true, "MINUS": true,
	"WITH": true, "FOR": true, "WINDOW": true, "QUALIFY": true,
	"SETTINGS": true, "FORMAT": true, "SAMPLE": true, "PREWHERE": true,
}

var clauseKeywords = map[string]bool{
	"SELECT": true, "FROM": true, "WHERE": true, "JOIN": true, "INNER": true,
	"LEFT": true, "RIGHT": true, "FULL": true, "OUTER": true, "CROSS": true,
	"NATURAL": true, "ON": true, "USING": true, "GROUP": true, "BY": true,
	"HAVING": true, "ORDER": true, "LIMIT": true, "OFFSET": true, "FETCH": true,
	"UNION": true, "INTERSECT": true, "EXCEPT": true, "MINUS": true, "FOR": true,
	"WINDOW": true, "QUALIFY": true, "INTO": true, "AS": true,
}

func (p *parser) parseTableRef() (*queravuev1.SqlTableRef, *queravuev1.QueryBuilderError) {
	if p.atEnd() {
		return nil, parseError("expected table name", p.eofOffset())
	}
	if p.peek().isPunct("(") {
		return nil, unsupportedError("subqueries and parenthesized table expressions are not supported", p.peek().start)
	}
	if p.peek().isWord("LATERAL") {
		return nil, unsupportedError("LATERAL tables are not supported", p.peek().start)
	}
	first := p.peek()
	if !first.isIdent() {
		return nil, parseError("expected table name", first.start)
	}
	p.pos++
	ref := &queravuev1.SqlTableRef{}
	if p.peek().isPunct(".") {
		p.pos++
		if p.atEnd() || !p.peek().isIdent() {
			return nil, parseError("expected table name after '.'", p.curOffset())
		}
		ref.Schema = p.unquote(first)
		ref.Table = p.unquote(p.peek())
		p.pos++
		if p.peek().isPunct(".") {
			return nil, unsupportedError("three-part table names are not supported", p.peek().start)
		}
	} else {
		ref.Table = p.unquote(first)
	}
	if p.peek().isWord("WITH") {
		return nil, unsupportedError("table hints are not supported", p.peek().start)
	}
	alias, err := p.parseOptionalAlias(tableTerminators)
	if err != nil {
		return nil, err
	}
	ref.Alias = alias
	if p.peek().isWord("WITH") {
		return nil, unsupportedError("table hints are not supported", p.peek().start)
	}
	return ref, nil
}

func (p *parser) parseJoins() ([]*queravuev1.SqlJoin, *queravuev1.QueryBuilderError) {
	var joins []*queravuev1.SqlJoin
	for !p.atEnd() {
		tok := p.peek()
		var kind queravuev1.SqlJoinKind
		switch {
		case tok.isWord("CROSS") || tok.isWord("NATURAL") || tok.isWord("STRAIGHT_JOIN"):
			return nil, unsupportedError(fmt.Sprintf("%s JOIN is not supported", tok.up), tok.start)
		case tok.isWord("JOIN"):
			kind = queravuev1.SqlJoinKind_SQL_JOIN_KIND_INNER
			p.pos++
		case tok.isWord("INNER"):
			kind = queravuev1.SqlJoinKind_SQL_JOIN_KIND_INNER
			p.pos++
			if !p.peek().isWord("JOIN") {
				return nil, parseError("expected JOIN after INNER", p.curOffset())
			}
			p.pos++
		case tok.isWord("LEFT"):
			kind = queravuev1.SqlJoinKind_SQL_JOIN_KIND_LEFT
			p.pos++
			if p.peek().isWord("OUTER") {
				p.pos++
			}
			if !p.peek().isWord("JOIN") {
				return nil, parseError("expected JOIN after LEFT", p.curOffset())
			}
			p.pos++
		case tok.isWord("RIGHT"):
			kind = queravuev1.SqlJoinKind_SQL_JOIN_KIND_RIGHT
			p.pos++
			if p.peek().isWord("OUTER") {
				p.pos++
			}
			if !p.peek().isWord("JOIN") {
				return nil, parseError("expected JOIN after RIGHT", p.curOffset())
			}
			p.pos++
		case tok.isWord("FULL"):
			kind = queravuev1.SqlJoinKind_SQL_JOIN_KIND_FULL
			p.pos++
			if p.peek().isWord("OUTER") {
				p.pos++
			}
			if !p.peek().isWord("JOIN") {
				return nil, parseError("expected JOIN after FULL", p.curOffset())
			}
			p.pos++
		default:
			return joins, nil
		}

		tbl, err := p.parseTableRef()
		if err != nil {
			return nil, err
		}
		if p.peek().isWord("USING") {
			return nil, unsupportedError("JOIN USING is not supported; use ON", p.peek().start)
		}
		if !p.peek().isWord("ON") {
			return nil, parseError("expected ON condition after JOIN table", p.curOffset())
		}
		p.pos++
		onCond, err := p.parseCondition(false)
		if err != nil {
			return nil, err
		}
		joins = append(joins, &queravuev1.SqlJoin{
			Kind:  kind,
			Table: tbl,
			On:    onCond,
		})
	}
	return joins, nil
}

func (p *parser) parseCondition(allowAgg bool) (*queravuev1.SqlCondition, *queravuev1.QueryBuilderError) {
	return p.parseOr(allowAgg)
}

func (p *parser) parseOr(allowAgg bool) (*queravuev1.SqlCondition, *queravuev1.QueryBuilderError) {
	first, err := p.parseAnd(allowAgg)
	if err != nil {
		return nil, err
	}
	children := []*queravuev1.SqlCondition{first}
	for p.peek().isWord("OR") {
		p.pos++
		next, err := p.parseAnd(allowAgg)
		if err != nil {
			return nil, err
		}
		children = append(children, next)
	}
	if len(children) == 1 {
		return first, nil
	}
	return &queravuev1.SqlCondition{
		Node: &queravuev1.SqlCondition_Group{
			Group: &queravuev1.SqlConditionGroup{
				Op:       queravuev1.SqlBoolOp_SQL_BOOL_OP_OR,
				Children: children,
			},
		},
	}, nil
}

func (p *parser) parseAnd(allowAgg bool) (*queravuev1.SqlCondition, *queravuev1.QueryBuilderError) {
	first, err := p.parseNot(allowAgg)
	if err != nil {
		return nil, err
	}
	children := []*queravuev1.SqlCondition{first}
	for p.peek().isWord("AND") {
		p.pos++
		next, err := p.parseNot(allowAgg)
		if err != nil {
			return nil, err
		}
		children = append(children, next)
	}
	if len(children) == 1 {
		return first, nil
	}
	return &queravuev1.SqlCondition{
		Node: &queravuev1.SqlCondition_Group{
			Group: &queravuev1.SqlConditionGroup{
				Op:       queravuev1.SqlBoolOp_SQL_BOOL_OP_AND,
				Children: children,
			},
		},
	}, nil
}

func (p *parser) parseNot(allowAgg bool) (*queravuev1.SqlCondition, *queravuev1.QueryBuilderError) {
	if p.peek().isWord("NOT") {
		p.pos++
		inner, err := p.parseNot(allowAgg)
		if err != nil {
			return nil, err
		}
		negateCondition(inner)
		return inner, nil
	}
	return p.parsePrimaryCondition(allowAgg)
}

func (p *parser) parsePrimaryCondition(allowAgg bool) (*queravuev1.SqlCondition, *queravuev1.QueryBuilderError) {
	if p.atEnd() {
		return nil, parseError("expected condition", p.eofOffset())
	}
	if p.peek().isPunct("(") {
		p.pos++
		if p.peek().isWord("SELECT") || p.peek().isWord("WITH") {
			return nil, unsupportedError("subqueries are not supported", p.peek().start)
		}
		inner, err := p.parseCondition(allowAgg)
		if err != nil {
			return nil, err
		}
		if p.peek().isPunct(",") {
			return nil, unsupportedError("tuple expressions are not supported", p.peek().start)
		}
		if !p.peek().isPunct(")") {
			return nil, parseError("expected ')'", p.curOffset())
		}
		p.pos++
		return inner, nil
	}
	if p.peek().isWord("EXISTS") {
		return nil, unsupportedError("EXISTS subqueries are not supported", p.peek().start)
	}
	return p.parseComparison(allowAgg)
}

func (p *parser) parseComparison(allowAgg bool) (*queravuev1.SqlCondition, *queravuev1.QueryBuilderError) {
	leftStart := p.curOffset()
	left, err := p.parseOperand(allowAgg)
	if err != nil {
		return nil, err
	}
	if p.atEnd() {
		return nil, unsupportedError("expected comparison operator", leftStart)
	}

	tok := p.peek()
	cmp := &queravuev1.SqlComparison{Left: left}

	switch {
	case tok.isWord("IS"):
		p.pos++
		if p.peek().isWord("NOT") {
			cmp.Negated = true
			p.pos++
		}
		if p.peek().isWord("NULL") {
			p.pos++
			cmp.Op = queravuev1.SqlOperator_SQL_OPERATOR_IS_NULL
			return wrapComparison(cmp), nil
		}
		return nil, unsupportedError("only IS NULL / IS NOT NULL is supported", p.curOffset())

	case tok.isWord("NOT"):
		cmp.Negated = true
		p.pos++
		if p.atEnd() {
			return nil, parseError("expected IN, LIKE, or BETWEEN after NOT", p.eofOffset())
		}
		switch {
		case p.peek().isWord("IN"):
			return p.finishIn(cmp, allowAgg)
		case p.peek().isWord("LIKE"):
			return p.finishLike(cmp, allowAgg)
		case p.peek().isWord("BETWEEN"):
			return p.finishBetween(cmp, allowAgg)
		default:
			return nil, unsupportedError(fmt.Sprintf("unsupported NOT %s operator", p.peek().text), p.peek().start)
		}

	case tok.isWord("IN"):
		return p.finishIn(cmp, allowAgg)

	case tok.isWord("LIKE"):
		return p.finishLike(cmp, allowAgg)

	case tok.isWord("BETWEEN"):
		return p.finishBetween(cmp, allowAgg)

	case tok.isWord("ILIKE") || tok.isWord("SIMILAR") || tok.isWord("REGEXP") || tok.isWord("RLIKE") || tok.isWord("MATCH"):
		return nil, unsupportedError(fmt.Sprintf("operator %s is not supported", tok.up), tok.start)

	default:
		op, width, ok := p.matchComparisonPunct()
		if !ok {
			if tok.isPunct("+") || tok.isPunct("-") || tok.isPunct("*") || tok.isPunct("/") || tok.isPunct("%") || tok.isPunct("|") || tok.isPunct(":") {
				return nil, unsupportedError("arithmetic and expression operators are not supported", tok.start)
			}
			return nil, unsupportedError(fmt.Sprintf("expected comparison operator, got %q", tok.text), tok.start)
		}
		p.pos += width
		if p.peek().isWord("ANY") || p.peek().isWord("ALL") || p.peek().isWord("SOME") {
			return nil, unsupportedError("quantified comparisons are not supported", p.peek().start)
		}
		right, err := p.parseOperand(allowAgg)
		if err != nil {
			return nil, err
		}
		cmp.Op = op
		cmp.Operands = []*queravuev1.SqlOperand{right}
		return wrapComparison(cmp), nil
	}
}

func wrapComparison(cmp *queravuev1.SqlComparison) *queravuev1.SqlCondition {
	return &queravuev1.SqlCondition{
		Node: &queravuev1.SqlCondition_Comparison{Comparison: cmp},
	}
}

func (p *parser) finishIn(cmp *queravuev1.SqlComparison, allowAgg bool) (*queravuev1.SqlCondition, *queravuev1.QueryBuilderError) {
	p.pos++
	if !p.peek().isPunct("(") {
		return nil, parseError("expected '(' after IN", p.curOffset())
	}
	p.pos++
	if p.peek().isWord("SELECT") || p.peek().isWord("WITH") {
		return nil, unsupportedError("subqueries in IN are not supported", p.peek().start)
	}
	if p.peek().isPunct(")") {
		return nil, parseError("IN list cannot be empty", p.peek().start)
	}
	var ops []*queravuev1.SqlOperand
	for {
		op, err := p.parseOperand(allowAgg)
		if err != nil {
			return nil, err
		}
		ops = append(ops, op)
		if !p.peek().isPunct(",") {
			break
		}
		p.pos++
	}
	if !p.peek().isPunct(")") {
		return nil, parseError("expected ')' after IN list", p.curOffset())
	}
	p.pos++
	cmp.Op = queravuev1.SqlOperator_SQL_OPERATOR_IN
	cmp.Operands = ops
	return wrapComparison(cmp), nil
}

func (p *parser) finishLike(cmp *queravuev1.SqlComparison, allowAgg bool) (*queravuev1.SqlCondition, *queravuev1.QueryBuilderError) {
	p.pos++
	pat, err := p.parseOperand(allowAgg)
	if err != nil {
		return nil, err
	}
	if p.peek().isWord("ESCAPE") {
		return nil, unsupportedError("LIKE ESCAPE is not supported", p.peek().start)
	}
	cmp.Op = queravuev1.SqlOperator_SQL_OPERATOR_LIKE
	cmp.Operands = []*queravuev1.SqlOperand{pat}
	return wrapComparison(cmp), nil
}

func (p *parser) finishBetween(cmp *queravuev1.SqlComparison, allowAgg bool) (*queravuev1.SqlCondition, *queravuev1.QueryBuilderError) {
	p.pos++
	low, err := p.parseOperand(allowAgg)
	if err != nil {
		return nil, err
	}
	if !p.peek().isWord("AND") {
		return nil, parseError("expected AND in BETWEEN", p.curOffset())
	}
	p.pos++
	high, err := p.parseOperand(allowAgg)
	if err != nil {
		return nil, err
	}
	cmp.Op = queravuev1.SqlOperator_SQL_OPERATOR_BETWEEN
	cmp.Operands = []*queravuev1.SqlOperand{low, high}
	return wrapComparison(cmp), nil
}

func (p *parser) matchComparisonPunct() (queravuev1.SqlOperator, int, bool) {
	t0 := p.peek()
	if t0.kind != sqlsplit.TokenPunct {
		return 0, 0, false
	}
	t1, has1 := p.peekAt(1)
	adjacent := has1 && t1.kind == sqlsplit.TokenPunct && t0.end == t1.start
	switch t0.text {
	case "=":
		return queravuev1.SqlOperator_SQL_OPERATOR_EQ, 1, true
	case "<":
		if adjacent && t1.text == ">" {
			return queravuev1.SqlOperator_SQL_OPERATOR_NE, 2, true
		}
		if adjacent && t1.text == "=" {
			return queravuev1.SqlOperator_SQL_OPERATOR_LE, 2, true
		}
		return queravuev1.SqlOperator_SQL_OPERATOR_LT, 1, true
	case ">":
		if adjacent && t1.text == "=" {
			return queravuev1.SqlOperator_SQL_OPERATOR_GE, 2, true
		}
		return queravuev1.SqlOperator_SQL_OPERATOR_GT, 1, true
	case "!":
		if adjacent && t1.text == "=" {
			return queravuev1.SqlOperator_SQL_OPERATOR_NE, 2, true
		}
	}
	return 0, 0, false
}

func (p *parser) parseOperand(allowAgg bool) (*queravuev1.SqlOperand, *queravuev1.QueryBuilderError) {
	if p.atEnd() {
		return nil, parseError("expected operand", p.eofOffset())
	}
	tok := p.peek()

	if tok.isPunct("(") {
		if t1, ok := p.peekAt(1); ok && (t1.isWord("SELECT") || t1.isWord("WITH")) {
			return nil, unsupportedError("subqueries are not supported", tok.start)
		}
		return nil, unsupportedError("parenthesized expressions in operands are not supported", tok.start)
	}
	if tok.isWord("CASE") || tok.isWord("CAST") {
		return nil, unsupportedError(fmt.Sprintf("%s expressions are not supported", tok.up), tok.start)
	}
	if tok.isWord("NULL") {
		p.pos++
		return literalOperand(&queravuev1.SqlLiteral{
			Value: &queravuev1.SqlLiteral_NullValue{NullValue: true},
		}), nil
	}
	if tok.isWord("TRUE") || tok.isWord("FALSE") {
		p.pos++
		return literalOperand(&queravuev1.SqlLiteral{
			Value: &queravuev1.SqlLiteral_BoolValue{BoolValue: tok.up == "TRUE"},
		}), nil
	}
	if tok.kind == sqlsplit.TokenString {
		p.pos++
		return literalOperand(&queravuev1.SqlLiteral{
			Value: &queravuev1.SqlLiteral_StringValue{StringValue: p.unquoteString(tok.text)},
		}), nil
	}
	if tok.kind == sqlsplit.TokenNumber {
		p.pos++
		lit, err := parseNumberLiteral(tok.text, false, tok.start)
		if err != nil {
			return nil, err
		}
		return literalOperand(lit), nil
	}
	if tok.isPunct("-") || tok.isPunct("+") {
		t1, ok := p.peekAt(1)
		if !ok || t1.kind != sqlsplit.TokenNumber {
			return nil, parseError("expected number after unary sign", tok.start)
		}
		neg := tok.isPunct("-")
		p.pos += 2
		lit, err := parseNumberLiteral(t1.text, neg, tok.start)
		if err != nil {
			return nil, err
		}
		return literalOperand(lit), nil
	}

	if _, ok := parseAggregateKeyword(tok); ok && p.peekTokenIsPunct(1, "(") {
		if !allowAgg {
			return nil, unsupportedError("aggregate functions are not allowed in this clause", tok.start)
		}
		agg, err := p.parseAggregateExpr()
		if err != nil {
			return nil, err
		}
		return &queravuev1.SqlOperand{
			Kind: &queravuev1.SqlOperand_Aggregate{Aggregate: agg},
		}, nil
	}

	if tok.isIdent() && p.peekTokenIsPunct(1, "(") {
		return nil, unsupportedError(fmt.Sprintf("function %s is not supported", tok.text), tok.start)
	}

	if tok.isIdent() {
		col, err := p.parseColumnRef()
		if err != nil {
			return nil, err
		}
		return &queravuev1.SqlOperand{
			Kind: &queravuev1.SqlOperand_Column{Column: col},
		}, nil
	}

	return nil, parseError(fmt.Sprintf("unexpected token %q", tok.text), tok.start)
}

func literalOperand(lit *queravuev1.SqlLiteral) *queravuev1.SqlOperand {
	return &queravuev1.SqlOperand{Kind: &queravuev1.SqlOperand_Literal{Literal: lit}}
}

func parseNumberLiteral(raw string, neg bool, offset int) (*queravuev1.SqlLiteral, *queravuev1.QueryBuilderError) {
	numStr := raw
	if neg {
		numStr = "-" + raw
	}
	if strings.ContainsAny(raw, ".eE") {
		f, err := strconv.ParseFloat(numStr, 64)
		if err != nil {
			return nil, parseError("invalid floating point literal", offset)
		}
		return &queravuev1.SqlLiteral{
			Value: &queravuev1.SqlLiteral_DoubleValue{DoubleValue: f},
		}, nil
	}
	n, err := strconv.ParseInt(numStr, 10, 64)
	if err != nil {
		return nil, parseError("invalid integer literal", offset)
	}
	return &queravuev1.SqlLiteral{
		Value: &queravuev1.SqlLiteral_IntValue{IntValue: n},
	}, nil
}

func (p *parser) parseColumnRef() (*queravuev1.SqlColumnRef, *queravuev1.QueryBuilderError) {
	first := p.peek()
	if !first.isIdent() {
		return nil, parseError("expected column name", p.curOffset())
	}
	p.pos++
	if !p.peek().isPunct(".") {
		return &queravuev1.SqlColumnRef{Column: p.unquote(first)}, nil
	}
	p.pos++
	second := p.peek()
	if !second.isIdent() {
		return nil, parseError("expected column name after '.'", p.curOffset())
	}
	p.pos++
	if p.peek().isPunct(".") {
		return nil, unsupportedError("three-part column names are not supported", p.peek().start)
	}
	return &queravuev1.SqlColumnRef{
		TableAlias: p.unquote(first),
		Column:     p.unquote(second),
	}, nil
}

func parseAggregateKeyword(tok token) (queravuev1.SqlAggregate, bool) {
	if tok.kind != sqlsplit.TokenWord {
		return 0, false
	}
	switch tok.up {
	case "COUNT":
		return queravuev1.SqlAggregate_SQL_AGGREGATE_COUNT, true
	case "SUM":
		return queravuev1.SqlAggregate_SQL_AGGREGATE_SUM, true
	case "AVG":
		return queravuev1.SqlAggregate_SQL_AGGREGATE_AVG, true
	case "MIN":
		return queravuev1.SqlAggregate_SQL_AGGREGATE_MIN, true
	case "MAX":
		return queravuev1.SqlAggregate_SQL_AGGREGATE_MAX, true
	}
	return 0, false
}

func (p *parser) parseAggregateExpr() (*queravuev1.SqlAggregateExpr, *queravuev1.QueryBuilderError) {
	fnTok := p.peek()
	fn, ok := parseAggregateKeyword(fnTok)
	if !ok {
		return nil, unsupportedError(fmt.Sprintf("function %s is not supported", fnTok.text), fnTok.start)
	}
	p.pos++
	if !p.peek().isPunct("(") {
		return nil, parseError("expected '(' after aggregate function", p.curOffset())
	}
	p.pos++

	distinct := false
	if p.peek().isWord("DISTINCT") {
		distinct = true
		p.pos++
	}

	var col *queravuev1.SqlColumnRef
	if p.peek().isPunct("*") {
		if fn != queravuev1.SqlAggregate_SQL_AGGREGATE_COUNT || distinct {
			return nil, unsupportedError("only COUNT(*) supports '*'", p.peek().start)
		}
		p.pos++
		col = &queravuev1.SqlColumnRef{}
	} else {
		if !p.peek().isIdent() || p.peekTokenIsPunct(1, "(") {
			return nil, unsupportedError("aggregate arguments must be column references", p.curOffset())
		}
		var err *queravuev1.QueryBuilderError
		col, err = p.parseColumnRef()
		if err != nil {
			return nil, err
		}
	}
	if !p.peek().isPunct(")") {
		return nil, unsupportedError("complex aggregate arguments are not supported", p.curOffset())
	}
	p.pos++
	return &queravuev1.SqlAggregateExpr{
		Function: fn,
		Column:   col,
		Distinct: distinct,
	}, nil
}

func (p *parser) parseGroupBy() ([]*queravuev1.SqlColumnRef, *queravuev1.QueryBuilderError) {
	p.pos++
	if !p.peek().isWord("BY") {
		return nil, parseError("expected BY after GROUP", p.curOffset())
	}
	p.pos++
	var cols []*queravuev1.SqlColumnRef
	for {
		tok := p.peek()
		if tok.isWord("ROLLUP") || tok.isWord("CUBE") || tok.isWord("GROUPING") {
			return nil, unsupportedError(fmt.Sprintf("GROUP BY %s is not supported", tok.up), tok.start)
		}
		if !tok.isIdent() || p.peekTokenIsPunct(1, "(") {
			return nil, unsupportedError("GROUP BY items must be column references", tok.start)
		}
		col, err := p.parseColumnRef()
		if err != nil {
			return nil, err
		}
		cols = append(cols, col)
		if !p.peek().isPunct(",") {
			break
		}
		p.pos++
	}
	return cols, nil
}

func (p *parser) parseOrderBy() ([]*queravuev1.SqlOrderTerm, *queravuev1.QueryBuilderError) {
	p.pos++
	if !p.peek().isWord("BY") {
		return nil, parseError("expected BY after ORDER", p.curOffset())
	}
	p.pos++

	if p.tryConsumeMssqlNullPaginationOrder() {
		return nil, nil
	}

	orderNullsSample := p.dialect.OrderTerm("x", false, sqldialect.NullsFirst)
	usesCaseNulls := strings.Contains(orderNullsSample, "CASE WHEN")
	usesIsNullPrefix := !usesCaseNulls && strings.Contains(orderNullsSample, "IS NULL")

	var terms []*queravuev1.SqlOrderTerm
	for {
		var term *queravuev1.SqlOrderTerm
		var err *queravuev1.QueryBuilderError
		switch {
		case usesCaseNulls && p.peek().isWord("CASE"):
			term, err = p.parseCaseNullOrderTerm()
		default:
			term, err = p.parseSingleOrderTerm(usesIsNullPrefix)
		}
		if err != nil {
			return nil, err
		}
		terms = append(terms, term)
		if !p.peek().isPunct(",") {
			break
		}
		p.pos++
	}
	return terms, nil
}

func (p *parser) tryConsumeMssqlNullPaginationOrder() bool {
	if !p.peek().isPunct("(") {
		return false
	}
	t1, ok1 := p.peekAt(1)
	t2, ok2 := p.peekAt(2)
	t3, ok3 := p.peekAt(3)
	if !ok1 || !ok2 || !ok3 || !t1.isWord("SELECT") || !t2.isWord("NULL") || !t3.isPunct(")") {
		return false
	}
	t4, ok4 := p.peekAt(4)
	if !ok4 || (!t4.isWord("OFFSET") && !t4.isWord("FETCH")) {
		return false
	}
	p.pos += 4
	return true
}

func (p *parser) parseCaseNullOrderTerm() (*queravuev1.SqlOrderTerm, *queravuev1.QueryBuilderError) {
	caseStart := p.peek().start
	p.pos++
	if !p.peek().isWord("WHEN") {
		return nil, unsupportedError("CASE expressions in ORDER BY are not supported", caseStart)
	}
	p.pos++
	expr1, err := p.parseOperand(true)
	if err != nil {
		return nil, err
	}
	if expr1.GetLiteral() != nil || !p.peek().isWord("IS") {
		return nil, unsupportedError("CASE expressions in ORDER BY are not supported", caseStart)
	}
	p.pos++
	if !p.peek().isWord("NULL") {
		return nil, unsupportedError("CASE expressions in ORDER BY are not supported", caseStart)
	}
	p.pos++
	if !p.peek().isWord("THEN") {
		return nil, unsupportedError("CASE expressions in ORDER BY are not supported", caseStart)
	}
	p.pos++
	thenTok := p.peek()
	if thenTok.kind != sqlsplit.TokenNumber || (thenTok.text != "0" && thenTok.text != "1") {
		return nil, unsupportedError("CASE expressions in ORDER BY are not supported", caseStart)
	}
	p.pos++
	if !p.peek().isWord("ELSE") {
		return nil, unsupportedError("CASE expressions in ORDER BY are not supported", caseStart)
	}
	p.pos++
	elseTok := p.peek()
	wantElse := "1"
	nulls := queravuev1.SqlNulls_SQL_NULLS_FIRST
	if thenTok.text == "1" {
		wantElse = "0"
		nulls = queravuev1.SqlNulls_SQL_NULLS_LAST
	}
	if elseTok.kind != sqlsplit.TokenNumber || elseTok.text != wantElse {
		return nil, unsupportedError("CASE expressions in ORDER BY are not supported", caseStart)
	}
	p.pos++
	if !p.peek().isWord("END") || !p.peekTokenIsPunct(1, ",") {
		return nil, unsupportedError("CASE expressions in ORDER BY are not supported", caseStart)
	}
	p.pos += 2

	expr2, err := p.parseOperand(true)
	if err != nil {
		return nil, err
	}
	if !proto.Equal(expr1, expr2) {
		return nil, unsupportedError("CASE expressions in ORDER BY are not supported", caseStart)
	}
	desc := p.parseSortDirection()
	return &queravuev1.SqlOrderTerm{
		Expression: expr1,
		Descending: desc,
		Nulls:      nulls,
	}, nil
}

func (p *parser) parseSingleOrderTerm(allowIsNullPrefix bool) (*queravuev1.SqlOrderTerm, *queravuev1.QueryBuilderError) {
	start := p.curOffset()
	expr, err := p.parseOperand(true)
	if err != nil {
		return nil, err
	}
	if expr.GetLiteral() != nil {
		return nil, unsupportedError("ORDER BY literal or column position is not supported", start)
	}

	if allowIsNullPrefix && p.peek().isWord("IS") {
		p.pos++
		if !p.peek().isWord("NULL") {
			return nil, unsupportedError("expressions in ORDER BY are not supported", start)
		}
		p.pos++
		nulls := queravuev1.SqlNulls_SQL_NULLS_LAST
		if p.peek().isWord("DESC") {
			nulls = queravuev1.SqlNulls_SQL_NULLS_FIRST
			p.pos++
		} else if p.peek().isWord("ASC") {
			p.pos++
		}
		if !p.peek().isPunct(",") {
			return nil, unsupportedError("expressions in ORDER BY are not supported", start)
		}
		p.pos++
		expr2, err := p.parseOperand(true)
		if err != nil {
			return nil, err
		}
		if !proto.Equal(expr, expr2) {
			return nil, unsupportedError("expressions in ORDER BY are not supported", start)
		}
		desc := p.parseSortDirection()
		return &queravuev1.SqlOrderTerm{
			Expression: expr,
			Descending: desc,
			Nulls:      nulls,
		}, nil
	}

	if isSelectExprOp(p.peek()) {
		return nil, unsupportedError("expressions in ORDER BY are not supported", p.peek().start)
	}

	desc := p.parseSortDirection()
	nulls := queravuev1.SqlNulls_SQL_NULLS_UNSPECIFIED
	if p.peek().isWord("NULLS") {
		p.pos++
		switch {
		case p.peek().isWord("FIRST"):
			nulls = queravuev1.SqlNulls_SQL_NULLS_FIRST
			p.pos++
		case p.peek().isWord("LAST"):
			nulls = queravuev1.SqlNulls_SQL_NULLS_LAST
			p.pos++
		default:
			return nil, parseError("expected FIRST or LAST after NULLS", p.curOffset())
		}
	}
	return &queravuev1.SqlOrderTerm{
		Expression: expr,
		Descending: desc,
		Nulls:      nulls,
	}, nil
}

func (p *parser) parseSortDirection() bool {
	if p.peek().isWord("DESC") {
		p.pos++
		return true
	}
	if p.peek().isWord("ASC") {
		p.pos++
	}
	return false
}

func (p *parser) parseLimitOffset() (limit, offset uint64, err *queravuev1.QueryBuilderError) {
	if p.peek().isWord("LIMIT") {
		p.pos++
		if p.peek().isWord("ALL") {
			return 0, 0, unsupportedError("LIMIT ALL is not supported", p.peek().start)
		}
		limTok := p.peek()
		lim, err := p.parseUint64()
		if err != nil {
			return 0, 0, err
		}
		if lim == 0 {
			return 0, 0, unsupportedError("LIMIT 0 is not supported", limTok.start)
		}
		if p.peek().isPunct(",") {
			return 0, 0, unsupportedError("MySQL comma LIMIT syntax is not supported; use LIMIT ... OFFSET ...", p.peek().start)
		}
		limit = lim
		if p.peek().isWord("OFFSET") {
			p.pos++
			off, err := p.parseUint64()
			if err != nil {
				return 0, 0, err
			}
			offset = off
		}
		return limit, offset, nil
	}

	if p.peek().isWord("OFFSET") {
		p.pos++
		off, err := p.parseUint64()
		if err != nil {
			return 0, 0, err
		}
		offset = off
		if p.peek().isWord("ROW") || p.peek().isWord("ROWS") {
			p.pos++
		}
		if p.peek().isWord("LIMIT") {
			p.pos++
			limTok := p.peek()
			lim, err := p.parseUint64()
			if err != nil {
				return 0, 0, err
			}
			if lim == 0 {
				return 0, 0, unsupportedError("LIMIT 0 is not supported", limTok.start)
			}
			limit = lim
		}
	}

	if p.peek().isWord("FETCH") {
		lim, err := p.parseFetch()
		if err != nil {
			return 0, 0, err
		}
		limit = lim
	}
	return limit, offset, nil
}

func (p *parser) parseFetch() (uint64, *queravuev1.QueryBuilderError) {
	p.pos++
	if !p.peek().isWord("FIRST") && !p.peek().isWord("NEXT") {
		return 0, parseError("expected FIRST or NEXT after FETCH", p.curOffset())
	}
	p.pos++
	limTok := p.peek()
	lim, err := p.parseUint64()
	if err != nil {
		return 0, err
	}
	if lim == 0 {
		return 0, unsupportedError("FETCH 0 ROWS is not supported", limTok.start)
	}
	if p.peek().isWord("PERCENT") {
		return 0, unsupportedError("FETCH PERCENT is not supported", p.peek().start)
	}
	if !p.peek().isWord("ROW") && !p.peek().isWord("ROWS") {
		return 0, parseError("expected ROW or ROWS in FETCH clause", p.curOffset())
	}
	p.pos++
	if p.peek().isWord("WITH") {
		return 0, unsupportedError("FETCH WITH TIES is not supported", p.peek().start)
	}
	if !p.peek().isWord("ONLY") {
		return 0, parseError("expected ONLY in FETCH clause", p.curOffset())
	}
	p.pos++
	return lim, nil
}

func (p *parser) parseUint64() (uint64, *queravuev1.QueryBuilderError) {
	tok := p.peek()
	if tok.kind != sqlsplit.TokenNumber || strings.ContainsAny(tok.text, ".eE") {
		return 0, parseError("expected non-negative integer", p.curOffset())
	}
	v, err := strconv.ParseUint(tok.text, 10, 64)
	if err != nil {
		return 0, parseError("invalid integer", tok.start)
	}
	p.pos++
	return v, nil
}

func (p *parser) unquote(tok token) string {
	if tok.kind != sqlsplit.TokenQuotedIdent {
		return tok.text
	}
	text := tok.text
	open := text[0]
	closer := open
	if open == '[' {
		closer = ']'
	}
	body := text[1 : len(text)-1]
	if p.lexer == sqlsplit.MSSQL && open == '[' {
		return strings.ReplaceAll(body, "]]", "]")
	}
	if p.lexer == sqlsplit.ClickHouse {
		body = strings.ReplaceAll(body, string([]byte{closer, closer}), string(closer))
		return strings.ReplaceAll(body, `\\`, `\`)
	}
	return strings.ReplaceAll(body, string([]byte{closer, closer}), string(closer))
}

func (p *parser) unquoteString(raw string) string {
	if (p.lexer == sqlsplit.Postgres || p.lexer == sqlsplit.DuckDB) && strings.HasPrefix(raw, "$") {
		second := strings.IndexByte(raw[1:], '$')
		tag := raw[:second+2]
		return raw[len(tag) : len(raw)-len(tag)]
	}
	if p.lexer == sqlsplit.Oracle && len(raw) >= 4 && (raw[0] == 'q' || raw[0] == 'Q' || raw[0] == 'n' || raw[0] == 'N') {
		qIdx := strings.IndexByte(raw, '\'')
		if qIdx > 0 && qIdx+2 < len(raw) {
			return raw[qIdx+2 : len(raw)-2]
		}
	}
	if p.lexer == sqlsplit.MSSQL && (strings.HasPrefix(raw, "N'") || strings.HasPrefix(raw, "n'")) {
		return strings.ReplaceAll(raw[2:len(raw)-1], "''", "'")
	}
	backslash := p.lexer == sqlsplit.MySQL || p.lexer == sqlsplit.ClickHouse
	if (p.lexer == sqlsplit.Postgres || p.lexer == sqlsplit.DuckDB) && (strings.HasPrefix(raw, "E'") || strings.HasPrefix(raw, "e'")) {
		backslash = true
		raw = raw[1:]
	}
	quote := raw[0]
	body := raw[1 : len(raw)-1]
	if !backslash {
		return strings.ReplaceAll(body, string([]byte{quote, quote}), string(quote))
	}
	return unescapeBackslashString(body, quote)
}

func unescapeBackslashString(body string, quote byte) string {
	var b strings.Builder
	b.Grow(len(body))
	for i := 0; i < len(body); i++ {
		c := body[i]
		if c == quote && i+1 < len(body) && body[i+1] == quote {
			b.WriteByte(quote)
			i++
			continue
		}
		if c == '\\' && i+1 < len(body) {
			i++
			switch body[i] {
			case '0':
				b.WriteByte(0)
			case 'b':
				b.WriteByte('\b')
			case 'n':
				b.WriteByte('\n')
			case 'r':
				b.WriteByte('\r')
			case 't':
				b.WriteByte('\t')
			case 'Z':
				b.WriteByte(0x1a)
			case '\\', '\'', '"':
				b.WriteByte(body[i])
			default:
				b.WriteByte(body[i])
			}
			continue
		}
		b.WriteByte(c)
	}
	return b.String()
}

func parseError(msg string, offset int) *queravuev1.QueryBuilderError {
	off := uint32(max(offset, 0)) //nolint:gosec // bounded by input string length
	return &queravuev1.QueryBuilderError{
		Kind:    queravuev1.QueryBuilderErrorKind_QUERY_BUILDER_ERROR_KIND_PARSE,
		Message: msg,
		Offset:  &off,
	}
}

func unsupportedError(msg string, offset int) *queravuev1.QueryBuilderError {
	off := uint32(max(offset, 0)) //nolint:gosec // bounded by input string length
	return &queravuev1.QueryBuilderError{
		Kind:    queravuev1.QueryBuilderErrorKind_QUERY_BUILDER_ERROR_KIND_UNSUPPORTED_CONSTRUCT,
		Message: msg,
		Offset:  &off,
	}
}
