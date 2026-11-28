//go:build duckdb

package duckdb

import (
	"database/sql/driver"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"math/big"
	"strconv"
	"strings"

	duckdbdriver "github.com/duckdb/duckdb-go/v2"

	"github.com/doubledare704/queravue/core/internal/engine"
)

type valueConverter func(engine.Value) (driver.Value, error)

var signedRanges = map[string][2]int64{
	"TINYINT": {-1 << 7, 1<<7 - 1}, "SMALLINT": {-1 << 15, 1<<15 - 1},
	"INTEGER": {-1 << 31, 1<<31 - 1}, "BIGINT": {-1 << 63, 1<<63 - 1},
}

var unsignedLimits = map[string]uint64{
	"UTINYINT": 1<<8 - 1, "USMALLINT": 1<<16 - 1, "UINTEGER": 1<<32 - 1, "UBIGINT": 1<<64 - 1,
}

// converterFor builds the converter for a DuckDB type name as duckdb_columns()
// reports it, because the appender takes the Go type each column needs.
func converterFor(typeName string) (valueConverter, error) {
	t := strings.ToUpper(strings.TrimSpace(typeName))
	if element, ok := listElementType(t); ok {
		return listConverter(element)
	}
	if bounds, ok := signedRanges[t]; ok {
		return signedValue(bounds[0], bounds[1]), nil
	}
	if limit, ok := unsignedLimits[t]; ok {
		return unsignedValue(limit), nil
	}
	switch {
	case t == "BOOLEAN":
		return boolValue, nil
	case t == "FLOAT", t == "DOUBLE":
		return floatValue, nil
	case t == "HUGEINT", t == "UHUGEINT":
		return hugeValue, nil
	case strings.HasPrefix(t, "DECIMAL("):
		return decimalConverter(t)
	case t == "VARCHAR", strings.HasPrefix(t, "ENUM("):
		return stringValue, nil
	case t == "JSON":
		return jsonValue, nil
	case t == "BLOB":
		return bytesValue, nil
	case t == "UUID":
		return uuidValue, nil
	case t == "DATE", t == "TIMESTAMP", t == "TIMESTAMP WITH TIME ZONE", t == "TIMESTAMP_S", t == "TIMESTAMP_MS", t == "TIMESTAMP_NS":
		return timeValue, nil
	}
	return nil, fmt.Errorf("type %s cannot be bulk loaded", typeName)
}

func listElementType(t string) (string, bool) {
	if !strings.HasSuffix(t, "]") {
		return "", false
	}
	open := strings.LastIndexByte(t, '[')
	return t[:open], open > 0
}

func listConverter(elementType string) (valueConverter, error) {
	element, err := converterFor(elementType)
	if err != nil {
		return nil, err
	}
	return func(v engine.Value) (driver.Value, error) {
		switch v.Kind {
		case engine.VNull:
			return nil, nil
		case engine.VArray:
			out := make([]any, len(v.Array))
			for i, item := range v.Array {
				if out[i], err = element(item); err != nil {
					return nil, err
				}
			}
			return out, nil
		}
		return nil, errNotAssignable(v)
	}, nil
}

func signedValue(lo, hi int64) valueConverter {
	return func(v engine.Value) (driver.Value, error) {
		switch v.Kind {
		case engine.VNull:
			return nil, nil
		case engine.VInt:
			if v.Int < lo || v.Int > hi {
				return nil, errors.New("an integer is outside the column's range")
			}
			return v.Int, nil
		}
		return nil, errNotAssignable(v)
	}
}

func unsignedValue(limit uint64) valueConverter {
	return func(v engine.Value) (driver.Value, error) {
		switch v.Kind {
		case engine.VNull:
			return nil, nil
		case engine.VInt:
			if v.Int >= 0 && uint64(v.Int) <= limit {
				return uint64(v.Int), nil
			}
			return nil, errors.New("an integer is outside the column's range")
		case engine.VDecimal, engine.VText:
			if n, err := strconv.ParseUint(v.Str, 10, 64); err == nil && n <= limit {
				return n, nil
			}
			return nil, errors.New("an integer is outside the column's range")
		}
		return nil, errNotAssignable(v)
	}
}

