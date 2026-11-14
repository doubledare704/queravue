//go:build duckdb && (darwin || linux)

package duckdb

import (
	"context"
	"os"
	"os/exec"
	"runtime"
	"strconv"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
)

// The measurements recorded in docs/perf/iteration-10.md, run with DUCKDB_PERF=1.
func residentMB() float64 {
	out, err := exec.Command("ps", "-o", "rss=", "-p", strconv.Itoa(os.Getpid())).Output()
	if err != nil {
		return -1
	}
	kb, _ := strconv.Atoi(strings.TrimSpace(string(out)))
	return float64(kb) / 1024
}

type rssSampler struct{ peak atomic.Uint64 }

func (s *rssSampler) run(stop <-chan struct{}) {
	for {
		s.peak.Store(max(s.peak.Load(), uint64(residentMB()*1024)))
		select {
		case <-stop:
			return
		case <-time.After(20 * time.Millisecond):
		}
	}
}

func (s *rssSampler) peakMB() float64 { return float64(s.peak.Load()) / 1024 }

type countingSink struct {
	rows     int64
	heapPeak uint64
}

func (c *countingSink) Columns([]engine.Column) error { return nil }
func (c *countingSink) Batch(rows [][]engine.Value) error {
	c.rows += int64(len(rows))
	if c.rows%(20*engine.MaxBatchRows) == 0 {
		var m runtime.MemStats
		runtime.ReadMemStats(&m)
		c.heapPeak = max(c.heapPeak, m.HeapAlloc)
	}
	return nil
}

// DUCKDB_PERF_FILE reuses a seeded file, so a second run measures a process
// that only opened it.
func perfConn(t *testing.T) engine.Conn {
	path := os.Getenv("DUCKDB_PERF_FILE")
	if _, err := os.Stat(path); path != "" && err == nil {
		return connectTo(t, map[string]string{ParamPath: path})
	}
	seededPath, c := seededFile(t)
	if path != "" {
		_ = c.Close()
		if err := os.Rename(seededPath, path); err != nil {
			t.Fatal(err)
		}
		return connectTo(t, map[string]string{ParamPath: path})
	}
	return c
}

func TestPerfStreamAndIdleMemory(t *testing.T) {
	if os.Getenv("DUCKDB_PERF") != "1" {
		t.Skip("set DUCKDB_PERF=1 to run the DuckDB measurements")
	}
	runtime.GC()
	t.Logf("PERF resident before opening: %.1f MB", residentMB())
	c := perfConn(t)
	time.Sleep(2 * time.Second)
	runtime.GC()
	var m runtime.MemStats
	runtime.ReadMemStats(&m)
	t.Logf("PERF resident with a seeded 1M-row file open and idle: %.1f MB, Go heap %d MB", residentMB(), m.HeapAlloc>>20)

	ex, _ := engine.As[engine.Executor](c)
	for _, tc := range []struct{ name, sql string }{
		{"1M rows x 3 columns (million_items)", "SELECT id, val, payload FROM million_items"},
		{"1M rows, one INTEGER column", "SELECT i FROM range(1000000) t(i)"},
		{"10M rows x 2 columns", "SELECT i, 'row-' || i::VARCHAR FROM range(10000000) t(i)"},
	} {
		runtime.GC()
		var base runtime.MemStats
		runtime.ReadMemStats(&base)
		sampler := &rssSampler{}
		stop := make(chan struct{})
		done := make(chan struct{})
		go func() { sampler.run(stop); close(done) }()
		sink := &countingSink{}
		sum, err := ex.Execute(context.Background(), engine.Statement{SQL: tc.sql}, sink)
		close(stop)
		<-done
		if err != nil {
			t.Fatal(err)
		}
		runtime.GC()
		t.Logf("PERF %s: %v (%.0f rows/s), Go heap %d MB -> peak %d MB, peak resident %.0f MB, resident after %.0f MB",
			tc.name, sum.Duration.Round(time.Millisecond), float64(sum.RowsRead)/sum.Duration.Seconds(), base.HeapAlloc>>20, sink.heapPeak>>20, sampler.peakMB(), residentMB())
	}

	for _, limit := range []string{"256MB"} {
		limited := connectTo(t, map[string]string{ParamPath: MemoryPath, ParamMemoryLimit: limit})
		lex, _ := engine.As[engine.Executor](limited)
		sampler := &rssSampler{}
		stop := make(chan struct{})
		done := make(chan struct{})
		go func() { sampler.run(stop); close(done) }()
		sink := &countingSink{}
		sum, err := lex.Execute(context.Background(), engine.Statement{SQL: "SELECT i, 'row-' || i::VARCHAR || repeat('x', 40) FROM range(10000000) t(i)"}, sink)
		close(stop)
		<-done
		t.Logf("PERF 10M rows x 2 columns (~600 MB result) with memory_limit=%s: err=%v, %v, peak resident %.0f MB", limit, err, sum.Duration.Round(time.Millisecond), sampler.peakMB())
	}
}
