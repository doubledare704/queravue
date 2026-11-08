package format

import "github.com/doubledare704/queravue/core/internal/sqlsplit"

type renderer struct {
	w *writer
	o Options
}

func (r *renderer) statement(nodes []node, level int) {
	for _, s := range segments(nodes) {
		r.segment(s, level)
	}
}

func (r *renderer) segment(s segment, level int) {
	r.w.newline(level)
	for _, c := range s.lead {
		r.w.comment(c.tok, level)
	}
	if len(s.head) == 0 {
		r.inline(s.body, level)
		return
	}
	whole := append(append([]node{}, s.head...), s.body...)
	if r.fits(whole) {
		r.flat(whole)
		return
	}
	r.inline(s.head, level)
	switch s.kind {
	case kindList:
		if items := splitCommas(s.body); len(items) > 1 {
			r.brokenList(items, level+1)
		} else {
			r.inline(s.body, level)
		}
	case kindCond:
		r.brokenCond(splitCond(s.body), level)
	case kindJoin:
		r.brokenJoin(s.body, level)
	default:
		r.inline(s.body, level)
	}
}

func (r *renderer) brokenList(items []listItem, level int) {
	leading := r.o.CommaStyle == CommaLeading
	for _, it := range items {
		if len(it.afterComma) > 0 {
			leading = false
		}
	}
	for i, it := range items {
		r.w.newline(level)
		if leading && i > 0 {
			r.w.atom(token{text: ",", kind: sqlsplit.TokenPunct})
		}
		r.inline(it.nodes, level)
		last := i == len(items)-1
		if !leading && !last {
			r.w.atom(token{text: ",", kind: sqlsplit.TokenPunct})
			r.comments(it.afterComma, level)
		}
	}
}

func (r *renderer) comments(cs []node, level int) {
	for _, c := range cs {
		r.w.comment(token{text: c.tok.text, kind: c.tok.kind}, level)
	}
}

func (r *renderer) brokenCond(parts []condPart, level int) {
	r.inline(parts[0].nodes, level)
	for _, p := range parts[1:] {
		r.w.newline(level + 1)
		r.w.atom(*p.conj)
		r.inline(p.nodes, level+1)
	}
}

func (r *renderer) brokenJoin(body []node, level int) {
	split := len(body)
	for i, n := range body {
		if w := n.upperWord(); w == "ON" || w == "USING" {
			split = i
			break
		}
	}
	r.inline(body[:split], level)
	if split == len(body) {
		return
	}
	r.w.newline(level + 1)
	r.w.atom(body[split].tok)
	rest := body[split+1:]
	if body[split].upperWord() == "USING" {
		r.inline(rest, level+1)
		return
	}
	parts := splitCond(rest)
	r.inline(parts[0].nodes, level+1)
	for _, p := range parts[1:] {
		r.w.newline(level + 2)
		r.w.atom(*p.conj)
		r.inline(p.nodes, level+2)
	}
}

func (r *renderer) inline(nodes []node, level int) {
	for _, n := range nodes {
		switch n.kind {
		case atomNode:
			r.w.atom(n.tok)
		case commentNode:
			r.w.comment(n.tok, level)
		case groupNode:
			r.group(n, level)
		}
	}
}

func (r *renderer) group(g node, level int) {
	if r.fits([]node{g}) {
		r.flat([]node{g})
		return
	}
	r.w.atom(g.tok)
	items := splitCommas(g.kids)
	parts := splitCond(g.kids)
	switch {
	case isSubquery(g.kids):
		r.statement(g.kids, level+1)
		r.closeGroup(g, level)
	case len(items) > 1:
		r.brokenList(items, level+1)
		r.closeGroup(g, level)
	case len(parts) > 1:
		r.w.newline(level + 1)
		r.inline(parts[0].nodes, level+1)
		for _, p := range parts[1:] {
			r.w.newline(level + 1)
			r.w.atom(*p.conj)
			r.inline(p.nodes, level+1)
		}
		r.closeGroup(g, level)
	default:
		r.inline(g.kids, level)
		r.w.atom(g.close)
	}
}

func (r *renderer) closeGroup(g node, level int) {
	r.w.newline(level)
	r.w.atom(g.close)
}

func (r *renderer) fits(nodes []node) bool {
	s := r.w.scratch()
	flatInto(s, nodes)
	return !s.forced && s.col+1 <= r.o.MaxLineWidth
}

func (r *renderer) flat(nodes []node) { flatInto(r.w, nodes) }

func flatInto(w *writer, nodes []node) {
	for _, n := range nodes {
		switch n.kind {
		case atomNode:
			w.atom(n.tok)
		case commentNode:
			w.flatComment(n.tok)
		case groupNode:
			w.atom(n.tok)
			flatInto(w, n.kids)
			w.atom(n.close)
		}
	}
}
