package format

import "github.com/doubledare704/queravue/core/internal/sqlsplit"

type clauseKind int

const (
	kindPlain clauseKind = iota
	kindList
	kindCond
	kindJoin
	kindSetOp
)

type segment struct {
	lead []node
	head []node
	body []node
	kind clauseKind
}

var joinModifiers = wordSet(`INNER LEFT RIGHT FULL CROSS OUTER NATURAL`)

func segments(nodes []node) []segment {
	var out []segment
	cur := segment{}
	for i := 0; i < len(nodes); {
		n, kind := clauseStart(nodes, i)
		if n == 0 {
			cur.body = append(cur.body, nodes[i])
			i++
			continue
		}
		var lead []node
		for len(cur.body) > 0 && cur.body[len(cur.body)-1].isOwnLineComment() {
			lead = append([]node{cur.body[len(cur.body)-1]}, lead...)
			cur.body = cur.body[:len(cur.body)-1]
		}
		if len(cur.head)+len(cur.body)+len(cur.lead) > 0 {
			out = append(out, cur)
		}
		head := make([]node, n)
		copy(head, nodes[i:i+n])
		for j := range head {
			if head[j].kind == atomNode {
				head[j].tok.keyword = true
			}
		}
		cur = segment{lead: lead, head: head, kind: kind}
		if w := head[0].upperWord(); w == "FETCH" || w == "OFFSET" {
			cur.body = markRowWords(nodes, i+n)
			i += len(cur.body)
		}
		i += n
		if kind == kindSetOp {
			out = append(out, cur)
			cur = segment{}
		}
	}
	if len(cur.head)+len(cur.body)+len(cur.lead) > 0 {
		out = append(out, cur)
	}
	return out
}

func clauseStart(nodes []node, i int) (int, clauseKind) {
	w := nodes[i].upperWord()
	if w == "" || i > 0 && nodes[i-1].isPunct(".") {
		return 0, kindPlain
	}
	at := func(k int) string {
		if i+k < len(nodes) {
			return nodes[i+k].upperWord()
		}
		return ""
	}
	prev := ""
	if i > 0 {
		prev = nodes[i-1].upperWord()
	}
	switch w {
	case "SELECT":
		return selectHeadLength(nodes, i), kindList
	case "FROM":
		if prev == "DISTINCT" {
			return 0, kindPlain
		}
		return 1, kindList
	case "WHERE", "HAVING", "QUALIFY":
		return 1, kindCond
	case "GROUP", "ORDER":
		if at(1) == "BY" {
			return 2, kindList
		}
	case "LIMIT", "OFFSET":
		return 1, kindPlain
	case "FETCH":
		if at(1) == "FIRST" || at(1) == "NEXT" {
			return 2, kindPlain
		}
	case "FOR":
		return lockHeadLength(nodes, i), kindPlain
	case "UNION", "INTERSECT", "EXCEPT":
		if at(1) == "ALL" || at(1) == "DISTINCT" {
			return 2, kindSetOp
		}
		return 1, kindSetOp
	case "VALUES":
		if i > 0 && nodes[i-1].kind == atomNode && nodes[i-1].tok.kind == sqlsplit.TokenPunct {
			return 0, kindPlain
		}
		return 1, kindList
	case "INSERT", "REPLACE":
		if i == 0 {
			return insertHeadLength(nodes), kindPlain
		}
	case "UPDATE":
		if prev == "DO" {
			return 0, kindPlain
		}
		if at(1) == "OR" && at(2) != "" {
			return 3, kindPlain
		}
		return 1, kindPlain
	case "SET":
		return 1, kindList
	case "DELETE":
		if at(1) == "FROM" {
			return 2, kindPlain
		}
		return 1, kindPlain
	case "WITH":
		if i == 0 {
			if at(1) == "RECURSIVE" {
				return 2, kindList
			}
			return 1, kindList
		}
	case "RETURNING", "OUTPUT":
		return 1, kindList
	case "WINDOW":
		if at(2) == "AS" {
			return 1, kindList
		}
	case "ON":
		switch at(1) {
		case "CONFLICT":
			return 2, kindPlain
		case "DUPLICATE":
			if at(2) == "KEY" && at(3) == "UPDATE" {
				return 4, kindList
			}
		}
	case "DO":
		if at(1) == "NOTHING" || at(1) == "UPDATE" {
			return 2, kindPlain
		}
	case "JOIN", "STRAIGHT_JOIN":
		return 1, kindJoin
	case "INNER", "LEFT", "RIGHT", "FULL", "CROSS", "OUTER", "NATURAL":
		return joinHeadLength(nodes, i)
	}
	return 0, kindPlain
}

