package dataformat

import (
	"bufio"
	"context"
	"errors"
	"fmt"
	"io"
	"slices"

	"github.com/doubledare704/queravue/core/internal/engine"
)

type position struct {
	line, column, offset int64
}

func (p position) failure(err error) *ParseError {
	return &ParseError{Line: p.line, Column: p.column, Offset: p.offset, Err: err}
}

type input struct {
	*bufio.Reader
	pos position
	ctx context.Context
}

func openInput(ctx context.Context, src io.Reader) (*input, error) {
	in := &input{Reader: bufio.NewReaderSize(src, 32<<10), pos: position{line: 1, column: 1}, ctx: ctx}
	if err := ctx.Err(); err != nil {
		return nil, fmt.Errorf("dataformat: %w", err)
	}
	b, err := in.Peek(4)
	if err != nil && !errors.Is(err, io.EOF) {
		return nil, in.pos.failure(fmt.Errorf("read encoding prefix: %w", err))
	}
	switch {
	case len(b) >= 2 && (string(b[:2]) == "\xff\xfe" || string(b[:2]) == "\xfe\xff"),
		len(b) >= 4 && string(b[:4]) == "\x00\x00\xfe\xff":
		return nil, in.pos.failure(errEncoding)
	case len(b) >= 3 && string(b[:3]) == "\xef\xbb\xbf":
		_, _ = in.Discard(3)
		in.pos.offset = 3
	}
	return in, nil
}

func (in *input) advance(r rune, n int) {
	in.pos.offset += int64(n)
	if r == '\n' {
		in.pos.line++
		in.pos.column = 1
	} else {
		in.pos.column += int64(n)
	}
}

func (in *input) readByte() (byte, error) {
	if in.Buffered() == 0 {
		if err := in.ctx.Err(); err != nil {
			return 0, fmt.Errorf("dataformat: %w", err)
		}
	}
	b, err := in.ReadByte()
	if err != nil {
		return b, fmt.Errorf("read byte: %w", err)
	}
	in.advance(rune(b), 1)
	return b, nil
}

type recordReader[T any] func(ctx context.Context) (T, int, error)

type batchReader[T any] struct {
	read         recordReader[T]
	maxBytes     int
	pending      T
	pendingBytes int
	pendingErr   error
}

func (b *batchReader[T]) Next(ctx context.Context) ([]T, error) {
	return b.next(ctx, engine.MaxBatchRows)
}

func (b *batchReader[T]) next(ctx context.Context, maxRows int) ([]T, error) {
	if err := ctx.Err(); err != nil {
		return nil, fmt.Errorf("dataformat: %w", err)
	}
	if b.pendingErr != nil {
		err := b.pendingErr
		b.pendingErr = nil
		return nil, err
	}
	var batch []T
	var size int
	if b.pendingBytes != 0 {
		batch = append(batch, b.pending)
		size = b.pendingBytes
		var zero T
		b.pending, b.pendingBytes = zero, 0
	}
	for len(batch) < maxRows && size < b.maxBytes {
		if err := ctx.Err(); err != nil {
			return nil, fmt.Errorf("dataformat: %w", err)
		}
		value, cost, err := b.read(ctx)
		if err != nil {
			if len(batch) == 0 {
				return nil, err
			}
			b.pendingErr = err
			break
		}
		if size+cost > b.maxBytes && len(batch) != 0 {
			b.pending, b.pendingBytes = value, cost
			break
		}
		batch = append(batch, value)
		size += cost
	}
	return batch, nil
}

// Reader implements engine.RowBatchSource with recoverable errors between batches.
type Reader struct {
	batchReader[[]engine.Value]
	readHeader func(context.Context) error
	columns    []string
	ready      bool
}

// NewReader discovers columns when columns is nil.
func NewReader(ctx context.Context, src io.Reader, opts Options, columns []string) (*Reader, error) {
	if err := opts.normalize(); err != nil {
		return nil, err
	}
	if opts.Format == SQL {
		return nil, errors.New("dataformat: SQL dump reading is unsupported")
	}
	in, err := openInput(ctx, src)
	if err != nil {
		return nil, err
	}
	r := &Reader{columns: slices.Clone(columns), ready: columns != nil}
	r.maxBytes = opts.MaxBytes
	if opts.Format == CSV || opts.Format == TSV {
		d := &delimitedReader{input: in, opts: opts, reader: r, header: opts.Header}
		r.read, r.readHeader = d.read, d.readHeader
	} else {
		r.read = (&objectReader{frames: jsonFrames{input: in, opts: opts}, reader: r}).read
	}
	return r, nil
}

// Columns returns names in row order, retaining the first data record if needed.
func (r *Reader) Columns(ctx context.Context) ([]string, error) {
	if err := ctx.Err(); err != nil {
		return nil, fmt.Errorf("dataformat: %w", err)
	}
	if r.readHeader != nil {
		if err := r.readHeader(ctx); err != nil && !errors.Is(err, io.EOF) {
			return nil, err
		}
	}
	if !r.ready {
		row, size, err := r.read(ctx)
		if err != nil && !errors.Is(err, io.EOF) {
			return nil, err
		}
		if err == nil {
			r.pending, r.pendingBytes = row, size
		}
	}
	return slices.Clone(r.columns), nil
}

func columnNames(count int) []string {
	names := make([]string, count)
	for i := range names {
		names[i] = fmt.Sprintf("column_%d", i+1)
	}
	return names
}
