//go:build duckdb

package duckdb

import (
	"bytes"
	"database/sql/driver"
	"encoding/json"
	"fmt"
	"math"
	"math/big"
	"sort"
	"strconv"
	"strings"
	"time"

	duckdbdriver "github.com/duckdb/duckdb-go/v2"

	"github.com/doubledare704/queravue/core/internal/engine"
)

const (
	dateLayout      = "2006-01-02"
	timeLayout      = "15:04:05.999999999"
	timeZoneLayout  = "15:04:05.999999999Z07:00"
	timestampLayout = "2006-01-02 15:04:05.999999999"
)

// convert maps a driver value to a typed value. typeName is the column's
// DuckDB type; values nested in a LIST or STRUCT have none.
func convert(typeName string, v any) engine.Value {
	switch x := v.(type) {
	case nil:
		return engine.Null()
	case bool:
		return engine.Bool(x)
	case int8:
		return engine.Int(int64(x))
	case int16:
		return engine.Int(int64(x))
	case int32:
		return engine.Int(int64(x))
	case int64:
		return engine.Int(x)
	case int:
		return engine.Int(int64(x))
	case uint8:
		return engine.Int(int64(x))
	case uint16:
		return engine.Int(int64(x))
	case uint32:
		return engine.Int(int64(x))
	case uint64:
		if x > math.MaxInt64 {
			return engine.Decimal(strconv.FormatUint(x, 10))
		}
		return engine.Int(int64(x))
	case float32:
		return engine.Float(float64(x))
	case float64:
		return engine.Float(x)
	case string:
		return convertString(typeName, x)
	case []byte:
		if strings.EqualFold(typeName, "UUID") && len(x) == 16 {
			return engine.UUID(formatUUID(x))
		}
		return engine.Bytes(append([]byte(nil), x...))
	case time.Time:
		return convertTime(typeName, x)
	case *big.Int:
		return engine.Decimal(x.String())
	case duckdbdriver.Decimal:
		return engine.Decimal(x.String())
	case duckdbdriver.Interval:
		return engine.Text(formatInterval(x))
	case duckdbdriver.Union:
		return convert("", x.Value)
	case []any:
		items := make([]engine.Value, len(x))
		for i, item := range x {
			items[i] = convert("", item)
		}
		return engine.Array(items)
	case map[string]any, duckdbdriver.OrderedMap:
		return engine.JSON(marshalJSON(x))
	}
	if strings.EqualFold(typeName, "JSON") {
		return engine.JSON(marshalJSON(v))
	}
	return engine.Text(fmt.Sprint(v))
}

func convertString(typeName, s string) engine.Value {
	if strings.EqualFold(typeName, "JSON") {
		return engine.JSON(marshalJSON(s))
	}
	return engine.Text(s)
}

func convertTime(typeName string, t time.Time) engine.Value {
	switch strings.ToUpper(typeName) {
	case "TIMESTAMP WITH TIME ZONE", "TIMESTAMPTZ":
		return engine.Timestamptz(t)
	case "DATE":
		return engine.Text(t.Format(dateLayout))
	case "TIME":
		return engine.Text(t.Format(timeLayout))
	case "TIME WITH TIME ZONE":
		return engine.Text(t.Format(timeZoneLayout))
	case "TIMESTAMP", "TIMESTAMP_S", "TIMESTAMP_MS", "TIMESTAMP_NS":
		return engine.Text(t.Format(timestampLayout))
	}
	return engine.Text(t.Format(time.RFC3339Nano))
}

func formatUUID(b []byte) string {
	h := fmt.Sprintf("%x", b)
	return h[0:8] + "-" + h[8:12] + "-" + h[12:16] + "-" + h[16:20] + "-" + h[20:32]
}

// formatInterval writes an interval the way DuckDB prints it.
func formatInterval(iv duckdbdriver.Interval) string {
	var parts []string
	unit := func(n int64, singular string) {
		if n == 0 {
			return
		}
		name := singular
		if n != 1 {
			name += "s"
		}
		parts = append(parts, fmt.Sprintf("%d %s", n, name))
	}
	unit(int64(iv.Months)/12, "year")
	unit(int64(iv.Months)%12, "month")
	unit(int64(iv.Days), "day")
	if iv.Micros != 0 || len(parts) == 0 {
		parts = append(parts, formatMicros(iv.Micros))
	}
	return strings.Join(parts, " ")
}

