package completion

import (
	"context"
	"errors"
	"sync"
	"sync/atomic"
	"testing"
	"time"
)

func newTestCache() (*ttlCache[string, int], *time.Time) {
	c := newTTLCache[string, int](time.Minute)
	now := time.Unix(1000, 0)
	c.now = func() time.Time { return now }
	return c, &now
}

func TestTTLCacheServesFreshEntriesAndExpiresThem(t *testing.T) {
	c, now := newTestCache()
	var runs atomic.Int32
	compute := func(context.Context) (int, error) { return int(runs.Add(1)), nil }
	for want := 1; want <= 2; want++ {
		v, err := c.get(context.Background(), "s", "k", false, compute)
		if err != nil || v != 1 {
			t.Fatalf("get #%d = %d, %v; want cached 1", want, v, err)
		}
	}
	*now = now.Add(2 * time.Minute)
	if v, _ := c.get(context.Background(), "s", "k", false, compute); v != 2 {
		t.Errorf("after the TTL got %d, want a fresh run", v)
	}
}

func TestTTLCacheRefreshAndInvalidate(t *testing.T) {
	c, _ := newTestCache()
	var runs atomic.Int32
	compute := func(context.Context) (int, error) { return int(runs.Add(1)), nil }
	c.get(context.Background(), "s", "k", false, compute) //nolint:errcheck // value checked below
	if v, _ := c.get(context.Background(), "s", "k", true, compute); v != 2 {
		t.Errorf("refresh got %d, want 2", v)
	}
	c.invalidate("s")
	if v, _ := c.get(context.Background(), "s", "k", false, compute); v != 3 {
		t.Errorf("after invalidate got %d, want 3", v)
	}
	if v, _ := c.get(context.Background(), "other", "k", false, compute); v != 4 {
		t.Errorf("other session got %d, want its own run", v)
	}
}

func TestTTLCacheDoesNotKeepErrors(t *testing.T) {
	c, _ := newTestCache()
	var runs atomic.Int32
	boom := errors.New("boom")
	failing := func(context.Context) (int, error) { runs.Add(1); return 0, boom }
	if _, err := c.get(context.Background(), "s", "k", false, failing); !errors.Is(err, boom) {
		t.Fatalf("err = %v", err)
	}
	ok := func(context.Context) (int, error) { return 7, nil }
	if v, err := c.get(context.Background(), "s", "k", false, ok); err != nil || v != 7 {
		t.Errorf("after an error got %d, %v; want a fresh run", v, err)
	}
}

func TestTTLCacheSharesOneRunBetweenConcurrentCallers(t *testing.T) {
	c, _ := newTestCache()
	var runs atomic.Int32
	release := make(chan struct{})
	compute := func(context.Context) (int, error) {
		runs.Add(1)
		<-release
		return 5, nil
	}
	var wg sync.WaitGroup
	results := make([]int, 4)
	for i := range results {
		wg.Add(1)
		go func() {
			defer wg.Done()
			results[i], _ = c.get(context.Background(), "s", "k", false, compute)
		}()
	}
	time.Sleep(50 * time.Millisecond)
	close(release)
	wg.Wait()
	if n := runs.Load(); n != 1 {
		t.Errorf("ran %d times, want 1", n)
	}
	for _, r := range results {
		if r != 5 {
			t.Errorf("results = %v", results)
		}
	}
}

func TestTTLCacheWaiterGivesUpButTheRunFinishesInTheBackground(t *testing.T) {
	c, _ := newTestCache()
	release := make(chan struct{})
	compute := func(context.Context) (int, error) {
		<-release
		return 9, nil
	}
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Millisecond)
	defer cancel()
	if _, err := c.get(ctx, "s", "k", false, compute); !errors.Is(err, context.DeadlineExceeded) {
		t.Fatalf("err = %v, want deadline exceeded", err)
	}
	close(release)
	deadline := time.Now().Add(2 * time.Second)
	for {
		v, err := c.get(context.Background(), "s", "k", false, func(context.Context) (int, error) { return -1, nil })
		if err == nil && v == 9 {
			return
		}
		if time.Now().After(deadline) {
			t.Fatalf("background result never became available: %d, %v", v, err)
		}
		time.Sleep(5 * time.Millisecond)
	}
}