func selectHeadLength(nodes []node, i int) int {
	n := 1
	at := func(k int) string {
		if i+k < len(nodes) {
			return nodes[i+k].upperWord()
		}
		return ""
	}
	for {
		switch at(n) {
		case "DISTINCT":
			n++
			if at(n) == "ON" && i+n+1 < len(nodes) && nodes[i+n+1].kind == groupNode {
				n += 2
			}
		case "ALL":
			n++
		case "TOP":
			n++
			if i+n < len(nodes) {
				n++
			}
			if at(n) == "PERCENT" {
				n++
			}
			if at(n) == "WITH" && at(n+1) == "TIES" {
				n += 2
			}
		default:
			return n
		}
	}
}

func lockHeadLength(nodes []node, i int) int {
	n := 1
	for i+n < len(nodes) {
		switch nodes[i+n].upperWord() {
		case "UPDATE", "SHARE", "NO", "KEY":
			n++
		case "NOWAIT", "SKIP", "LOCKED":
			if n == 1 {
				return 0
			}
			n++
		default:
			if n == 1 {
				switch nodes[i+n].upperWord() {
				case "JSON", "XML", "BROWSE":
					return 2
				}
				return 0
			}
			return n
		}
	}
	return n
}

func insertHeadLength(nodes []node) int {
	for k := 1; k <= 4 && k < len(nodes); k++ {
		if nodes[k].upperWord() == "INTO" {
			return k + 1
		}
	}
	return 1
}

func joinHeadLength(nodes []node, i int) (int, clauseKind) {
	k := i
	for k < len(nodes) && joinModifiers[nodes[k].upperWord()] {
		k++
	}
	if k < len(nodes) {
		switch nodes[k].upperWord() {
		case "JOIN", "APPLY":
			return k - i + 1, kindJoin
		}
	}
	return 0, kindPlain
}

type condPart struct {
	conj  *token
	nodes []node
}

func splitCond(nodes []node) []condPart {
	parts := []condPart{{}}
	between, caseDepth := false, 0
	for _, n := range nodes {
		switch n.upperWord() {
		case "BETWEEN":
			between = true
		case "CASE":
			caseDepth++
		case "END":
			caseDepth = max(caseDepth-1, 0)
		case "AND", "OR":
			if n.upperWord() == "AND" && between {
				between = false
			} else if caseDepth == 0 {
				tok := n.tok
				parts = append(parts, condPart{conj: &tok})
				continue
			}
		}
		last := &parts[len(parts)-1]
		last.nodes = append(last.nodes, n)
	}
	return parts
}

type listItem struct {
	nodes      []node
	afterComma []node
}

func splitCommas(nodes []node) []listItem {
	items := []listItem{{}}
	for i := 0; i < len(nodes); i++ {
		if !nodes[i].isPunct(",") {
			last := &items[len(items)-1]
			last.nodes = append(last.nodes, nodes[i])
			continue
		}
		prev := &items[len(items)-1]
		for i+1 < len(nodes) && nodes[i+1].kind == commentNode && !nodes[i+1].tok.newlineBefore {
			prev.afterComma = append(prev.afterComma, nodes[i+1])
			i++
		}
		items = append(items, listItem{})
	}
	return items
}

func markRowWords(nodes []node, from int) []node {
	end := from
	for end < len(nodes) && (isNumberWord(nodes[end]) || rowWords[nodes[end].upperWord()]) {
		end++
	}
	body := make([]node, end-from)
	copy(body, nodes[from:end])
	for j := range body {
		if rowWords[body[j].upperWord()] {
			body[j].tok.keyword = true
		}
	}
	return body
}

var rowWords = wordSet(`ROW ROWS ONLY PERCENT WITH TIES`)

func isNumberWord(n node) bool { return n.kind == atomNode && n.tok.kind == sqlsplit.TokenNumber }
