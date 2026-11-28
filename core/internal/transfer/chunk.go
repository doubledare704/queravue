package transfer

import (
	"errors"
	"fmt"
	"io"
)

// MaxChunkBytes is the largest file chunk sent over gRPC (ADR 0024 §1).
const MaxChunkBytes = 1 << 20

// ChunkWriter groups writes into chunks of at most MaxChunkBytes. emit must not
// keep the slice after it returns.
type ChunkWriter struct {
	emit  func([]byte) error
	buf   []byte
	bytes uint64
}

// NewChunkWriter returns a ChunkWriter that hands full chunks to emit.
func NewChunkWriter(emit func([]byte) error) *ChunkWriter {
	return &ChunkWriter{emit: emit, buf: make([]byte, 0, MaxChunkBytes)}
}

// Write implements io.Writer.
func (w *ChunkWriter) Write(p []byte) (int, error) {
	written := len(p)
	for len(p) > 0 {
		n := min(len(p), MaxChunkBytes-len(w.buf))
		w.buf = append(w.buf, p[:n]...)
		p = p[n:]
		if len(w.buf) == MaxChunkBytes {
			if err := w.Flush(); err != nil {
				return written - len(p), err
			}
		}
	}
	return written, nil
}

// Flush sends the buffered bytes, if any.
func (w *ChunkWriter) Flush() error {
	if len(w.buf) == 0 {
		return nil
	}
	n := len(w.buf)
	err := w.emit(w.buf)
	w.buf = w.buf[:0]
	if err != nil {
		return fmt.Errorf("transfer: send chunk: %w", err)
	}
	w.bytes += uint64(n)
	return nil
}

// Bytes is how many bytes have been sent.
func (w *ChunkWriter) Bytes() uint64 { return w.bytes }

// ChunkReader reads the file bytes of an upload stream, one chunk at a time.
type ChunkReader struct {
	next  func() ([]byte, error)
	buf   []byte
	bytes uint64
}

// NewChunkReader returns a reader over chunks; next returns io.EOF at the end.
func NewChunkReader(next func() ([]byte, error)) *ChunkReader { return &ChunkReader{next: next} }

// Read implements io.Reader.
func (r *ChunkReader) Read(p []byte) (int, error) {
	for len(r.buf) == 0 {
		chunk, err := r.next()
		if err != nil {
			if errors.Is(err, io.EOF) {
				return 0, io.EOF
			}
			return 0, fmt.Errorf("transfer: receive chunk: %w", err)
		}
		if len(chunk) > MaxChunkBytes {
			return 0, newError(KindParse, "a chunk is larger than %d bytes", MaxChunkBytes)
		}
		r.buf = chunk
	}
	n := copy(p, r.buf)
	r.buf = r.buf[n:]
	r.bytes += uint64(n) //nolint:gosec // n is non-negative
	return n, nil
}

// Bytes is how many bytes have been read.
func (r *ChunkReader) Bytes() uint64 { return r.bytes }
