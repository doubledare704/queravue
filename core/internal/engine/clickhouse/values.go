package clickhouse

import (
	"encoding/json"
	"fmt"
	"math/big"
	"net"
	"net/netip"
	"reflect"
	"strings"
	"time"

	"github.com/shopspring/decimal"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func unwrapType(typeName string) string {
	for {
		inner, ok := unwrapOnce(typeName)
		if !ok {
			return typeName
		}
		typeName = inner
	}
}

func unwrapOnce(typeName string) (string, bool) {
	for _, wrapper := range []string{"Nullable(", "LowCardinality(", "SimpleAggregateFunction("} {
		if strings.HasPrefix(typeName, wrapper) && strings.HasSuffix(typeName, ")") {
			inner := typeName[len(wrapper) : len(typeName)-1]
			if wrapper == "SimpleAggregateFunction(" {
				_, inner, _ = strings.Cut(inner, ", ")
			}
			return inner, true
		}
	}
	return "", false
}

func isNullable(typeName string) bool {
	return strings.HasPrefix(typeName, "Nullable(") ||
		strings.HasPrefix(typeName, "LowCardinality(Nullable(")
}

func kindOf(typeName string) engine.ValueKind {
	base := unwrapType(typeName)
	switch {
	case base == "Bool":
		return engine.VBool
	case base == "UInt64", base == "Int128", base == "UInt128", base == "Int256", base == "UInt256":
		return engine.VDecimal
	case strings.HasPrefix(base, "Int"), strings.HasPrefix(base, "UInt"):
		return engine.VInt
	case strings.HasPrefix(base, "Float"):
		return engine.VFloat
	case strings.HasPrefix(base, "Decimal"):
		return engine.VDecimal
	case strings.HasPrefix(base, "DateTime"):
		return engine.VTimestamptz
	case base == "UUID":
		return engine.VUUID
	case strings.HasPrefix(base, "Array("):
		return engine.VArray
	case base == "JSON", strings.HasPrefix(base, "JSON("), strings.HasPrefix(base, "Object("),
		strings.HasPrefix(base, "Map("), strings.HasPrefix(base, "Tuple("), strings.HasPrefix(base, "Nested("):
		return engine.VJSON
	}
	return engine.VText
}

func convert(typeName string, v reflect.Value) engine.Value {
	for v.Kind() == reflect.Pointer || v.Kind() == reflect.Interface {
		if v.IsNil() {
			return engine.Null()
		}
		v = v.Elem()
	}
	return convertConcrete(unwrapType(typeName), v)
}

func convertConcrete(base string, v reflect.Value) engine.Value {
	switch x := v.Interface().(type) {
	case time.Time:
		return convertTime(base, x)
	case decimal.Decimal:
		return engine.Decimal(x.String())
	case big.Int:
		return engine.Decimal(x.String())
	case *big.Int:
		return engine.Decimal(x.String())
	case netip.Addr:
		return engine.Text(x.String())
	case net.IP:
		return engine.Text(x.String())
	case fmt.Stringer:
		if base == "UUID" {
			return engine.UUID(x.String())
		}
		return engine.Text(x.String())
	}
	switch v.Kind() {
	case reflect.Bool:
		return engine.Bool(v.Bool())
	case reflect.Int, reflect.Int8, reflect.Int16, reflect.Int32, reflect.Int64:
		return engine.Int(v.Int())
	case reflect.Uint, reflect.Uint8, reflect.Uint16, reflect.Uint32, reflect.Uint64:
		return convertUnsigned(v.Uint())
	case reflect.Float32, reflect.Float64:
		return engine.Float(v.Float())
	case reflect.String:
		return convertString(base, v.String())
	case reflect.Slice, reflect.Array:
		return convertSequence(base, v)
	case reflect.Map, reflect.Struct:
		return convertStructured(v)
	}
	return engine.Text(fmt.Sprint(v.Interface()))
}

func convertTime(base string, t time.Time) engine.Value {
	switch {
	case strings.HasPrefix(base, "Date32"), base == "Date":
		return engine.Text(t.Format("2006-01-02"))
	case strings.HasPrefix(base, "Time64"), base == "Time":
		return engine.Text(t.Format("15:04:05.999999999"))
	}
	return engine.Timestamptz(t)
}

func convertUnsigned(u uint64) engine.Value {
	if u > 1<<63-1 {
		return engine.Decimal(fmt.Sprint(u))
	}
	return engine.Int(int64(u))
}

func convertString(base, s string) engine.Value {
	switch {
	case base == "JSON", strings.HasPrefix(base, "JSON("), strings.HasPrefix(base, "Object("):
		return engine.JSON(s)
	case base == "UUID":
		return engine.UUID(s)
	}
	return engine.Text(s)
}

func convertSequence(base string, v reflect.Value) engine.Value {
	if v.Kind() == reflect.Slice && v.Type().Elem().Kind() == reflect.Uint8 {
		return engine.Text(string(v.Bytes()))
	}
	elementType := ""
	if inner, ok := strings.CutPrefix(base, "Array("); ok {
		elementType = strings.TrimSuffix(inner, ")")
	}
	if elementType == "" && strings.HasPrefix(base, "Tuple(") {
		return convertStructured(v)
	}
	items := make([]engine.Value, v.Len())
	for i := range items {
		items[i] = convert(elementType, v.Index(i))
	}
	return engine.Array(items)
}

func convertStructured(v reflect.Value) engine.Value {
	encoded, err := json.Marshal(v.Interface())
	if err != nil {
		return engine.Text(fmt.Sprint(v.Interface()))
	}
	return engine.JSON(string(encoded))
}

func toArgs(vals []engine.Value) ([]any, error) {
	out := make([]any, len(vals))
	for i, v := range vals {
		switch v.Kind {
		case engine.VNull:
			out[i] = nil
		case engine.VBool:
			out[i] = v.Bool
		case engine.VInt:
			out[i] = v.Int
		case engine.VFloat:
			out[i] = v.Float
		case engine.VDecimal, engine.VText, engine.VJSON, engine.VUUID:
			out[i] = v.Str
		case engine.VBytes:
			out[i] = string(v.Bytes)
		case engine.VTimestamptz:
			out[i] = v.Time
		default:
			return nil, fmt.Errorf("parameter %d: unsupported type", i+1)
		}
	}
	return out, nil
}
