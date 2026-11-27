package dataformat

import (
	"errors"
	"io"
	"runtime"
	"runtime/metrics"
	"strings"
	"testing"
	"time"
)

type repeatingCSV struct {
	row    string
	offset int
}

func (r *repeatingCSV) Read(dst []byte) (int, error) {
	for n := 0; n < len(dst); {
		copied := copy(dst[n:], r.row[r.offset:])
		n += copied
		r.offset = (r.offset + copied) % len(r.row)
	}
	return len(dst), nil
}

func TestReadGiBCSVWithFlatHeap(t *testing.T) {
	if testing.Short() {
		t.Skip("1 GiB streaming measurement")
	}
	const totalBytes = 1 << 30
	const rowBytes = 4096
	src := &repeatingCSV{row: "42," + strings.Repeat("x", rowBytes-4) + "\n"}
	limited := &io.LimitedReader{R: src, N: totalBytes}
	r, err := NewReader(t.Context(), limited, Options{}, nil)
	if err != nil {
		t.Fatal(err)
	}
	samples := []metrics.Sample{{Name: "/gc/heap/live:bytes"}}
	runtime.GC()
	metrics.Read(samples)
	baseline := samples[0].Value.Uint64()
	peak := baseline
	start := time.Now()
	totalRows := 0
	nextSample := 0
	for {
		batch, err := r.Next(t.Context())
		if errors.Is(err, io.EOF) {
			break
		}
		if err != nil {
			t.Fatal(err)
		}
		totalRows += len(batch)
		if totalRows >= nextSample {
			runtime.GC()
			nextSample = totalRows + (8<<20)/rowBytes
		}
		metrics.Read(samples)
		peak = max(peak, samples[0].Value.Uint64())
		runtime.KeepAlive(batch)
	}
	if limited.N != 0 || totalRows != totalBytes/rowBytes {
		t.Fatalf("read %d bytes and %d rows", totalBytes-limited.N, totalRows)
	}
	const mib = 1 << 20
	elapsed := time.Since(start)
	t.Logf("read 1 GiB (%d rows) in %s (%.1f MiB/s); live heap baseline %.2f MiB, peak %.2f MiB, increase %.2f MiB",
		totalRows, elapsed.Round(time.Millisecond), totalBytes/mib/elapsed.Seconds(), float64(baseline)/mib, float64(peak)/mib, float64(peak-baseline)/mib)
	if peak-baseline > 4*mib {
		t.Fatalf("live heap increased by %d bytes, limit %d", peak-baseline, 4*mib)
	}
}
