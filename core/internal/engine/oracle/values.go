package oracle

import (
	"fmt"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/doubledare704/queravue/core/internal/engine"
)

// maxLOBBytes caps one LOB cell. go-ora reads a LOB whole, so the cap bounds
// what reaches the sink, not what the driver holds for the current row.
const maxLOBBytes = 1 << 20

const truncationMarker = "… [truncated]"

// nativeNames maps go-ora type names to the names Oracle uses.
var nativeNames = map[string]string{
	"TIMESTAMPDTY":     "TIMESTAMP",
	"TIMESTAMPTZ_DTY":  "TIMESTAMP WITH TIME ZONE",
	"TIMESTAMPLTZ_DTY": "TIMESTAMP WITH LOCAL TIME ZONE",
	"INTERVALDS_DTY":   "INTERVAL DAY TO SECOND",
	"INTERVALYM_DTY":   "INTERVAL YEAR TO MONTH",
	"LONGVARCHAR":      "CLOB",
	"OCICLOBLOCATOR":   "CLOB",
	"LONGRAW":          "BLOB",
	"OCIBLOBLOCATOR":   "BLOB",
	"IBFLOAT":          "BINARY_FLOAT",
	"IBDOUBLE":         "BINARY_DOUBLE",
	"VARCHAR":          "VARCHAR2",
	"NVARCHAR":         "NVARCHAR2",
	"XMLTYPE":          "XMLTYPE",
}

func nativeName(driverName string) string {
	if n, ok := nativeNames[strings.ToUpper(driverName)]; ok {
		return n
	}
	return strings.ToUpper(driverName)
}

const maxIntPrecision = 18

// columnKind maps a native type name and, for NUMBER, its precision and
// scale (hasSize false when the column has none) to a value kind.
func columnKind(native string, precision, scale int64, hasSize bool) engine.ValueKind {
	switch native {
	case "NUMBER":
		if hasSize && precision > 0 && precision <= maxIntPrecision && scale == 0 {
			return engine.VInt
		}
		return engine.VDecimal
	case "FLOAT":
		return engine.VDecimal
	case "BINARY_FLOAT", "BINARY_DOUBLE":
		return engine.VFloat
	case "DATE", "TIMESTAMP", "TIMESTAMP WITH TIME ZONE", "TIMESTAMP WITH LOCAL TIME ZONE":
		return engine.VTimestamptz
	case "BLOB", "RAW", "LONG RAW":
		return engine.VBytes
	case "BOOLEAN":
		return engine.VBool
	case "JSON":
		return engine.VJSON
	}
	return engine.VText
}

// kindOfDataType maps a data_type from the catalog views to a value kind.
func kindOfDataType(dataType string, precision, scale int64, hasPrecision bool) engine.ValueKind {
	base := strings.ToUpper(dataType)
	if i := strings.IndexByte(base, '('); i >= 0 {
		base = strings.TrimSpace(base[:i]) + base[strings.LastIndexByte(base, ')')+1:]
	}
	switch {
	case strings.HasPrefix(base, "TIMESTAMP"):
		return engine.VTimestamptz
	case strings.HasPrefix(base, "INTERVAL"):
		return engine.VText
	}
	return columnKind(base, precision, scale, hasPrecision)
}

// convert turns one driver value into a typed value. Anything unexpected
// falls back to text, so a result is never lost to a decode bug.
func convert(kind engine.ValueKind, native string, v any) engine.Value {
	switch x := v.(type) {
	case nil:
		return engine.Null()
	case string:
		return convertString(kind, native, x)
	case []byte:
		return convertBytes(kind, x)
	case time.Time:
		return engine.Timestamptz(x)
	case float32:
		return engine.Float(float64(x))
	case float64:
		return engine.Float(x)
	case int64:
		return engine.Int(x)
	case bool:
		return engine.Bool(x)
	}
	return engine.Text(fmt.Sprint(v))
}

func convertString(kind engine.ValueKind, native, s string) engine.Value {
	switch kind {
	case engine.VInt:
		if n, err := strconv.ParseInt(s, 10, 64); err == nil {
			return engine.Int(n)
		}
		return engine.Decimal(s)
	case engine.VDecimal:
		return engine.Decimal(s)
	case engine.VJSON:
		return engine.JSON(s)
	case engine.VText:
		if native == "CLOB" || native == "NCLOB" {
			return engine.Text(capText(s))
		}
		return engine.Text(s)
	}
	return engine.Text(s)
}

func convertBytes(kind engine.ValueKind, b []byte) engine.Value {
	if kind == engine.VBytes {
		if len(b) > maxLOBBytes {
			b = b[:maxLOBBytes]
		}
		return engine.Bytes(append([]byte(nil), b...))
	}
	return engine.Text(capText(string(b)))
}

func capText(s string) string {
	if len(s) <= maxLOBBytes {
		return s
	}
	cut := maxLOBBytes
	for cut > 0 && !utf8.RuneStart(s[cut]) {
		cut--
	}
	return s[:cut] + truncationMarker
}

// toArgs converts bind parameters to driver arguments.
func toArgs(vals []engine.Value) ([]any, error) {
	out := make([]any, len(vals))
	for i, v := range vals {
		switch v.Kind {
		case engine.VNull:
			out[i] = nil
		case engine.VBool:
			out[i] = 0
			if v.Bool {
				out[i] = 1
			}
		case engine.VInt:
			out[i] = v.Int
		case engine.VFloat:
			out[i] = v.Float
		case engine.VDecimal, engine.VText, engine.VJSON, engine.VUUID:
			out[i] = v.Str
		case engine.VBytes:
			out[i] = v.Bytes
		case engine.VTimestamptz:
			out[i] = v.Time
		default:
			return nil, fmt.Errorf("parameter %d: unsupported type", i+1)
		}
	}
	return out, nil
}
