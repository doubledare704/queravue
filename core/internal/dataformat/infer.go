package dataformat

import (
	"context"
	"encoding/json"
	"errors"
	"io"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/doubledare704/queravue/core/internal/engine"
)

const maxSkippedSample = 1000

// TimestampLayouts are the text forms read as timestamps; zone-less ones are UTC.
var TimestampLayouts = []string{time.RFC3339Nano, "2006-01-02 15:04:05.999999999Z07:00", "2006-01-02T15:04:05.999999999", "2006-01-02 15:04:05.999999999", "2006-01-02"}

// InferredColumn describes the kinds and nulls observed in the sample.
type InferredColumn struct {
	Name     string
	Kind     engine.ValueKind
	Nullable bool
	Warning  string
}

// Infer consumes up to maxRows from the reader; a fresh reader can replay the sample.
func (r *Reader) Infer(ctx context.Context, maxRows int) ([]InferredColumn, error) {
	columns, _, err := r.infer(ctx, maxRows, false)
	return columns, err
}

// InferLenient is Infer that skips malformed records and reports how many it skipped.
func (r *Reader) InferLenient(ctx context.Context, maxRows int) (columns []InferredColumn, skipped int, err error) {
	return r.infer(ctx, maxRows, true)
}

func (r *Reader) infer(ctx context.Context, maxRows int, lenient bool) ([]InferredColumn, int, error) {
	if maxRows < 0 {
		return nil, 0, errors.New("dataformat: negative sample row limit")
	}
	names, err := r.Columns(ctx)
	if err != nil {
		return nil, 0, err
	}
	skipped := 0
	columns := make([]InferredColumn, len(names))
	for i, name := range names {
		columns[i].Name = name
	}
	for maxRows > 0 {
		batch, err := r.next(ctx, min(maxRows, engine.MaxBatchRows))
		if errors.Is(err, io.EOF) {
			break
		}
		var parse *ParseError
		if lenient && errors.As(err, &parse) {
			skipped++
			if skipped > maxSkippedSample {
				break
			}
			continue
		}
		if err != nil {
			return nil, 0, err
		}
		for _, row := range batch {
			for i, value := range row {
				columns[i].observe(value, r.format == CSV || r.format == TSV)
			}
		}
		maxRows -= len(batch)
	}
	for i := range columns {
		if columns[i].Kind == engine.VNull {
			columns[i].Kind = engine.VText
		}
	}
	return columns, skipped, nil
}

func (c *InferredColumn) observe(v engine.Value, delimited bool) {
	if v.Kind == engine.VNull {
		c.Nullable = true
		return
	}
	if c.Warning != "" {
		return
	}
	kind := v.Kind
	if kind == engine.VText {
		if delimited {
			kind = textKind(v.Str)
		} else {
			kind = stringKind(v.Str)
		}
	}
	switch {
	case c.Kind == engine.VNull || c.Kind == kind:
		c.Kind = kind
	case isNumeric(c.Kind) && isNumeric(kind):
		if c.Kind == engine.VFloat || kind == engine.VFloat {
			c.Kind = engine.VFloat
		} else {
			c.Kind = engine.VDecimal
		}
	default:
		c.Kind = engine.VText
		c.Warning = "mixed value kinds in sample; inferred text"
	}
}

func isNumeric(kind engine.ValueKind) bool {
	return kind == engine.VInt || kind == engine.VFloat || kind == engine.VDecimal
}

func textKind(s string) engine.ValueKind {
	switch strings.ToLower(s) {
	case "true", "false":
		return engine.VBool
	}
	if s == "" {
		return engine.VText
	}
	switch s[0] {
	case '{', '[':
		if json.Valid([]byte(s)) {
			return engine.VJSON
		}
	case '-', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9':
		if json.Valid([]byte(s)) && !strings.ContainsAny(s, " \t\r\n") {
			return numberValue(s).Kind
		}
	}
	return stringKind(s)
}

func stringKind(s string) engine.ValueKind {
	if len(s) == 36 {
		if _, err := uuid.Parse(s); err == nil {
			return engine.VUUID
		}
	}
	if len(s) >= len("2006-01-02") && s[4] == '-' {
		for _, layout := range TimestampLayouts {
			if _, err := time.Parse(layout, s); err == nil {
				return engine.VTimestamptz
			}
		}
	}
	return engine.VText
}

func numberValue(s string) engine.Value {
	if i, err := strconv.ParseInt(s, 10, 64); err == nil {
		return engine.Int(i)
	}
	if strings.ContainsAny(s, "eE") {
		if f, err := strconv.ParseFloat(s, 64); err == nil {
			return engine.Float(f)
		}
	}
	return engine.Decimal(s)
}

// SniffKind is the kind a delimited text cell reads as.
func SniffKind(s string) engine.ValueKind { return textKind(s) }
