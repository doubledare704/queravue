package sqlite

import (
	"context"
	"maps"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func TestParseURI(t *testing.T) {
	tests := []struct {
		in      string
		want    map[string]string
		wantErr string
	}{
		{"sqlite:///Users/me/data.db", map[string]string{"path": "/Users/me/data.db"}, ""},
		{"sqlite3:///tmp/a%20b.db", map[string]string{"path": "/tmp/a b.db"}, ""},
		{"sqlite://rel/x.db", map[string]string{"path": "rel/x.db"}, ""},
		{"file:/tmp/x.db?mode=ro", map[string]string{"path": "/tmp/x.db", "read_only": "true"}, ""},
		{"file:///tmp/x.db?mode=rwc", map[string]string{"path": "/tmp/x.db", "create_if_missing": "true"}, ""},
		{"file:x.db", map[string]string{"path": "x.db"}, ""},
		{"/abs/path.sqlite", map[string]string{"path": "/abs/path.sqlite"}, ""},
		{"", nil, "empty"},
		{"sqlite://", nil, "missing file path"},
		{"postgres://h/db", nil, "unsupported scheme"},
	}
	for _, tt := range tests {
		t.Run(tt.in, func(t *testing.T) {
			cfg, sec, err := New().ParseURI(tt.in)
			if tt.wantErr != "" {
				if err == nil || !strings.Contains(err.Error(), tt.wantErr) {
					t.Fatalf("err = %v, want %q", err, tt.wantErr)
				}
				return
			}
			if err != nil {
				t.Fatal(err)
			}
			if !maps.Equal(cfg.Params, tt.want) {
				t.Errorf("params = %v, want %v", cfg.Params, tt.want)
			}
			if !sec.IsZero() {
				t.Error("sqlite has no secret")
			}
		})
	}
}

func connect(t *testing.T, params map[string]string) (engine.Conn, error) {
	t.Helper()
	c, err := New().Connect(context.Background(), engine.Config{EngineID: ID, Params: params}, engine.Secret{})
	if c != nil {
		t.Cleanup(func() { _ = c.Close() })
	}
	return c, err
}

func TestConnectLifecycle(t *testing.T) {
	dir := t.TempDir()
	path := filepath.Join(dir, "sub dir?", "x.db")
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		t.Fatal(err)
	}

	if _, err := connect(t, map[string]string{"path": path}); engine.KindOf(err) != engine.KindNotFound {
		t.Fatalf("missing file: kind = %v (%v), want not_found", engine.KindOf(err), err)
	}
	if _, err := os.Stat(path); !os.IsNotExist(err) {
		t.Fatal("missing file must not be created without create_if_missing")
	}

	c, err := connect(t, map[string]string{"path": path, "create_if_missing": "true"})
	if err != nil {
		t.Fatalf("create: %v", err)
	}
	info, err := c.ServerInfo(context.Background())
	if err != nil || info.Product != "SQLite" || !strings.HasPrefix(info.Version, "3.") {
		t.Fatalf("ServerInfo = %+v, %v", info, err)
	}
	if err := c.Close(); err != nil {
		t.Fatal(err)
	}
	if err := c.Close(); err != nil {
		t.Fatal("second Close must be a no-op")
	}
	if _, err := os.Stat(path); err != nil {
		t.Fatalf("file not created: %v", err)
	}

	ro, err := connect(t, map[string]string{"path": path, "read_only": "true"})
	if err != nil {
		t.Fatalf("read-only: %v", err)
	}
	if err := ro.Ping(context.Background()); err != nil {
		t.Fatal(err)
	}
}

func TestConnectNotADatabase(t *testing.T) {
	path := filepath.Join(t.TempDir(), "junk.db")
	if err := os.WriteFile(path, []byte(strings.Repeat("not a database ", 100)), 0o600); err != nil {
		t.Fatal(err)
	}
	_, err := connect(t, map[string]string{"path": path})
	if engine.KindOf(err) != engine.KindInvalidConfig {
		t.Fatalf("kind = %v (%v), want invalid_config", engine.KindOf(err), err)
	}
}

func TestConnectValidation(t *testing.T) {
	if _, err := connect(t, map[string]string{}); engine.KindOf(err) != engine.KindInvalidConfig {
		t.Fatalf("empty path: %v", err)
	}
	if _, err := connect(t, map[string]string{"path": "/x", "read_only": "maybe"}); engine.KindOf(err) != engine.KindInvalidConfig {
		t.Fatalf("bad bool: %v", err)
	}
}
