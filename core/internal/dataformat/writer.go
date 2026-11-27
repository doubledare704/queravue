package dataformat

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"strings"
	"unicode/utf8"

	"github.com/doubledare704/queravue/core/internal/engine"
)

// Writer requires one Columns call before any Batch calls and a final Close.
type Writer interface {
	Columns(ctx context.Context, columns []engine.Column) error
	Batch(ctx context.Context, rows [][]engine.Value) error
	Close(ctx context.Context) error
}

type rowWriter struct {
	dst                      io.Writer
	opts                     Options
	clipboard                bool
	names                    [][]byte
	started, closed, hasRows bool
	buf                      bytes.Buffer
	err                      error
}

// NewWriter emits delimited or JSON records without retaining caller rows.
func NewWriter(dst io.Writer, opts Options) (Writer, error) {
	if err := opts.normalize(); err != nil {
		return nil, err
	}
	if opts.Format == SQL {
		return nil, errors.New("dataformat: SQL requires NewSQLWriter")
	}
	return &rowWriter{dst: dst, opts: opts}, nil
}

// NewClipboardWriter preserves the wire layout used by CopyRange.
func NewClipboardWriter(dst io.Writer, format Format, header bool) Writer {
	opts := Options{Format: format, Header: header}
	_ = opts.normalize()
	return &rowWriter{dst: dst, opts: opts, clipboard: true}
}

func (w *rowWriter) Columns(ctx context.Context, columns []engine.Column) error {
	if w.started || w.closed {
		return errors.New("dataformat: columns already set or writer closed")
	}
	if err := ctx.Err(); err != nil {
		return fmt.Errorf("dataformat: %w", err)
	}
	if !w.clipboard && (w.opts.Header || w.opts.Format == JSON || w.opts.Format == NDJSON) {
		size := len(columns) * valueBudget
		for _, col := range columns {
			size += len(col.Name)
			if size > w.opts.MaxRecordBytes {
				return errRecordSize
			}
		}
	}
	w.started = true
	w.names = make([][]byte, len(columns))
	if w.opts.Format == JSON || w.opts.Format == NDJSON {
		if err := w.setObjectKeys(columns); err != nil {
			w.err = err
			return err
		}
	}
	if w.opts.Format == JSON {
		w.buf.WriteByte('[')
	}
	if w.opts.Format == CSV || w.opts.Format == TSV {
		if w.opts.BOM {
			w.buf.WriteString("\ufeff")
		}
		if w.opts.Header {
			for i, col := range columns {
				w.delimit(i)
				w.field(col.Name, i == 0 && !w.opts.BOM)
			}
			w.endLine()
			bomBytes := 0
			if w.opts.BOM {
				bomBytes = 3
			}
			if !w.clipboard && w.buf.Len()-bomBytes+len(columns)*valueBudget > w.opts.MaxRecordBytes {
				w.err = errRecordSize
			}
		}
	}
	return w.flush()
}

func (w *rowWriter) setObjectKeys(columns []engine.Column) error {
	used := make(map[string]bool, len(columns))
	reserved := make(map[string]bool, len(columns))
	nextSuffix := make(map[string]int)
	for _, col := range columns {
		reserved[col.Name] = true
	}
	for i, col := range columns {
		name := col.Name
		if !w.clipboard {
			if !utf8.ValidString(name) {
				return fmt.Errorf("dataformat: invalid JSON column %d", i+1)
			}
			if used[name] {
				for suffix := max(2, nextSuffix[name]); ; suffix++ {
					candidate := fmt.Sprintf("%s_%d", name, suffix)
					if !used[candidate] && !reserved[candidate] {
						nextSuffix[name] = suffix + 1
						name = candidate
						break
					}
				}
			}
			used[name] = true
		}
		w.names[i], _ = json.Marshal(strings.ToValidUTF8(name, "\uFFFD"))
	}
	return nil
}