func boolValue(v engine.Value) (driver.Value, error) {
	switch v.Kind {
	case engine.VNull:
		return nil, nil
	case engine.VBool:
		return v.Bool, nil
	case engine.VInt:
		if v.Int == 0 || v.Int == 1 {
			return v.Int == 1, nil
		}
	}
	return nil, errNotAssignable(v)
}

func floatValue(v engine.Value) (driver.Value, error) {
	switch v.Kind {
	case engine.VNull:
		return nil, nil
	case engine.VFloat:
		return v.Float, nil
	case engine.VInt:
		return float64(v.Int), nil
	}
	return nil, errNotAssignable(v)
}

func hugeValue(v engine.Value) (driver.Value, error) {
	switch v.Kind {
	case engine.VNull:
		return nil, nil
	case engine.VInt:
		return big.NewInt(v.Int), nil
	case engine.VDecimal, engine.VText:
		if n, ok := new(big.Int).SetString(v.Str, 10); ok {
			return n, nil
		}
		return nil, errors.New("not an integer")
	}
	return nil, errNotAssignable(v)
}

func decimalConverter(t string) (valueConverter, error) {
	var width, scale int
	if _, err := fmt.Sscanf(t, "DECIMAL(%d,%d)", &width, &scale); err != nil {
		return nil, fmt.Errorf("type %s cannot be bulk loaded", t)
	}
	unit := new(big.Int).Exp(big.NewInt(10), big.NewInt(int64(scale)), nil)
	limit := new(big.Int).Exp(big.NewInt(10), big.NewInt(int64(width)), nil)
	return func(v engine.Value) (driver.Value, error) {
		var text string
		switch v.Kind {
		case engine.VNull:
			return nil, nil
		case engine.VDecimal, engine.VText:
			text = v.Str
		case engine.VInt:
			text = strconv.FormatInt(v.Int, 10)
		default:
			return nil, errNotAssignable(v)
		}
		exact, ok := new(big.Rat).SetString(text)
		if !ok {
			return nil, errors.New("not a decimal number")
		}
		scaled := new(big.Int).Quo(new(big.Int).Mul(exact.Num(), unit), exact.Denom())
		if scaled.CmpAbs(limit) >= 0 {
			return nil, errors.New("a decimal is outside the column's range")
		}
		return duckdbdriver.Decimal{Width: uint8(width), Scale: uint8(scale), Value: scaled}, nil //nolint:gosec // width and scale come from DECIMAL(w,s), at most 38
	}, nil
}

func stringValue(v engine.Value) (driver.Value, error) {
	switch v.Kind {
	case engine.VNull:
		return nil, nil
	case engine.VText, engine.VDecimal, engine.VJSON, engine.VUUID:
		return v.Str, nil
	case engine.VInt:
		return strconv.FormatInt(v.Int, 10), nil
	case engine.VFloat:
		return strconv.FormatFloat(v.Float, 'g', -1, 64), nil
	}
	return nil, errNotAssignable(v)
}

func jsonValue(v engine.Value) (driver.Value, error) {
	switch v.Kind {
	case engine.VNull:
		return nil, nil
	case engine.VJSON, engine.VText:
		if !json.Valid([]byte(v.Str)) {
			return nil, errors.New("not valid JSON")
		}
		return json.RawMessage(v.Str), nil
	}
	return nil, errNotAssignable(v)
}

func bytesValue(v engine.Value) (driver.Value, error) {
	switch v.Kind {
	case engine.VNull:
		return nil, nil
	case engine.VBytes:
		return v.Bytes, nil
	}
	return nil, errNotAssignable(v)
}

func uuidValue(v engine.Value) (driver.Value, error) {
	switch v.Kind {
	case engine.VNull:
		return nil, nil
	case engine.VUUID, engine.VText:
		raw, err := hex.DecodeString(strings.ReplaceAll(v.Str, "-", ""))
		if err != nil || len(raw) != len(duckdbdriver.UUID{}) {
			return nil, errors.New("not a UUID")
		}
		return raw, nil
	}
	return nil, errNotAssignable(v)
}

func timeValue(v engine.Value) (driver.Value, error) {
	switch v.Kind {
	case engine.VNull:
		return nil, nil
	case engine.VTimestamptz:
		return v.Time, nil
	}
	return nil, errNotAssignable(v)
}

func errNotAssignable(v engine.Value) error {
	return fmt.Errorf("a value of kind %d cannot be stored in this column", v.Kind)
}
