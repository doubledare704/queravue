package duckdb

import (
	"maps"
	"strings"
	"testing"
)

func TestParseURI(t *testing.T) {
	tests := []struct {
		in      string
		want    map[string]string
		wantErr string
	}{
		{"duckdb:///Users/me/a.duckdb", map[string]string{"path": "/Users/me/a.duckdb"}, ""},
		{"duckdb:///tmp/a%20b.duckdb", map[string]string{"path": "/tmp/a b.duckdb"}, ""},
		{"duckdb://rel/x.duckdb", map[string]string{"path": "rel/x.duckdb"}, ""},
		{"duckdb://:memory:", map[string]string{"path": ":memory:"}, ""},
		{"duckdb:///tmp/x.db?access_mode=read_only", map[string]string{"path": "/tmp/x.db", "read_only": "true"}, ""},
		{"duckdb:///tmp/x.db?read_only=true&memory_limit=2GB", map[string]string{"path": "/tmp/x.db", "read_only": "true", "memory_limit": "2GB"}, ""},
		{"/abs/path.duckdb", map[string]string{"path": "/abs/path.duckdb"}, ""},
		{":memory:", map[string]string{"path": ":memory:"}, ""},
		{"", nil, "empty"},
		{"duckdb://", nil, "missing file path"},
		{"postgres://h/db", nil, "unsupported scheme"},
		{"duckdb:///x?a=%zz", nil, "invalid query"},
	}
	for _, tt := range tests {
		t.Run(tt.in, func(t *testing.T) {
			got, err := parseURI(tt.in)
			if tt.wantErr != "" {
				if err == nil || !strings.Contains(err.Error(), tt.wantErr) {
					t.Fatalf("err = %v, want %q", err, tt.wantErr)
				}
				return
			}
			if err != nil {
				t.Fatal(err)
			}
			if !maps.Equal(got, tt.want) {
				t.Errorf("params = %v, want %v", got, tt.want)
			}
		})
	}
}
