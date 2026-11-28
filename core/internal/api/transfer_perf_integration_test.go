//go:build integration

package api_test

import (
	"context"
	"fmt"
	"io"
	"io/fs"
	"path/filepath"
	"sync"
	"testing"
	"time"

	"google.golang.org/grpc"

	"github.com/doubledare704/queravue/core/internal/api"
	"github.com/doubledare704/queravue/core/internal/engine/enginetest"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

const (
	perfImportBytes = 1 << 30
	perfExportRows  = 1_000_000

	// DuckDB costs about 23 MiB of resident memory the first time a transfer loads it, on top of the shared budget.
	parquetRSSAllowanceMiB = 25
)

// csvGenerator produces CSV rows on demand, so a 1 GiB file never exists in memory.
type csvGenerator struct {
	next, written int
	pending       []byte
}

func (g *csvGenerator) Read(p []byte) (int, error) {
	for len(g.pending) == 0 {
		if g.written >= perfImportBytes {
			return 0, io.EOF
		}
		g.pending = g.pending[:0]
		if g.next == 0 {
			g.pending = append(g.pending, "id,name,amount,created,active,payload\n"...)
		}
		for len(g.pending) < 64<<10 && g.written+len(g.pending) < perfImportBytes {
			g.next++
			g.pending = fmt.Appendf(g.pending, "%d,customer %d,%d.%02d,2024-02-29T12:00:00Z,%t,a payload of about forty characters\n", g.next, g.next, g.next%100000, g.next%100, g.next%2 == 0)
		}
		g.written += len(g.pending)
	}
	n := copy(p, g.pending)
	g.pending = g.pending[n:]
	return n, nil
}

type generatedImportStream struct {
	grpc.ServerStream
	header  *queravuev1.ImportRequest
	source  io.Reader
	sentHdr bool
	lastMsg *queravuev1.ImportSummary
	err     *queravuev1.TransferError
	mu      sync.Mutex
}

func (s *generatedImportStream) Context() context.Context { return context.Background() }

func (s *generatedImportStream) Recv() (*queravuev1.ImportRequest, error) {
	if !s.sentHdr {
		s.sentHdr = true
		return s.header, nil
	}
	buf := make([]byte, 1<<20)
	n, err := io.ReadFull(s.source, buf)
	if n == 0 {
		return nil, io.EOF
	}
	if err != nil && err != io.ErrUnexpectedEOF {
		return nil, err
	}
	return &queravuev1.ImportRequest{Message: &queravuev1.ImportRequest_Chunk{Chunk: buf[:n]}}, nil
}

func (s *generatedImportStream) Send(m *queravuev1.ImportResponse) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	switch e := m.GetEvent().(type) {
	case *queravuev1.ImportResponse_Summary:
		s.lastMsg = e.Summary
	case *queravuev1.ImportResponse_Error:
		s.err = e.Error
	}
	return nil
}

// LOAD_PERF=1 go test -tags=integration -run TestIntegrationPerfImport1GiB -v -timeout 30m ./internal/api/
func TestIntegrationPerfImport1GiBCSVIntoPostgres(t *testing.T) {
	enginetest.SkipUnlessLoadPerf(t)
	tg := sqlTargets()[0]
	conn := tg.open(t)
	env := newXferEnv(t, conn, false)
	table := qualify(tg, conn, "qv_xfer_perf_import")
	run(t, conn, "DROP TABLE IF EXISTS "+table)
	run(t, conn, fmt.Sprintf("CREATE TABLE %s (id bigint, name text, amount numeric(14,2), created timestamptz, active boolean, payload text)", table))
	t.Cleanup(func() { run(t, conn, "DROP TABLE IF EXISTS "+table) })

	s := &generatedImportStream{source: &csvGenerator{}, header: &queravuev1.ImportRequest{Message: &queravuev1.ImportRequest_Header{Header: &queravuev1.ImportHeader{
		SessionId: env.session.ID, Format: queravuev1.TransferFormat_TRANSFER_FORMAT_CSV, FormatOptions: csvOptions(true),
		Target: &queravuev1.ImportHeader_ExistingTable{ExistingTable: &queravuev1.TableRef{Schema: "public", Table: "qv_xfer_perf_import"}},
	}}}}
	sampler := enginetest.StartRSSSampler(t)
	start := time.Now()
	if err := env.svc.Import(s); err != nil {
		t.Fatal(err)
	}
	elapsed := time.Since(start)
	baseline, peak := sampler.Stop()
	if s.err != nil {
		t.Fatalf("import error: %v", s.err)
	}
	rows := s.lastMsg.GetRowsCommitted()
	t.Logf("import 1 GiB CSV into postgres: %d rows in %.1fs (%.0f rows/s, %.1f MiB/s), RSS baseline %.1f MiB, peak %.1f MiB (+%.1f)",
		rows, elapsed.Seconds(), float64(rows)/elapsed.Seconds(), 1024/elapsed.Seconds(), baseline, peak, peak-baseline)
	if counted := run(t, conn, "SELECT COUNT(*) FROM "+table).rows[0][0].Int; uint64(counted) != rows {
		t.Errorf("table holds %d rows, import reported %d", counted, rows)
	}
	if peak-baseline > enginetest.LoadRSSBudgetMiB {
		t.Errorf("RSS peak grew %.1f MiB, budget %d MiB", peak-baseline, enginetest.LoadRSSBudgetMiB)
	}
}

