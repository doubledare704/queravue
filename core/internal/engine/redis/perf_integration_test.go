//go:build integration

package redis

import (
	"context"
	"os"
	"os/exec"
	"runtime"
	"runtime/debug"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func rssMB(t *testing.T) float64 {
	t.Helper()
	out, err := exec.Command("ps", "-o", "rss=", "-p", strconv.Itoa(os.Getpid())).Output()
	if err != nil {
		t.Fatal(err)
	}
	kb, err := strconv.Atoi(strings.TrimSpace(string(out)))
	if err != nil {
		t.Fatal(err)
	}
	return float64(kb) / 1024
}

func TestIntegrationPerfIdleAndScanMemory(t *testing.T) {
	if os.Getenv("REDIS_PERF") == "" {
		t.Skip("set REDIS_PERF=1 to measure")
	}
	runtime.GC()
	before := rssMB(t)
	c := connect(t, redisTarget())
	kv, _ := engine.As[engine.KeyValueStore](c)
	if err := c.Ping(context.Background()); err != nil {
		t.Fatal(err)
	}
	time.Sleep(2 * time.Second)
	runtime.GC()
	debug.FreeOSMemory()
	idle := rssMB(t)

	peak := idle
	var keys, pages int
	start := time.Now()
	err := kv.ScanKeys(context.Background(), engine.ScanOptions{Pattern: "scan:*"}, func(p engine.ScanPage) error {
		keys += len(p.Keys)
		if pages++; pages%100 == 0 {
			peak = max(peak, rssMB(t))
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	scanTime := time.Since(start)

	start = time.Now()
	entries := 0
	for cursor := ""; ; {
		p, err := kv.ReadValue(context.Background(), engine.ReadOptions{Key: []byte("big:hash"), Cursor: cursor, PageSize: 1000})
		if err != nil {
			t.Fatal(err)
		}
		entries += len(p.Hash)
		if cursor = p.NextCursor; cursor == "" {
			break
		}
	}
	hashTime := time.Since(start)

	start = time.Now()
	if _, err := kv.KeyInfo(context.Background(), 0, []byte("big:hash")); err != nil {
		t.Fatal(err)
	}
	infoTime := time.Since(start)
	t.Logf("RSS before open %.1f MB, session open and idle %.1f MB, peak during the scan %.1f MB", before, idle, peak)
	t.Logf("SCAN of %d keys in %d pages: %s; HSCAN of %d entries: %s; GetKeyInfo of the 100k hash: %s",
		keys, pages, scanTime.Round(time.Millisecond), entries, hashTime.Round(time.Millisecond), infoTime.Round(time.Millisecond))
}
