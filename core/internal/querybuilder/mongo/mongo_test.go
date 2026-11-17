package mongo

import (
	"fmt"
	"testing"

	"google.golang.org/protobuf/proto"

	pb "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

func TestRoundTrip(t *testing.T) {
	cases := []struct {
		op    pb.MongoOperator
		value string
	}{
		{pb.MongoOperator_MONGO_OPERATOR_EQ, `"text"`}, {pb.MongoOperator_MONGO_OPERATOR_NE, `null`}, {pb.MongoOperator_MONGO_OPERATOR_GT, `{"$numberInt":"3"}`}, {pb.MongoOperator_MONGO_OPERATOR_GTE, `{"$numberLong":"9999999999"}`}, {pb.MongoOperator_MONGO_OPERATOR_LT, `{"$numberDouble":"1.5"}`}, {pb.MongoOperator_MONGO_OPERATOR_LTE, `{"$date":{"$numberLong":"0"}}`}, {pb.MongoOperator_MONGO_OPERATOR_IN, `["a","b"]`}, {pb.MongoOperator_MONGO_OPERATOR_NIN, `[true,false]`}, {pb.MongoOperator_MONGO_OPERATOR_EXISTS, `true`}, {pb.MongoOperator_MONGO_OPERATOR_REGEX, `"^ab"`}, {pb.MongoOperator_MONGO_OPERATOR_TYPE, `"string"`},
	}
	for i, tc := range cases {
		for j := 0; j < 5; j++ {
			t.Run(fmt.Sprintf("%d/%d", i, j), func(t *testing.T) {
				f := &pb.MongoFieldCondition{Path: fmt.Sprintf("field%d", j), Op: tc.op, ValueEjson: tc.value, Negated: j%2 == 1}
				if tc.op == pb.MongoOperator_MONGO_OPERATOR_REGEX {
					f.RegexOptions = "i"
				}
				m := &pb.MongoFindModel{Filter: &pb.MongoCondition{Node: &pb.MongoCondition_Field{Field: f}}, Projection: []*pb.MongoProjectionField{{Path: "name", Mode: pb.MongoProjectionMode_MONGO_PROJECTION_MODE_INCLUDE}}, Sort: []*pb.MongoSortField{{Path: "created", Descending: true}, {Path: "name"}}}
				filter, projection, sort, err := Generate(m)
				if err != nil {
					t.Fatal(err)
				}
				got, err := Parse(filter, projection, sort)
				if err != nil {
					t.Fatal(err)
				}
				if !proto.Equal(m, got) {
					t.Fatalf("model mismatch: %v != %v", m, got)
				}
				f2, p2, s2, err := Generate(got)
				if err != nil || f2 != filter || p2 != projection || s2 != sort {
					t.Fatalf("text mismatch: %q %q %q: %v", f2, p2, s2, err)
				}
			})
		}
	}
}

func TestRawAndGroups(t *testing.T) {
	for _, input := range []string{`{"$expr":{"$gt":["$a",3]}}`, `{"a":{"$elemMatch":{"x":1}}}`, `{"$or":[{"a":1},{"$nor":[{"b":{"$ne":2}}]}]}`} {
		t.Run(input, func(t *testing.T) {
			m, err := Parse(input, "", "")
			if err != nil {
				t.Fatal(err)
			}
			f, _, _, err := Generate(m)
			if err != nil {
				t.Fatal(err)
			}
			again, err := Parse(f, "", "")
			if err != nil || !proto.Equal(m, again) {
				t.Fatalf("round trip: %v %v", again, err)
			}
		})
	}
}

func TestParsedFilterPreservesEJSON(t *testing.T) {
	inputs := []string{
		`{"name":"Ada"}`, `{"age":{"$gt":18}}`, `{"tags":{"$in":["a","b"]}}`, `{"name":{"$regex":"^a","$options":"i"}}`, `{"$expr":{"$gt":["$a",3]}}`, `{"a":{"$elemMatch":{"x":1}}}`, `{"$or":[{"a":1},{"b":{"$ne":2}}]}`,
	}
	for _, input := range inputs {
		t.Run(input, func(t *testing.T) {
			m, err := Parse(input, "", "")
			if err != nil {
				t.Fatal(err)
			}
			got, _, _, err := Generate(m)
			if err != nil {
				t.Fatal(err)
			}
			original, err := document(input)
			if err != nil {
				t.Fatal(err)
			}
			canonical, err := encode(original)
			if err != nil {
				t.Fatal(err)
			}
			if got != canonical {
				t.Fatalf("got %s, want %s", got, canonical)
			}
		})
	}
}

func TestMultipleFieldOperatorsBecomeVisualConditions(t *testing.T) {
	model, err := Parse(`{"age":{"$gt":18,"$lt":40}}`, "", "")
	if err != nil {
		t.Fatal(err)
	}
	if model.GetFilter().GetGroup() == nil || len(model.GetFilter().GetGroup().GetChildren()) != 2 {
		t.Fatalf("expected two visual conditions: %v", model)
	}
	filter, _, _, err := Generate(model)
	if err != nil {
		t.Fatal(err)
	}
	again, err := Parse(filter, "", "")
	if err != nil || !proto.Equal(model, again) {
		t.Fatalf("round trip: %v, %v", again, err)
	}
}

func TestUnsupportedOperandsRemainRaw(t *testing.T) {
	for _, input := range []string{
		`{"x":{"$in":"not an array"}}`,
		`{"x":{"$exists":1}}`,
		`{"x":{"$regex":5}}`,
		`{"x":{"$type":["string","int"]}}`,
		`{"x":{"$not":{"$elemMatch":{"a":1}}}}`,
	} {
		t.Run(input, func(t *testing.T) {
			model, err := Parse(input, "", "")
			if err != nil || model.GetFilter().GetRawEjson() == "" {
				t.Fatalf("expected raw condition: %v, %v", model, err)
			}
			generated, _, _, err := Generate(model)
			if err != nil {
				t.Fatal(err)
			}
			original, err := document(input)
			if err != nil {
				t.Fatal(err)
			}
			canonical, err := encode(original)
			if err != nil || generated != canonical {
				t.Fatalf("got %s, want %s: %v", generated, canonical, err)
			}
		})
	}
}