type discardExport struct {
	grpc.ServerStream
	bytes uint64
	rows  uint64
}

func (d *discardExport) Context() context.Context { return context.Background() }

func (d *discardExport) Send(m *queravuev1.ExportTableResponse) error {
	switch e := m.GetEvent().GetEvent().(type) {
	case *queravuev1.ExportEvent_Chunk:
		d.bytes += uint64(len(e.Chunk))
	case *queravuev1.ExportEvent_Summary:
		d.rows = e.Summary.GetRows()
	case *queravuev1.ExportEvent_Error:
		return fmt.Errorf("export error: %s", e.Error.GetMessage())
	}
	return nil
}

func dirBytes(dir string) int64 {
	var total int64
	_ = filepath.WalkDir(dir, func(_ string, d fs.DirEntry, err error) error {
		if err == nil && !d.IsDir() {
			if info, err := d.Info(); err == nil {
				total += info.Size()
			}
		}
		return nil
	})
	return total
}

// LOAD_PERF=1 go test -tags=integration,duckdb -run TestIntegrationPerfExport1MRows -v -timeout 30m ./internal/api/
func TestIntegrationPerfExport1MRowsToEveryFormat(t *testing.T) {
	enginetest.SkipUnlessLoadPerf(t)
	tg := sqlTargets()[0]
	conn := tg.open(t)
	env := newXferEnv(t, conn, false)
	table := qualify(tg, conn, "qv_xfer_perf_export")
	run(t, conn, "DROP TABLE IF EXISTS "+table)
	run(t, conn, fmt.Sprintf("CREATE TABLE %s (id bigint, name text, amount numeric(14,2), created timestamptz, active boolean, payload text)", table))
	t.Cleanup(func() { run(t, conn, "DROP TABLE IF EXISTS "+table) })
	run(t, conn, fmt.Sprintf(`INSERT INTO %s SELECT g, 'customer ' || g, (g %% 100000) + (g %% 100) / 100.0, timestamptz '2024-02-29 12:00:00+00' + g * interval '1 second', g %% 2 = 0, 'a payload of about forty characters' FROM generate_series(1, %d) g`, table, perfExportRows))

	formats := map[string]queravuev1.TransferFormat{
		"csv": queravuev1.TransferFormat_TRANSFER_FORMAT_CSV, "ndjson": queravuev1.TransferFormat_TRANSFER_FORMAT_NDJSON,
		"sql": queravuev1.TransferFormat_TRANSFER_FORMAT_SQL, "parquet": queravuev1.TransferFormat_TRANSFER_FORMAT_PARQUET,
	}
	for _, name := range []string{"csv", "ndjson", "sql", "parquet"} {
		t.Run(name, func(t *testing.T) {
			if name == "parquet" && !hasFormat(env, queravuev1.TransferFormat_TRANSFER_FORMAT_PARQUET) {
				t.Skip("this build has no DuckDB (use -tags=integration,duckdb)")
			}
			sink := &discardExport{}
			var spoolPeak int64
			stop := make(chan struct{})
			var watcher sync.WaitGroup
			watcher.Add(1)
			go func() {
				defer watcher.Done()
				tick := time.NewTicker(100 * time.Millisecond)
				defer tick.Stop()
				for {
					select {
					case <-stop:
						return
					case <-tick.C:
						spoolPeak = max(spoolPeak, dirBytes(env.results.Dir()))
					}
				}
			}()
			sampler := enginetest.StartRSSSampler(t)
			start := time.Now()
			err := env.svc.ExportTable(&queravuev1.ExportTableRequest{
				SessionId: env.session.ID, Table: &queravuev1.TableRef{Schema: "public", Table: "qv_xfer_perf_export"},
				Options: &queravuev1.ExportOptions{Format: formats[name], FormatOptions: csvOptions(true)},
			}, sink)
			elapsed := time.Since(start)
			baseline, peak := sampler.Stop()
			close(stop)
			watcher.Wait()
			if err != nil {
				t.Fatal(err)
			}
			t.Logf("export %d rows to %s: %.1fs (%.0f rows/s), %.1f MiB, RSS baseline %.1f MiB, peak %.1f MiB (+%.1f), spool peak %.1f MiB, duckdb memory_limit %s",
				sink.rows, name, elapsed.Seconds(), float64(sink.rows)/elapsed.Seconds(), float64(sink.bytes)/(1<<20), baseline, peak, peak-baseline, float64(spoolPeak)/(1<<20), api.ParquetMemoryLimit)
			if sink.rows != perfExportRows {
				t.Errorf("%d rows exported", sink.rows)
			}
			budget := float64(enginetest.LoadRSSBudgetMiB)
			if name == "parquet" {
				budget += parquetRSSAllowanceMiB
			}
			if peak-baseline > budget {
				t.Errorf("RSS peak grew %.1f MiB, budget %.0f MiB", peak-baseline, budget)
			}
		})
	}
}

func hasFormat(env *xferEnv, f queravuev1.TransferFormat) bool {
	resp, _ := env.svc.ListFormats(context.Background(), &queravuev1.ListFormatsRequest{})
	for _, got := range resp.GetExportFormats() {
		if got == f {
			return true
		}
	}
	return false
}
