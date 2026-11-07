//go:build integration

package shell_test

import (
	"context"
	"os"
	"os/exec"
	"runtime"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/shell"
)

// Budgets. The PRD allows +200 MB for a 1M-row result; a forEach retains
// nothing, so its transient peak (garbage between collections) must stay well
// under that and the heap must fall back once it ends.
const (
	idleShellBudget    = 15 << 20
	iteratePeakLimit   = 100 << 20
	iterateRetainLimit = 10 << 20
)

func rssBytes(t *testing.T) uint64 {
	t.Helper()
	out, err := exec.Command("ps", "-o", "rss=", "-p", strconv.Itoa(os.Getpid())).Output()
	if err != nil {
		t.Skipf("ps unavailable: %v", err)
	}
	kb, err := strconv.ParseUint(strings.TrimSpace(string(out)), 10, 64)
	if err != nil {
		t.Skipf("cannot read rss: %v", err)
	}
	return kb << 10
}

func heapInUse() uint64 {
	var m runtime.MemStats
	runtime.GC()
	runtime.GC()
	runtime.ReadMemStats(&m)
	return m.HeapInuse
}

func mib(b uint64) float64 { return float64(b) / (1 << 20) }

func TestIdleMemoryWithShellsOpen(t *testing.T) {
	backend := connect(t)
	ctx := context.Background()
	base, baseRSS := heapInUse(), rssBytes(t)

	var shells []*shell.Shell
	t.Cleanup(func() {
		for _, s := range shells {
			s.Close()
		}
	})
	open := func() {
		s, err := shell.New(backend, shell.Options{Database: "queravue"})
		if err != nil {
			t.Fatal(err)
		}
		tr := &transcript{shell: s, ctx: ctx}
		if _, e := s.Eval(ctx, `db.users.countDocuments()`, false, tr); e != nil {
			t.Fatal(e)
		}
		shells = append(shells, s)
	}

	open()
	one, oneRSS := heapInUse(), rssBytes(t)
	for range 9 {
		open()
	}
	ten, tenRSS := heapInUse(), rssBytes(t)
	time.Sleep(2 * time.Second)
	idle, idleRSS := heapInUse(), rssBytes(t)

	t.Logf("heap in use: base %.1f MiB, 1 shell %.1f MiB (+%.1f), 10 shells %.1f MiB (+%.1f), 10 shells after 2s idle %.1f MiB",
		mib(base), mib(one), mib(one)-mib(base), mib(ten), mib(ten)-mib(base), mib(idle))
	t.Logf("rss: base %.1f MiB, 1 shell %.1f MiB, 10 shells %.1f MiB, idle %.1f MiB", mib(baseRSS), mib(oneRSS), mib(tenRSS), mib(idleRSS))

	if d := int64(one) - int64(base); d > idleShellBudget {
		t.Errorf("one open shell added %.1f MiB of heap, budget %.0f MiB", float64(d)/(1<<20), mib(idleShellBudget))
	}
	if d := int64(ten) - int64(base); d > 10*idleShellBudget {
		t.Errorf("ten open shells added %.1f MiB of heap", float64(d)/(1<<20))
	}
}

// TestForEachMillionDocumentsKeepsMemoryFlat iterates the seeded
// queravue.events collection (`docker compose --profile seed up mongo-seed`).
func TestForEachMillionDocumentsKeepsMemoryFlat(t *testing.T) {
	backend := connect(t)
	ctx := context.Background()
	sh, err := shell.New(backend, shell.Options{Database: "queravue"})
	if err != nil {
		t.Fatal(err)
	}
	defer sh.Close()
	tr := &transcript{shell: sh, ctx: ctx}
	if _, e := sh.Eval(ctx, `db.events.estimatedDocumentCount()`, false, tr); e != nil {
		t.Fatal(e)
	}
	if !strings.Contains(tr.b.String(), `"1000000"`) {
		t.Skipf("queravue.events is not seeded with 1M documents (got %s)", strings.TrimSpace(tr.b.String()))
	}
	tr.b.Reset()

	before, beforeRSS := heapInUse(), rssBytes(t)
	var peakHeap, peakRSS uint64
	stop := make(chan struct{})
	done := make(chan struct{})
	go func() {
		defer close(done)
		for {
			select {
			case <-stop:
				return
			case <-time.After(100 * time.Millisecond):
				var m runtime.MemStats
				runtime.ReadMemStats(&m)
				peakHeap = max(peakHeap, m.HeapInuse)
			}
		}
	}()
	started := time.Now()
	_, evalErr := sh.Eval(ctx, `var n = 0; db.events.find().forEach(function (d) { n++ }); n`, false, tr)
	took := time.Since(started)
	close(stop)
	<-done
	peakRSS = rssBytes(t)
	if evalErr != nil {
		t.Fatal(evalErr)
	}
	if !strings.Contains(tr.b.String(), `"1000000"`) {
		t.Fatalf("iterated the wrong number of documents: %s", tr.b.String())
	}
	after := heapInUse()
	t.Logf("1M documents through forEach in %v: heap before %.1f MiB, peak %.1f MiB, after %.1f MiB; rss before %.1f MiB, after %.1f MiB",
		took.Round(time.Millisecond), mib(before), mib(peakHeap), mib(after), mib(beforeRSS), mib(peakRSS))
	if g := int64(peakHeap) - int64(before); g > iteratePeakLimit {
		t.Errorf("heap peaked %.1f MiB above its start while iterating 1M documents, limit %.0f MiB", float64(g)/(1<<20), mib(iteratePeakLimit))
	}
	if g := int64(after) - int64(before); g > iterateRetainLimit {
		t.Errorf("heap kept %.1f MiB after iterating 1M documents: something is retained", float64(g)/(1<<20))
	}
}
