package api

import (
	"context"
	"errors"
	"fmt"

	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/mockdata"
	"github.com/doubledare704/queravue/core/internal/results"
)

func protoToTargetRef(ref *queravuev1.MockTargetRef) (mockdata.TargetRef, error) {
	if ref == nil {
		return mockdata.TargetRef{}, errors.New("missing target")
	}
	switch t := ref.GetTarget().(type) {
	case *queravuev1.MockTargetRef_Table:
		if t.Table == nil || t.Table.GetTable() == "" {
			return mockdata.TargetRef{}, errors.New("table target requires a table name")
		}
		return mockdata.TargetRef{
			Database: t.Table.GetDatabase(),
			Schema:   t.Table.GetSchema(),
			Name:     t.Table.GetTable(),
		}, nil
	case *queravuev1.MockTargetRef_Collection:
		if t.Collection == nil || t.Collection.GetCollection() == "" {
			return mockdata.TargetRef{}, errors.New("collection target requires a collection name")
		}
		return mockdata.TargetRef{
			IsCollection: true,
			Database:     t.Collection.GetDatabase(),
			Name:         t.Collection.GetCollection(),
		}, nil
	default:
		return mockdata.TargetRef{}, errors.New("unknown target kind")
	}
}

func targetRefToProto(ref mockdata.TargetRef) *queravuev1.MockTargetRef {
	if ref.IsCollection {
		return &queravuev1.MockTargetRef{
			Target: &queravuev1.MockTargetRef_Collection{
				Collection: &queravuev1.CollectionRef{
					Database:   ref.Database,
					Collection: ref.Name,
				},
			},
		}
	}
	return &queravuev1.MockTargetRef{
		Target: &queravuev1.MockTargetRef_Table{
			Table: &queravuev1.TableRef{
				Database: ref.Database,
				Schema:   ref.Schema,
				Table:    ref.Name,
			},
		},
	}
}

func protoToSpec(in *queravuev1.MockSpec) (mockdata.Spec, error) {
	if in == nil {
		return mockdata.Spec{}, &mockdata.Error{Kind: mockdata.ErrParse, Message: "missing mock spec"}
	}
	targets := make([]mockdata.TargetSpec, 0, len(in.GetTargets()))
	for _, pt := range in.GetTargets() {
		ref, err := protoToTargetRef(pt.GetTarget())
		if err != nil {
			return mockdata.Spec{}, &mockdata.Error{Kind: mockdata.ErrParse, Message: err.Error()}
		}
		rules := make([]mockdata.ColumnRule, 0, len(pt.GetRules()))
		for _, pr := range pt.GetRules() {
			rule, err := protoToColumnRule(pr)
			if err != nil {
				return mockdata.Spec{}, &mockdata.Error{
					Kind:    mockdata.ErrParse,
					Message: err.Error(),
					Target:  &ref,
					Column:  pr.GetColumnOrPath(),
				}
			}
			rules = append(rules, rule)
		}
		targets = append(targets, mockdata.TargetSpec{
			Target: ref,
			Rows:   pt.GetRows(),
			Rules:  rules,
		})
	}
	return mockdata.Spec{Seed: in.GetSeed(), Targets: targets}, nil
}

