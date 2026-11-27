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

// InferredColumn describes the kinds and nulls observed in the sample.
type InferredColumn struct {
	Name     string
	Kind     engine.ValueKind
	Nullable bool
	Warning  string
}

// Infer consumes up to maxRows from the reader; a fresh reader can replay the sample.
func (r *Reader) Infer(ctx context.Context, maxRows int) ([]InferredColumn, error) {
	if maxRows < 0 {
		return nil, errors.New("dataformat: negative sample row limit")
	}
	names, err := r.Columns(ctx)
	if err != nil {
		return nil, err
	}
	columns := make([]InferredColumn, len(names))
	for i, name := range names {
		columns[i].Name = name
	}
	for maxRows > 0 {
		batch, err := r.next(ctx, min(maxRows, engine.MaxBatchRows))
		if errors.Is(err, io.EOF) {
			break
		}
		if err != nil {
			return nil, err
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
	return columns, nil
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
	if _, err := time.Parse(time.RFC3339Nano, s); err == nil {
		return engine.VTimestamptz
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
