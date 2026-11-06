package history_test

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/history"
)

func TestStore_CapAndSearch(t *testing.T) {
	ctx := context.Background()
	// Create store with small cap = 5
	store, err := history.NewStore(":memory:", 5, nil)
	if err != nil {
		t.Fatalf("new store: %v", err)
	}
	defer func() { _ = store.Close() }()

	// Insert 10 entries
	now := time.Now()
	for i := 1; i <= 10; i++ {
		_, err := store.Append(ctx, history.Entry{
			ConnectionID: "conn-1",
			QueryText:    fmt.Sprintf("SELECT %d;", i),
			StartedAt:    now.Add(time.Duration(i) * time.Minute),
			Duration:     10 * time.Millisecond,
			RowsAffected: uint64(i),
		})
		if err != nil {
			t.Fatalf("append %d: %v", i, err)
		}
	}

	// List without filters - should be capped at 5
	entries, total, err := store.List(ctx, "", "", 100, 0)
	if err != nil {
		t.Fatalf("list: %v", err)
	}

	if total != 5 {
		t.Errorf("total count = %d, want 5 (capped)", total)
	}
	if len(entries) != 5 {
		t.Fatalf("got %d entries, want 5", len(entries))
	}

	// Should be the newest 5 (entries 10 down to 6)
	if entries[0].QueryText != "SELECT 10;" {
		t.Errorf("entries[0] = %q, want SELECT 10;", entries[0].QueryText)
	}
	if entries[4].QueryText != "SELECT 6;" {
		t.Errorf("entries[4] = %q, want SELECT 6;", entries[4].QueryText)
	}

	// Search filter
	searchEntries, searchTotal, err := store.List(ctx, "", "SELECT 9", 10, 0)
	if err != nil {
		t.Fatalf("search: %v", err)
	}
	if searchTotal != 1 || len(searchEntries) != 1 || searchEntries[0].QueryText != "SELECT 9;" {
		t.Errorf("search unexpected result: %+v", searchEntries)
	}

	// Clear
	if err := store.Clear(ctx, "conn-1"); err != nil {
		t.Fatalf("clear: %v", err)
	}

	entriesAfterClear, totalAfterClear, err := store.List(ctx, "", "", 10, 0)
	if err != nil {
		t.Fatalf("list after clear: %v", err)
	}
	if totalAfterClear != 0 || len(entriesAfterClear) != 0 {
		t.Errorf("expected 0 entries after clear, got %d", totalAfterClear)
	}
}
