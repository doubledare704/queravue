package dataformat

import (
	"bytes"
	"encoding/hex"
	"encoding/json"
	"math"
	"strconv"
	"strings"
	"time"
	"unicode/utf8"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func valueText(v engine.Value) string {
	switch v.Kind {
	case engine.VBool:
		return strconv.FormatBool(v.Bool)
	case engine.VInt:
		return strconv.FormatInt(v.Int, 10)
	case engine.VFloat:
		return strconv.FormatFloat(v.Float, 'g', -1, 64)
	case engine.VDecimal:
		return v.Str
	case engine.VText:
		return v.Str
	case engine.VBytes:
		return `\x` + hex.EncodeToString(v.Bytes)
	case engine.VTimestamptz:
		return v.Time.Format(time.RFC3339Nano)
	case engine.VJSON:
		return v.Str
	case engine.VUUID:
		return v.Str
	case engine.VArray:
		var b bytes.Buffer
		writeJSON(&b, v)
		return b.String()
	}
	return ""
}

func writeJSON(b *bytes.Buffer, v engine.Value) {
	switch v.Kind {
	case engine.VBool:
		b.WriteString(strconv.FormatBool(v.Bool))
	case engine.VInt:
		b.WriteString(strconv.FormatInt(v.Int, 10))
	case engine.VFloat:
		if math.IsNaN(v.Float) || math.IsInf(v.Float, 0) {
			writeJSONString(b, strconv.FormatFloat(v.Float, 'g', -1, 64))
		} else {
			b.WriteString(strconv.FormatFloat(v.Float, 'g', -1, 64))
		}
	case engine.VDecimal:
		if json.Valid([]byte(v.Str)) && !strings.ContainsAny(v.Str, "\"[{ tfn") {
			b.WriteString(v.Str)
		} else {
			writeJSONString(b, v.Str)
		}
	case engine.VJSON:
		if utf8.ValidString(v.Str) && json.Valid([]byte(v.Str)) {
			b.WriteString(v.Str)
		} else {
			writeJSONString(b, v.Str)
		}
	case engine.VArray:
		b.WriteByte('[')
		for i, e := range v.Array {
			if i > 0 {
				b.WriteByte(',')
			}
			writeJSON(b, e)
		}
		b.WriteByte(']')
	case engine.VText, engine.VBytes, engine.VTimestamptz, engine.VUUID:
		writeJSONString(b, valueText(v))
	default:
		b.WriteString("null")
	}
}

func writeJSONString(b *bytes.Buffer, s string) {
	enc, _ := json.Marshal(strings.ToValidUTF8(s, "\uFFFD"))
	b.Write(enc)
}

func valueFits(v engine.Value, remaining *int, depth int) bool {
	if depth > 1000 {
		return false
	}
	*remaining -= 1 + len(v.Str) + len(v.Bytes)
	if *remaining < 0 {
		return false
	}
	if v.Kind == engine.VArray {
		for _, child := range v.Array {
			if !valueFits(child, remaining, depth+1) {
				return false
			}
		}
	}
	return true
}