func protoToColumnRule(in *queravuev1.MockColumnRule) (mockdata.ColumnRule, error) {
	if in == nil {
		return mockdata.ColumnRule{}, errors.New("nil column rule")
	}
	out := mockdata.ColumnRule{
		ColumnOrPath: in.GetColumnOrPath(),
		NullRatio:    in.GetNullRatio(),
		Unique:       in.GetUnique(),
	}
	switch r := in.GetRule().(type) {
	case *queravuev1.MockColumnRule_Faker:
		out.Kind = mockdata.RuleFaker
		out.FakerKind = r.Faker.GetKind()
	case *queravuev1.MockColumnRule_Sequence:
		out.Kind = mockdata.RuleSequence
		out.Sequence = mockdata.SequenceRule{Start: r.Sequence.GetStart(), Step: r.Sequence.GetStep()}
	case *queravuev1.MockColumnRule_IntRange:
		out.Kind = mockdata.RuleIntRange
		out.IntRange = mockdata.IntRangeRule{Min: r.IntRange.GetMin(), Max: r.IntRange.GetMax()}
	case *queravuev1.MockColumnRule_FloatRange:
		out.Kind = mockdata.RuleFloatRange
		out.FloatRange = mockdata.FloatRangeRule{Min: r.FloatRange.GetMin(), Max: r.FloatRange.GetMax()}
	case *queravuev1.MockColumnRule_DecimalRange:
		out.Kind = mockdata.RuleDecimalRange
		out.DecimalRange = mockdata.DecimalRangeRule{
			Min:   r.DecimalRange.GetMin(),
			Max:   r.DecimalRange.GetMax(),
			Scale: r.DecimalRange.GetScale(),
		}
	case *queravuev1.MockColumnRule_TimeRange:
		out.Kind = mockdata.RuleTimeRange
		out.TimeRange = mockdata.TimeRangeRule{
			FromMs:   r.TimeRange.GetFromMs(),
			ToMs:     r.TimeRange.GetToMs(),
			DateOnly: r.TimeRange.GetDateOnly(),
		}
	case *queravuev1.MockColumnRule_WeightedValues:
		out.Kind = mockdata.RuleWeightedValues
		vals := make([]engine.Value, len(r.WeightedValues.GetValues()))
		for i, v := range r.WeightedValues.GetValues() {
			vals[i] = results.ValueFromProto(v)
		}
		out.WeightedValues = mockdata.WeightedValuesRule{
			Values:  vals,
			Weights: append([]float64(nil), r.WeightedValues.GetWeights()...),
		}
	case *queravuev1.MockColumnRule_Constant:
		out.Kind = mockdata.RuleConstant
		out.Constant = mockdata.ConstantRule{Value: results.ValueFromProto(r.Constant.GetValue())}
	case *queravuev1.MockColumnRule_Pattern:
		out.Kind = mockdata.RulePattern
		out.Pattern = mockdata.PatternRule{Pattern: r.Pattern.GetPattern()}
	case *queravuev1.MockColumnRule_ForeignKey:
		p := r.ForeignKey.GetParent()
		if p == nil || p.GetTable() == "" {
			return mockdata.ColumnRule{}, errors.New("foreign_key requires parent table")
		}
		out.Kind = mockdata.RuleForeignKey
		out.ForeignKey = mockdata.ForeignKeyRule{
			Parent: mockdata.TargetRef{
				Database: p.GetDatabase(),
				Schema:   p.GetSchema(),
				Name:     p.GetTable(),
			},
			ParentColumn:     r.ForeignKey.GetParentColumn(),
			FromExistingRows: r.ForeignKey.GetFromExistingRows(),
		}
	case *queravuev1.MockColumnRule_Document:
		fields := make([]mockdata.ColumnRule, 0, len(r.Document.GetFields()))
		for _, pf := range r.Document.GetFields() {
			f, err := protoToColumnRule(pf)
			if err != nil {
				return mockdata.ColumnRule{}, fmt.Errorf("document field %q: %w", pf.GetColumnOrPath(), err)
			}
			fields = append(fields, f)
		}
		out.Kind = mockdata.RuleDocument
		out.Document = mockdata.DocumentRule{Fields: fields}
	case *queravuev1.MockColumnRule_Array:
		if r.Array.GetElement() == nil {
			return mockdata.ColumnRule{}, errors.New("array rule requires an element rule")
		}
		elem, err := protoToColumnRule(r.Array.GetElement())
		if err != nil {
			return mockdata.ColumnRule{}, fmt.Errorf("array element: %w", err)
		}
		out.Kind = mockdata.RuleArray
		out.Array = mockdata.ArrayRule{
			MinLength: r.Array.GetMinLength(),
			MaxLength: r.Array.GetMaxLength(),
			Element:   &elem,
		}
	case *queravuev1.MockColumnRule_Skip:
		out.Kind = mockdata.RuleSkip
	default:
		return mockdata.ColumnRule{}, errors.New("missing rule")
	}
	return out, nil
}

func specToProto(spec mockdata.Spec) *queravuev1.MockSpec {
	targets := make([]*queravuev1.MockTarget, len(spec.Targets))
	for i, t := range spec.Targets {
		rules := make([]*queravuev1.MockColumnRule, len(t.Rules))
		for j, r := range t.Rules {
			rules[j] = columnRuleToProto(r)
		}
		targets[i] = &queravuev1.MockTarget{
			Target: targetRefToProto(t.Target),
			Rows:   t.Rows,
			Rules:  rules,
		}
	}
	return &queravuev1.MockSpec{
		Seed:    spec.Seed,
		Targets: targets,
	}
}

