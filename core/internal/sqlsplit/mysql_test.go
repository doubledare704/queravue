package sqlsplit

import (
	"reflect"
	"testing"
)

func TestSplitMySQL(t *testing.T) {
	tests := []struct {
		name string
		in   string
		want []string
	}{
		{"backslash escape", `select 'a\'; b'; select 2`, []string{`select 'a\'; b'`, "select 2"}},
		{"double-quoted string", `select "a;\"b"; select 2`, []string{`select "a;\"b"`, "select 2"}},
		{"backtick ident", "select `a;b` from t; x", []string{"select `a;b` from t", "x"}},
		{"hash comment", "select 1 # ; no\n; select 2", []string{"select 1", "select 2"}},
		{"dash comment needs space", "select 1 -- ; no\n; select 2", []string{"select 1", "select 2"}},
		{"double dash without space is not a comment", "select 5--3; select 2", []string{"select 5--3", "select 2"}},
		{"block comment not nested", "select /* a /* ; */ 1; z", []string{"select /* a /* ; */ 1", "z"}},
		{"delimiter", "DELIMITER //\ncreate procedure p() begin select 1; select 2; end//\nDELIMITER ;\nselect 3;",
			[]string{"create procedure p() begin select 1; select 2; end", "select 3"}},
		{"delimiter lowercase $$", "delimiter $$\nselect 1; select 2$$\nselect 3$$",
			[]string{"select 1; select 2", "select 3"}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := texts(MySQL, tt.in); !reflect.DeepEqual(got, tt.want) {
				t.Errorf("got %q\nwant %q", got, tt.want)
			}
		})
	}
}
