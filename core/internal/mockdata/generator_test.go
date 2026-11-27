package mockdata

import (
	"errors"
	"math"
	"regexp"
	"strings"
	"testing"
	"time"

	"github.com/shopspring/decimal"
	"go.mongodb.org/mongo-driver/v2/bson"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func TestRuleGenerators(t *testing.T) {
	target := TargetRef{Database: "app", Schema: "public", Name: "items"}

	t.Run("sequence", func(t *testing.T) {
		g, err := buildGenerator(1, target, "id", ColumnRule{
			ColumnOrPath: "id",
			Kind:         RuleSequence,
			Sequence:     SequenceRule{Start: 10, Step: 5},
		})
		if err != nil {
			t.Fatal(err)
		}
		for i, want := range []int64{10, 15, 20} {
			v, err := g.next(&genContext{})
			if err != nil {
				t.Fatal(err)
			}
			if v.val.Kind != engine.VInt || v.val.Int != want {
				t.Fatalf("row %d = %+v, want %d", i, v.val, want)
			}
		}
	})

	t.Run("sequence default step 1", func(t *testing.T) {
		g, err := buildGenerator(1, target, "id", ColumnRule{
			ColumnOrPath: "id",
			Kind:         RuleSequence,
			Sequence:     SequenceRule{Start: 1, Step: 0},
		})
		if err != nil {
			t.Fatal(err)
		}
		for i, want := range []int64{1, 2, 3} {
			v, err := g.next(&genContext{})
			if err != nil {
				t.Fatal(err)
			}
			if v.val.Int != want {
				t.Fatalf("row %d = %d, want %d", i, v.val.Int, want)
			}
		}
	})

	t.Run("int range signed", func(t *testing.T) {
		g, err := buildGenerator(7, target, "temp", ColumnRule{
			ColumnOrPath: "temp",
			Kind:         RuleIntRange,
			IntRange:     IntRangeRule{Min: -5, Max: 5},
		})
		if err != nil {
			t.Fatal(err)
		}
		for range 500 {
			v, err := g.next(&genContext{})
			if err != nil {
				t.Fatal(err)
			}
			if v.val.Kind != engine.VInt || v.val.Int < -5 || v.val.Int > 5 {
				t.Fatalf("out of range: %+v", v.val)
			}
		}
	})

	t.Run("float range", func(t *testing.T) {
		g, err := buildGenerator(7, target, "score", ColumnRule{
			ColumnOrPath: "score",
			Kind:         RuleFloatRange,
			FloatRange:   FloatRangeRule{Min: -1.5, Max: 2.5},
		})
		if err != nil {
			t.Fatal(err)
		}
		for range 500 {
			v, err := g.next(&genContext{})
			if err != nil {
				t.Fatal(err)
			}
			if v.val.Kind != engine.VFloat || v.val.Float < -1.5 || v.val.Float >= 2.5 {
				t.Fatalf("out of range: %+v", v.val)
			}
		}
	})

	t.Run("decimal range", func(t *testing.T) {
		g, err := buildGenerator(7, target, "price", ColumnRule{
			ColumnOrPath: "price",
			Kind:         RuleDecimalRange,
			DecimalRange: DecimalRangeRule{Min: "10.00", Max: "25.50", Scale: 2},
		})
		if err != nil {
			t.Fatal(err)
		}
		minD := decimal.RequireFromString("10.00")
		maxD := decimal.RequireFromString("25.50")
		for range 500 {
			v, err := g.next(&genContext{})
			if err != nil {
				t.Fatal(err)
			}
			if v.val.Kind != engine.VDecimal {
				t.Fatalf("kind=%v, want VDecimal", v.val.Kind)
			}
			d, err := decimal.NewFromString(v.val.Str)
			if err != nil {
				t.Fatalf("invalid decimal %q: %v", v.val.Str, err)
			}
			if d.LessThan(minD) || d.GreaterThan(maxD) {
				t.Fatalf("decimal %s out of [%s, %s]", v.val.Str, minD, maxD)
			}
			if parts := strings.Split(v.val.Str, "."); len(parts) != 2 || len(parts[1]) != 2 {
				t.Fatalf("decimal %q does not have scale 2", v.val.Str)
			}
		}
	})

	t.Run("time range and date_only", func(t *testing.T) {
		from := time.Date(2025, 1, 1, 12, 30, 0, 0, time.UTC)
		to := time.Date(2026, 1, 1, 12, 30, 0, 0, time.UTC)
		g, err := buildGenerator(7, target, "born", ColumnRule{
			ColumnOrPath: "born",
			Kind:         RuleTimeRange,
			TimeRange:    TimeRangeRule{FromMs: from.UnixMilli(), ToMs: to.UnixMilli(), DateOnly: true},
		})
		if err != nil {
			t.Fatal(err)
		}
		for range 200 {
			v, err := g.next(&genContext{})
			if err != nil {
				t.Fatal(err)
			}
			if v.val.Kind != engine.VTimestamptz {
				t.Fatalf("kind=%v, want VTimestamptz", v.val.Kind)
			}
			if v.val.Time.Hour() != 0 || v.val.Time.Minute() != 0 || v.val.Time.Second() != 0 || v.val.Time.Nanosecond() != 0 {
				t.Fatalf("expected midnight UTC for date_only, got %s", v.val.Time)
			}
		}
	})

	t.Run("constant", func(t *testing.T) {
		g, err := buildGenerator(1, target, "env", ColumnRule{
			ColumnOrPath: "env",
			Kind:         RuleConstant,
			Constant:     ConstantRule{Value: engine.Text("staging")},
		})
		if err != nil {
			t.Fatal(err)
		}
		v, err := g.next(&genContext{})
		if err != nil || v.val.Kind != engine.VText || v.val.Str != "staging" {
			t.Fatalf("got %+v, err=%v", v.val, err)
		}
	})

	t.Run("pattern with escapes", func(t *testing.T) {
		g, err := buildGenerator(1, target, "code", ColumnRule{
			ColumnOrPath: "code",
			Kind:         RulePattern,
			Pattern:      PatternRule{Pattern: `ID-###-??-\#\?\\`},
		})
		if err != nil {
			t.Fatal(err)
		}
		re := regexp.MustCompile(`^ID-\d{3}-[A-Z]{2}-#\?\\$`)
		for range 100 {
			v, err := g.next(&genContext{})
			if err != nil {
				t.Fatal(err)
			}
			if !re.MatchString(v.val.Str) {
				t.Fatalf("pattern mismatch: %q", v.val.Str)
			}
		}
	})

	t.Run("skip", func(t *testing.T) {
		g, err := buildGenerator(1, target, "s", ColumnRule{ColumnOrPath: "s", Kind: RuleSkip})
		if err != nil {
			t.Fatal(err)
		}
		v, err := g.next(&genContext{})
		if err != nil || !v.omitted {
			t.Fatalf("skip got %+v, err=%v", v, err)
		}
	})
}

func TestNullRatioTolerance100k(t *testing.T) {
	target := TargetRef{Database: "app", Schema: "public", Name: "events"}
	g, err := buildGenerator(1234, target, "note", ColumnRule{
		ColumnOrPath: "note",
		NullRatio:    0.25,
		Kind:         RuleFaker,
		FakerKind:    "word",
	})
	if err != nil {
		t.Fatal(err)
	}
	const n = 100_000
	var nulls int
	for range n {
		v, err := g.next(&genContext{})
		if err != nil {
			t.Fatal(err)
		}
		if v.val.Kind == engine.VNull {
			nulls++
		}
	}
	got := float64(nulls) / float64(n)
	if math.Abs(got-0.25) > 0.01 {
		t.Fatalf("null ratio = %.4f, want 0.25 ± 0.01", got)
	}
}

func TestWeightedValuesDistribution100k(t *testing.T) {
	target := TargetRef{Database: "app", Schema: "public", Name: "orders"}
	g, err := buildGenerator(99, target, "status", ColumnRule{
		ColumnOrPath: "status",
		Kind:         RuleWeightedValues,
		WeightedValues: WeightedValuesRule{
			Values:  []engine.Value{engine.Text("paid"), engine.Text("pending"), engine.Text("failed")},
			Weights: []float64{0.7, 0.2, 0.1},
		},
	})
	if err != nil {
		t.Fatal(err)
	}
	counts := map[string]int{}
	const n = 100_000
	for range n {
		v, err := g.next(&genContext{})
		if err != nil {
			t.Fatal(err)
		}
		counts[v.val.Str]++
	}
	if math.Abs(float64(counts["paid"])/n-0.7) > 0.01 ||
		math.Abs(float64(counts["pending"])/n-0.2) > 0.01 ||
		math.Abs(float64(counts["failed"])/n-0.1) > 0.01 {
		t.Fatalf("unexpected weighted counts: %+v", counts)
	}
}

func TestUniqueSuccessAndExhaustion(t *testing.T) {
	target := TargetRef{Database: "app", Schema: "public", Name: "codes"}
	g, err := buildGenerator(5, target, "code", ColumnRule{
		ColumnOrPath: "code",
		Unique:       true,
		Kind:         RuleIntRange,
		IntRange:     IntRangeRule{Min: 1, Max: 5},
	})
	if err != nil {
		t.Fatal(err)
	}
	seen := map[int64]bool{}
	for range 5 {
		v, err := g.next(&genContext{})
		if err != nil {
			t.Fatalf("unexpected error within cardinality: %v", err)
		}
		if seen[v.val.Int] {
			t.Fatalf("duplicate value %d", v.val.Int)
		}
		seen[v.val.Int] = true
	}
	_, err = g.next(&genContext{})
	var me *Error
	if !errors.As(err, &me) || me.Kind != ErrUniqueExhausted || me.Column != "code" {
		t.Fatalf("got err=%v, want ErrUniqueExhausted for column code", err)
	}

	strGen, err := buildGenerator(5, target, "tag", ColumnRule{
		ColumnOrPath: "tag",
		Unique:       true,
		Kind:         RuleWeightedValues,
		WeightedValues: WeightedValuesRule{
			Values: []engine.Value{engine.Text("a"), engine.Text("b")},
		},
	})
	if err != nil {
		t.Fatal(err)
	}
	seenStr := map[string]bool{}
	for range 2 {
		v, err := strGen.next(&genContext{})
		if err != nil {
			t.Fatalf("unexpected error for unique string: %v", err)
		}
		seenStr[v.val.Str] = true
	}
	if len(seenStr) != 2 {
		t.Fatalf("expected 2 distinct strings, got %+v", seenStr)
	}
	_, err = strGen.next(&genContext{})
	if !errors.As(err, &me) || me.Kind != ErrUniqueExhausted || me.Column != "tag" {
		t.Fatalf("got err=%v, want ErrUniqueExhausted for column tag", err)
	}
}

func TestRuleValidationErrors(t *testing.T) {
	target := TargetRef{Database: "app", Schema: "public", Name: "bad"}
	cases := []struct {
		name string
		rule ColumnRule
	}{
		{"negative null ratio", ColumnRule{ColumnOrPath: "c", NullRatio: -0.1, Kind: RuleConstant}},
		{"null ratio > 1", ColumnRule{ColumnOrPath: "c", NullRatio: 1.1, Kind: RuleConstant}},
		{"unknown faker", ColumnRule{ColumnOrPath: "c", Kind: RuleFaker, FakerKind: "nope"}},
		{"int min > max", ColumnRule{ColumnOrPath: "c", Kind: RuleIntRange, IntRange: IntRangeRule{Min: 10, Max: 5}}},
		{"float min >= max", ColumnRule{ColumnOrPath: "c", Kind: RuleFloatRange, FloatRange: FloatRangeRule{Min: 5, Max: 5}}},
		{"decimal min > max", ColumnRule{ColumnOrPath: "c", Kind: RuleDecimalRange, DecimalRange: DecimalRangeRule{Min: "10", Max: "2", Scale: 2}}},
		{"decimal bad scale", ColumnRule{ColumnOrPath: "c", Kind: RuleDecimalRange, DecimalRange: DecimalRangeRule{Min: "1", Max: "2", Scale: 99}}},
		{"time from > to", ColumnRule{ColumnOrPath: "c", Kind: RuleTimeRange, TimeRange: TimeRangeRule{FromMs: 100, ToMs: 50}}},
		{"weighted empty", ColumnRule{ColumnOrPath: "c", Kind: RuleWeightedValues}},
		{"weighted mismatch", ColumnRule{ColumnOrPath: "c", Kind: RuleWeightedValues, WeightedValues: WeightedValuesRule{Values: []engine.Value{engine.Int(1)}, Weights: []float64{1, 2}}}},
		{"pattern trailing escape", ColumnRule{ColumnOrPath: "c", Kind: RulePattern, Pattern: PatternRule{Pattern: `abc\`}}},
		{"fk missing parent", ColumnRule{ColumnOrPath: "c", Kind: RuleForeignKey}},
		{"array min > max", ColumnRule{ColumnOrPath: "c", Kind: RuleArray, Array: ArrayRule{MinLength: 5, MaxLength: 2, Element: &ColumnRule{Kind: RuleFaker, FakerKind: "word"}}}},
		{"array max > cap", ColumnRule{ColumnOrPath: "c", Kind: RuleArray, Array: ArrayRule{MinLength: 1, MaxLength: maxArrayLength + 1, Element: &ColumnRule{Kind: RuleFaker, FakerKind: "word"}}}},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			_, err := buildGenerator(1, target, tc.rule.ColumnOrPath, tc.rule)
			var me *Error
			if !errors.As(err, &me) || me.Kind != ErrParse {
				t.Fatalf("got err=%v, want ErrParse", err)
			}
		})
	}
}

func TestDocumentCanonicalEJSONEncoding(t *testing.T) {
	target := TargetRef{IsCollection: true, Database: "shop", Name: "orders"}
	rules := []ColumnRule{
		{ColumnOrPath: "oid", Kind: RuleFaker, FakerKind: "object_id"},
		{ColumnOrPath: "count", Kind: RuleSequence, Sequence: SequenceRule{Start: 1, Step: 1}},
		{ColumnOrPath: "total", Kind: RuleDecimalRange, DecimalRange: DecimalRangeRule{Min: "10.00", Max: "20.00", Scale: 2}},
		{ColumnOrPath: "created_at", Kind: RuleTimeRange, TimeRange: TimeRangeRule{FromMs: 1700000000000, ToMs: 1700001000000}},
		{
			ColumnOrPath: "address",
			Kind:         RuleDocument,
			Document: DocumentRule{
				Fields: []ColumnRule{
					{ColumnOrPath: "city", Kind: RuleFaker, FakerKind: "city"},
					{ColumnOrPath: "zip", Kind: RulePattern, Pattern: PatternRule{Pattern: "#####"}},
				},
			},
		},
		{
			ColumnOrPath: "items",
			Kind:         RuleArray,
			Array: ArrayRule{
				MinLength: 2,
				MaxLength: 2,
				Element: &ColumnRule{
					Kind: RuleDocument,
					Document: DocumentRule{
						Fields: []ColumnRule{
							{ColumnOrPath: "sku", Kind: RulePattern, Pattern: PatternRule{Pattern: "??-###"}},
							{ColumnOrPath: "qty", Kind: RuleIntRange, IntRange: IntRangeRule{Min: 1, Max: 5}},
						},
					},
				},
			},
		},
	}

	root, err := compileDocTree(42, target, rules)
	if err != nil {
		t.Fatal(err)
	}
	doc, err := root.generateDocument(&genContext{})
	if err != nil {
		t.Fatal(err)
	}
	var parsed bson.D
	if err := bson.UnmarshalExtJSON([]byte(doc), true, &parsed); err != nil {
		t.Fatalf("generated document is not valid canonical EJSON: %v\ndoc: %s", err, doc)
	}
	if !strings.Contains(doc, `"$oid"`) || !strings.Contains(doc, `"$numberLong"`) || !strings.Contains(doc, `"$numberDecimal"`) || !strings.Contains(doc, `"$date"`) {
		t.Fatalf("expected canonical EJSON type wrappers in %s", doc)
	}
}
