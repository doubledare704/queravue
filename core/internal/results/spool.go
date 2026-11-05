// Package results spools query results to disk in fixed-size pages, so the
// UI can read any window of a result in O(1) while core memory stays bounded.
package results

import (
	"errors"
	"fmt"
	"os"
	"sync"

	"google.golang.org/protobuf/proto"

	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

// PageRows is the number of rows per spool page.
const PageRows = 500

// DefaultCap is the default spool size cap per result.
const DefaultCap int64 = 2 << 30

var (
	// ErrFull is returned by Append once the size cap is reached. The result
	// is then marked truncated and the caller should stop reading.
	ErrFull = errors.New("results: spool size cap reached")
	// ErrClosed is returned for operations on a closed spool.
	ErrClosed = errors.New("results: closed")
)

type page struct {
	off int64
	n   int32
}

// Spool holds one result. One goroutine appends; any number read.
type Spool struct {
	path string
	cap  int64

	mu        sync.RWMutex
	f         *os.File
	pages     []page // one entry per full or flushed page
	size      int64  // bytes written
	flushed   uint64 // rows in flushed pages
	pending   []*queravuev1.Row
	columns   []*queravuev1.Column
	done      bool
	truncated bool
}

// newSpool creates the spool file at path.
func newSpool(path string, capBytes int64) (*Spool, error) {
	f, err := os.OpenFile(path, os.O_RDWR|os.O_CREATE|os.O_EXCL, 0o600) //nolint:gosec // path is built by Manager from a UUID
	if err != nil {
		return nil, fmt.Errorf("results: create spool: %w", err)
	}
	if capBytes <= 0 {
		capBytes = DefaultCap
	}
	return &Spool{path: path, cap: capBytes, f: f}, nil
}

// SetColumns records the result's columns (used by CopyRange).
func (s *Spool) SetColumns(cols []*queravuev1.Column) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.columns = cols
}

// Columns returns the recorded columns.
func (s *Spool) Columns() []*queravuev1.Column {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.columns
}

// Append adds rows. Rows are buffered until a page is full. It returns
// ErrFull when the size cap is reached; rows appended before that stay.
func (s *Spool) Append(rows []*queravuev1.Row) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.f == nil {
		return ErrClosed
	}
	for _, r := range rows {
		if s.truncated {
			return ErrFull
		}
		s.pending = append(s.pending, r)
		if len(s.pending) == PageRows {
			if err := s.flushLocked(); err != nil {
				return err
			}
			if s.size >= s.cap {
				s.truncated = true
				return ErrFull
			}
		}
	}
	return nil
}

// flushLocked writes the pending rows as one page.
func (s *Spool) flushLocked() error {
	if len(s.pending) == 0 {
		return nil
	}
	b, err := proto.Marshal(&queravuev1.RowBatch{Rows: s.pending})
	if err != nil {
		return fmt.Errorf("results: encode page: %w", err)
	}
	if _, err := s.f.WriteAt(b, s.size); err != nil {
		return fmt.Errorf("results: write page: %w", err)
	}
	s.pages = append(s.pages, page{off: s.size, n: int32(len(b))}) //nolint:gosec // a page of 500 rows is far below 2 GiB
	s.size += int64(len(b))
	s.flushed += uint64(len(s.pending))
	s.pending = s.pending[:0]
	return nil
}

// Finish flushes the last partial page and marks the spool complete.
func (s *Spool) Finish() error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.f == nil {
		return ErrClosed
	}
	s.done = true
	return s.flushLocked()
}

// Total returns the rows readable now.
func (s *Spool) Total() uint64 {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.flushed + uint64(len(s.pending))
}

// State returns rows readable, whether the result is complete and whether it
// was truncated at the size cap.
func (s *Spool) State() (rows uint64, done, truncated bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.flushed + uint64(len(s.pending)), s.done || s.truncated, s.truncated
}

// Size returns the bytes written to disk.
func (s *Spool) Size() int64 {
	s.mu.RLock()
	defer s.mu.RUnlock()
	return s.size
}

// ReadRows returns up to limit rows starting at offset; fewer at the end of
// what is spooled so far. Each call reads at most ceil(limit/PageRows)+1
// pages, independent of offset.
func (s *Spool) ReadRows(offset uint64, limit int) ([]*queravuev1.Row, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()
	if s.f == nil {
		return nil, ErrClosed
	}
	total := s.flushed + uint64(len(s.pending))
	if limit <= 0 || offset >= total {
		return nil, nil
	}
	end := min(offset+uint64(limit), total)
	out := make([]*queravuev1.Row, 0, end-offset)
	for pos := offset; pos < end; {
		pi := int(pos / PageRows) //nolint:gosec // page index fits int
		var rows []*queravuev1.Row
		if pi < len(s.pages) {
			p := s.pages[pi]
			buf := make([]byte, p.n)
			if _, err := s.f.ReadAt(buf, p.off); err != nil {
				return nil, fmt.Errorf("results: read page %d: %w", pi, err)
			}
			var batch queravuev1.RowBatch
			if err := proto.Unmarshal(buf, &batch); err != nil {
				return nil, fmt.Errorf("results: decode page %d: %w", pi, err)
			}
			rows = batch.Rows
		} else {
			rows = s.pending
		}
		from := int(pos - uint64(pi)*PageRows)  //nolint:gosec // < PageRows
		to := min(len(rows), from+int(end-pos)) //nolint:gosec // end-pos <= limit
		out = append(out, rows[from:to]...)
		pos += uint64(to - from) //nolint:gosec // to >= from

		if to == from {
			break
		}
	}
	return out, nil
}

// Close deletes the spool file. It is safe to call more than once.
func (s *Spool) Close() error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.f == nil {
		return nil
	}
	err := s.f.Close()
	s.f = nil
	s.pending = nil
	s.pages = nil
	if rerr := os.Remove(s.path); rerr != nil && !errors.Is(rerr, os.ErrNotExist) && err == nil {
		err = rerr
	}
	return err
}
