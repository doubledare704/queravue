package mongo

import (
	"errors"
	"testing"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func TestEJSONRoundTripAllTypes(t *testing.T) {
	oid := bson.NewObjectID()
	dec, _ := bson.ParseDecimal128("1234567890.1234567890123")
	cases := []struct {
		name string
		val  any
	}{
		{"double", 1.5},
		{"double whole", float64(3)},
		{"string", "héllo   😀"},
		{"document", bson.D{{Key: "a", Value: int32(1)}}},
		{"array", bson.A{int32(1), "x", nil}},
		{"binary generic", bson.Binary{Subtype: 0, Data: []byte{1, 2, 3}}},
		{"binary uuid", bson.Binary{Subtype: 4, Data: make([]byte, 16)}},
		{"binary user", bson.Binary{Subtype: 0x80, Data: []byte("x")}},
		{"undefined", bson.Undefined{}},
		{"objectid", oid},
		{"bool", true},
		{"date", bson.NewDateTimeFromTime(time.Date(1969, 7, 20, 20, 17, 0, 0, time.UTC))},
		{"date far", bson.DateTime(253402300800000)},
		{"null", nil},
		{"regex", bson.Regex{Pattern: "^a.*b$", Options: "im"}},
		{"dbpointer", bson.DBPointer{DB: "db", Pointer: oid}},
		{"javascript", bson.JavaScript("function(){}")},
		{"symbol", bson.Symbol("sym")},
		{"code with scope", bson.CodeWithScope{Code: "x", Scope: bson.D{{Key: "a", Value: int32(1)}}}},
		{"int32", int32(7)},
		{"int32 min", int32(-2147483648)},
		{"timestamp", bson.Timestamp{T: 1700000000, I: 3}},
		{"int64", int64(1) << 62},
		{"int64 small", int64(5)},
		{"decimal128", dec},
		{"minkey", bson.MinKey{}},
		{"maxkey", bson.MaxKey{}},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			orig, err := bson.Marshal(bson.D{{Key: "_id", Value: int32(1)}, {Key: "v", Value: tc.val}})
			if err != nil {
				t.Fatal(err)
			}
			text, err := toEJSON(orig)
			if err != nil {
				t.Fatal(err)
			}
			back, err := parseDocument(text, true, engine.InputDocument)
			if err != nil {
				t.Fatalf("parse %s: %v", text, err)
			}
			if string(back) != string(orig) {
				t.Fatalf("bytes differ after round trip\n text: %s\n orig: %v\n back: %v", text, bson.Raw(orig), back)
			}
			again, _ := toEJSON(back)
			if again != text {
				t.Fatalf("ejson not stable: %s vs %s", text, again)
			}
		})
	}
}

func TestInt64StaysInt64(t *testing.T) {
	raw, err := parseDocument(`{"n":{"$numberLong":"5"},"d":{"$numberDouble":"5"},"i":{"$numberInt":"5"}}`, true, engine.InputDocument)
	if err != nil {
		t.Fatal(err)
	}
	for k, want := range map[string]bson.Type{"n": bson.TypeInt64, "d": bson.TypeDouble, "i": bson.TypeInt32} {
		if got := raw.Lookup(k).Type; got != want {
			t.Errorf("%s: type %v, want %v", k, got, want)
		}
	}
}

func TestParseErrors(t *testing.T) {
	cases := []struct {
		name      string
		text      string
		canonical bool
		wantPos   int // -1: don't check
	}{
		{"unterminated", `{"a": 1`, false, -1},
		{"bad token", `{"a": ]}`, false, 6},
		{"bad token after emoji", `{"😀": ]}`, false, 7}, // emoji is 2 UTF-16 units
		{"trailing data", `{"a":1} x`, false, -1},
		{"bare number in document", `{"a": 1}`, true, -1},
		{"nested bare number", `{"a": {"b": [1]}}`, true, -1},
		{"bad wrapper", `{"a": {"$numberLong": "x"}}`, true, -1},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			_, err := parseDocument(tc.text, tc.canonical, engine.InputFilter)
			var e *engine.Error
			if !errors.As(err, &e) || e.Kind != engine.KindParse {
				t.Fatalf("err = %v, want parse error", err)
			}
			if e.Input != engine.InputFilter {
				t.Errorf("input = %v", e.Input)
			}
			if tc.wantPos >= 0 && e.Position != tc.wantPos {
				t.Errorf("position = %d, want %d (%s)", e.Position, tc.wantPos, e.Msg)
			}
		})
	}
}

func TestRelaxedFilterAccepted(t *testing.T) {
	raw, err := parseDocument(`{"age": {"$gt": 21}, "name": "x"}`, false, engine.InputFilter)
	if err != nil {
		t.Fatal(err)
	}
	if raw.Lookup("name").StringValue() != "x" {
		t.Fatal("bad parse")
	}
}

func TestValueRoundTrip(t *testing.T) {
	for _, text := range []string{`{"$oid":"507f1f77bcf86cd799439011"}`, `{"$numberInt":"5"}`, `"abc"`, `{"$numberLong":"9"}`} {
		v, err := parseValue(text, engine.InputDocument)
		if err != nil {
			t.Fatalf("%s: %v", text, err)
		}
		got, err := valueToEJSON(v)
		if err != nil {
			t.Fatal(err)
		}
		if got != text {
			t.Errorf("got %s want %s", got, text)
		}
	}
	_, err := parseValue(`{"$oid": ]`, engine.InputDocument)
	var e *engine.Error
	if !errors.As(err, &e) || e.Position != 9 {
		t.Errorf("err = %+v", err)
	}
}