func (w *rowWriter) Batch(ctx context.Context, rows [][]engine.Value) error {
	if w.err != nil {
		return w.err
	}
	if !w.started || w.closed {
		return errors.New("dataformat: writer requires columns and must be open")
	}
	for _, row := range rows {
		if err := ctx.Err(); err != nil {
			return fmt.Errorf("dataformat: %w", err)
		}
		if len(row) != len(w.names) {
			return fmt.Errorf("dataformat: row has %d values, expected %d", len(row), len(w.names))
		}
		if !w.clipboard {
			remaining := w.opts.MaxRecordBytes - len(row)*valueBudget
			for _, value := range row {
				if !valueFits(value, &remaining, 0) {
					return errRecordSize
				}
			}
		}
		if w.opts.Format == JSON || w.opts.Format == NDJSON {
			w.object(row)
		} else {
			for i, v := range row {
				w.delimit(i)
				if v.Kind == engine.VNull {
					w.buf.WriteString(w.opts.NullText)
				} else {
					w.field(valueText(v), i == 0 && !w.hasRows && !w.opts.Header && !w.opts.BOM)
				}
			}
			w.endLine()
		}
		size := w.buf.Len() + len(row)*valueBudget
		if w.opts.Format == JSON && !w.hasRows {
			size++
		}
		if !w.clipboard && size > w.opts.MaxRecordBytes && w.err == nil {
			w.buf.Reset()
			return errRecordSize
		}
		if err := w.flush(); err != nil {
			return err
		}
		w.hasRows = true
	}
	return nil
}

func (w *rowWriter) object(row []engine.Value) {
	if w.opts.Format == JSON && w.hasRows {
		w.buf.WriteByte(',')
	}
	if w.clipboard {
		w.buf.WriteString("\n  ")
	}
	w.buf.WriteByte('{')
	for i, value := range row {
		if i > 0 {
			w.buf.WriteByte(',')
			if w.clipboard {
				w.buf.WriteByte(' ')
			}
		}
		w.buf.Write(w.names[i])
		w.buf.WriteByte(':')
		if w.clipboard {
			w.buf.WriteByte(' ')
		}
		start := w.buf.Len()
		writeJSON(&w.buf, value)
		if w.opts.Format == NDJSON {
			encoded := w.buf.Bytes()[start:]
			if bytes.ContainsAny(encoded, "\r\n") {
				var compact bytes.Buffer
				_ = json.Compact(&compact, encoded)
				w.buf.Truncate(start)
				w.buf.Write(compact.Bytes())
			}
		}
	}
	w.buf.WriteByte('}')
	if w.opts.Format == NDJSON {
		w.buf.WriteByte('\n')
	}
}

func (w *rowWriter) delimit(i int) {
	if i > 0 {
		w.buf.WriteRune(w.opts.Delimiter)
	}
}

func (w *rowWriter) field(s string, first bool) {
	q := string(w.opts.Quote)
	if !w.clipboard {
		if !utf8.ValidString(s) || strings.ContainsRune(s, 0) {
			w.err = errors.New("dataformat: delimited output requires UTF-8 text without NUL")
			return
		}
	}
	if strings.ContainsAny(s, q+string(w.opts.Delimiter)+"\r\n") ||
		(!w.clipboard && (s == w.opts.NullText || first && strings.HasPrefix(s, "\ufeff"))) {
		w.buf.WriteString(q)
		w.buf.WriteString(strings.ReplaceAll(s, q, q+q))
		w.buf.WriteString(q)
		return
	}
	w.buf.WriteString(s)
}

func (w *rowWriter) endLine() {
	if !w.clipboard {
		w.buf.WriteByte('\r')
	}
	w.buf.WriteByte('\n')
}

func (w *rowWriter) flush() error {
	if w.err != nil {
		return w.err
	}
	_, w.err = w.buf.WriteTo(w.dst)
	if w.err != nil {
		w.err = fmt.Errorf("dataformat: write: %w", w.err)
	}
	return w.err
}

func (w *rowWriter) Close(ctx context.Context) error {
	if w.closed || w.err != nil {
		return w.err
	}
	if !w.started {
		return errors.New("dataformat: writer requires columns")
	}
	if err := ctx.Err(); err != nil {
		return fmt.Errorf("dataformat: %w", err)
	}
	w.closed = true
	if w.opts.Format == JSON {
		if w.clipboard && w.hasRows {
			w.buf.WriteByte('\n')
		}
		w.buf.WriteString("]\n")
	}
	return w.flush()
}
