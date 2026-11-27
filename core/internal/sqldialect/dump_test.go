package sqldialect

import (
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func TestPostgresSpecialDumpLiterals(t *testing.T) {
	for _, tc := range []struct {
		name  string
		value engine.Value
		want  string
	}{
		{"nan", engine.Decimal("NaN"), "'NaN'::numeric"},
		{"positive infinity", engine.Decimal("Infinity"), "'Infinity'::numeric"},
		{"negative infinity", engine.Decimal("-Infinity"), "'-Infinity'::numeric"},
		{"empty array", engine.Array(nil), "'{}'"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			got, err := FormatDumpLiteral(Postgres, tc.value)
			if err != nil || got != tc.want {
				t.Fatalf("got %q and %v, want %q", got, err, tc.want)
			}
		})
	}
	for _, v := range []engine.Value{
		engine.Decimal("NaN cast"),
		engine.Array([]engine.Value{engine.Array(nil)}),
	} {
		if _, err := FormatDumpLiteral(Postgres, v); err == nil {
			t.Fatal("expected an error for an unrepresentable value")
		}
	}
}
