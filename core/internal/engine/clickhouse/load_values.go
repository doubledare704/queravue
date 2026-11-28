package clickhouse

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"math"
	"math/big"
	"strconv"
	"strings"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
)

type valueConverter func(engine.Value) (any, error)

var errNullNotAllowed = errors.New("NULL in a column that is not Nullable")

// columnConverters reads the target's column types, because the native
// protocol takes exactly the Go type each column is declared with. A NULL for a
// column that is not Nullable is refused: the driver would write the type's
// default instead.
func (c *Conn) columnConverters(ctx context.Context, db *sql.DB, database, table string, columns []string) ([]valueConverter, error) {
	rows, err := db.QueryContext(ctx, "SELECT name, type FROM system.columns WHERE database = ? AND table = ?", database, table)
	if err != nil {
		return nil, c.loadError(ctx, err)
	}
	defer func() { _ = rows.Close() }()
	types := map[string]string{}
	for rows.Next() {
		var name, typeName string
		if err := rows.Scan(&name, &typeName); err != nil {
			return nil, c.loadError(ctx, err)
		}
		types[name] = typeName
	}
	if err := rows.Err(); err != nil {
		return nil, c.loadError(ctx, err)
	}
	if len(types) == 0 {
		return nil, engine.Errorf(engine.KindNotFound, ID, "load rows", "table %s does not exist", table)
	}
	out := make([]valueConverter, len(columns))
	for i, name := range columns {
		typeName, ok := types[name]
		if !ok {
			return nil, engine.Errorf(engine.KindNotFound, ID, "load rows", "column %s does not exist", name)
		}
		if out[i], err = converterFor(typeName); err != nil {
			return nil, engine.Errorf(engine.KindUnsupported, ID, "load rows", "column %s: %s", name, err.Error())
		}
	}
	return out, nil
}

func converterFor(typeName string) (valueConverter, error) {
	if inner, ok := strings.CutPrefix(typeName, "Nullable("); ok {
		base, err := converterFor(strings.TrimSuffix(inner, ")"))
		if err != nil {
			return nil, err
		}
		return func(v engine.Value) (any, error) {
			if v.Kind == engine.VNull {
				return nil, nil
			}
			return base(v)
		}, nil
	}
	if inner, ok := strings.CutPrefix(typeName, "LowCardinality("); ok {
		return converterFor(strings.TrimSuffix(inner, ")"))
	}
	base, err := nonNullConverter(typeName)
	if err != nil {
		return nil, err
	}
	return func(v engine.Value) (any, error) {
		if v.Kind == engine.VNull {
			return nil, errNullNotAllowed
		}
		return base(v)
	}, nil
}

func nonNullConverter(typeName string) (valueConverter, error) {
	switch {
	case strings.HasPrefix(typeName, "Array("):
		return arrayConverter(strings.TrimSuffix(strings.TrimPrefix(typeName, "Array("), ")"))
	case typeName == "Bool":
		return boolValue, nil
	case typeName == "Float32":
		return floatValue(32), nil
	case typeName == "Float64":
		return floatValue(64), nil
	case isBigInteger(typeName):
		return bigIntegerValue, nil
	case strings.HasPrefix(typeName, "Int"):
		return signedValue(typeName)
	case strings.HasPrefix(typeName, "UInt"):
		return unsignedValue(typeName)
	case strings.HasPrefix(typeName, "Decimal"):
		return decimalValue, nil
	case typeName == "String", strings.HasPrefix(typeName, "FixedString("),
		strings.HasPrefix(typeName, "Enum8("), strings.HasPrefix(typeName, "Enum16("):
		return stringValue, nil
	case typeName == "UUID", typeName == "IPv4", typeName == "IPv6":
		return identifierValue, nil
	case typeName == "Date", typeName == "Date32":
		return dateValue, nil
	case strings.HasPrefix(typeName, "DateTime"):
		return timeValue, nil
	}
	return nil, fmt.Errorf("type %s cannot be bulk loaded", typeName)
}

func arrayConverter(elementType string) (valueConverter, error) {
	element, err := converterFor(elementType)
	if err != nil {
		return nil, err
	}
	return func(v engine.Value) (any, error) {
		if v.Kind != engine.VArray {
			return nil, errNotAssignable(v)
		}
		out := make([]any, len(v.Array))
		for i, item := range v.Array {
			if out[i], err = element(item); err != nil {
				return nil, err
			}
		}
		return out, nil
	}, nil
}

func isBigInteger(typeName string) bool {
	switch typeName {
	case "Int128", "Int256", "UInt128", "UInt256":
		return true
	}
	return false
}

