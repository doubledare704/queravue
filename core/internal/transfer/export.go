package transfer

import (
	"context"
	"errors"
	"fmt"
	"io"
	"slices"
	"time"

	"github.com/doubledare704/queravue/core/internal/dataformat"
	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

const progressInterval = 200 * time.Millisecond

// ExportRun counts what an export has written and throttles its progress events.
type ExportRun struct {
	out      *ChunkWriter
	progress func(rows, bytes uint64) error
	rows     uint64
	last     time.Time
}

// NewExportRun sends chunks through chunk and progress through progress.
func NewExportRun(chunk func([]byte) error, progress func(rows, bytes uint64) error) *ExportRun {
	return &ExportRun{out: NewChunkWriter(chunk), progress: progress, last: time.Now()}
}

// Output is where the format writer writes.
func (r *ExportRun) Output() io.Writer { return r.out }

// Rows records n more rows written and reports progress when it is due.
func (r *ExportRun) Rows(n int) error {
	r.rows += uint64(n) //nolint:gosec // n is non-negative
	if time.Since(r.last) < progressInterval {
		return nil
	}
	r.last = time.Now()
	return r.progress(r.rows, r.out.Bytes())
}

// Finish flushes the last chunk and returns the totals.
func (r *ExportRun) Finish() (rows, bytes uint64, err error) {
	if err := r.out.Flush(); err != nil {
		return 0, 0, err
	}
	return r.rows, r.out.Bytes(), nil
}

// RowFormat says how rows are written.
type RowFormat struct {
	Format  Format
	Options Options
	Dialect sqldialect.Dialect
	Target  sqldialect.Target
	Design  *sqldialect.TableDesign
	Parquet ParquetConfig
}

// NewRowWriter returns the writer for rows in f.
func NewRowWriter(dst io.Writer, f RowFormat) (dataformat.Writer, error) {
	switch f.Format {
	case SQL:
		if f.Dialect == nil {
			return nil, newError(KindUnsupported, "SQL dumps need a SQL connection")
		}
		target := f.Target
		if f.Options.SQLTable != "" {
			target.Table = f.Options.SQLTable
		}
		dump := dataformat.SQLDumpOptions{Dialect: f.Dialect, Target: target}
		if f.Options.SQLIncludeDDL {
			dump.Create = f.Design
		}
		return wrapFormat(dataformat.NewSQLWriter(dst, dump))
	case Parquet:
		return NewParquetWriter(dst, f.Parquet)
	case CSV, TSV, JSON, NDJSON:
		opts, err := f.Options.DataformatOptions(f.Format)
		if err != nil {
			return nil, err
		}
		return wrapFormat(dataformat.NewWriter(dst, opts))
	}
	return nil, newError(KindUnsupported, "unsupported export format")
}

func wrapFormat(w dataformat.Writer, err error) (dataformat.Writer, error) {
	if err != nil {
		return nil, newError(KindParse, "%v", err)
	}
	return w, nil
}

// RowsToWriter is an engine.RowSink that projects columns and feeds a format writer.
type RowsToWriter struct {
	Ctx     context.Context //nolint:containedctx // a sink has no ctx parameter
	Run     *ExportRun
	Only    []string
	NewFile func(cols []engine.Column) (dataformat.Writer, error)
	writer  dataformat.Writer
	project []int
}

// Columns implements engine.RowSink.
func (s *RowsToWriter) Columns(cols []engine.Column) error {
	chosen := cols
	if len(s.Only) > 0 {
		chosen = make([]engine.Column, 0, len(s.Only))
		for _, name := range s.Only {
			i := slices.IndexFunc(cols, func(c engine.Column) bool { return c.Name == name })
			if i < 0 {
				return newError(KindMapping, "the result has no column %q", name)
			}
			s.project = append(s.project, i)
			chosen = append(chosen, cols[i])
		}
	}
	w, err := s.NewFile(chosen)
	if err != nil {
		return err
	}
	s.writer = w
	return wrapWrite(w.Columns(s.Ctx, chosen))
}

// Batch implements engine.RowSink.
func (s *RowsToWriter) Batch(rows [][]engine.Value) error {
	if s.project != nil {
		picked := make([][]engine.Value, len(rows))
		for i, row := range rows {
			picked[i] = make([]engine.Value, len(s.project))
			for j, from := range s.project {
				picked[i][j] = row[from]
			}
		}
		rows = picked
	}
	if err := wrapWrite(s.writer.Batch(s.Ctx, rows)); err != nil {
		return err
	}
	return s.Run.Rows(len(rows))
}

// Abort discards a half-written file.
func (s *RowsToWriter) Abort() {
	if s.writer != nil {
		AbortWriter(s.writer)
	}
}

// AbortWriter releases what an unfinished writer holds, such as Parquet's temporary files.
func AbortWriter(w dataformat.Writer) {
	if a, ok := w.(interface{ Abort() }); ok {
		a.Abort()
	}
}

// Close finishes the file.
func (s *RowsToWriter) Close() error {
	if s.writer == nil {
		return nil
	}
	return wrapWrite(s.writer.Close(s.Ctx))
}

func wrapWrite(err error) error {
	var typed *Error
	if err == nil || errors.As(err, &typed) {
		return err
	}
	return fmt.Errorf("transfer: write: %w", err)
}

// SpoolSource reads a spooled result in order.
type SpoolSource interface {
	ReadRows(offset uint64, limit int) ([][]engine.Value, error)
	State() (rows uint64, done bool)
}

// ExportSpool writes the chosen columns of a spooled result, waiting for rows that are still arriving.
func ExportSpool(ctx context.Context, src SpoolSource, cols []engine.Column, picks []int, w dataformat.Writer, run *ExportRun) error {
	defer AbortWriter(w)
	chosen := cols
	if len(picks) > 0 {
		chosen = make([]engine.Column, len(picks))
		for i, p := range picks {
			if p < 0 || p >= len(cols) {
				return newError(KindMapping, "column index %d is out of range", p)
			}
			chosen[i] = cols[p]
		}
	}
	if err := wrapWrite(w.Columns(ctx, chosen)); err != nil {
		return err
	}
	var offset uint64
	for {
		rows, err := src.ReadRows(offset, engine.MaxBatchRows)
		if err != nil {
			return fmt.Errorf("transfer: read result: %w", err)
		}
		if len(rows) == 0 {
			total, done := src.State()
			if done && offset >= total {
				break
			}
			select {
			case <-ctx.Done():
				return fmt.Errorf("transfer: %w", ctx.Err())
			case <-time.After(50 * time.Millisecond):
			}
			continue
		}
		offset += uint64(len(rows))
		if len(picks) > 0 {
			rows = project(rows, picks)
		}
		if err := wrapWrite(w.Batch(ctx, rows)); err != nil {
			return err
		}
		if err := run.Rows(len(rows)); err != nil {
			return err
		}
	}
	return wrapWrite(w.Close(ctx))
}

func project(rows [][]engine.Value, picks []int) [][]engine.Value {
	out := make([][]engine.Value, len(rows))
	for i, row := range rows {
		out[i] = make([]engine.Value, len(picks))
		for j, p := range picks {
			if p < len(row) {
				out[i][j] = row[p]
			}
		}
	}
	return out
}
