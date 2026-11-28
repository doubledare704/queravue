package dataformat

import (
	"context"
	"errors"
	"fmt"
	"io"
	"unicode/utf8"

	"github.com/doubledare704/queravue/core/internal/engine"
)

type fieldEnd struct {
	end    int
	quoted bool
}

type delimitedReader struct {
	*input
	opts      Options
	reader    *Reader
	header    bool
	data      []byte
	fields    []fieldEnd
	headerErr error
}

type fieldState uint8

const (
	atFieldStart fieldState = iota
	inField
	inQuotedField
	afterQuote
	badField
)

func (d *delimitedReader) readHeader(ctx context.Context) error {
	if d.headerErr != nil {
		return d.headerErr
	}
	if !d.header {
		return nil
	}
	if err := ctx.Err(); err != nil {
		return fmt.Errorf("dataformat: %w", err)
	}
	d.ctx = ctx
	pos := d.pos
	if _, err := d.scan(); err != nil {
		if ctx.Err() == nil || pos != d.pos {
			d.headerErr = err
		}
		return err
	}
	d.header = false
	if d.reader.ready && len(d.fields) != len(d.reader.columns) {
		d.headerErr = pos.failure(fmt.Errorf("header has %d fields, expected %d", len(d.fields), len(d.reader.columns)))
		return d.headerErr
	}
	if !d.reader.ready {
		names := make([]string, len(d.fields))
		start := 0
		for i, f := range d.fields {
			names[i] = string(d.data[start:f.end])
			start = f.end
		}
		d.reader.columns, d.reader.ready = names, true
	}
	return nil
}

func (d *delimitedReader) read(ctx context.Context) ([]engine.Value, int, error) {
	d.ctx = ctx
	if d.headerErr != nil {
		return nil, 0, io.EOF
	}
	if err := d.readHeader(ctx); err != nil {
		return nil, 0, err
	}
	pos := d.pos
	d.reader.line = pos.line
	size, err := d.scan()
	if err != nil {
		return nil, 0, err
	}
	if !d.reader.ready {
		d.reader.columns = columnNames(len(d.fields))
		d.reader.ready = true
	}
	if len(d.fields) != len(d.reader.columns) {
		return nil, 0, pos.failure(fmt.Errorf("row has %d fields, expected %d", len(d.fields), len(d.reader.columns)))
	}
	row := make([]engine.Value, len(d.fields))
	data := string(d.data)
	start := 0
	for i, f := range d.fields {
		s := data[start:f.end]
		if f.quoted || s != d.opts.NullText {
			row[i] = engine.Text(s)
		}
		start = f.end
	}
	return row, size, nil
}

func (d *delimitedReader) scan() (int, error) {
	start := d.pos
	d.fields, d.data = d.fields[:0], d.data[:0]
	state := atFieldStart
	quoted := false
	var firstErr error
	for {
		pos := d.pos
		if d.Buffered() < utf8.UTFMax {
			if err := d.ctx.Err(); err != nil {
				return 0, fmt.Errorf("dataformat: scan delimited record: %w", err)
			}
		}
		r, n, err := d.ReadRune()
		if errors.Is(err, io.EOF) {
			if pos == start {
				return 0, io.EOF
			}
			if state == inQuotedField && firstErr == nil {
				firstErr = pos.failure(errors.New("unterminated quoted field"))
			}
			return d.finish(start, quoted, firstErr)
		}
		if err != nil {
			return 0, fmt.Errorf("dataformat: read delimited record: %w", err)
		}
		d.advance(r, n)
		if firstErr == nil {
			switch {
			case r == 0 || r == utf8.RuneError && n == 1:
				firstErr = pos.failure(errEncoding)
			case d.recordSize(start) > d.opts.MaxRecordBytes:
				firstErr = pos.failure(errRecordSize)
			}
		}
		if state != inQuotedField {
			if r == '\r' {
				next, err := d.Peek(1)
				if err != nil && !errors.Is(err, io.EOF) {
					return 0, fmt.Errorf("dataformat: read record terminator: %w", err)
				}
				if len(next) == 1 && next[0] == '\n' {
					_, _ = d.readByte()
					r = '\n'
				} else if firstErr == nil {
					firstErr = pos.failure(errors.New("bare carriage return in delimited field"))
				}
			}
			if r == '\n' {
				return d.finish(start, quoted, firstErr)
			}
			if r == d.opts.Delimiter {
				if firstErr == nil {
					d.fields = append(d.fields, fieldEnd{len(d.data), quoted})
				}
				state, quoted = atFieldStart, false
				continue
			}
			if state == badField {
				continue
			}
		}
		switch {
		case r == d.opts.Quote && state == atFieldStart:
			state, quoted = inQuotedField, true
			continue
		case r == d.opts.Quote && state == inQuotedField:
			state = afterQuote
			continue
		case r == d.opts.Quote && state == afterQuote:
			state = inQuotedField
		case state == afterQuote || r == d.opts.Quote:
			if firstErr == nil {
				firstErr = pos.failure(errors.New("invalid quoting in delimited field"))
			}
			state = badField
			continue
		case state == atFieldStart:
			state = inField
		}
		if firstErr == nil {
			d.data = utf8.AppendRune(d.data, r)
		}
	}
}

func (d *delimitedReader) recordSize(start position) int {
	return int(d.pos.offset-start.offset) + (len(d.fields)+1)*valueBudget
}

func (d *delimitedReader) finish(start position, quoted bool, err error) (int, error) {
	size := d.recordSize(start)
	if err != nil {
		return 0, err
	}
	if size > d.opts.MaxRecordBytes {
		return 0, start.failure(errRecordSize)
	}
	d.fields = append(d.fields, fieldEnd{len(d.data), quoted})
	return size, nil
}
