package mockdata

import (
	"encoding/base64"
	"encoding/json"
	"math"
	"strconv"
	"strings"

	"github.com/doubledare704/queravue/core/internal/engine"
)

type docNode struct {
	name     string
	gen      colGenerator
	children []*docNode
}

func compileDocTree(seed uint64, target TargetRef, rules []ColumnRule) (*docNode, error) {
	root := &docNode{}
	for _, r := range rules {
		if r.ColumnOrPath == "" {
			return nil, parseErr(&target, "", "document rule requires column_or_path")
		}
		if r.Kind == RuleSkip {
			continue
		}
		if strings.Contains(r.ColumnOrPath, ".") && r.Kind != RuleDocument {
			if err := insertDottedRule(root, seed, target, r.ColumnOrPath, r); err != nil {
				return nil, err
			}
			continue
		}
		g, err := buildGenerator(seed, target, r.ColumnOrPath, r)
		if err != nil {
			return nil, err
		}
		root.children = append(root.children, &docNode{name: r.ColumnOrPath, gen: g})
	}
	return root, nil
}

func insertDottedRule(root *docNode, seed uint64, target TargetRef, fullPath string, rule ColumnRule) error {
	parts := strings.Split(fullPath, ".")
	cur := root
	for i, seg := range parts {
		if seg == "" {
			return parseErr(&target, fullPath, "empty segment in field path")
		}
		if i == len(parts)-1 {
			g, err := buildGenerator(seed, target, fullPath, rule)
			if err != nil {
				return err
			}
			cur.children = append(cur.children, &docNode{name: seg, gen: g})
			return nil
		}
		var next *docNode
		for _, ch := range cur.children {
			if ch.name == seg && ch.gen == nil {
				next = ch
				break
			}
		}
		if next == nil {
			next = &docNode{name: seg}
			cur.children = append(cur.children, next)
		}
		cur = next
	}
	return nil
}

func (n *docNode) generateDocument(ctxGen *genContext) (string, error) {
	var b strings.Builder
	b.Grow(256)
	if err := writeDocObject(&b, n.children, ctxGen); err != nil {
		return "", err
	}
	return b.String(), nil
}

func writeDocObject(b *strings.Builder, nodes []*docNode, ctxGen *genContext) error {
	b.WriteByte('{')
	wrote := false
	for _, ch := range nodes {
		if ch.gen == nil {
			var sub strings.Builder
			if err := writeDocObject(&sub, ch.children, ctxGen); err != nil {
				return err
			}
			if sub.Len() <= 2 {
				continue
			}
			if wrote {
				b.WriteByte(',')
			}
			writeJSONString(b, ch.name)
			b.WriteByte(':')
			b.WriteString(sub.String())
			wrote = true
			continue
		}
		v, err := ch.gen.next(ctxGen)
		if err != nil {
			return err
		}
		if v.omitted {
			continue
		}
		if wrote {
			b.WriteByte(',')
		}
		writeJSONString(b, ch.name)
		b.WriteByte(':')
		writeEJSONValue(b, v)
		wrote = true
	}
	b.WriteByte('}')
	return nil
}

func writeEJSONValue(b *strings.Builder, v generatedValue) {
	if v.isDoc || len(v.fields) > 0 {
		b.WriteByte('{')
		for i, f := range v.fields {
			if i > 0 {
				b.WriteByte(',')
			}
			writeJSONString(b, f.name)
			b.WriteByte(':')
			writeEJSONValue(b, f.value)
		}
		b.WriteByte('}')
		return
	}
	if v.isArray || v.val.Kind == engine.VArray || len(v.elements) > 0 {
		b.WriteByte('[')
		for i, e := range v.elements {
			if i > 0 {
				b.WriteByte(',')
			}
			writeEJSONValue(b, e)
		}
		b.WriteByte(']')
		return
	}
	if v.isObjectID && v.val.Kind == engine.VText {
		b.WriteString(`{"$oid":"`)
		b.WriteString(v.val.Str)
		b.WriteString(`"}`)
		return
	}
	writeEJSONScalar(b, v.val)
}

func writeEJSONScalar(b *strings.Builder, v engine.Value) {
	switch v.Kind {
	case engine.VNull:
		b.WriteString("null")
	case engine.VBool:
		if v.Bool {
			b.WriteString("true")
		} else {
			b.WriteString("false")
		}
	case engine.VInt:
		b.WriteString(`{"$numberLong":"`)
		b.WriteString(strconv.FormatInt(v.Int, 10))
		b.WriteString(`"}`)
	case engine.VFloat:
		b.WriteString(`{"$numberDouble":"`)
		switch {
		case math.IsNaN(v.Float):
			b.WriteString("NaN")
		case math.IsInf(v.Float, 1):
			b.WriteString("Infinity")
		case math.IsInf(v.Float, -1):
			b.WriteString("-Infinity")
		default:
			b.WriteString(strconv.FormatFloat(v.Float, 'g', -1, 64))
		}
		b.WriteString(`"}`)
	case engine.VDecimal:
		b.WriteString(`{"$numberDecimal":`)
		writeJSONString(b, v.Str)
		b.WriteByte('}')
	case engine.VTimestamptz:
		b.WriteString(`{"$date":{"$numberLong":"`)
		b.WriteString(strconv.FormatInt(v.Time.UnixMilli(), 10))
		b.WriteString(`"}}`)
	case engine.VBytes:
		b.WriteString(`{"$binary":{"base64":"`)
		b.WriteString(base64.StdEncoding.EncodeToString(v.Bytes))
		b.WriteString(`","subType":"00"}}`)
	case engine.VJSON:
		trimmed := strings.TrimSpace(v.Str)
		if json.Valid([]byte(trimmed)) {
			b.WriteString(trimmed)
		} else {
			writeJSONString(b, v.Str)
		}
	default:
		writeJSONString(b, v.Str)
	}
}

func writeJSONString(b *strings.Builder, s string) {
	for i := 0; i < len(s); i++ {
		c := s[i]
		if c < 0x20 || c == '"' || c == '\\' || c >= 0x80 {
			encoded, _ := json.Marshal(s)
			b.Write(encoded)
			return
		}
	}
	b.WriteByte('"')
	b.WriteString(s)
	b.WriteByte('"')
}