func columnRuleToProto(r mockdata.ColumnRule) *queravuev1.MockColumnRule {
	out := &queravuev1.MockColumnRule{
		ColumnOrPath: r.ColumnOrPath,
		NullRatio:    r.NullRatio,
		Unique:       r.Unique,
	}
	switch r.Kind {
	case mockdata.RuleFaker:
		out.Rule = &queravuev1.MockColumnRule_Faker{Faker: &queravuev1.FakerRule{Kind: r.FakerKind}}
	case mockdata.RuleSequence:
		out.Rule = &queravuev1.MockColumnRule_Sequence{Sequence: &queravuev1.SequenceRule{Start: r.Sequence.Start, Step: r.Sequence.Step}}
	case mockdata.RuleIntRange:
		out.Rule = &queravuev1.MockColumnRule_IntRange{IntRange: &queravuev1.IntRangeRule{Min: r.IntRange.Min, Max: r.IntRange.Max}}
	case mockdata.RuleFloatRange:
		out.Rule = &queravuev1.MockColumnRule_FloatRange{FloatRange: &queravuev1.FloatRangeRule{Min: r.FloatRange.Min, Max: r.FloatRange.Max}}
	case mockdata.RuleDecimalRange:
		out.Rule = &queravuev1.MockColumnRule_DecimalRange{DecimalRange: &queravuev1.DecimalRangeRule{
			Min: r.DecimalRange.Min, Max: r.DecimalRange.Max, Scale: r.DecimalRange.Scale,
		}}
	case mockdata.RuleTimeRange:
		out.Rule = &queravuev1.MockColumnRule_TimeRange{TimeRange: &queravuev1.TimeRangeRule{
			FromMs: r.TimeRange.FromMs, ToMs: r.TimeRange.ToMs, DateOnly: r.TimeRange.DateOnly,
		}}
	case mockdata.RuleWeightedValues:
		vals := make([]*queravuev1.Value, len(r.WeightedValues.Values))
		for i, v := range r.WeightedValues.Values {
			vals[i] = results.ValueToProto(v)
		}
		out.Rule = &queravuev1.MockColumnRule_WeightedValues{WeightedValues: &queravuev1.WeightedValuesRule{
			Values: vals, Weights: append([]float64(nil), r.WeightedValues.Weights...),
		}}
	case mockdata.RuleConstant:
		out.Rule = &queravuev1.MockColumnRule_Constant{Constant: &queravuev1.ConstantRule{
			Value: results.ValueToProto(r.Constant.Value),
		}}
	case mockdata.RulePattern:
		out.Rule = &queravuev1.MockColumnRule_Pattern{Pattern: &queravuev1.PatternRule{Pattern: r.Pattern.Pattern}}
	case mockdata.RuleForeignKey:
		out.Rule = &queravuev1.MockColumnRule_ForeignKey{ForeignKey: &queravuev1.ForeignKeyRule{
			Parent: &queravuev1.TableRef{
				Database: r.ForeignKey.Parent.Database,
				Schema:   r.ForeignKey.Parent.Schema,
				Table:    r.ForeignKey.Parent.Name,
			},
			ParentColumn:     r.ForeignKey.ParentColumn,
			FromExistingRows: r.ForeignKey.FromExistingRows,
		}}
	case mockdata.RuleDocument:
		fields := make([]*queravuev1.MockColumnRule, len(r.Document.Fields))
		for i, f := range r.Document.Fields {
			fields[i] = columnRuleToProto(f)
		}
		out.Rule = &queravuev1.MockColumnRule_Document{Document: &queravuev1.DocumentRule{Fields: fields}}
	case mockdata.RuleArray:
		var elem *queravuev1.MockColumnRule
		if r.Array.Element != nil {
			elem = columnRuleToProto(*r.Array.Element)
		}
		out.Rule = &queravuev1.MockColumnRule_Array{Array: &queravuev1.ArrayRule{
			MinLength: r.Array.MinLength,
			MaxLength: r.Array.MaxLength,
			Element:   elem,
		}}
	default:
		out.Rule = &queravuev1.MockColumnRule_Skip{Skip: &queravuev1.SkipRule{}}
	}
	return out
}

func cyclesToProto(cycles []mockdata.Cycle) []*queravuev1.MockCycle {
	if len(cycles) == 0 {
		return nil
	}
	out := make([]*queravuev1.MockCycle, len(cycles))
	for i, c := range cycles {
		edges := make([]*queravuev1.MockCycleEdge, len(c.Edges))
		for j, e := range c.Edges {
			edges[j] = &queravuev1.MockCycleEdge{
				Child: &queravuev1.TableRef{
					Database: e.Child.Database,
					Schema:   e.Child.Schema,
					Table:    e.Child.Name,
				},
				Parent: &queravuev1.TableRef{
					Database: e.Parent.Database,
					Schema:   e.Parent.Schema,
					Table:    e.Parent.Name,
				},
				ConstraintName: e.ConstraintName,
				Nullable:       e.Nullable,
			}
		}
		out[i] = &queravuev1.MockCycle{Edges: edges}
	}
	return out
}

