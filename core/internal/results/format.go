package results

import (
	"bytes"
	"encoding/hex"
	"encoding/json"
	"math"
	"strconv"
	"strings"
	"time"

	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

// Formatter renders rows as TSV, CSV or a JSON array. Use Begin, then Row for
// each row, then End; take the output from the buffer returned by Buffer.
type Formatter struct {
	format queravuev1.CopyFormat
	cols   []*queravuev1.Column // selected columns, output order
	idx    []int                // source index per output column
	header bool
	buf    bytes.Buffer
	rows   int
}

// NewFormatter selects columns by index (nil or empty means all). Indices out
// of range are skipped.
func NewFormatter(format queravuev1.CopyFormat, all []*queravuev1.Column, indices []uint32, header bool) *Formatter {
	f := &Formatter{format: format, header: header}
	if len(indices) == 0 {
		for i := range all {
			f.idx = append(f.idx, i)
		}
	} else {
		for _, i := range indices {
			if int(i) < len(all) {
				f.idx = append(f.idx, int(i))
			}
		}
	}
	for _, i := range f.idx {
		f.cols = append(f.cols, all[i])
	}
	return f
}

// Buffer returns the pending output. Callers drain it with Reset or Next.
func (f *Formatter) Buffer() *bytes.Buffer { return &f.buf }

// Begin writes the preamble: the header line, or "[" for JSON.
func (f *Formatter) Begin() {
	switch f.format {
	case queravuev1.CopyFormat_COPY_FORMAT_JSON:
		f.buf.WriteByte('[')
	default:
		if f.header {
			for i, c := range f.cols {
				if i > 0 {
					f.buf.WriteByte(f.sep())
				}
				f.field(c.GetName())
			}
			f.buf.WriteByte('\n')
		}
	}
}

// Row writes one row.
func (f *Formatter) Row(r *queravuev1.Row) {
	vals := r.GetValues()
	if f.format == queravuev1.CopyFormat_COPY_FORMAT_JSON {
		if f.rows > 0 {
			f.buf.WriteByte(',')
		}
		f.buf.WriteString("\n  {")
		for i, ci := range f.idx {
			if i > 0 {
				f.buf.WriteString(", ")
			}
			name, _ := json.Marshal(f.cols[i].GetName())
			f.buf.Write(name)
			f.buf.WriteString(": ")
			if ci < len(vals) {
				writeJSON(&f.buf, vals[ci])
			} else {
				f.buf.WriteString("null")
			}
		}
		f.buf.WriteByte('}')
		f.rows++
		return
	}
	for i, ci := range f.idx {
		if i > 0 {
			f.buf.WriteByte(f.sep())
		}
		if ci < len(vals) {
			f.field(Text(vals[ci]))
		}
	}
	f.buf.WriteByte('\n')
	f.rows++
}

// End writes the closing "]" for JSON.
func (f *Formatter) End() {
	if f.format == queravuev1.CopyFormat_COPY_FORMAT_JSON {
		if f.rows > 0 {
			f.buf.WriteByte('\n')
		}
		f.buf.WriteString("]\n")
	}
}

func (f *Formatter) sep() byte {
	if f.format == queravuev1.CopyFormat_COPY_FORMAT_CSV {
		return ','
	}
	return '\t'
}

// field writes s with quoting for the delimited formats.
func (f *Formatter) field(s string) {
	need := strings.ContainsAny(s, "\"\n\r") || strings.IndexByte(s, f.sep()) >= 0
	if !need {
		f.buf.WriteString(s)
		return
	}
	f.buf.WriteByte('"')
	f.buf.WriteString(strings.ReplaceAll(s, `"`, `""`))
	f.buf.WriteByte('"')
}

// Text renders a value as plain text (NULL is empty).
func Text(v *queravuev1.Value) string {
	switch k := v.GetKind().(type) {
	case *queravuev1.Value_BoolValue:
		return strconv.FormatBool(k.BoolValue)
	case *queravuev1.Value_IntValue:
		return strconv.FormatInt(k.IntValue, 10)
	case *queravuev1.Value_DoubleValue:
		return strconv.FormatFloat(k.DoubleValue, 'g', -1, 64)
	case *queravuev1.Value_DecimalValue:
		return k.DecimalValue
	case *queravuev1.Value_TextValue:
		return k.TextValue
	case *queravuev1.Value_BytesValue:
		return `\x` + hex.EncodeToString(k.BytesValue)
	case *queravuev1.Value_TimestampValue:
		return k.TimestampValue.AsTime().Format(time.RFC3339Nano)
	case *queravuev1.Value_JsonValue:
		return k.JsonValue
	case *queravuev1.Value_UuidValue:
		return k.UuidValue
	case *queravuev1.Value_ArrayValue:
		var b bytes.Buffer
		writeJSON(&b, v)
		return b.String()
	}
	return ""
}

func writeJSON(b *bytes.Buffer, v *queravuev1.Value) {
	switch k := v.GetKind().(type) {
	case *queravuev1.Value_BoolValue:
		b.WriteString(strconv.FormatBool(k.BoolValue))
	case *queravuev1.Value_IntValue:
		b.WriteString(strconv.FormatInt(k.IntValue, 10))
	case *queravuev1.Value_DoubleValue:
		if math.IsNaN(k.DoubleValue) || math.IsInf(k.DoubleValue, 0) {
			writeJSONString(b, strconv.FormatFloat(k.DoubleValue, 'g', -1, 64))
		} else {
			b.WriteString(strconv.FormatFloat(k.DoubleValue, 'g', -1, 64))
		}
	case *queravuev1.Value_DecimalValue:
		if json.Valid([]byte(k.DecimalValue)) && !strings.ContainsAny(k.DecimalValue, "\"[{ tfn") {
			b.WriteString(k.DecimalValue)
		} else {
			writeJSONString(b, k.DecimalValue)
		}
	case *queravuev1.Value_JsonValue:
		if json.Valid([]byte(k.JsonValue)) {
			b.WriteString(k.JsonValue)
		} else {
			writeJSONString(b, k.JsonValue)
		}
	case *queravuev1.Value_ArrayValue:
		b.WriteByte('[')
		for i, e := range k.ArrayValue.GetValues() {
			if i > 0 {
				b.WriteByte(',')
			}
			writeJSON(b, e)
		}
		b.WriteByte(']')
	case *queravuev1.Value_TextValue, *queravuev1.Value_BytesValue, *queravuev1.Value_TimestampValue, *queravuev1.Value_UuidValue:
		writeJSONString(b, Text(v))
	default:
		b.WriteString("null")
	}
}

func writeJSONString(b *bytes.Buffer, s string) {
	enc, _ := json.Marshal(validUTF8(s))
	b.Write(enc)
}
