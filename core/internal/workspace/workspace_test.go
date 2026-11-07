package workspace

import (
	"context"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func newTestService(t *testing.T) (*Service, string) {
	t.Helper()
	dir := t.TempDir()
	root := filepath.Join(dir, "ws")
	s := NewService(Options{ConfigDir: filepath.Join(dir, "cfg"), DefaultRoot: root, DebounceInterval: 20 * time.Millisecond})
	return s, root
}

func wantKind(t *testing.T, err error, kind ErrorKind) *Error {
	t.Helper()
	var e *Error
	if !errors.As(err, &e) || e.Kind != kind {
		t.Fatalf("got %v, want workspace error kind %d", err, kind)
	}
	return e
}

func TestDefaultRootIsCreatedAndRootsPersist(t *testing.T) {
	s, root := newTestService(t)
	roots, err := s.Roots()
	if err != nil || len(roots) != 1 || roots[0].ID != DefaultRootID || roots[0].Path != root {
		t.Fatalf("roots = %+v, %v", roots, err)
	}
	if fi, err := os.Stat(root); err != nil || !fi.IsDir() {
		t.Fatalf("default root not created: %v", err)
	}
	other := filepath.Join(t.TempDir(), "second")
	saved, err := s.SetRoots([]Root{roots[0], {Path: other}})
	if err != nil || len(saved) != 2 || saved[1].ID == "" || saved[1].Name != "second" {
		t.Fatalf("SetRoots = %+v, %v", saved, err)
	}
	again := NewService(Options{ConfigDir: s.opt.ConfigDir, DefaultRoot: root})
	got, err := again.Roots()
	if err != nil || len(got) != 2 || got[1].Path != other {
		t.Fatalf("reloaded roots = %+v, %v", got, err)
	}
}

func TestSetRootsValidation(t *testing.T) {
	s, _ := newTestService(t)
	if _, err := s.SetRoots(nil); err == nil {
		t.Error("empty list accepted")
	}
	if _, err := s.SetRoots([]Root{{Path: "relative/dir"}}); err == nil {
		t.Error("relative path accepted")
	}
	p := t.TempDir()
	_, err := s.SetRoots([]Root{{Path: p}, {Path: p}})
	_ = wantKind(t, err, KindAlreadyExists)
}

func TestCreateReadWriteRoundTrip(t *testing.T) {
	s, _ := newTestService(t)
	f, err := s.Create(DefaultRootID, "reports/users.sql", false, "-- title: Users\nSELECT 1;\n")
	if err != nil {
		t.Fatal(err)
	}
	if f.Meta.Title != "Users" || f.Kind != KindSQL || f.Hash == "" {
		t.Fatalf("created = %+v", f)
	}
	_, err = s.Create(DefaultRootID, "reports/users.sql", false, "x")
	_ = wantKind(t, err, KindAlreadyExists)

	w, err := s.Write(DefaultRootID, "reports/users.sql", "SELECT 2;\n", WriteCheck{ExpectedHash: f.Hash})
	if err != nil {
		t.Fatal(err)
	}
	r, err := s.Read(DefaultRootID, "reports/users.sql")
	if err != nil || r.Content != "SELECT 2;\n" || r.Hash != w.Hash {
		t.Fatalf("read = %+v, %v", r, err)
	}
}

func TestWriteConflict(t *testing.T) {
	s, root := newTestService(t)
	f, err := s.Create(DefaultRootID, "a.sql", false, "v1")
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, "a.sql"), []byte("external"), 0o644); err != nil {
		t.Fatal(err)
	}
	_, err = s.Write(DefaultRootID, "a.sql", "mine", WriteCheck{ExpectedHash: f.Hash})
	e := wantKind(t, err, KindConflict)
	if e.Current == nil || e.Current.Content != "external" {
		t.Fatalf("conflict carries %+v", e.Current)
	}
	if b, _ := os.ReadFile(filepath.Join(root, "a.sql")); string(b) != "external" {
		t.Fatalf("file was overwritten: %q", b)
	}
	if _, err := s.Write(DefaultRootID, "a.sql", "mine", WriteCheck{ExpectedHash: f.Hash, Force: true}); err != nil {
		t.Fatalf("forced write: %v", err)
	}
	if b, _ := os.ReadFile(filepath.Join(root, "a.sql")); string(b) != "mine" {
		t.Fatalf("forced write lost: %q", b)
	}
}