func bigIntegerValue(v engine.Value) (any, error) {
	switch v.Kind {
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

func signedValue(typeName string) (valueConverter, error) {
	bits, err := strconv.Atoi(strings.TrimPrefix(typeName, "Int"))
	if err != nil {
		return nil, fmt.Errorf("type %s cannot be bulk loaded", typeName)
	}
	return func(v engine.Value) (any, error) {
		n, err := integerOf(v)
		if err != nil {
			return nil, err
		}
		if bits < 64 && (n < -(1<<(bits-1)) || n >= 1<<(bits-1)) {
			return nil, errors.New("an integer is outside the column's range")
		}
		switch bits {
		case 8:
			return int8(n), nil //nolint:gosec // n is range-checked above
		case 16:
			return int16(n), nil //nolint:gosec // n is range-checked above
		case 32:
			return int32(n), nil //nolint:gosec // n is range-checked above
		}
		return n, nil
	}, nil
}

func unsignedValue(typeName string) (valueConverter, error) {
	bits, err := strconv.Atoi(strings.TrimPrefix(typeName, "UInt"))
	if err != nil {
		return nil, fmt.Errorf("type %s cannot be bulk loaded", typeName)
	}
	return func(v engine.Value) (any, error) {
		if (v.Kind == engine.VDecimal || v.Kind == engine.VText) && bits == 64 {
			if n, err := strconv.ParseUint(v.Str, 10, 64); err == nil {
				return n, nil
			}
			return nil, errors.New("an integer is outside the column's range")
		}
		n, err := integerOf(v)
		if err != nil {
			return nil, err
		}
		if n < 0 || (bits < 64 && n >= 1<<bits) {
			return nil, errors.New("an integer is outside the column's range")
		}
		switch bits {
		case 8:
			return uint8(n), nil //nolint:gosec // n is range-checked above
		case 16:
			return uint16(n), nil //nolint:gosec // n is range-checked above
		case 32:
			return uint32(n), nil //nolint:gosec // n is range-checked above
		}
		return uint64(n), nil
	}, nil
}

func integerOf(v engine.Value) (int64, error) {
	switch v.Kind {
	case engine.VInt:
		return v.Int, nil
	case engine.VBool:
		if v.Bool {
			return 1, nil
		}
		return 0, nil
	}
	return 0, errNotAssignable(v)
}

func boolValue(v engine.Value) (any, error) {
	switch v.Kind {
	case engine.VBool:
		return v.Bool, nil
	case engine.VInt:
		if v.Int == 0 || v.Int == 1 {
			return v.Int == 1, nil
		}
	}
	return nil, errNotAssignable(v)
}

func floatValue(bits int) valueConverter {
	return func(v engine.Value) (any, error) {
		var f float64
		switch v.Kind {
		case engine.VFloat:
			f = v.Float
		case engine.VInt:
			f = float64(v.Int)
		default:
			return nil, errNotAssignable(v)
		}
		if bits == 32 {
			return float32(f), nil
		}
		return f, nil
	}
}

func decimalValue(v engine.Value) (any, error) {
	switch v.Kind {
	case engine.VDecimal, engine.VText:
		return v.Str, nil
	case engine.VInt:
		return strconv.FormatInt(v.Int, 10), nil
	case engine.VFloat:
		if !math.IsNaN(v.Float) && !math.IsInf(v.Float, 0) {
			return strconv.FormatFloat(v.Float, 'f', -1, 64), nil
		}
	}
	return nil, errNotAssignable(v)
}

func stringValue(v engine.Value) (any, error) {
	switch v.Kind {
	case engine.VText, engine.VDecimal, engine.VJSON, engine.VUUID:
		return v.Str, nil
	case engine.VBytes:
		return string(v.Bytes), nil
	case engine.VInt:
		return strconv.FormatInt(v.Int, 10), nil
	case engine.VFloat:
		return strconv.FormatFloat(v.Float, 'g', -1, 64), nil
	}
	return nil, errNotAssignable(v)
}

func identifierValue(v engine.Value) (any, error) {
	switch v.Kind {
	case engine.VUUID, engine.VText:
		return v.Str, nil
	}
	return nil, errNotAssignable(v)
}

func timeValue(v engine.Value) (any, error) {
	switch v.Kind {
	case engine.VTimestamptz:
		return v.Time, nil
	case engine.VText:
		return v.Str, nil
	}
	return nil, errNotAssignable(v)
}

// dateValue drops the time of day: the driver rounds a pre-1970 date with a
// time of day to the following day.
func dateValue(v engine.Value) (any, error) {
	if v.Kind == engine.VTimestamptz {
		t := v.Time.UTC()
		return time.Date(t.Year(), t.Month(), t.Day(), 0, 0, 0, 0, time.UTC), nil
	}
	return timeValue(v)
}

func errNotAssignable(v engine.Value) error {
	return fmt.Errorf("a value of kind %d cannot be stored in this column", v.Kind)
}
