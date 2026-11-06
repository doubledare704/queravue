package sqlsplit

import (
	"reflect"
	"testing"
)

func TestSplitMSSQL(t *testing.T) {
	tests := []struct {
		name string
		in   string
		want []string
	}{
		{"semicolons", "select 1; select 2", []string{"select 1", "select 2"}},
		{"bracket ident", "select [a;b] from t; x", []string{"select [a;b] from t", "x"}},
		{"bracket escape", "select [a]];b] from t; x", []string{"select [a]];b] from t", "x"}},
		{"N string", "select N'a;b'; select 2", []string{"select N'a;b'", "select 2"}},
		{"doubled quote", "select N'it''s; ok'; x", []string{"select N'it''s; ok'", "x"}},
		{"backslash is literal", `select 'a\'; select 2`, []string{`select 'a\'`, "select 2"}},
		{"GO separates batches", "select 1\nGO\nselect 2\ngo\n", []string{"select 1", "select 2"}},
		{"GO with count", "select 1\nGO 5\nselect 2", []string{"select 1", "select 2"}},
		{"GO with comment", "select 1\nGO -- run\nselect 2", []string{"select 1", "select 2"}},
		{"GO indented", "select 1\n   GO\nselect 2", []string{"select 1", "select 2"}},
		{"GO not alone on line", "select 1 GO select 2", []string{"select 1 GO select 2"}},
		{"gone is an identifier", "select 1\ngone\nfrom t", []string{"select 1\ngone\nfrom t"}},
		{"GO in string", "select 'a\nGO\nb'", []string{"select 'a\nGO\nb'"}},
		{"GO in block comment", "select 1 /*\nGO\n*/ ; select 2", []string{"select 1", "select 2"}},
		{"nested comment", "select /* a /* ; */ ; */ 1; z", []string{"select /* a /* ; */ ; */ 1", "z"}},
		{"procedure body runs to GO",
			"create procedure p as begin select 1; select 2; end\nGO\nselect 3",
			[]string{"create procedure p as begin select 1; select 2; end", "select 3"}},
		{"create or alter function",
			"CREATE OR ALTER FUNCTION f() RETURNS int AS BEGIN DECLARE @x int; SET @x = 1; RETURN @x; END\nGO\nselect 1",
			[]string{"CREATE OR ALTER FUNCTION f() RETURNS int AS BEGIN DECLARE @x int; SET @x = 1; RETURN @x; END", "select 1"}},
		{"create table is not a body", "create table t (a int); select 1", []string{"create table t (a int)", "select 1"}},
		{"temp table hash is not a comment", "select * from #t; select 2", []string{"select * from #t", "select 2"}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := texts(MSSQL, tt.in); !reflect.DeepEqual(got, tt.want) {
				t.Errorf("got %q\nwant %q", got, tt.want)
			}
		})
	}
}
