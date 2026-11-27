package mockdata

import (
	"context"
	"errors"
	"io"
	"reflect"
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
)

type captureRowLoader struct {
	cols []string
	rows [][]engine.Value
}

func (l *captureRowLoader) LoadRows(ctx context.Context, _ engine.LoadTarget, columns []string, src engine.RowBatchSource) (engine.LoadStats, error) {
	l.cols = append([]string(nil), columns...)
	var stats engine.LoadStats
	for {
		batch, err := src.Next(ctx)
		if errors.Is(err, io.EOF) {
			break
		}
		if err != nil {
			return stats, err
		}
		l.rows = append(l.rows, batch...)
		stats.Rows += uint64(len(batch))
		stats.Batches++
	}
	return stats, nil
}

func TestSeedDeterminismPreviewEqualsRunAndColumnIsolation(t *testing.T) {
	target := TargetRef{Database: "app", Schema: "public", Name: "users"}
	baseRules := []ColumnRule{
		{ColumnOrPath: "id", Unique: true, Kind: RuleSequence, Sequence: SequenceRule{Start: 1, Step: 1}},
		{ColumnOrPath: "email", Kind: RuleFaker, FakerKind: "email"},
		{ColumnOrPath: "score", Kind: RuleIntRange, IntRange: IntRangeRule{Min: 1, Max: 1000}},
		{ColumnOrPath: "code", Kind: RulePattern, Pattern: PatternRule{Pattern: "??-####"}},
	}

	spec := Spec{
		Seed: 777,
		Targets: []TargetSpec{
			{Target: target, Rows: 50, Rules: baseRules},
		},
	}

	previews, err := Preview(context.Background(), spec, 15, nil)
	if err != nil {
		t.Fatal(err)
	}
	if len(previews) != 1 || len(previews[0].Rows) != 15 {
		t.Fatalf("unexpected preview: %+v", previews)
	}

	loader := &captureRowLoader{}
	if _, err := Run(context.Background(), spec, loader, nil, nil, nil); err != nil {
		t.Fatal(err)
	}
	if len(loader.rows) != 50 {
		t.Fatalf("loaded %d rows, want 50", len(loader.rows))
	}

	if !reflect.DeepEqual(previews[0].Columns, loader.cols) {
		t.Fatalf("columns mismatch: preview=%v run=%v", previews[0].Columns, loader.cols)
	}
	for i := range 15 {
		if !reflect.DeepEqual(previews[0].Rows[i], loader.rows[i]) {
			t.Fatalf("row %d mismatch between preview and run:\npreview: %+v\nrun:     %+v", i, previews[0].Rows[i], loader.rows[i])
		}
	}

	// Adding an extra column at the front must not alter any existing column's generated values.
	extendedRules := append([]ColumnRule{
		{ColumnOrPath: "extra_city", Kind: RuleFaker, FakerKind: "city"},
	}, baseRules...)
	extendedSpec := Spec{
		Seed: 777,
		Targets: []TargetSpec{
			{Target: target, Rows: 15, Rules: extendedRules},
		},
	}
	extendedPreview, err := Preview(context.Background(), extendedSpec, 15, nil)
	if err != nil {
		t.Fatal(err)
	}
	for i := range 15 {
		gotWithoutExtra := extendedPreview[0].Rows[i][1:]
		if !reflect.DeepEqual(previews[0].Rows[i], gotWithoutExtra) {
			t.Fatalf("adding extra column altered existing columns at row %d:\nwant: %+v\ngot:  %+v", i, previews[0].Rows[i], gotWithoutExtra)
		}
	}
}
