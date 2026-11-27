package mockdata

import (
	"context"
	"fmt"
	"io"
	"strings"

	"github.com/doubledare704/queravue/core/internal/engine"
)

const (
	defaultBatchRows  = 2000
	defaultBatchBytes = 1 << 20
)

type compiledColumn struct {
	name string
	gen  colGenerator
	pool *KeyPool
}

type tableBatchSource struct {
	spec       TargetSpec
	columns    []string
	cols       []compiledColumn
	ctxGen     *genContext
	generated  uint64
	batchRows  int
	batchBytes int
	onBatch    func(committed uint64)
}

func newTableBatchSource(
	seed uint64,
	spec TargetSpec,
	referencedCols map[string]bool,
	store *keyStore,
	onBatch func(uint64),
) (*tableBatchSource, error) {
	cols := make([]compiledColumn, 0, len(spec.Rules))
	colNames := make([]string, 0, len(spec.Rules))
	targetKey := spec.Target.Key()

	for _, r := range spec.Rules {
		if r.ColumnOrPath == "" {
			return nil, parseErr(&spec.Target, "", "column rule requires column_or_path")
		}
		if r.Kind == RuleSkip {
			continue
		}
		gen, err := buildGenerator(seed, spec.Target, r.ColumnOrPath, r)
		if err != nil {
			return nil, err
		}
		var pool *KeyPool
		if referencedCols[strings.ToLower(r.ColumnOrPath)] {
			pool = store.ensure(targetKey, r.ColumnOrPath)
		}
		cols = append(cols, compiledColumn{name: r.ColumnOrPath, gen: gen, pool: pool})
		colNames = append(colNames, r.ColumnOrPath)
	}

	return &tableBatchSource{
		spec:       spec,
		columns:    colNames,
		cols:       cols,
		ctxGen:     &genContext{keys: store},
		batchRows:  defaultBatchRows,
		batchBytes: defaultBatchBytes,
		onBatch:    onBatch,
	}, nil
}

func (s *tableBatchSource) Next(ctx context.Context) ([][]engine.Value, error) {
	if s.generated > 0 && s.onBatch != nil {
		// Loader has committed the previous batch by the time it pulls the next one.
		s.onBatch(s.generated)
	}
	if err := ctx.Err(); err != nil {
		return nil, fmt.Errorf("mockdata: next row batch: %w", err)
	}
	if s.generated >= s.spec.Rows {
		return nil, io.EOF
	}
	rem := s.spec.Rows - s.generated
	capRows := s.batchRows
	if rem < uint64(s.batchRows) { //nolint:gosec // batchRows is positive
		capRows = int(rem) //nolint:gosec // bounded by batchRows
	}
	rows := make([][]engine.Value, 0, capRows)
	var estBytes int

	for range capRows {
		row := make([]engine.Value, len(s.cols))
		for j, c := range s.cols {
			gv, err := c.gen.next(s.ctxGen)
			if err != nil {
				return nil, err
			}
			row[j] = gv.val
			if c.pool != nil {
				c.pool.Add(gv.val)
			}
			estBytes += estimateValueBytes(gv.val)
		}
		rows = append(rows, row)
		s.generated++
		if estBytes >= s.batchBytes {
			break
		}
	}
	return rows, nil
}

func estimateValueBytes(v engine.Value) int {
	switch v.Kind {
	case engine.VNull, engine.VBool:
		return 8
	case engine.VInt, engine.VFloat:
		return 16
	case engine.VTimestamptz:
		return 24
	case engine.VText, engine.VDecimal, engine.VJSON, engine.VUUID:
		return 16 + len(v.Str)
	case engine.VBytes:
		return 16 + len(v.Bytes)
	case engine.VArray:
		n := 16
		for _, e := range v.Array {
			n += estimateValueBytes(e)
		}
		return n
	default:
		return 16
	}
}

type docBatchSource struct {
	spec       TargetSpec
	root       *docNode
	ctxGen     *genContext
	generated  uint64
	batchRows  int
	batchBytes int
	onBatch    func(committed uint64)
}

func newDocBatchSource(
	seed uint64,
	spec TargetSpec,
	store *keyStore,
	onBatch func(uint64),
) (*docBatchSource, error) {
	root, err := compileDocTree(seed, spec.Target, spec.Rules)
	if err != nil {
		return nil, err
	}
	return &docBatchSource{
		spec:       spec,
		root:       root,
		ctxGen:     &genContext{keys: store},
		batchRows:  defaultBatchRows,
		batchBytes: defaultBatchBytes,
		onBatch:    onBatch,
	}, nil
}

func (s *docBatchSource) Next(ctx context.Context) ([]engine.Document, error) {
	if s.generated > 0 && s.onBatch != nil {
		s.onBatch(s.generated)
	}
	if err := ctx.Err(); err != nil {
		return nil, fmt.Errorf("mockdata: next document batch: %w", err)
	}
	if s.generated >= s.spec.Rows {
		return nil, io.EOF
	}
	rem := s.spec.Rows - s.generated
	capRows := s.batchRows
	if rem < uint64(s.batchRows) { //nolint:gosec // batchRows is positive
		capRows = int(rem) //nolint:gosec // bounded by batchRows
	}
	docs := make([]engine.Document, 0, capRows)
	var estBytes int

	for range capRows {
		doc, err := s.root.generateDocument(s.ctxGen)
		if err != nil {
			return nil, err
		}
		docs = append(docs, doc)
		s.generated++
		estBytes += len(doc) + 16
		if estBytes >= s.batchBytes {
			break
		}
	}
	return docs, nil
}