func formatMicros(micros int64) string {
	sign := ""
	if micros < 0 {
		sign, micros = "-", -micros
	}
	out := fmt.Sprintf("%s%02d:%02d:%02d", sign, micros/3_600_000_000, micros/60_000_000%60, micros/1_000_000%60)
	if frac := micros % 1_000_000; frac != 0 {
		out += "." + strings.TrimRight(fmt.Sprintf("%06d", frac), "0")
	}
	return out
}

// marshalJSON renders nested values as JSON. STRUCT fields come back from the
// driver as an unordered Go map, so they are written sorted by name.
func marshalJSON(v any) string {
	var buf bytes.Buffer
	writeJSON(&buf, v)
	return buf.String()
}

func writeJSON(buf *bytes.Buffer, v any) {
	switch x := v.(type) {
	case nil:
		buf.WriteString("null")
	case map[string]any:
		keys := make([]string, 0, len(x))
		for k := range x {
			keys = append(keys, k)
		}
		sort.Strings(keys)
		buf.WriteByte('{')
		for i, k := range keys {
			if i > 0 {
				buf.WriteByte(',')
			}
			writeJSONString(buf, k)
			buf.WriteByte(':')
			writeJSON(buf, x[k])
		}
		buf.WriteByte('}')
	case duckdbdriver.OrderedMap:
		keys, values := x.Keys(), x.Values()
		buf.WriteByte('{')
		for i, k := range keys {
			if i > 0 {
				buf.WriteByte(',')
			}
			writeJSONString(buf, fmt.Sprint(k))
			buf.WriteByte(':')
			writeJSON(buf, values[i])
		}
		buf.WriteByte('}')
	case []any:
		buf.WriteByte('[')
		for i, item := range x {
			if i > 0 {
				buf.WriteByte(',')
			}
			writeJSON(buf, item)
		}
		buf.WriteByte(']')
	case duckdbdriver.Decimal:
		buf.WriteString(x.String())
	case *big.Int:
		buf.WriteString(x.String())
	case duckdbdriver.Interval:
		writeJSONString(buf, formatInterval(x))
	case duckdbdriver.Union:
		writeJSON(buf, x.Value)
	case []byte:
		writeJSONString(buf, fmt.Sprintf("\\x%X", x))
	case time.Time:
		writeJSONString(buf, x.Format(time.RFC3339Nano))
	case float32:
		writeJSONFloat(buf, float64(x))
	case float64:
		writeJSONFloat(buf, x)
	default:
		encoded, err := json.Marshal(x)
		if err != nil {
			writeJSONString(buf, fmt.Sprint(x))
			return
		}
		buf.Write(encoded)
	}
}

func writeJSONFloat(buf *bytes.Buffer, f float64) {
	if math.IsNaN(f) || math.IsInf(f, 0) {
		writeJSONString(buf, strconv.FormatFloat(f, 'g', -1, 64))
		return
	}
	buf.WriteString(strconv.FormatFloat(f, 'g', -1, 64))
}

func writeJSONString(buf *bytes.Buffer, s string) {
	encoded, _ := json.Marshal(s)
	buf.Write(encoded)
}

func toArgs(vals []engine.Value) ([]driver.NamedValue, error) {
	out := make([]driver.NamedValue, len(vals))
	for i, v := range vals {
		arg, err := toArg(v)
		if err != nil {
			return nil, fmt.Errorf("parameter %d: %w", i+1, err)
		}
		out[i] = driver.NamedValue{Ordinal: i + 1, Value: arg}
	}
	return out, nil
}

func toArg(v engine.Value) (driver.Value, error) {
	switch v.Kind {
	case engine.VNull:
		return nil, nil
	case engine.VBool:
		return v.Bool, nil
	case engine.VInt:
		return v.Int, nil
	case engine.VFloat:
		return v.Float, nil
	case engine.VDecimal, engine.VText, engine.VJSON, engine.VUUID:
		return v.Str, nil
	case engine.VBytes:
		return v.Bytes, nil
	case engine.VTimestamptz:
		return v.Time, nil
	case engine.VArray:
		return nil, fmt.Errorf("arrays cannot be bound; write the list in SQL")
	}
	return nil, fmt.Errorf("unsupported type")
}
