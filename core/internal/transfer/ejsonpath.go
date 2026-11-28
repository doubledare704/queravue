package transfer

import (
	"bytes"
	"encoding/json"
	"math"
	"strconv"
	"strings"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/mongo"
)

// PathExtractor turns an EJSON document into the values of dotted field paths.
// A "[]" segment visits every element of an array; a number picks one.
type PathExtractor struct {
	paths     [][]string
	canonical bool
}

// NewPathExtractor prepares paths; canonical keeps nested values in canonical EJSON, otherwise relaxed.
func NewPathExtractor(paths []string, canonical bool) *PathExtractor {
	split := make([][]string, len(paths))
	for i, p := range paths {
		split[i] = strings.Split(p, ".")
	}
	return &PathExtractor{paths: split, canonical: canonical}
}

// Columns are the output columns: one text column per path, since values differ in type across documents.
func (p *PathExtractor) Columns(paths []string) []engine.Column {
	cols := make([]engine.Column, len(paths))
	for i, name := range paths {
		cols[i] = engine.Column{Name: name, Kind: engine.VText}
	}
	return cols
}

// Row returns one value per path; a missing path is NULL.
func (p *PathExtractor) Row(doc engine.Document) ([]engine.Value, error) {
	text := doc
	if !p.canonical {
		relaxed, err := mongo.TranscodeEJSON([]byte(doc), false, false)
		if err != nil {
			return nil, newError(KindParse, "a document is not valid EJSON")
		}
		text = relaxed
	}
	row := make([]engine.Value, len(p.paths))
	for i, segments := range p.paths {
		raw, ok := lookup(json.RawMessage(text), segments)
		if ok {
			row[i] = scalarOf(raw)
		}
	}
	return row, nil
}

func lookup(node json.RawMessage, segments []string) (json.RawMessage, bool) {
	if len(segments) == 0 {
		return node, true
	}
	node = bytes.TrimSpace(node)
	if len(node) == 0 {
		return nil, false
	}
	switch node[0] {
	case '{':
		var fields map[string]json.RawMessage
		if json.Unmarshal(node, &fields) != nil {
			return nil, false
		}
		child, ok := fields[segments[0]]
		if !ok {
			return nil, false
		}
		return lookup(child, segments[1:])
	case '[':
		var items []json.RawMessage
		if json.Unmarshal(node, &items) != nil {
			return nil, false
		}
		if segments[0] == "[]" {
			return collect(items, segments[1:])
		}
		index, err := strconv.Atoi(segments[0])
		if err != nil || index < 0 || index >= len(items) {
			return nil, false
		}
		return lookup(items[index], segments[1:])
	}
	return nil, false
}

func collect(items []json.RawMessage, rest []string) (json.RawMessage, bool) {
	var found []json.RawMessage
	for _, item := range items {
		if value, ok := lookup(item, rest); ok {
			found = append(found, value)
		}
	}
	if len(found) == 0 {
		return nil, false
	}
	joined, _ := json.Marshal(found)
	return joined, true
}

func scalarOf(raw json.RawMessage) engine.Value {
	raw = bytes.TrimSpace(raw)
	switch raw[0] {
	case '"':
		var s string
		if json.Unmarshal(raw, &s) != nil {
			return engine.Null()
		}
		return engine.Text(s)
	case 't', 'f':
		return engine.Bool(raw[0] == 't')
	case 'n':
		return engine.Null()
	case '[':
		return engine.JSON(string(raw))
	case '{':
		if v, ok := wrapperScalar(raw); ok {
			return v
		}
		return engine.JSON(string(raw))
	}
	return numberText(string(raw))
}

func numberText(s string) engine.Value {
	if i, err := strconv.ParseInt(s, 10, 64); err == nil {
		return engine.Int(i)
	}
	if f, err := strconv.ParseFloat(s, 64); err == nil {
		return engine.Float(f)
	}
	return engine.Decimal(s)
}

func wrapperScalar(raw json.RawMessage) (engine.Value, bool) {
	var fields map[string]json.RawMessage
	if json.Unmarshal(raw, &fields) != nil || len(fields) != 1 {
		return engine.Value{}, false
	}
	for key, inner := range fields {
		var text string
		isText := json.Unmarshal(inner, &text) == nil
		switch {
		case key == "$oid" && isText:
			return engine.Text(text), true
		case (key == "$numberInt" || key == "$numberLong") && isText:
			i, err := strconv.ParseInt(text, 10, 64)
			return engine.Int(i), err == nil
		case key == "$numberDouble" && isText:
			f, err := strconv.ParseFloat(text, 64)
			if err != nil || math.IsNaN(f) || math.IsInf(f, 0) {
				return engine.Text(text), true
			}
			return engine.Float(f), true
		case key == "$numberDecimal" && isText:
			return engine.Decimal(text), true
		case key == "$date":
			return dateScalar(inner)
		case key == "$uuid" && isText:
			return engine.UUID(text), true
		}
	}
	return engine.Value{}, false
}

func dateScalar(inner json.RawMessage) (engine.Value, bool) {
	var iso string
	if json.Unmarshal(inner, &iso) == nil {
		t, err := time.Parse(time.RFC3339Nano, iso)
		return engine.Timestamptz(t), err == nil
	}
	var millis struct {
		Long string `json:"$numberLong"`
	}
	if json.Unmarshal(inner, &millis) != nil {
		return engine.Value{}, false
	}
	ms, err := strconv.ParseInt(millis.Long, 10, 64)
	return engine.Timestamptz(time.UnixMilli(ms).UTC()), err == nil
}