func TestWriteConflictByMtimeAndDeletedFile(t *testing.T) {
	s, root := newTestService(t)
	f, _ := s.Create(DefaultRootID, "a.sql", false, "v1")
	later := f.ModTime.Add(time.Hour)
	if err := os.Chtimes(filepath.Join(root, "a.sql"), later, later); err != nil {
		t.Fatal(err)
	}
	_, err := s.Write(DefaultRootID, "a.sql", "x", WriteCheck{ExpectedMtime: f.ModTime})
	_ = wantKind(t, err, KindConflict)

	if err := os.Remove(filepath.Join(root, "a.sql")); err != nil {
		t.Fatal(err)
	}
	_, err = s.Write(DefaultRootID, "a.sql", "x", WriteCheck{ExpectedHash: f.Hash})
	if e := wantKind(t, err, KindConflict); e.Current != nil {
		t.Fatalf("deleted file reported as %+v", e.Current)
	}
	if _, err := s.Write(DefaultRootID, "a.sql", "fresh", WriteCheck{}); err != nil {
		t.Fatalf("unchecked write: %v", err)
	}
}

func TestWriteLeavesNoTempFiles(t *testing.T) {
	s, root := newTestService(t)
	for i := range 5 {
		if _, err := s.Write(DefaultRootID, "a.sql", strings.Repeat("x", i), WriteCheck{}); err != nil {
			t.Fatal(err)
		}
	}
	entries, _ := os.ReadDir(root)
	for _, e := range entries {
		if strings.HasPrefix(e.Name(), tempPrefix) {
			t.Fatalf("leftover temp file %s", e.Name())
		}
	}
}

func TestWritePreservesMode(t *testing.T) {
	s, root := newTestService(t)
	if _, err := s.Roots(); err != nil {
		t.Fatal(err)
	}
	p := filepath.Join(root, "a.sql")
	if err := os.WriteFile(p, []byte("x"), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := s.Write(DefaultRootID, "a.sql", "y", WriteCheck{}); err != nil {
		t.Fatal(err)
	}
	if fi, _ := os.Stat(p); fi.Mode().Perm() != 0o600 {
		t.Fatalf("mode = %v", fi.Mode().Perm())
	}
}

func TestSizeCap(t *testing.T) {
	dir := t.TempDir()
	s := NewService(Options{ConfigDir: dir, DefaultRoot: filepath.Join(dir, "ws"), MaxFileSize: 10})
	_, err := s.Write(DefaultRootID, "a.sql", strings.Repeat("x", 11), WriteCheck{})
	_ = wantKind(t, err, KindTooLarge)
	if _, err := s.Roots(); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, "ws", "big.sql"), []byte(strings.Repeat("x", 11)), 0o644); err != nil {
		t.Fatal(err)
	}
	_, err = s.Read(DefaultRootID, "big.sql")
	_ = wantKind(t, err, KindTooLarge)
}

