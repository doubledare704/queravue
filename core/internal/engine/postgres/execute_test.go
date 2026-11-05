package postgres

import (
	"reflect"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func TestConvert(t *testing.T) {
	ts := time.Date(2024, 1, 2, 3, 4, 5, 123456000, time.UTC)
	tests := []struct {
		name string
		oid  uint32
		in   []byte
		want engine.Value
	}{
		{"null", oidInt4, nil, engine.Null()},
		{"bool t", oidBool, []byte("t"), engine.Bool(true)},
		{"bool f", oidBool, []byte("f"), engine.Bool(false)},
		{"int8", oidInt8, []byte("-9223372036854775808"), engine.Int(-9223372036854775808)},
		{"float", oidFloat8, []byte("1.5"), engine.Float(1.5)},
		{"numeric stays exact", oidNumeric, []byte("12345678901234567890.123456789"), engine.Decimal("12345678901234567890.123456789")},
		{"text", oidText, []byte("héllo"), engine.Text("héllo")},
		{"bytea", oidBytea, []byte(`\xdeadbeef`), engine.Bytes([]byte{0xde, 0xad, 0xbe, 0xef})},
		{"bad bytea falls back", oidBytea, []byte(`abc`), engine.Text("abc")},
		{"timestamptz", oidTimestamptz, []byte("2024-01-02 03:04:05.123456+00"), engine.Timestamptz(ts)},
		{"timestamptz offset", oidTimestamptz, []byte("2024-01-02 08:34:05.123456+05:30"), engine.Timestamptz(ts)},
		{"timestamptz infinity is text", oidTimestamptz, []byte("infinity"), engine.Text("infinity")},
		{"json", oidJSONB, []byte(`{"a": 1}`), engine.JSON(`{"a": 1}`)},
		{"uuid", oidUUID, []byte("a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11"), engine.UUID("a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11")},
		{"date is text", 1082, []byte("2024-01-02"), engine.Text("2024-01-02")},
		{"unknown is text", 99999, []byte("x"), engine.Text("x")},
		{"int array", 1007, []byte("{1,2,NULL}"), engine.Array([]engine.Value{engine.Int(1), engine.Int(2), engine.Null()})},
		{"empty array", 1007, []byte("{}"), engine.Array([]engine.Value{})},
		{"text array quoting", 1009, []byte(`{a,"b, c","d\"e",NULL,"NULL"}`),
			engine.Array([]engine.Value{engine.Text("a"), engine.Text("b, c"), engine.Text(`d"e`), engine.Null(), engine.Text("NULL")})},
		{"nested array", 1007, []byte("{{1,2},{3,4}}"),
			engine.Array([]engine.Value{
				engine.Array([]engine.Value{engine.Int(1), engine.Int(2)}),
				engine.Array([]engine.Value{engine.Int(3), engine.Int(4)}),
			})},
		{"array with dims", 1007, []byte("[0:1]={5,6}"), engine.Array([]engine.Value{engine.Int(5), engine.Int(6)})},
		{"malformed array falls back", 1007, []byte("{1,2"), engine.Text("{1,2")},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := convert(tt.oid, tt.in)
			if tt.want.Kind == engine.VTimestamptz {
				if got.Kind != engine.VTimestamptz || !got.Time.Equal(tt.want.Time) {
					t.Errorf("got %+v, want %+v", got, tt.want)
				}
				return
			}
			if !reflect.DeepEqual(got, tt.want) {
				t.Errorf("got %+v, want %+v", got, tt.want)
			}
		})
	}
}

func TestKindAndTypeName(t *testing.T) {
	if kindOf(1007) != engine.VArray || typeName(1007) != "int4[]" {
		t.Errorf("int4[]: %v %s", kindOf(1007), typeName(1007))
	}
	if kindOf(oidNumeric) != engine.VDecimal || typeName(424242) != "oid:424242" {
		t.Error("numeric / unknown")
	}
}
