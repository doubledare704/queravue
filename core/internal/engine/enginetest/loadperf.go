package enginetest

import (
	"context"
	"fmt"
	"io"
	"os"
	osexec "os/exec"
	"runtime"
	"strconv"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
)

// LoadPerfEnv opts the bulk load perf tests in.
const LoadPerfEnv = "LOAD_PERF"

// LoadPerfRows is the size of the perf loads.
const LoadPerfRows = 1_000_000

// Perf gates of iteration 13 lane L.
const (
	LoadRSSBudgetMiB    = 60
	LoadPostgresMinRate = 50_000
	LoadMongoMinRate    = 30_000
	rssSampleInterval   = 100 * time.Millisecond
	kibPerMiB           = 1 << 10
)

// SkipUnlessLoadPerf skips t unless LOAD_PERF is set.
func SkipUnlessLoadPerf(t *testing.T) {
	t.Helper()
	if os.Getenv(LoadPerfEnv) == "" {
		t.Skipf("set %s=1 to run the bulk load perf test", LoadPerfEnv)
	}
}

// RSSSampler records the peak resident set size of this process, sampled with
// ps every 100 ms.
type RSSSampler struct {
	baselineMiB float64
	stop        chan struct{}
	done        sync.WaitGroup
	mu          sync.Mutex
	peakMiB     float64
}

// StartRSSSampler collects garbage, takes the baseline and starts sampling.
func StartRSSSampler(t *testing.T) *RSSSampler {
	t.Helper()
	runtime.GC()
	base, err := currentRSSMiB()
	if err != nil {
		t.Fatalf("read rss: %v", err)
	}
	s := &RSSSampler{baselineMiB: base, peakMiB: base, stop: make(chan struct{})}
	s.done.Add(1)
	go s.run()
	return s
}

func (s *RSSSampler) run() {
	defer s.done.Done()
	tick := time.NewTicker(rssSampleInterval)
	defer tick.Stop()
	for {
		select {
		case <-s.stop:
			return
		case <-tick.C:
			if v, err := currentRSSMiB(); err == nil {
				s.mu.Lock()
				s.peakMiB = max(s.peakMiB, v)
				s.mu.Unlock()
			}
		}
	}
}

// Stop ends sampling and returns the baseline and the peak, both in MiB.
func (s *RSSSampler) Stop() (baselineMiB, peakMiB float64) {
	close(s.stop)
	s.done.Wait()
	if v, err := currentRSSMiB(); err == nil {
		s.peakMiB = max(s.peakMiB, v)
	}
	return s.baselineMiB, s.peakMiB
}

func currentRSSMiB() (float64, error) {
	out, err := osexec.Command("ps", "-o", "rss=", "-p", strconv.Itoa(os.Getpid())).Output() //nolint:gosec // fixed command, own pid
	if err != nil {
		return 0, fmt.Errorf("ps: %w", err)
	}
	kib, err := strconv.ParseFloat(strings.TrimSpace(string(out)), 64)
	if err != nil {
		return 0, fmt.Errorf("parse rss: %w", err)
	}
	return kib / kibPerMiB, nil
}

// RepeatingRowSource yields LoadPerfRows rows by replaying one prebuilt batch,
// so generating the data costs no memory or time during the load.
type RepeatingRowSource struct {
	Batch   [][]engine.Value
	batches int
}

// NewRepeatingRowSource builds a source of total rows from batch.
func NewRepeatingRowSource(batch [][]engine.Value, total int) *RepeatingRowSource {
	return &RepeatingRowSource{Batch: batch, batches: total / len(batch)}
}

// Next implements engine.RowBatchSource.
func (s *RepeatingRowSource) Next(context.Context) ([][]engine.Value, error) {
	if s.batches == 0 {
		return nil, io.EOF
	}
	s.batches--
	return s.Batch, nil
}

// RepeatingDocumentSource is RepeatingRowSource for documents.
type RepeatingDocumentSource struct {
	Batch   []engine.Document
	batches int
}

// NewRepeatingDocumentSource builds a source of total documents from batch.
func NewRepeatingDocumentSource(batch []engine.Document, total int) *RepeatingDocumentSource {
	return &RepeatingDocumentSource{Batch: batch, batches: total / len(batch)}
}

// Next implements engine.DocumentBatchSource.
func (s *RepeatingDocumentSource) Next(context.Context) ([]engine.Document, error) {
	if s.batches == 0 {
		return nil, io.EOF
	}
	s.batches--
	return s.Batch, nil
}

// PerfRowBatch builds the batch the row loader perf tests replay: rows of
// about 100 bytes with a bigint, text, decimal, timestamp, boolean and text.
func PerfRowBatch(rows int) [][]engine.Value {
	stamp := time.Date(2024, 2, 29, 12, 0, 0, 0, time.UTC)
	out := make([][]engine.Value, rows)
	for i := range out {
		out[i] = []engine.Value{
			engine.Int(int64(i)), engine.Text(fmt.Sprintf("customer %d", i)), engine.Decimal(fmt.Sprintf("%d.%02d", i, i%100)),
			engine.Timestamptz(stamp.Add(time.Duration(i) * time.Second)), engine.Bool(i%2 == 0),
			engine.Text("a payload of about forty characters"),
		}
	}
	return out
}

// PerfColumns names the columns of PerfRowBatch.
var PerfColumns = []string{"id", "name", "amount", "created", "active", "payload"}

// RowLoadPerf is one 1M-row load measurement.
type RowLoadPerf struct {
	Conn   engine.Conn
	Target engine.LoadTarget
	// Qualified is the table name as raw SQL; CreateSQL holds {table} for it.
	Qualified, CreateSQL string
	Batch                [][]engine.Value
}

// MeasureRowLoad loads LoadPerfRows rows by replaying Batch, logs time, rate
// and RSS, checks the row count on the server and the RSS budget.
func MeasureRowLoad(t *testing.T, p RowLoadPerf) {
	t.Helper()
	loader, ok := engine.As[engine.RowLoader](p.Conn)
	if !ok {
		t.Fatal("connection is not a RowLoader")
	}
	exec(t, p.Conn, "DROP TABLE IF EXISTS "+p.Qualified)
	exec(t, p.Conn, strings.ReplaceAll(p.CreateSQL, "{table}", p.Qualified))
	t.Cleanup(func() { exec(t, p.Conn, "DROP TABLE IF EXISTS "+p.Qualified) })

	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Minute)
	defer cancel()
	src := NewRepeatingRowSource(p.Batch, LoadPerfRows)
	sampler := StartRSSSampler(t)
	start := time.Now()
	stats, err := loader.LoadRows(ctx, p.Target, PerfColumns, src)
	elapsed := time.Since(start)
	baseline, peak := sampler.Stop()
	if err != nil {
		t.Fatal(err)
	}
	t.Logf("%d rows in %d batches, %.2fs, %.0f rows/s, RSS baseline %.1f MiB, peak %.1f MiB (+%.1f)",
		stats.Rows, stats.Batches, elapsed.Seconds(), float64(stats.Rows)/elapsed.Seconds(), baseline, peak, peak-baseline)
	col, _ := exec(t, p.Conn, "SELECT COUNT(*) FROM "+p.Qualified)
	if n := countCell(t, col.rows[0][0]); n != LoadPerfRows {
		t.Errorf("%d rows stored, want %d", n, LoadPerfRows)
	}
	if peak > baseline+LoadRSSBudgetMiB {
		t.Errorf("RSS peak %.1f MiB exceeds baseline %.1f + %d MiB", peak, baseline, LoadRSSBudgetMiB)
	}
}
