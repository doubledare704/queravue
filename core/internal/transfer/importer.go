package transfer

import (
	"bytes"
	"context"
	"encoding/json"
	"io"

	"github.com/doubledare704/queravue/core/internal/dataformat"
	"github.com/doubledare704/queravue/core/internal/engine"
)

// RowReader yields the rows of a file in batches, with the 1-based line or record
// number of every row of the last batch.
type RowReader interface {
	Columns(ctx context.Context) ([]string, error)
	Next(ctx context.Context) ([][]engine.Value, error)
	Lines() []int64
}

// Importer loads records through the engine's bulk loaders and nothing else.
type Importer struct {
	RowLoader    engine.RowLoader
	DocLoader    engine.DocumentLoader
	Policy       ErrorPolicy
	MaxRowErrors int
	BytesRead    func() uint64
	Progress     func(committed, bytesRead uint64) error
}

func (im *Importer) maxErrors() int {
	if im.MaxRowErrors <= 0 {
		return DefaultMaxRowErrors
	}
	return im.MaxRowErrors
}

func (im *Importer) report(delivered uint64) error {
	return im.Progress(delivered, im.BytesRead())
}

// ImportRows loads rows into a table.
func (im *Importer) ImportRows(ctx context.Context, rd RowReader, mapper *Mapper, target engine.LoadTarget) Result {
	p := &pipeline[[]engine.Value, []engine.Value]{
		reader: rd, convert: mapper.convert, policy: im.Policy, maxErrors: im.maxErrors(), report: im.report,
	}
	var committed uint64
	var loadErr error
	for {
		callStart := p.delivered
		stats, err := im.RowLoader.LoadRows(ctx, target, mapper.Columns(), p)
		committed += stats.Rows
		if err == nil {
			break
		}
		if !im.canRetryRowByRow(p, err, stats, callStart) {
			loadErr = err
			break
		}
		retried, err := im.retryRowByRow(ctx, p, target, mapper.Columns())
		committed += retried
		if err != nil {
			loadErr = err
			break
		}
	}
	return p.result(committed, loadErr)
}

// canRetryRowByRow holds only when the failed batch is known to have committed nothing.
func (im *Importer) canRetryRowByRow(p *pipeline[[]engine.Value, []engine.Value], err error, stats engine.LoadStats, callStart uint64) bool {
	return im.Policy == PolicySkip && engine.KindOf(err) == engine.KindConstraint &&
		p.inflight != nil && stats.Rows == p.deliveredBefore-callStart
}

func (im *Importer) retryRowByRow(ctx context.Context, p *pipeline[[]engine.Value, []engine.Value], target engine.LoadTarget, columns []string) (uint64, error) {
	rows, lines := p.inflightCopy()
	var committed uint64
	for i, row := range rows {
		stats, err := im.RowLoader.LoadRows(ctx, target, columns, &oneBatch{rows: [][]engine.Value{row}})
		committed += stats.Rows
		if err == nil {
			continue
		}
		if engine.KindOf(err) != engine.KindConstraint {
			return committed, err
		}
		p.delivered--
		if p.reject(lines[i], problem{KindConstraint, "", Classify(err).Message}) {
			return committed, errSourceStopped
		}
	}
	return committed, nil
}

type oneBatch struct {
	rows [][]engine.Value
	done bool
}

func (b *oneBatch) Next(context.Context) ([][]engine.Value, error) {
	if b.done {
		return nil, errEOF
	}
	b.done = true
	return b.rows, nil
}

// ImportRowsAsDocuments loads tabular records as flat documents of text fields.
func (im *Importer) ImportRowsAsDocuments(ctx context.Context, rd RowReader, mapper *Mapper, database, collection string) Result {
	p := &pipeline[[]engine.Value, engine.Document]{
		reader: rd, policy: im.Policy, maxErrors: im.maxErrors(), report: im.report,
		convert: func(row []engine.Value) (engine.Document, *problem) {
			mapped, bad := mapper.convert(row)
			if bad != nil {
				return "", bad
			}
			return flatDocument(mapper.Columns(), mapped), nil
		},
	}
	return im.loadDocuments(ctx, p, database, collection)
}

// ImportDocuments loads EJSON documents.
func (im *Importer) ImportDocuments(ctx context.Context, rd *dataformat.DocumentReader, database, collection string) Result {
	p := &pipeline[engine.Document, engine.Document]{
		reader: rd, policy: im.Policy, maxErrors: im.maxErrors(), report: im.report,
		convert: func(doc engine.Document) (engine.Document, *problem) { return doc, nil },
	}
	return im.loadDocuments(ctx, p, database, collection)
}

type documentPipeline interface {
	engine.DocumentBatchSource
	result(committed uint64, loadErr error) Result
}

func (im *Importer) loadDocuments(ctx context.Context, p documentPipeline, database, collection string) Result {
	stats, err := im.DocLoader.LoadDocuments(ctx, database, collection, p)
	return p.result(stats.Rows, err)
}

func flatDocument(names []string, values []engine.Value) engine.Document {
	var b bytes.Buffer
	b.WriteByte('{')
	for i, name := range names {
		if i > 0 {
			b.WriteByte(',')
		}
		key, _ := json.Marshal(name)
		b.Write(key)
		b.WriteByte(':')
		if values[i].Kind == engine.VNull {
			b.WriteString("null")
			continue
		}
		text, _ := json.Marshal(dataformat.ValueText(values[i]))
		b.Write(text)
	}
	b.WriteByte('}')
	return b.String()
}

var errEOF = io.EOF
