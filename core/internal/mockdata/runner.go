package mockdata

import (
	"context"
	"errors"
	"fmt"
	"io"
	"strings"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
)

const (
	defaultPreviewRows = 20
	maxPreviewRows     = 200
	progressInterval   = 250 * time.Millisecond
)

type fkParentKey struct {
	targetKey string
	column    string
}

// Preview generates up to maxPreviewRows sample rows or documents per target without writing.
func Preview(ctx context.Context, spec Spec, rows uint32, keyLoader ExistingKeyLoader) ([]TablePreview, error) {
	if rows == 0 {
		rows = defaultPreviewRows
	}
	if rows > maxPreviewRows {
		rows = maxPreviewRows
	}

	if err := validateSpec(spec); err != nil {
		return nil, err
	}

	refColsByTarget, existingFKs := collectForeignKeyNeeds(spec)
	keyStore := NewKeyStore()
	if err := preloadExistingKeys(ctx, existingFKs, keyStore, keyLoader); err != nil {
		return nil, err
	}

	previews := make([]TablePreview, 0, len(spec.Targets))
	for _, ts := range spec.Targets {
		if err := ctx.Err(); err != nil {
			return nil, fmt.Errorf("mockdata: preview: %w", err)
		}
		previewSpec := ts
		previewSpec.Rows = min(ts.Rows, uint64(rows))
		if ts.Rows == 0 {
			previewSpec.Rows = uint64(rows)
		}

		if ts.Target.IsCollection {
			src, err := newDocBatchSource(spec.Seed, previewSpec, keyStore, nil)
			if err != nil {
				return nil, err
			}
			var docs []string
			for {
				batch, err := src.Next(ctx)
				if errors.Is(err, io.EOF) {
					break
				}
				if err != nil {
					return nil, err
				}
				docs = append(docs, batch...)
			}
			previews = append(previews, TablePreview{
				Target:         ts.Target,
				DocumentsEJSON: docs,
			})
			continue
		}

		if err := ensureParentKeysAvailable(ctx, ts, keyStore, keyLoader); err != nil {
			return nil, err
		}
		src, err := newTableBatchSource(spec.Seed, previewSpec, refColsByTarget[ts.Target.Key()], keyStore, nil)
		if err != nil {
			return nil, err
		}
		var outRows [][]engine.Value
		for {
			batch, err := src.Next(ctx)
			if errors.Is(err, io.EOF) {
				break
			}
			if err != nil {
				return nil, err
			}
			outRows = append(outRows, batch...)
		}
		previews = append(previews, TablePreview{
			Target:  ts.Target,
			Columns: src.columns,
			Rows:    outRows,
		})
	}
	return previews, nil
}

// Run generates and loads every target in order, emitting throttled progress and per-target completion events.
func Run(
	ctx context.Context,
	spec Spec,
	rowLoader engine.RowLoader,
	docLoader engine.DocumentLoader,
	keyLoader ExistingKeyLoader,
	emit func(RunEvent) error,
) (Summary, error) {
	runStart := time.Now()
	summary := Summary{}

	if err := validateSpec(spec); err != nil {
		return summary, err
	}

	refColsByTarget, existingFKs := collectForeignKeyNeeds(spec)
	keyStore := NewKeyStore()
	if err := preloadExistingKeys(ctx, existingFKs, keyStore, keyLoader); err != nil {
		summary.ElapsedMs = elapsedMs(runStart)
		return summary, err
	}

	for _, ts := range spec.Targets {
		if err := ctx.Err(); err != nil {
			summary.ElapsedMs = elapsedMs(runStart)
			return summary, fmt.Errorf("mockdata: run: %w", err)
		}
		if err := ensureParentKeysAvailable(ctx, ts, keyStore, keyLoader); err != nil {
			summary.ElapsedMs = elapsedMs(runStart)
			return summary, err
		}

		tStart := time.Now()
		lastProgress := tStart
		var committedSoFar uint64
		var emitErr error

		onBatch := func(generated uint64) {
			committedSoFar = generated
			if emit == nil || time.Since(lastProgress) < progressInterval {
				return
			}
			lastProgress = time.Now()
			secs := lastProgress.Sub(tStart).Seconds()
			var rps float64
			if secs > 0 {
				rps = float64(generated) / secs
			}
			if err := emit(RunEvent{Progress: &Progress{
				Target:        ts.Target,
				Rows:          generated,
				RowsPerSecond: rps,
			}}); err != nil && emitErr == nil {
				emitErr = err
			}
		}

		var stats engine.LoadStats
		var loadErr error

		if ts.Target.IsCollection {
			if docLoader == nil {
				summary.ElapsedMs = elapsedMs(runStart)
				return summary, &Error{
					Kind:    ErrUnsupported,
					Message: "connection does not support document loading",
					Target:  &ts.Target,
				}
			}
			src, err := newDocBatchSource(spec.Seed, ts, keyStore, onBatch)
			if err != nil {
				summary.ElapsedMs = elapsedMs(runStart)
				return summary, err
			}
			stats, loadErr = docLoader.LoadDocuments(ctx, ts.Target.Database, ts.Target.Name, src)
		} else {
			if rowLoader == nil {
				summary.ElapsedMs = elapsedMs(runStart)
				return summary, &Error{
					Kind:    ErrUnsupported,
					Message: "connection does not support bulk row loading",
					Target:  &ts.Target,
				}
			}
			src, err := newTableBatchSource(spec.Seed, ts, refColsByTarget[ts.Target.Key()], keyStore, onBatch)
			if err != nil {
				summary.ElapsedMs = elapsedMs(runStart)
				return summary, err
			}
			target := engine.LoadTarget{
				Database: ts.Target.Database,
				Schema:   ts.Target.Schema,
				Table:    ts.Target.Name,
			}
			stats, loadErr = rowLoader.LoadRows(ctx, target, src.columns, src)
		}

		_ = committedSoFar
		summary.Rows += stats.Rows
		if loadErr != nil {
			summary.ElapsedMs = elapsedMs(runStart)
			return summary, loadErr
		}
		if emitErr != nil {
			summary.ElapsedMs = elapsedMs(runStart)
			return summary, emitErr
		}

		done := TargetDone{
			Target:    ts.Target,
			Rows:      stats.Rows,
			ElapsedMs: elapsedMs(tStart),
		}
		summary.Done = append(summary.Done, done)
		if emit != nil {
			if err := emit(RunEvent{TargetDone: &done}); err != nil {
				summary.ElapsedMs = elapsedMs(runStart)
				return summary, err
			}
		}
	}

	summary.ElapsedMs = elapsedMs(runStart)
	return summary, nil
}

