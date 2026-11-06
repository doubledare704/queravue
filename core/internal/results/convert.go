package results

import (
	"strings"
	"unicode/utf8"

	"google.golang.org/protobuf/types/known/structpb"
	"google.golang.org/protobuf/types/known/timestamppb"

	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

// validUTF8 replaces invalid sequences: proto3 strings must be UTF-8, and a
// stray byte in a SQLite TEXT cell must not fail a whole result page.
func validUTF8(s string) string {
	if utf8.ValidString(s) {
		return s
	}
	return strings.ToValidUTF8(s, "\uFFFD")
}

// ValueToProto converts an engine value to its wire form.
func ValueToProto(v engine.Value) *queravuev1.Value {
	out := &queravuev1.Value{}
	switch v.Kind {
	case engine.VBool:
		out.Kind = &queravuev1.Value_BoolValue{BoolValue: v.Bool}
	case engine.VInt:
		out.Kind = &queravuev1.Value_IntValue{IntValue: v.Int}
	case engine.VFloat:
		out.Kind = &queravuev1.Value_DoubleValue{DoubleValue: v.Float}
	case engine.VDecimal:
		out.Kind = &queravuev1.Value_DecimalValue{DecimalValue: validUTF8(v.Str)}
	case engine.VText:
		out.Kind = &queravuev1.Value_TextValue{TextValue: validUTF8(v.Str)}
	case engine.VBytes:
		out.Kind = &queravuev1.Value_BytesValue{BytesValue: v.Bytes}
	case engine.VTimestamptz:
		out.Kind = &queravuev1.Value_TimestampValue{TimestampValue: timestamppb.New(v.Time)}
	case engine.VJSON:
		out.Kind = &queravuev1.Value_JsonValue{JsonValue: validUTF8(v.Str)}
	case engine.VUUID:
		out.Kind = &queravuev1.Value_UuidValue{UuidValue: validUTF8(v.Str)}
	case engine.VArray:
		arr := &queravuev1.ArrayValue{Values: make([]*queravuev1.Value, len(v.Array))}
		for i, e := range v.Array {
			arr.Values[i] = ValueToProto(e)
		}
		out.Kind = &queravuev1.Value_ArrayValue{ArrayValue: arr}
	default:
		out.Kind = &queravuev1.Value_NullValue{NullValue: structpb.NullValue_NULL_VALUE}
	}
	return out
}

// ValueFromProto converts a wire value (a bind parameter) to an engine value.
func ValueFromProto(v *queravuev1.Value) engine.Value {
	switch k := v.GetKind().(type) {
	case *queravuev1.Value_BoolValue:
		return engine.Bool(k.BoolValue)
	case *queravuev1.Value_IntValue:
		return engine.Int(k.IntValue)
	case *queravuev1.Value_DoubleValue:
		return engine.Float(k.DoubleValue)
	case *queravuev1.Value_DecimalValue:
		return engine.Decimal(k.DecimalValue)
	case *queravuev1.Value_TextValue:
		return engine.Text(k.TextValue)
	case *queravuev1.Value_BytesValue:
		return engine.Bytes(k.BytesValue)
	case *queravuev1.Value_TimestampValue:
		return engine.Timestamptz(k.TimestampValue.AsTime())
	case *queravuev1.Value_JsonValue:
		return engine.JSON(k.JsonValue)
	case *queravuev1.Value_UuidValue:
		return engine.UUID(k.UuidValue)
	case *queravuev1.Value_ArrayValue:
		vals := make([]engine.Value, len(k.ArrayValue.GetValues()))
		for i, e := range k.ArrayValue.GetValues() {
			vals[i] = ValueFromProto(e)
		}
		return engine.Array(vals)
	}
	return engine.Null()
}

// RowsToProto converts engine rows to wire rows.
func RowsToProto(rows [][]engine.Value) []*queravuev1.Row {
	out := make([]*queravuev1.Row, len(rows))
	for i, r := range rows {
		vals := make([]*queravuev1.Value, len(r))
		for j, v := range r {
			vals[j] = ValueToProto(v)
		}
		out[i] = &queravuev1.Row{Values: vals}
	}
	return out
}

var kindToProto = map[engine.ValueKind]queravuev1.ValueKind{
	engine.VBool:        queravuev1.ValueKind_VALUE_KIND_BOOL,
	engine.VInt:         queravuev1.ValueKind_VALUE_KIND_INT,
	engine.VFloat:       queravuev1.ValueKind_VALUE_KIND_FLOAT,
	engine.VDecimal:     queravuev1.ValueKind_VALUE_KIND_DECIMAL,
	engine.VText:        queravuev1.ValueKind_VALUE_KIND_TEXT,
	engine.VBytes:       queravuev1.ValueKind_VALUE_KIND_BYTES,
	engine.VTimestamptz: queravuev1.ValueKind_VALUE_KIND_TIMESTAMPTZ,
	engine.VJSON:        queravuev1.ValueKind_VALUE_KIND_JSON,
	engine.VUUID:        queravuev1.ValueKind_VALUE_KIND_UUID,
	engine.VArray:       queravuev1.ValueKind_VALUE_KIND_ARRAY,
}

// KindToProto converts an engine ValueKind to proto ValueKind.
func KindToProto(k engine.ValueKind) queravuev1.ValueKind {
	if pk, ok := kindToProto[k]; ok {
		return pk
	}
	return queravuev1.ValueKind_VALUE_KIND_UNSPECIFIED
}

// ColumnsToProto converts engine columns to wire columns.
func ColumnsToProto(cols []engine.Column) []*queravuev1.Column {
	out := make([]*queravuev1.Column, len(cols))
	for i, c := range cols {
		out[i] = &queravuev1.Column{Name: validUTF8(c.Name), TypeName: c.TypeName, Kind: KindToProto(c.Kind)}
	}
	return out
}
