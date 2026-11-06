package mongo

import (
	"encoding/json"
	"errors"
	"fmt"
	"unicode/utf16"

	"go.mongodb.org/mongo-driver/v2/bson"

	"github.com/doubledare704/queravue/core/internal/engine"
)

// This file is the only place that converts between BSON and Extended JSON
// text (ADR 0009). Documents leave core as canonical EJSON v2; documents
// entering core from the editor must be canonical; filter, sort and
// projection may be relaxed.

// toEJSON renders a BSON document as canonical EJSON.
func toEJSON(raw bson.Raw) (string, error) {
	b, err := bson.MarshalExtJSON(raw, true, false)
	if err != nil {
		return "", fmt.Errorf("mongo: encode document: %w", err)
	}
	return string(b), nil
}

// valueToEJSON renders a single BSON value (e.g. an _id) as canonical EJSON.
// Scalars are wrapped by the driver in a one-field document {"v": ...} whose
// value we extract so the result is itself valid EJSON.
func valueToEJSON(v bson.RawValue) (string, error) {
	doc, err := bson.Marshal(bson.D{{Key: "v", Value: v}})
	if err != nil {
		return "", fmt.Errorf("mongo: encode value: %w", err)
	}
	text, err := bson.MarshalExtJSON(bson.Raw(doc), true, false)
	if err != nil {
		return "", fmt.Errorf("mongo: encode value: %w", err)
	}
	var wrap struct {
		V json.RawMessage `json:"v"`
	}
	if err := json.Unmarshal(text, &wrap); err != nil {
		return "", fmt.Errorf("mongo: encode value: %w", err)
	}
	return string(wrap.V), nil
}

// parseDocument parses text into BSON. With canonical set, bare JSON numbers
// are rejected so an Int64 can never decay into a double; otherwise relaxed
// EJSON is accepted. input names the request field for error reporting.
func parseDocument(text string, canonical bool, input engine.Input) (bson.Raw, error) {
	if err := checkSyntax(text, input); err != nil {
		return nil, err
	}
	if canonical {
		if err := rejectBareNumbers(text, input); err != nil {
			return nil, err
		}
	}
	var doc bson.D
	if err := bson.UnmarshalExtJSON([]byte(text), canonical, &doc); err != nil {
		return nil, &engine.Error{Kind: engine.KindParse, Engine: ID, Op: "parse", Input: input,
			Msg: err.Error(), Err: err}
	}
	raw, err := bson.Marshal(doc)
	if err != nil {
		return nil, &engine.Error{Kind: engine.KindParse, Engine: ID, Op: "parse", Input: input,
			Msg: err.Error(), Err: err}
	}
	return raw, nil
}

// parseValue parses a canonical EJSON value (any BSON type) such as an _id.
func parseValue(text string, input engine.Input) (bson.RawValue, error) {
	wrapped := `{"v":` + text + `}`
	if err := checkSyntax(wrapped, input); err != nil {
		// Positions refer to the user's text, not the wrapper.
		var e *engine.Error
		if errors.As(err, &e) && e.Position >= 5 {
			e.Position -= 5
		}
		return bson.RawValue{}, err
	}
	raw, err := parseDocument(wrapped, true, input)
	if err != nil {
		return bson.RawValue{}, err
	}
	return raw.Lookup("v"), nil
}

// checkSyntax reports JSON syntax errors with a UTF-16 position.
func checkSyntax(text string, input engine.Input) error {
	var v any
	dec := json.NewDecoder(bytesReader(text))
	dec.UseNumber()
	err := dec.Decode(&v)
	if err == nil {
		// Trailing garbage after the first value.
		if dec.More() {
			return syntaxErr(text, int(dec.InputOffset()), "unexpected data after value", input)
		}
		return nil
	}
	var se *json.SyntaxError
	if errors.As(err, &se) {
		return syntaxErr(text, int(se.Offset)-1, se.Error(), input)
	}
	return syntaxErr(text, len(text), "unexpected end of input", input)
}

func syntaxErr(text string, byteOff int, msg string, input engine.Input) *engine.Error {
	if byteOff < 0 {
		byteOff = 0
	}
	if byteOff > len(text) {
		byteOff = len(text)
	}
	return &engine.Error{Kind: engine.KindParse, Engine: ID, Op: "parse", Input: input,
		Msg: msg, Position: utf16Offset(text, byteOff)}
}

// utf16Offset converts a byte offset in s to UTF-16 code units.
func utf16Offset(s string, byteOff int) int {
	n := 0
	for _, r := range s[:byteOff] {
		n += len(utf16.Encode([]rune{r}))
	}
	return n
}

// rejectBareNumbers fails on a JSON number that is not inside a $-wrapper,
// i.e. a number whose BSON type would be a guess.
func rejectBareNumbers(text string, input engine.Input) error {
	dec := json.NewDecoder(bytesReader(text))
	dec.UseNumber()
	var walk func(v any, inWrapper bool) error
	walk = func(v any, inWrapper bool) error {
		switch t := v.(type) {
		case json.Number:
			if !inWrapper {
				return &engine.Error{Kind: engine.KindParse, Engine: ID, Op: "parse", Input: input,
					Msg: fmt.Sprintf("number %s has no type; use {\"$numberInt\":\"…\"}, {\"$numberLong\":\"…\"} or {\"$numberDouble\":\"…\"}", t.String())}
			}
		case map[string]any:
			for k, e := range t {
				w := inWrapper || (len(k) > 0 && k[0] == '$')
				if err := walk(e, w); err != nil {
					return err
				}
			}
		case []any:
			for _, e := range t {
				if err := walk(e, inWrapper); err != nil {
					return err
				}
			}
		}
		return nil
	}
	var v any
	if err := dec.Decode(&v); err != nil {
		return nil // syntax already checked
	}
	return walk(v, false)
}
