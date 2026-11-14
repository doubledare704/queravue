package sqlsplit

import "testing"

func TestDuckDBSplit(t *testing.T) {
	tests := []struct {
		name, text string
		want       []string
	}{
		{"dollar quote hides semicolon", "SELECT $$a;b$$; SELECT 2", []string{"SELECT $$a;b$$", "SELECT 2"}},
		{"tagged dollar quote", "SELECT $t$a;b$t$; SELECT 2", []string{"SELECT $t$a;b$t$", "SELECT 2"}},
		{"positional parameter is not a quote", "SELECT $1; SELECT $2", []string{"SELECT $1", "SELECT $2"}},
		{"nested block comment", "SELECT /* a /* ; */ ; */ 1; SELECT 2", []string{"SELECT /* a /* ; */ ; */ 1", "SELECT 2"}},
		{"backslash is literal", `SELECT 'a\'; SELECT 2`, []string{`SELECT 'a\'`, "SELECT 2"}},
		{"E string escapes quote", `SELECT E'it\'s;'; SELECT 2`, []string{`SELECT E'it\'s;'`, "SELECT 2"}},
		{"quoted identifier", `SELECT "a;b" FROM t; SELECT 2`, []string{`SELECT "a;b" FROM t`, "SELECT 2"}},
		{"begin is not a block", "BEGIN; SELECT 1; COMMIT", []string{"BEGIN", "SELECT 1", "COMMIT"}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var got []string
			for _, r := range Split(DuckDB, tt.text) {
				got = append(got, tt.text[r.Start:r.End])
			}
			if len(got) != len(tt.want) {
				t.Fatalf("got %q, want %q", got, tt.want)
			}
			for i := range got {
				if got[i] != tt.want[i] {
					t.Errorf("statement %d = %q, want %q", i, got[i], tt.want[i])
				}
			}
		})
	}
}