func TestPathSafety(t *testing.T) {
	s, root := newTestService(t)
	outside := t.TempDir()
	if err := os.WriteFile(filepath.Join(outside, "secret.sql"), []byte("secret"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink(outside, filepath.Join(root, "link")); err != nil {
		t.Skipf("symlinks unavailable: %v", err)
	}
	if err := os.Symlink(filepath.Join(outside, "secret.sql"), filepath.Join(root, "file-link.sql")); err != nil {
		t.Fatal(err)
	}
	escapes := []string{"../x.sql", "a/../../x.sql", "/etc/passwd", "..", "link/secret.sql", "link/new.sql", "link/sub/new.sql", "file-link.sql"}
	for _, p := range escapes {
		t.Run(p, func(t *testing.T) {
			_, err := s.Read(DefaultRootID, p)
			_ = wantKind(t, err, KindPathEscapesRoot)
			_, err = s.Write(DefaultRootID, p, "x", WriteCheck{})
			_ = wantKind(t, err, KindPathEscapesRoot)
			_, err = s.Create(DefaultRootID, p, false, "x")
			_ = wantKind(t, err, KindPathEscapesRoot)
			err = s.Delete(DefaultRootID, p)
			_ = wantKind(t, err, KindPathEscapesRoot)
			err = s.Rename(DefaultRootID, "a.sql", p)
			_ = wantKind(t, err, KindPathEscapesRoot)
			err = s.Rename(DefaultRootID, p, "b.sql")
			_ = wantKind(t, err, KindPathEscapesRoot)
		})
	}
	if _, err := os.Stat(filepath.Join(outside, "new.sql")); err == nil {
		t.Fatal("a write escaped through the symlink")
	}
	_, err := s.ListTree(DefaultRootID, "link")
	_ = wantKind(t, err, KindPathEscapesRoot)
	if _, err := s.Read(DefaultRootID, "nested/../ok.sql"); err != nil {
		_ = wantKind(t, err, KindNotFound)
	}
	if _, err := s.Read("unknown", "a.sql"); err == nil {
		t.Fatal("unknown root accepted")
	}
}

func TestSymlinkedRootStillWorks(t *testing.T) {
	dir := t.TempDir()
	target := filepath.Join(dir, "target")
	if err := os.Mkdir(target, 0o755); err != nil {
		t.Fatal(err)
	}
	link := filepath.Join(dir, "link")
	if err := os.Symlink(target, link); err != nil {
		t.Skipf("symlinks unavailable: %v", err)
	}
	s := NewService(Options{ConfigDir: dir, DefaultRoot: link})
	if _, err := s.Create(DefaultRootID, "a.sql", false, "x"); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(filepath.Join(target, "a.sql")); err != nil {
		t.Fatal(err)
	}
}

func TestListTree(t *testing.T) {
	s, root := newTestService(t)
	for _, f := range []string{"b.sql", "A.mongo.js", "notes.txt", "sub/z.sql", ".git/config"} {
		if _, err := s.Create(DefaultRootID, f, false, "-- title: "+f+"\n"); err != nil {
			t.Fatal(err)
		}
	}
	if err := os.WriteFile(filepath.Join(root, tempPrefix+"123"), nil, 0o644); err != nil {
		t.Fatal(err)
	}
	got, err := s.ListTree(DefaultRootID, "")
	if err != nil {
		t.Fatal(err)
	}
	var names []string
	for _, e := range got {
		names = append(names, e.Name)
	}
	if strings.Join(names, ",") != "sub,A.mongo.js,b.sql,notes.txt" {
		t.Fatalf("names = %v", names)
	}
	if got[0].IsDir != true || got[2].Meta.Title != "b.sql" || got[1].Kind != KindMongo || got[3].Kind != KindOther {
		t.Fatalf("entries = %+v", got)
	}
}

func TestRenameMoveAndDelete(t *testing.T) {
	s, root := newTestService(t)
	if _, err := s.Create(DefaultRootID, "a.sql", false, "x"); err != nil {
		t.Fatal(err)
	}
	if err := s.Rename(DefaultRootID, "a.sql", "folder/b.sql"); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(filepath.Join(root, "folder", "b.sql")); err != nil {
		t.Fatal(err)
	}
	if _, err := s.Create(DefaultRootID, "c.sql", false, "y"); err != nil {
		t.Fatal(err)
	}
	_ = wantKind(t, s.Rename(DefaultRootID, "c.sql", "folder/b.sql"), KindAlreadyExists)
	_ = wantKind(t, s.Rename(DefaultRootID, "missing.sql", "d.sql"), KindNotFound)
	_ = wantKind(t, s.Rename(DefaultRootID, "folder", "folder/inner"), KindIO)
	_ = wantKind(t, s.Rename(DefaultRootID, "", "x"), KindIO)

	if err := s.Delete(DefaultRootID, "folder"); err != nil {
		t.Fatal(err)
	}
	if _, err := os.Stat(filepath.Join(root, "folder")); err == nil {
		t.Fatal("folder still exists")
	}
	_ = wantKind(t, s.Delete(DefaultRootID, "folder"), KindNotFound)
	_ = wantKind(t, s.Delete(DefaultRootID, ""), KindIO)
	if _, err := s.Create(DefaultRootID, "dir", true, ""); err != nil {
		t.Fatal(err)
	}
	_ = wantKind(t, mustErr(s.Create(DefaultRootID, "dir", true, "")), KindAlreadyExists)
}

func mustErr(_ *File, err error) error { return err }

func seedSearch(t *testing.T, s *Service) {
	t.Helper()
	files := map[string]string{
		"users.sql":              "-- title: Active users\n-- tags: reports, users\nSELECT * FROM users WHERE active;\n",
		"orders.sql":             "-- tags: reports\nSELECT total FROM orders;\n",
		"mongo/cleanup.mongo.js": "// title: Cleanup\ndb.logs.deleteMany({old: true})\n",
		"notes.txt":              "users are great\n",
		".git/hooks.sql":         "SELECT users\n",
		"binary.sql":             "SELECT 1\x00users",
	}
	for p, c := range files {
		if _, err := s.Create(DefaultRootID, p, false, c); err != nil {
			t.Fatal(err)
		}
	}
}

func collect(t *testing.T, s *Service, q SearchQuery) []Hit {
	t.Helper()
	var hits []Hit
	if err := s.Search(context.Background(), q, func(h Hit) error { hits = append(hits, h); return nil }); err != nil {
		t.Fatal(err)
	}
	return hits
}

func paths(hits []Hit) string {
	var p []string
	for _, h := range hits {
		p = append(p, h.Path)
	}
	return strings.Join(p, ",")
}

func TestSearch(t *testing.T) {
	s, _ := newTestService(t)
	seedSearch(t, s)
	tests := []struct {
		name string
		q    SearchQuery
		want string
	}{
		{"everything", SearchQuery{}, "mongo/cleanup.mongo.js,orders.sql,users.sql"},
		{"full text", SearchQuery{Text: "FROM users"}, "users.sql"},
		{"file name", SearchQuery{Text: "orders"}, "orders.sql"},
		{"title", SearchQuery{Text: "cleanup"}, "mongo/cleanup.mongo.js"},
		{"tag text", SearchQuery{Text: "report"}, "orders.sql,users.sql"},
		{"tag filter", SearchQuery{Tags: []string{"users"}}, "users.sql"},
		{"all tags required", SearchQuery{Tags: []string{"reports", "users"}}, "users.sql"},
		{"tag filter is case-insensitive", SearchQuery{Tags: []string{"REPORTS"}}, "orders.sql,users.sql"},
		{"text and tag", SearchQuery{Text: "total", Tags: []string{"reports"}}, "orders.sql"},
		{"no match", SearchQuery{Text: "zzz"}, ""},
		{"limit", SearchQuery{Limit: 2}, "mongo/cleanup.mongo.js,orders.sql"},
		{"unknown root", SearchQuery{RootID: "nope"}, ""},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			if got := paths(collect(t, s, tc.q)); got != tc.want {
				t.Fatalf("got %q, want %q", got, tc.want)
			}
		})
	}
	hits := collect(t, s, SearchQuery{Text: "deleteMany"})
	if len(hits) != 1 || hits[0].Line != 2 || !strings.Contains(hits[0].Snippet, "deleteMany") {
		t.Fatalf("snippet hit = %+v", hits)
	}
}

