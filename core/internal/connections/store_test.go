package connections

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"
)

func TestFileStoreRoundTrip(t *testing.T) {
	dir := filepath.Join(t.TempDir(), "Queravue")
	s := NewFileStore(dir)

	got, err := s.Load()
	if err != nil || len(got) != 0 {
		t.Fatalf("Load missing file = %v, %v", got, err)
	}

	now := time.Date(2026, 11, 5, 12, 0, 0, 0, time.UTC)
	in := []Connection{{
		ID: "a", Name: "Local PG", EngineID: "postgres",
		Params: map[string]string{"host": "localhost"},
		Folder: "Work/Clients", Color: ColorRed, Production: true,
		SecretRef: "conn/a", CreatedAt: now, UpdatedAt: now,
	}}
	if err := s.Save(in); err != nil {
		t.Fatal(err)
	}
	got, err = s.Load()
	if err != nil {
		t.Fatal(err)
	}
	if len(got) != 1 || got[0].Name != "Local PG" || got[0].Color != ColorRed || !got[0].Production ||
		got[0].Folder != "Work/Clients" || !got[0].CreatedAt.Equal(now) {
		t.Errorf("round trip = %+v", got)
	}

	fi, err := os.Stat(s.Path())
	if err != nil {
		t.Fatal(err)
	}
	if fi.Mode().Perm() != 0o600 {
		t.Errorf("file perm = %v, want 0600", fi.Mode().Perm())
	}
	di, _ := os.Stat(dir)
	if di.Mode().Perm() != 0o700 {
		t.Errorf("dir perm = %v, want 0700", di.Mode().Perm())
	}
	b, _ := os.ReadFile(s.Path())
	if !strings.Contains(string(b), `"color": "red"`) || !strings.Contains(string(b), `"version": 1`) {
		t.Errorf("unexpected file:\n%s", b)
	}

	entries, _ := os.ReadDir(dir)
	if len(entries) != 1 {
		t.Errorf("leftover files in config dir: %v", entries)
	}
}

func TestFileStoreCorruptFileIsPreserved(t *testing.T) {
	dir := t.TempDir()
	s := NewFileStore(dir)
	junk := []byte("{not json")
	if err := os.WriteFile(s.Path(), junk, 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := s.Load(); err == nil {
		t.Fatal("want parse error")
	}
	svc := newTestService(t, s)
	if _, err := svc.Create(t.Context(), Connection{Name: "x", EngineID: "fake", Params: map[string]string{"host": "h"}}, nil); err == nil {
		t.Fatal("Create must fail while the file is unreadable")
	}
	b, _ := os.ReadFile(s.Path())
	if string(b) != string(junk) {
		t.Error("corrupt file was overwritten")
	}
}

func TestFileStoreNewerVersionRejected(t *testing.T) {
	s := NewFileStore(t.TempDir())
	if err := os.WriteFile(s.Path(), []byte(`{"version": 99, "connections": []}`), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := s.Load(); err == nil || !strings.Contains(err.Error(), "version 99") {
		t.Fatalf("err = %v", err)
	}
}

func TestNormalizeFolder(t *testing.T) {
	tests := []struct{ in, want string }{
		{"", ""},
		{"/", ""},
		{" Work / /Clients/", "Work/Clients"},
		{"a", "a"},
	}
	for _, tt := range tests {
		if got := NormalizeFolder(tt.in); got != tt.want {
			t.Errorf("NormalizeFolder(%q) = %q, want %q", tt.in, got, tt.want)
		}
	}
}

func TestColorUnknownNameLoadsAsNone(t *testing.T) {
	var c Color
	if err := c.UnmarshalText([]byte("magenta")); err != nil || c != ColorNone {
		t.Errorf("got %v, %v", c, err)
	}
}
