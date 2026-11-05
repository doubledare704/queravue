package postgres

import (
	"maps"
	"strings"
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func TestParseURI(t *testing.T) {
	tests := []struct {
		name     string
		in       string
		want     map[string]string
		wantPW   string
		wantErr  string
		engineID string
	}{
		{
			name:   "full URI",
			in:     "postgres://alice:s3cr%40t@db.example.com:6543/app?sslmode=require&application_name=x",
			want:   map[string]string{"host": "db.example.com", "port": "6543", "user": "alice", "database": "app", "sslmode": "require"},
			wantPW: "s3cr@t",
		},
		{
			name: "postgresql scheme no password",
			in:   "postgresql://bob@localhost/postgres",
			want: map[string]string{"host": "localhost", "user": "bob", "database": "postgres"},
		},
		{
			name: "ipv6 host",
			in:   "postgres://[::1]:5432/db",
			want: map[string]string{"host": "::1", "port": "5432", "database": "db"},
		},
		{
			name:   "password in query",
			in:     "postgres://u@h/db?password=qp",
			want:   map[string]string{"host": "h", "user": "u", "database": "db"},
			wantPW: "qp",
		},
		{
			name: "host only",
			in:   "postgres://h",
			want: map[string]string{"host": "h"},
		},
		{
			name:   "keyword value",
			in:     "host=h port=5433 dbname=d user=u password='p w\\'x' sslmode=disable",
			want:   map[string]string{"host": "h", "port": "5433", "database": "d", "user": "u", "sslmode": "disable"},
			wantPW: "p w'x",
		},
		{
			name:     "cockroach URI",
			in:       "postgresql://root@crdb:26257/defaultdb?sslmode=verify-full",
			want:     map[string]string{"host": "crdb", "port": "26257", "user": "root", "database": "defaultdb", "sslmode": "verify-full"},
			engineID: IDCockroach,
		},
		{name: "empty", in: "  ", wantErr: "empty"},
		{name: "wrong scheme", in: "mysql://u@h/db", wantErr: "unsupported scheme"},
		{name: "bad port", in: "postgres://h:99999/db", wantErr: "invalid"},
		{name: "bad sslmode", in: "postgres://h/db?sslmode=yes", wantErr: "invalid sslmode"},
		{name: "multi host", in: "postgres://a,b/db", wantErr: "multiple hosts"},
		{name: "unterminated quote", in: "host='h", wantErr: "unterminated"},
		{name: "garbage kv", in: "nonsense", wantErr: "key=value"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			v := VariantPostgres
			if tt.engineID == IDCockroach {
				v = VariantCockroach
			}
			cfg, sec, err := New(v).ParseURI(tt.in)
			if tt.wantErr != "" {
				if err == nil || !strings.Contains(err.Error(), tt.wantErr) {
					t.Fatalf("err = %v, want containing %q", err, tt.wantErr)
				}
				if engine.KindOf(err) != engine.KindInvalidConfig {
					t.Errorf("kind = %v, want invalid_config", engine.KindOf(err))
				}
				return
			}
			if err != nil {
				t.Fatalf("ParseURI: %v", err)
			}
			if !maps.Equal(cfg.Params, tt.want) {
				t.Errorf("params = %v, want %v", cfg.Params, tt.want)
			}
			if sec.Reveal() != tt.wantPW {
				t.Errorf("password = %q, want %q", sec.Reveal(), tt.wantPW)
			}
			if _, ok := cfg.Params[ParamPassword]; ok {
				t.Error("password leaked into params")
			}
		})
	}
}

func TestParseURIErrorDoesNotLeakPassword(t *testing.T) {
	_, _, err := New(VariantPostgres).ParseURI("postgres://u:hunter2@h:bad%zz/db")
	if err == nil {
		t.Fatal("want error")
	}
	if strings.Contains(err.Error(), "hunter2") {
		t.Errorf("error leaks password: %v", err)
	}
}

func TestParseBanner(t *testing.T) {
	tests := []struct {
		banner, sv   string
		product, ver string
	}{
		{"PostgreSQL 17.11 (Debian 17.11-1.pgdg120+1) on aarch64-unknown-linux-gnu", "17.11 (Debian)", "PostgreSQL", "17.11"},
		{"PostgreSQL 16.4, compiled by Visual C++", "16.4", "PostgreSQL", "16.4"},
		{"CockroachDB CCL v24.2.3 (aarch64-apple-darwin, built 2024/09/23)", "13.0.0", "CockroachDB", "24.2.3"},
		{"weird", "15.2 (x)", "PostgreSQL", "15.2"},
	}
	for _, tt := range tests {
		got := parseBanner(tt.banner, tt.sv)
		if got.Product != tt.product || got.Version != tt.ver {
			t.Errorf("parseBanner(%q) = %s %s, want %s %s", tt.banner, got.Product, got.Version, tt.product, tt.ver)
		}
	}
}

func TestConnConfigUsesSecretNotEnv(t *testing.T) {
	t.Setenv("PGPASSWORD", "from-env")
	e := New(VariantPostgres)
	cfg := e.desc.WithDefaults(engine.Config{EngineID: IDPostgres, Params: map[string]string{"host": "h", "user": "u"}})
	cc, err := e.connConfig(cfg, engine.NewSecret("from-keychain"))
	if err != nil {
		t.Fatal(err)
	}
	if cc.Password != "from-keychain" {
		t.Errorf("password = %q, want keychain value", cc.Password)
	}
	cc, err = e.connConfig(cfg, engine.Secret{})
	if err != nil {
		t.Fatal(err)
	}
	if cc.Password != "" {
		t.Errorf("empty secret must override PGPASSWORD, got %q", cc.Password)
	}
	if cc.Host != "h" || cc.Port != 5432 || cc.Database != "postgres" || cc.User != "u" {
		t.Errorf("config = %s:%d/%s user %s", cc.Host, cc.Port, cc.Database, cc.User)
	}
}

func TestKVQuoting(t *testing.T) {
	e := New(VariantPostgres)
	cfg := e.desc.WithDefaults(engine.Config{EngineID: IDPostgres, Params: map[string]string{
		"host": "h", "database": `we'ird db\`, "user": "a b",
	}})
	cc, err := e.connConfig(cfg, engine.Secret{})
	if err != nil {
		t.Fatal(err)
	}
	if cc.Database != `we'ird db\` || cc.User != "a b" {
		t.Errorf("got db=%q user=%q", cc.Database, cc.User)
	}
}
