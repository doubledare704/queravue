package completion

import (
	"context"
	"fmt"
	"slices"
	"strings"

	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

// Kind says what a completion item is.
type Kind int

// Item kinds.
const (
	KindKeyword Kind = iota + 1
	KindFunction
	KindTable
	KindView
	KindColumn
	KindSchema
	KindAlias
)

// Item is one completion candidate. Offsets are UTF-16 code units.
type Item struct {
	Label        string
	Kind         Kind
	Detail       string
	InsertText   string
	ReplaceStart int
	ReplaceEnd   int
	SortKey      string
}

// Request is the input of Complete.
type Request struct {
	Dialect sqlsplit.Dialect
	// Text is the statement window; Cursor is a UTF-16 offset into it.
	Text   string
	Cursor int
	// MaxItems of 0 means DefaultMaxItems.
	MaxItems int
	// Schema is the schema unqualified names refer to; empty picks a default.
	Schema   string
	Snapshot *Snapshot
	Recency  *Recency
}

// Result is the output of Complete.
type Result struct {
	Items []Item
	// Incomplete is true when MaxItems cut the list.
	Incomplete bool
	State      State
}

// Item limits.
const (
	DefaultMaxItems = 200
	MaxItemsLimit   = 1000
)

// Ranking tiers, best first (ADR 0015).
const (
	tierScope = iota + 1
	tierColumns
	tierObjects
	tierWords
	tierRest
)

type candidate struct {
	label     string
	matchName string
	kind      Kind
	detail    string
	insert    string
	tier      int
	wordRel   int
}

// Complete returns ranked candidates for the cursor. It never fails on
// unparsable SQL; it returns an error only when ctx ends.
func Complete(ctx context.Context, req Request) (Result, error) {
	snap := req.Snapshot
	res := Result{State: snap.State()}
	om := sqlsplit.NewOffsetMap(req.Text)
	a := Analyze(req.Dialect, req.Text, om.ToByte(req.Cursor))
	if a.Suppress {
		return res, nil
	}
	if err := ctx.Err(); err != nil {
		return res, fmt.Errorf("completion: %w", err)
	}
	g := generator{req: req, a: a, snap: snap, schema: snap.DefaultSchema(req.Schema)}
	cands := g.candidates()
	if err := ctx.Err(); err != nil {
		return res, fmt.Errorf("completion: %w", err)
	}
	items := g.rank(cands, om)
	limit := req.MaxItems
	if limit <= 0 {
		limit = DefaultMaxItems
	}
	limit = min(limit, MaxItemsLimit)
	if len(items) > limit {
		items, res.Incomplete = items[:limit], true
	}
	res.Items = items
	g.touchRecency()
	return res, nil
}

type generator struct {
	req    Request
	a      Context
	snap   *Snapshot
	schema string
	cands  []candidate
}

func (g *generator) add(c candidate) { g.cands = append(g.cands, c) }

func (g *generator) candidates() []candidate {
	if len(g.a.Qualifier) > 0 {
		g.qualified()
		return g.cands
	}
	switch g.a.Clause {
	case ClauseFrom, ClauseInsertTarget, ClauseUpdateTarget:
		if g.a.AtTable {
			g.addCTEs()
			g.addObjects(tierColumns, nil)
		}
	case ClauseInsertColumns:
		g.addScopeColumns()
	case ClauseValues:
		g.addFunctions()
	case ClauseNone:
		g.addCTEs()
		if g.a.AtTable {
			g.addObjects(tierColumns, nil)
		} else {
			g.addObjects(tierRest, nil)
		}
	default:
		g.addScopeNames()
		g.addScopeColumns()
		g.addSelectNames()
		g.addObjects(tierObjects, g.inScope())
		g.addFunctions()
	}
	g.addKeywords()
	return g.cands
}

func (g *generator) inScope() map[*Table]bool {
	out := map[*Table]bool{}
	for _, t := range g.a.Scope {
		for _, found := range g.lookup(t) {
			out[found] = true
		}
	}
	return out
}

func (g *generator) lookup(t tableRef) []*Table {
	if t.derived != nil || g.findCTE(t) != nil {
		return nil
	}
	found := g.snap.Lookup(t.schema, t.name)
	if len(found) > 1 && t.schema == "" {
		for _, f := range found {
			if strings.EqualFold(f.Schema, g.schema) {
				return []*Table{f}
			}
		}
	}
	return found
}

func (g *generator) findCTE(t tableRef) *cte {
	if t.schema != "" || t.derived != nil {
		return nil
	}
	for i := range g.a.CTEs {
		if strings.EqualFold(g.a.CTEs[i].name, t.name) {
			return &g.a.CTEs[i]
		}
	}
	return nil
}

func (g *generator) columnsOf(t tableRef, depth int) []Column {
	if depth > 4 {
		return nil
	}
	if c := g.findCTE(t); c != nil {
		return g.derivedColumns(c.derived, depth+1)
	}
	if t.derived != nil {
		return g.derivedColumns(t.derived, depth+1)
	}
	if found := g.lookup(t); len(found) > 0 {
		return found[0].Columns
	}
	return nil
}

func (g *generator) derivedColumns(d *derivedTable, depth int) []Column {
	if len(d.explicit) > 0 {
		out := make([]Column, len(d.explicit))
		for i, n := range d.explicit {
			out[i] = Column{Name: n}
		}
		return out
	}
	var out []Column
	for _, it := range d.items {
		switch {
		case !it.star:
			out = append(out, Column{Name: it.name})
		case it.from == "":
			for _, in := range d.inner {
				out = append(out, g.columnsOf(in, depth)...)
			}
		default:
			for _, in := range d.inner {
				if strings.EqualFold(in.visibleName(), it.from) {
					out = append(out, g.columnsOf(in, depth)...)
				}
			}
		}
	}
	return out
}

func (g *generator) addColumns(cols []Column, owner string, tier int) {
	for _, c := range cols {
		detail := owner
		if c.Type != "" {
			detail = c.Type + " · " + owner
		}
		g.add(candidate{label: c.Name, matchName: c.Name, kind: KindColumn, detail: detail, insert: identForInsert(g.req.Dialect, c.Name), tier: tier})
	}
}

func (g *generator) addScopeColumns() {
	seen := map[string]bool{}
	for _, t := range g.a.Scope {
		key := lower(t.visibleName()) + "|" + lower(t.schema)
		if seen[key] {
			continue
		}
		seen[key] = true
		g.addColumns(g.columnsOf(t, 0), t.visibleName(), tierColumns)
	}
}

func (g *generator) addScopeNames() {
	seen := map[string]bool{}
	for _, t := range g.a.Scope {
		name := t.visibleName()
		if name == "" || seen[lower(name)] {
			continue
		}
		seen[lower(name)] = true
		kind, detail := KindTable, "table"
		if t.alias != "" {
			kind, detail = KindAlias, "alias of "+displayTable(t)
		}
		g.add(candidate{label: name, matchName: name, kind: kind, detail: detail, insert: identForInsert(g.req.Dialect, name), tier: tierScope})
	}
}

func displayTable(t tableRef) string {
	switch {
	case t.derived != nil && t.name == "":
		return "subquery"
	case t.schema != "":
		return t.schema + "." + t.name
	}
	return t.name
}

func (g *generator) addSelectNames() {
	switch g.a.Clause {
	case ClauseGroupBy, ClauseOrderBy, ClauseHaving:
		for _, n := range g.a.SelectNames {
			g.add(candidate{label: n, matchName: n, kind: KindColumn, detail: "select list", insert: identForInsert(g.req.Dialect, n), tier: tierColumns})
		}
	}
}

func (g *generator) addCTEs() {
	for _, c := range g.a.CTEs {
		g.add(candidate{label: c.name, matchName: c.name, kind: KindTable, detail: "CTE", insert: identForInsert(g.req.Dialect, c.name), tier: tierScope})
	}
}

// addObjects adds tables and views: those of the default schema plain, others
// schema-qualified, and the schema names. Tables in skip are left out.
func (g *generator) addObjects(tier int, skip map[*Table]bool) {
	for _, t := range g.snap.Tables() {
		if skip[t] {
			continue
		}
		kind, detail := KindTable, "table"
		if t.View {
			kind, detail = KindView, "view"
		}
		insert := identForInsert(g.req.Dialect, t.Name)
		label, tableTier := t.Name, tier
		if g.schema == "" || !strings.EqualFold(t.Schema, g.schema) {
			label = t.Schema + "." + t.Name
			insert = identForInsert(g.req.Dialect, t.Schema) + "." + insert
			detail += " · " + t.Schema
			tableTier = max(tier, tierObjects)
		}
		g.add(candidate{label: label, matchName: t.Name, kind: kind, detail: detail, insert: insert, tier: tableTier})
	}
	for _, s := range g.snap.Schemas() {
		g.add(candidate{label: s, matchName: s, kind: KindSchema, detail: "schema", insert: identForInsert(g.req.Dialect, s), tier: max(tier, tierObjects)})
	}
}

func (g *generator) qualified() {
	q := g.a.Qualifier
	for _, t := range g.a.Scope {
		if len(q) == 1 && strings.EqualFold(t.visibleName(), q[0]) {
			g.addColumns(g.columnsOf(t, 0), t.visibleName(), tierScope)
			return
		}
	}
	if len(q) == 1 {
		if c := g.findCTE(tableRef{name: q[0]}); c != nil {
			g.addColumns(g.derivedColumns(c.derived, 1), c.name, tierScope)
			return
		}
	}
	schema, table := "", q[len(q)-1]
	if len(q) >= 2 {
		schema = q[len(q)-2]
	}
	if found := g.snap.Lookup(schema, table); len(found) > 0 && (len(q) >= 2 || !g.snap.HasSchema(table)) {
		g.addColumns(found[0].Columns, found[0].Name, tierScope)
		return
	}
	target := q[len(q)-1]
	if g.snap.HasSchema(target) {
		for _, t := range g.snap.TablesIn(target) {
			kind, detail := KindTable, "table"
			if t.View {
				kind, detail = KindView, "view"
			}
			g.add(candidate{label: t.Name, matchName: t.Name, kind: kind, detail: detail, insert: identForInsert(g.req.Dialect, t.Name), tier: tierScope})
		}
	}
}

func (g *generator) addFunctions() {
	for _, f := range functionsOf(g.req.Dialect) {
		g.add(candidate{label: f, matchName: f, kind: KindFunction, detail: "function", insert: f, tier: tierWords, wordRel: 0})
	}
}

func (g *generator) addKeywords() {
	relevant := relevantKeywords[g.a.Clause]
	for _, k := range keywordsOf(g.req.Dialect) {
		rel := 1
		if slices.Contains(relevant, k) {
			rel = 0
		}
		g.add(candidate{label: k, matchName: k, kind: KindKeyword, detail: "keyword", insert: k, tier: tierWords, wordRel: rel})
	}
}

var relevantKeywords = map[Clause][]string{
	ClauseNone:         {"SELECT", "INSERT INTO", "UPDATE", "DELETE FROM", "WITH", "CREATE TABLE", "ALTER TABLE", "DROP TABLE", "EXPLAIN", "BEGIN", "COMMIT", "ROLLBACK", "TRUNCATE", "PRAGMA", "USE", "SHOW"},
	ClauseSelect:       {"DISTINCT", "ALL", "FROM", "CASE", "AS", "TOP"},
	ClauseFrom:         {"JOIN", "INNER JOIN", "LEFT JOIN", "RIGHT JOIN", "FULL JOIN", "CROSS JOIN", "WHERE", "GROUP BY", "ORDER BY", "HAVING", "LIMIT", "UNION", "UNION ALL", "ON", "USING", "AS"},
	ClauseOn:           {"AND", "OR", "NOT", "IN", "IS NULL", "IS NOT NULL", "LIKE", "BETWEEN", "WHERE", "JOIN", "INNER JOIN", "LEFT JOIN", "GROUP BY", "ORDER BY"},
	ClauseWhere:        {"AND", "OR", "NOT", "IN", "IS NULL", "IS NOT NULL", "LIKE", "BETWEEN", "EXISTS", "CASE", "GROUP BY", "ORDER BY", "LIMIT"},
	ClauseGroupBy:      {"HAVING", "ORDER BY", "LIMIT"},
	ClauseHaving:       {"AND", "OR", "NOT", "ORDER BY", "LIMIT"},
	ClauseOrderBy:      {"ASC", "DESC", "NULLS FIRST", "NULLS LAST", "LIMIT", "OFFSET"},
	ClauseInsertTarget: {"VALUES", "SELECT", "DEFAULT"},
	ClauseUpdateSet:    {"WHERE", "FROM", "RETURNING", "CASE", "NULL", "DEFAULT"},
	ClauseReturning:    {"AS"},
	ClauseLimit:        {"OFFSET"},
}

func (g *generator) rank(cands []candidate, om sqlsplit.OffsetMap) []Item {
	prefix := g.a.Prefix
	start, end := om.ToUTF16(g.a.ReplaceStart), om.ToUTF16(g.a.ReplaceEnd)
	items := make([]Item, 0, len(cands))
	for _, c := range cands {
		class, ok := matchName(prefix, c.matchName)
		if !ok {
			continue
		}
		exact := 1
		if prefix != "" && strings.EqualFold(prefix, c.matchName) {
			exact = 0
		}
		recency := g.req.Recency.bucket(c.matchName)
		if c.tier == tierWords {
			recency = 2
		}
		insert := c.insert
		if g.a.Quoted && c.kind != KindKeyword && c.kind != KindFunction && !isQuotedIdent(insert) {
			insert = quoteIdent(g.req.Dialect, c.matchName)
		}
		items = append(items, Item{
			Label: c.label, Kind: c.kind, Detail: c.detail, InsertText: insert, ReplaceStart: start, ReplaceEnd: end,
			SortKey: fmt.Sprintf("%d%d%d%d%d%s", c.tier, class, exact, recency, c.wordRel, lower(c.label)),
		})
	}
	slices.SortFunc(items, func(a, b Item) int { return strings.Compare(a.SortKey, b.SortKey) })
	return items
}

func (g *generator) touchRecency() {
	if g.req.Recency == nil {
		return
	}
	var names []string
	for _, t := range g.a.Tokens {
		if t.Kind != sqlsplit.TokenWord && t.Kind != sqlsplit.TokenQuotedIdent {
			continue
		}
		if t.Start == g.a.ReplaceStart && t.End == g.a.ReplaceEnd && g.a.Prefix != "" {
			continue
		}
		text := unquoteIdent(t.Text(g.req.Text))
		if t.Kind == sqlsplit.TokenWord && (slices.Contains(keywordsOf(g.req.Dialect), strings.ToUpper(text)) || reservedWords(g.req.Dialect)[strings.ToUpper(text)]) {
			continue
		}
		names = append(names, text)
	}
	g.req.Recency.Touch(names...)
}
