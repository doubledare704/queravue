package transfer

import (
	"context"
	"io"

	"github.com/doubledare704/queravue/core/internal/dataformat"
	"github.com/doubledare704/queravue/core/internal/engine"
)

// DocsToJSON is an engine.DocSink writing documents as JSON or NDJSON.
type DocsToJSON struct {
	Ctx    context.Context //nolint:containedctx // a sink has no ctx parameter
	Run    *ExportRun
	Writer *dataformat.DocumentWriter
}

// Batch implements engine.DocSink.
func (s *DocsToJSON) Batch(docs []engine.Document) error {
	if err := wrapWrite(s.Writer.Batch(s.Ctx, docs)); err != nil {
		return err
	}
	return s.Run.Rows(len(docs))
}

// NewDocumentWriter writes documents as JSON or NDJSON in the chosen EJSON flavor.
func NewDocumentWriter(dst io.Writer, f Format, canonical bool) (*dataformat.DocumentWriter, error) {
	w, err := dataformat.NewDocumentWriter(dst, dataformat.Options{Format: f.dataformat()}, canonical)
	if err != nil {
		return nil, newError(KindParse, "%v", err)
	}
	return w, nil
}

// DocsToRows is an engine.DocSink that turns documents into rows of the chosen field paths.
type DocsToRows struct {
	Ctx    context.Context //nolint:containedctx // a sink has no ctx parameter
	Run    *ExportRun
	Writer dataformat.Writer
	Paths  *PathExtractor
}

// Batch implements engine.DocSink.
func (s *DocsToRows) Batch(docs []engine.Document) error {
	rows := make([][]engine.Value, len(docs))
	for i, doc := range docs {
		row, err := s.Paths.Row(doc)
		if err != nil {
			return err
		}
		rows[i] = row
	}
	if err := wrapWrite(s.Writer.Batch(s.Ctx, rows)); err != nil {
		return err
	}
	return s.Run.Rows(len(docs))
}