func summaryToProto(s mockdata.Summary) *queravuev1.MockSummary {
	done := make([]*queravuev1.MockTargetDone, len(s.Done))
	for i, d := range s.Done {
		done[i] = &queravuev1.MockTargetDone{
			Target:    targetRefToProto(d.Target),
			Rows:      d.Rows,
			ElapsedMs: d.ElapsedMs,
		}
	}
	return &queravuev1.MockSummary{
		Rows:      s.Rows,
		ElapsedMs: s.ElapsedMs,
		Done:      done,
	}
}

func toMockError(err error, fallbackTarget *mockdata.TargetRef, fallbackCol string) *queravuev1.MockError {
	if err == nil {
		return nil
	}
	if errors.Is(err, context.Canceled) {
		return &queravuev1.MockError{
			Kind:    queravuev1.MockErrorKind_MOCK_ERROR_KIND_CANCELED,
			Message: "mock generation cancelled",
			Target:  optTargetRef(fallbackTarget),
			Column:  fallbackCol,
		}
	}
	if errors.Is(err, context.DeadlineExceeded) {
		return &queravuev1.MockError{
			Kind:    queravuev1.MockErrorKind_MOCK_ERROR_KIND_TIMEOUT,
			Message: "mock generation timed out",
			Target:  optTargetRef(fallbackTarget),
			Column:  fallbackCol,
		}
	}
	var me *mockdata.Error
	if errors.As(err, &me) {
		t := me.Target
		if t == nil {
			t = fallbackTarget
		}
		col := me.Column
		if col == "" {
			col = fallbackCol
		}
		return &queravuev1.MockError{
			Kind:    mockErrorKind(me.Kind),
			Message: me.Message,
			Target:  optTargetRef(t),
			Column:  col,
		}
	}
	var ee *engine.Error
	if errors.As(err, &ee) {
		return &queravuev1.MockError{
			Kind:    engineToMockErrorKind(ee.Kind),
			Message: ee.Msg,
			Target:  optTargetRef(fallbackTarget),
			Column:  fallbackCol,
		}
	}
	return &queravuev1.MockError{
		Kind:    queravuev1.MockErrorKind_MOCK_ERROR_KIND_SERVER,
		Message: err.Error(),
		Target:  optTargetRef(fallbackTarget),
		Column:  fallbackCol,
	}
}

func optTargetRef(t *mockdata.TargetRef) *queravuev1.MockTargetRef {
	if t == nil {
		return nil
	}
	return targetRefToProto(*t)
}

func mockErrorKind(k mockdata.ErrorKind) queravuev1.MockErrorKind {
	switch k {
	case mockdata.ErrParse:
		return queravuev1.MockErrorKind_MOCK_ERROR_KIND_PARSE
	case mockdata.ErrCycle:
		return queravuev1.MockErrorKind_MOCK_ERROR_KIND_CYCLE
	case mockdata.ErrUniqueExhausted:
		return queravuev1.MockErrorKind_MOCK_ERROR_KIND_UNIQUE_EXHAUSTED
	case mockdata.ErrUnsupported:
		return queravuev1.MockErrorKind_MOCK_ERROR_KIND_UNSUPPORTED
	default:
		return queravuev1.MockErrorKind_MOCK_ERROR_KIND_SERVER
	}
}

func engineToMockErrorKind(k engine.Kind) queravuev1.MockErrorKind {
	switch k {
	case engine.KindParse, engine.KindInvalidConfig:
		return queravuev1.MockErrorKind_MOCK_ERROR_KIND_PARSE
	case engine.KindConfirmationRequired:
		return queravuev1.MockErrorKind_MOCK_ERROR_KIND_CONFIRMATION_REQUIRED
	case engine.KindAuth, engine.KindSSHAuth:
		return queravuev1.MockErrorKind_MOCK_ERROR_KIND_AUTH
	case engine.KindNetwork, engine.KindConnectionLost, engine.KindTunnelLost:
		return queravuev1.MockErrorKind_MOCK_ERROR_KIND_NETWORK
	case engine.KindTimeout:
		return queravuev1.MockErrorKind_MOCK_ERROR_KIND_TIMEOUT
	case engine.KindCanceled:
		return queravuev1.MockErrorKind_MOCK_ERROR_KIND_CANCELED
	case engine.KindUnsupported:
		return queravuev1.MockErrorKind_MOCK_ERROR_KIND_UNSUPPORTED
	default:
		return queravuev1.MockErrorKind_MOCK_ERROR_KIND_SERVER
	}
}
