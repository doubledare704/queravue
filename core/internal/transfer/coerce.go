package transfer

import (
	"encoding/hex"
	"encoding/json"
	"errors"
	"math"
	"regexp"
	"strconv"
	"strings"
	"time"

	"github.com/google/uuid"

	"github.com/doubledare704/queravue/core/internal/dataformat"
	"github.com/doubledare704/queravue/core/internal/engine"
)

var errCoerce = errors.New("value does not fit the column type")

var plainNumber = regexp.MustCompile(`^[+-]?([0-9]+\.?[0-9]*|\.[0-9]+)([eE][+-]?[0-9]+)?$`)

func parseFloatText(s string) (float64, bool) {
	if !plainNumber.MatchString(s) {
		return 0, false
	}
	f, err := strconv.ParseFloat(s, 64)
	return f, err == nil
}

// Coerce converts v to the kind of its target column. Values the server parses
// itself (dates, enums, arrays) pass through as text.
func Coerce(v engine.Value, kind engine.ValueKind) (engine.Value, error) {
	if v.Kind == engine.VNull || v.Kind == kind || kind == engine.VNull {
		return v, nil
	}
	switch kind {
	case engine.VText:
		return engine.Text(dataformat.ValueText(v)), nil
	case engine.VBool:
		return coerceBool(v)
	case engine.VInt:
		return coerceInt(v)
	case engine.VFloat:
		return coerceFloat(v)
	case engine.VDecimal:
		return coerceDecimal(v)
	case engine.VBytes:
		return coerceBytes(v)
	case engine.VTimestamptz:
		return coerceTimestamp(v)
	case engine.VJSON:
		return coerceJSON(v)
	case engine.VUUID:
		return coerceUUID(v)
	}
	return v, nil
}

func coerceBool(v engine.Value) (engine.Value, error) {
	switch v.Kind {
	case engine.VInt:
		if v.Int == 0 || v.Int == 1 {
			return engine.Bool(v.Int == 1), nil
		}
	case engine.VText:
		switch strings.ToLower(strings.TrimSpace(v.Str)) {
		case "true", "t", "yes", "y", "1":
			return engine.Bool(true), nil
		case "false", "f", "no", "n", "0":
			return engine.Bool(false), nil
		}
	}
	return v, errCoerce
}

func coerceInt(v engine.Value) (engine.Value, error) {
	switch v.Kind {
	case engine.VText, engine.VDecimal:
		s := strings.TrimSpace(v.Str)
		if i, err := strconv.ParseInt(s, 10, 64); err == nil {
			return engine.Int(i), nil
		}
		if f, ok := parseFloatText(s); ok && f == math.Trunc(f) && math.Abs(f) < 1<<53 {
			return engine.Int(int64(f)), nil
		}
	case engine.VFloat:
		if v.Float == math.Trunc(v.Float) && math.Abs(v.Float) < 1<<53 {
			return engine.Int(int64(v.Float)), nil
		}
	}
	return v, errCoerce
}

func coerceFloat(v engine.Value) (engine.Value, error) {
	switch v.Kind {
	case engine.VInt:
		return engine.Float(float64(v.Int)), nil
	case engine.VText, engine.VDecimal:
		if f, ok := parseFloatText(strings.TrimSpace(v.Str)); ok {
			return engine.Float(f), nil
		}
	}
	return v, errCoerce
}

func coerceDecimal(v engine.Value) (engine.Value, error) {
	switch v.Kind {
	case engine.VInt:
		return engine.Decimal(strconv.FormatInt(v.Int, 10)), nil
	case engine.VFloat:
		if math.IsNaN(v.Float) || math.IsInf(v.Float, 0) {
			return v, errCoerce
		}
		return engine.Decimal(strconv.FormatFloat(v.Float, 'f', -1, 64)), nil
	case engine.VText:
		if s := strings.TrimSpace(v.Str); plainNumber.MatchString(s) {
			return engine.Decimal(s), nil
		}
	}
	return v, errCoerce
}

func coerceBytes(v engine.Value) (engine.Value, error) {
	if v.Kind == engine.VText {
		if raw, ok := strings.CutPrefix(v.Str, `\x`); ok {
			if b, err := hex.DecodeString(raw); err == nil {
				return engine.Bytes(b), nil
			}
		}
	}
	return v, errCoerce
}

func coerceTimestamp(v engine.Value) (engine.Value, error) {
	if v.Kind != engine.VText {
		return v, errCoerce
	}
	s := strings.TrimSpace(v.Str)
	for _, layout := range dataformat.TimestampLayouts {
		if t, err := time.Parse(layout, s); err == nil {
			return engine.Timestamptz(t), nil
		}
	}
	return v, errCoerce
}

func coerceJSON(v engine.Value) (engine.Value, error) {
	switch v.Kind {
	case engine.VText:
		if json.Valid([]byte(v.Str)) {
			return engine.JSON(v.Str), nil
		}
		return v, errCoerce
	case engine.VBool, engine.VInt, engine.VFloat, engine.VDecimal, engine.VArray:
		return engine.JSON(dataformat.ValueText(v)), nil
	}
	return v, errCoerce
}

func coerceUUID(v engine.Value) (engine.Value, error) {
	if v.Kind != engine.VText {
		return v, errCoerce
	}
	id, err := uuid.Parse(strings.TrimSpace(v.Str))
	if err != nil {
		return v, errCoerce
	}
	return engine.UUID(id.String()), nil
}