func validateSpec(spec Spec) error {
	if len(spec.Targets) == 0 {
		return parseErr(nil, "", "mock spec requires at least one target")
	}
	for _, ts := range spec.Targets {
		if ts.Target.Name == "" {
			return parseErr(&ts.Target, "", "target requires a table or collection name")
		}
		if ts.Target.IsCollection {
			if _, err := compileDocTree(spec.Seed, ts.Target, ts.Rules); err != nil {
				return err
			}
		} else {
			for _, r := range ts.Rules {
				if r.ColumnOrPath == "" {
					return parseErr(&ts.Target, "", "column rule requires column_or_path")
				}
				if _, err := buildGenerator(spec.Seed, ts.Target, r.ColumnOrPath, r); err != nil {
					return err
				}
			}
		}
	}
	if cycles := CheckSpecCycles(spec); len(cycles) > 0 {
		e := cycles[0].Edges[0]
		return &Error{
			Kind:    ErrCycle,
			Message: fmt.Sprintf("foreign-key cycle involving %s -> %s (%s)", e.Child.Name, e.Parent.Name, e.ConstraintName),
			Target:  &e.Child,
			Column:  e.ConstraintName,
		}
	}
	return nil
}

func collectForeignKeyNeeds(spec Spec) (map[string]map[string]bool, map[fkParentKey]TargetRef) {
	refColsByTarget := map[string]map[string]bool{}
	existingFKs := map[fkParentKey]TargetRef{}
	inRunTargets := map[string]bool{}
	for _, ts := range spec.Targets {
		inRunTargets[ts.Target.Key()] = true
	}

	var walkRules func(rules []ColumnRule)
	walkRules = func(rules []ColumnRule) {
		for _, r := range rules {
			switch r.Kind {
			case RuleForeignKey:
				pKey := r.ForeignKey.Parent.Key()
				colLower := strings.ToLower(r.ForeignKey.ParentColumn)
				if r.ForeignKey.FromExistingRows || !inRunTargets[pKey] {
					existingFKs[fkParentKey{targetKey: pKey, column: colLower}] = r.ForeignKey.Parent
				} else {
					cols := refColsByTarget[pKey]
					if cols == nil {
						cols = map[string]bool{}
						refColsByTarget[pKey] = cols
					}
					cols[colLower] = true
				}
			case RuleDocument:
				walkRules(r.Document.Fields)
			case RuleArray:
				if r.Array.Element != nil {
					walkRules([]ColumnRule{*r.Array.Element})
				}
			}
		}
	}
	for _, ts := range spec.Targets {
		walkRules(ts.Rules)
	}
	return refColsByTarget, existingFKs
}

func preloadExistingKeys(ctx context.Context, needed map[fkParentKey]TargetRef, store *KeyStore, loader ExistingKeyLoader) error {
	for k, parent := range needed {
		if loader == nil {
			continue
		}
		pool, err := loader.LoadKeys(ctx, parent, k.column, DefaultExistingKeySampleCap)
		if err != nil {
			return err
		}
		store.Set(k.targetKey, k.column, pool)
	}
	return nil
}

func ensureParentKeysAvailable(ctx context.Context, ts TargetSpec, store *KeyStore, loader ExistingKeyLoader) error {
	if loader == nil {
		return nil
	}
	for _, r := range ts.Rules {
		if r.Kind != RuleForeignKey || r.NullRatio >= 1.0 {
			continue
		}
		pKey := r.ForeignKey.Parent.Key()
		if store.Get(pKey, r.ForeignKey.ParentColumn).Len() > 0 {
			continue
		}
		pool, err := loader.LoadKeys(ctx, r.ForeignKey.Parent, r.ForeignKey.ParentColumn, DefaultExistingKeySampleCap)
		if err != nil {
			return err
		}
		if pool.Len() > 0 {
			store.Set(pKey, r.ForeignKey.ParentColumn, pool)
		}
	}
	return nil
}

func elapsedMs(start time.Time) uint64 {
	d := time.Since(start)
	if d < 0 {
		return 0
	}
	return uint64(d.Milliseconds()) //nolint:gosec // guarded non-negative above
}
