package dataformat

import (
	"bytes"
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/mongo"
)

// DocumentReader yields canonical engine documents for either input flavor.
type DocumentReader struct {
	batchReader[engine.Document]
}

// NewDocumentReader accepts relaxed EJSON unless canonical input is required.
func NewDocumentReader(ctx context.Context, src io.Reader, opts Options, canonical bool) (*DocumentReader, error) {
	if err := documentOptions(&opts); err != nil {
		return nil, err
	}
	in, err := openInput(ctx, src)
	if err != nil {
		return nil, err
	}
	frames := jsonFrames{input: in, opts: opts}
	r := &DocumentReader{}
	r.maxBytes = opts.MaxBytes
	r.read = func(ctx context.Context) (engine.Document, int, error) {
		data, start, err := frames.next(ctx)
		if err != nil {
			return "", 0, err
		}
		if trimmed := bytes.Trim(data, " \r\n\t"); len(trimmed) == 0 || trimmed[0] != '{' {
			return "", 0, start.failure(errors.New("expected EJSON object"))
		}
		var checked json.RawMessage
		if err := json.Unmarshal(data, &checked); err != nil {
			return "", 0, jsonError(start, data, fmt.Errorf("decode EJSON document: %w", err))
		}
		text, err := mongo.TranscodeEJSON(string(checked), canonical, true)
		if err != nil {
			return "", 0, start.failure(fmt.Errorf("decode EJSON document: %w", err))
		}
		size := max(len(data), len(text)) + 16
		if size > opts.MaxBytes {
			return "", 0, start.failure(errRecordSize)
		}
		return text, size, nil
	}
	return r, nil
}

func documentOptions(opts *Options) error {
	if opts.Format != JSON && opts.Format != NDJSON {
		return errors.New("dataformat: document format must be JSON or NDJSON")
	}
	return opts.normalize()
}

// DocumentWriter transcodes documents to the requested export flavor.
type DocumentWriter struct {
	dst                                 io.Writer
	opts                                Options
	canonical, started, hasRows, closed bool
	err                                 error
}

// NewDocumentWriter accepts canonical or relaxed document input.
func NewDocumentWriter(dst io.Writer, opts Options, canonical bool) (*DocumentWriter, error) {
	if err := documentOptions(&opts); err != nil {
		return nil, err
	}
	return &DocumentWriter{dst: dst, opts: opts, canonical: canonical}, nil
}

// Batch emits complete documents without retaining the supplied slice.
func (w *DocumentWriter) Batch(ctx context.Context, docs []engine.Document) error {
	if w.closed {
		return errors.New("dataformat: document writer closed")
	}
	for _, doc := range docs {
		if err := ctx.Err(); err != nil {
			return fmt.Errorf("dataformat: %w", err)
		}
		if w.err != nil {
			return w.err
		}
		if len(doc) > w.opts.MaxBytes {
			return errRecordSize
		}
		if !json.Valid([]byte(doc)) {
			return errors.New("dataformat: invalid EJSON document")
		}
		text, err := mongo.TranscodeEJSON(doc, false, w.canonical)
		if err != nil {
			return fmt.Errorf("encode EJSON document: %w", err)
		}
		if len(text)+16 > w.opts.MaxBytes {
			return errRecordSize
		}
		if w.opts.Format == JSON {
			if err := w.begin(); err != nil {
				return err
			}
			if w.hasRows {
				w.write(",")
			}
		}
		w.write(text)
		if w.opts.Format == NDJSON {
			w.write("\n")
		}
		if w.err != nil {
			return w.err
		}
		w.hasRows = true
	}
	return w.err
}

func (w *DocumentWriter) begin() error {
	if !w.started && w.opts.Format == JSON {
		w.write("[")
		w.started = true
	}
	return w.err
}

// Close finishes the array, including when no documents were supplied.
func (w *DocumentWriter) Close(ctx context.Context) error {
	if w.closed || w.err != nil {
		return w.err
	}
	if err := ctx.Err(); err != nil {
		return fmt.Errorf("dataformat: %w", err)
	}
	w.closed = true
	if w.opts.Format == JSON {
		_ = w.begin()
		w.write("]\n")
	}
	return w.err
}

func (w *DocumentWriter) write(text string) {
	if w.err == nil {
		w.err = writeString(w.dst, text)
	}
}

func writeString(dst io.Writer, s string) error {
	n, err := io.WriteString(dst, s)
	if err != nil {
		return fmt.Errorf("dataformat: write: %w", err)
	}
	if n != len(s) {
		return fmt.Errorf("dataformat: write: %w", io.ErrShortWrite)
	}
	return nil
}
