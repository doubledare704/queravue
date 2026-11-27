package results

import (
	"bytes"
	"context"

	"github.com/doubledare704/queravue/core/internal/dataformat"
	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

// Formatter adapts protobuf rows and column selection to the shared clipboard encoder.
type Formatter struct {
	writer dataformat.Writer
	cols   []engine.Column
	idx    []int
	row    []engine.Value
	buf    bytes.Buffer
}

// NewFormatter skips out-of-range indices and selects all columns when indices is empty.
func NewFormatter(format queravuev1.CopyFormat, all []*queravuev1.Column, indices []uint32, header bool) *Formatter {
	f := &Formatter{}
	if len(indices) == 0 {
		for i := range all {
			f.idx = append(f.idx, i)
		}
	} else {
		for _, i := range indices {
			if uint64(i) < uint64(len(all)) {
				f.idx = append(f.idx, int(i))
			}
		}
	}
	for _, i := range f.idx {
		f.cols = append(f.cols, engine.Column{Name: all[i].GetName()})
	}
	f.row = make([]engine.Value, len(f.idx))
	layout := dataformat.TSV
	switch format {
	case queravuev1.CopyFormat_COPY_FORMAT_CSV:
		layout = dataformat.CSV
	case queravuev1.CopyFormat_COPY_FORMAT_JSON:
		layout = dataformat.JSON
	}
	f.writer = dataformat.NewClipboardWriter(&f.buf, layout, header)
	return f
}

// Buffer can be drained between rows without resetting the encoder.
func (f *Formatter) Buffer() *bytes.Buffer { return &f.buf }

// Begin emits the preamble into the pending output buffer.
func (f *Formatter) Begin() { _ = f.writer.Columns(context.Background(), f.cols) }

// Row fills missing projected cells with nulls.
func (f *Formatter) Row(r *queravuev1.Row) {
	vals := r.GetValues()
	for i, ci := range f.idx {
		f.row[i] = engine.Null()
		if ci < len(vals) {
			f.row[i] = ValueFromProto(vals[ci])
		}
	}
	_ = f.writer.Batch(context.Background(), [][]engine.Value{f.row})
	clear(f.row)
}

// End completes the clipboard payload.
func (f *Formatter) End() { _ = f.writer.Close(context.Background()) }
