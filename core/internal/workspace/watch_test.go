package workspace

import (
	"context"
	"os"
	"path/filepath"
	"testing"
	"time"
)

type changes chan Change

func startWatch(t *testing.T, s *Service) changes {
	t.Helper()
	ctx, cancel := context.WithCancel(context.Background())
	out := make(changes, 64)
	done := make(chan struct{})
	go func() {
		defer close(done)
		_ = s.Watch(ctx, nil, func(c Change) error { out <- c; return nil })
	}()
	t.Cleanup(func() { cancel(); <-done })
	time.Sleep(100 * time.Millisecond)
	return out
}

func expect(t *testing.T, ch changes, path string, kind ChangeKind) Change {
	t.Helper()
	deadline := time.After(5 * time.Second)
	for {
		select {
		case c := <-ch:
			if c.Path == path && c.Kind == kind {
				return c
			}
		case <-deadline:
			t.Fatalf("no change %d for %s", kind, path)
		}
	}
}

func expectNothing(t *testing.T, ch changes, within time.Duration) {
	t.Helper()
	select {
	case c := <-ch:
		t.Fatalf("unexpected change %+v", c)
	case <-time.After(within):
	}
}

func TestWatchReportsExternalEdit(t *testing.T) {
	s, root := newTestService(t)
	if _, err := s.Create(DefaultRootID, "a.sql", false, "v1"); err != nil {
		t.Fatal(err)
	}
	ch := startWatch(t, s)
	expectNothing(t, ch, 100*time.Millisecond)
	if err := os.WriteFile(filepath.Join(root, "a.sql"), []byte("edited elsewhere"), 0o644); err != nil {
		t.Fatal(err)
	}
	c := expect(t, ch, "a.sql", ChangeModified)
	if c.RootID != DefaultRootID || c.ModTime.IsZero() {
		t.Fatalf("change = %+v", c)
	}
}

func TestWatchReportsExternalCreateAndDelete(t *testing.T) {
	s, root := newTestService(t)
	ch := startWatch(t, s)
	if err := os.WriteFile(filepath.Join(root, "new.sql"), []byte("x"), 0o644); err != nil {
		t.Fatal(err)
	}
	expect(t, ch, "new.sql", ChangeCreated)
	if err := os.Remove(filepath.Join(root, "new.sql")); err != nil {
		t.Fatal(err)
	}
	expect(t, ch, "new.sql", ChangeDeleted)
}

func TestWatchSeesFilesInNewFolders(t *testing.T) {
	s, root := newTestService(t)
	ch := startWatch(t, s)
	if err := os.MkdirAll(filepath.Join(root, "pulled", "deep"), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, "pulled", "deep", "q.sql"), []byte("x"), 0o644); err != nil {
		t.Fatal(err)
	}
	expect(t, ch, "pulled/deep/q.sql", ChangeCreated)
	if err := os.WriteFile(filepath.Join(root, "pulled", "deep", "q.sql"), []byte("y"), 0o644); err != nil {
		t.Fatal(err)
	}
	expect(t, ch, "pulled/deep/q.sql", ChangeModified)
}

func TestWatchCoalescesBursts(t *testing.T) {
	s, root := newTestService(t)
	ch := startWatch(t, s)
	p := filepath.Join(root, "burst.sql")
	for i := range 20 {
		if err := os.WriteFile(p, []byte{byte('a' + i)}, 0o644); err != nil {
			t.Fatal(err)
		}
	}
	expect(t, ch, "burst.sql", ChangeCreated)
	expectNothing(t, ch, 200*time.Millisecond)
}

func TestWatchIgnoresOwnWritesAndGit(t *testing.T) {
	s, root := newTestService(t)
	ch := startWatch(t, s)
	if _, err := s.Create(DefaultRootID, "mine.sql", false, "x"); err != nil {
		t.Fatal(err)
	}
	if _, err := s.Write(DefaultRootID, "mine.sql", "y", WriteCheck{}); err != nil {
		t.Fatal(err)
	}
	if err := os.MkdirAll(filepath.Join(root, ".git"), 0o755); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, ".git", "HEAD"), []byte("x"), 0o644); err != nil {
		t.Fatal(err)
	}
	expectNothing(t, ch, 300*time.Millisecond)
	if err := os.WriteFile(filepath.Join(root, "mine.sql"), []byte("external"), 0o644); err != nil {
		t.Fatal(err)
	}
	expect(t, ch, "mine.sql", ChangeModified)
}

func TestWatchReportsOwnRenameOnce(t *testing.T) {
	s, _ := newTestService(t)
	if _, err := s.Create(DefaultRootID, "old.sql", false, "x"); err != nil {
		t.Fatal(err)
	}
	ch := startWatch(t, s)
	if err := s.Rename(DefaultRootID, "old.sql", "new.sql"); err != nil {
		t.Fatal(err)
	}
	c := expect(t, ch, "new.sql", ChangeRenamed)
	if c.OldPath != "old.sql" {
		t.Fatalf("change = %+v", c)
	}
	expectNothing(t, ch, 200*time.Millisecond)
}

func TestWatchStopsWhenEmitFails(t *testing.T) {
	s, root := newTestService(t)
	errc := make(chan error, 1)
	go func() {
		errc <- s.Watch(context.Background(), nil, func(Change) error { return context.Canceled })
	}()
	time.Sleep(100 * time.Millisecond)
	if err := os.WriteFile(filepath.Join(root, "x.sql"), []byte("x"), 0o644); err != nil {
		t.Fatal(err)
	}
	select {
	case err := <-errc:
		if err == nil {
			t.Fatal("want emit error")
		}
	case <-time.After(5 * time.Second):
		t.Fatal("Watch did not stop")
	}
}
