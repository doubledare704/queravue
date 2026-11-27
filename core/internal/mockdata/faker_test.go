package mockdata

import (
	"encoding/json"
	"reflect"
	"slices"
	"testing"

	"github.com/google/uuid"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func TestSupportedFakerKindsDeterministicAndValid(t *testing.T) {
	kinds := SupportedFakerKinds()
	if len(kinds) == 0 {
		t.Fatal("SupportedFakerKinds returned empty list")
	}
	if !slices.IsSorted(kinds) {
		t.Fatalf("SupportedFakerKinds is not sorted: %v", kinds)
	}

	for _, kind := range kinds {
		t.Run(kind, func(t *testing.T) {
			a := newFakerSource(kind, 42, "t:db.public.users", "col")
			b := newFakerSource(kind, 42, "t:db.public.users", "col")
			c := newFakerSource(kind, 99, "t:db.public.users", "col")

			var seenDifferent bool
			for i := range 10 {
				va := a.next()
				vb := b.next()
				vc := c.next()

				if !reflect.DeepEqual(va, vb) {
					t.Fatalf("row %d: non-deterministic for kind %q: %+v vs %+v", i, kind, va, vb)
				}
				if !reflect.DeepEqual(vc, va) {
					seenDifferent = true
				}
				assertFakerValueValid(t, kind, va)
			}
			if !seenDifferent {
				t.Fatalf("kind %q produced identical sequence for seeds 42 and 99", kind)
			}
		})
	}
}

func assertFakerValueValid(t *testing.T, kind string, v engine.Value) {
	t.Helper()
	switch kind {
	case "bool":
		if v.Kind != engine.VBool {
			t.Fatalf("bool kind=%v, want VBool", v.Kind)
		}
	case "uuid":
		if v.Kind != engine.VUUID {
			t.Fatalf("uuid kind=%v, want VUUID", v.Kind)
		}
		if _, err := uuid.Parse(v.Str); err != nil {
			t.Fatalf("invalid uuid %q: %v", v.Str, err)
		}
	case "object_id":
		if v.Kind != engine.VText || len(v.Str) != 24 {
			t.Fatalf("object_id = %+v, want 24-hex VText", v)
		}
	case "json_object":
		if v.Kind != engine.VJSON || !json.Valid([]byte(v.Str)) {
			t.Fatalf("invalid json_object %+v", v)
		}
	default:
		if v.Kind != engine.VText || v.Str == "" {
			t.Fatalf("kind %q produced empty or non-text value: %+v", kind, v)
		}
	}
}
