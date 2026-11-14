package sqlsplit

import "testing"

func TestClickHouseSplit(t *testing.T) {
	tests := []struct {
		name, text string
		want       []string
	}{
		{"backslash escaped quote", `SELECT 'it\'s; fine'; SELECT 2`, []string{`SELECT 'it\'s; fine'`, `SELECT 2`}},
		{"hash comment hides semicolon", "SELECT 1 # a; b\n; SELECT 2", []string{"SELECT 1", "SELECT 2"}},
		{"dash comment without space", "SELECT 1 --a; b\n; SELECT 2", []string{"SELECT 1", "SELECT 2"}},
		{"backtick identifier", "SELECT `a;b` FROM t; SELECT 2", []string{"SELECT `a;b` FROM t", "SELECT 2"}},
		{"double quoted identifier", `SELECT "a;b" FROM t; SELECT 2`, []string{`SELECT "a;b" FROM t`, "SELECT 2"}},
		{"block comment", "SELECT /* ; */ 1; SELECT 2", []string{"SELECT /* ; */ 1", "SELECT 2"}},
		{"delimiter is not a command", "DELIMITER //; SELECT 1", []string{"DELIMITER //", "SELECT 1"}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			var got []string
			for _, r := range Split(ClickHouse, tt.text) {
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