func TestSearchSkipsOversizedFiles(t *testing.T) {
	dir := t.TempDir()
	s := NewService(Options{ConfigDir: dir, DefaultRoot: filepath.Join(dir, "ws"), MaxFileSize: 20})
	if _, err := s.Create(DefaultRootID, "small.sql", false, "SELECT needle"); err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(dir, "ws", "big.sql"), []byte(strings.Repeat("needle ", 10)), 0o644); err != nil {
		t.Fatal(err)
	}
	if got := paths(collect(t, s, SearchQuery{Text: "needle"})); got != "small.sql" {
		t.Fatalf("got %q", got)
	}
}

func TestSearchDoesNotFollowSymlinks(t *testing.T) {
	s, root := newTestService(t)
	outside := t.TempDir()
	if err := os.WriteFile(filepath.Join(outside, "x.sql"), []byte("needle"), 0o644); err != nil {
		t.Fatal(err)
	}
	if err := os.Symlink(outside, filepath.Join(root, "link")); err != nil {
		t.Skipf("symlinks unavailable: %v", err)
	}
	if err := os.Symlink(filepath.Join(outside, "x.sql"), filepath.Join(root, "y.sql")); err != nil {
		t.Fatal(err)
	}
	if got := collect(t, s, SearchQuery{Text: "needle"}); len(got) != 0 {
		t.Fatalf("followed a symlink out of the root: %+v", got)
	}
}

func TestSearchIsCancellable(t *testing.T) {
	s, _ := newTestService(t)
	seedSearch(t, s)
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	err := s.Search(ctx, SearchQuery{}, func(Hit) error { return nil })
	if !errors.Is(err, context.Canceled) {
		t.Fatalf("got %v, want context.Canceled", err)
	}
	stop := errors.New("stop")
	err = s.Search(context.Background(), SearchQuery{}, func(Hit) error { return stop })
	if !errors.Is(err, stop) {
		t.Fatalf("got %v, want emit error", err)
	}
}
