package sqlsplit

import (
	"reflect"
	"testing"
)

func TestOracleSplit(t *testing.T) {
	cases := []struct {
		name string
		text string
		want []string
	}{
		{"semicolons", "SELECT 1 FROM dual; SELECT 2 FROM dual;", []string{"SELECT 1 FROM dual", "SELECT 2 FROM dual"}},
		{"anonymous block ends at slash", "BEGIN\n  x := 1;\n  y := 2;\nEND;\n/\nSELECT 3 FROM dual;", []string{"BEGIN\n  x := 1;\n  y := 2;\nEND;", "SELECT 3 FROM dual"}},
		{"declare block", "DECLARE n NUMBER; BEGIN n := 1; END;\n/", []string{"DECLARE n NUMBER; BEGIN n := 1; END;"}},
		{"create or replace procedure", "CREATE OR REPLACE PROCEDURE p AS BEGIN NULL; END;\n/\nSELECT 1 FROM dual;", []string{"CREATE OR REPLACE PROCEDURE p AS BEGIN NULL; END;", "SELECT 1 FROM dual"}},
		{"editionable package body", "CREATE OR REPLACE EDITIONABLE PACKAGE BODY pk AS PROCEDURE a IS BEGIN NULL; END; END pk;\n  /  \nSELECT 1 FROM dual;", []string{"CREATE OR REPLACE EDITIONABLE PACKAGE BODY pk AS PROCEDURE a IS BEGIN NULL; END; END pk;", "SELECT 1 FROM dual"}},
		{"create table is not a block", "CREATE TABLE t (a NUMBER); CREATE TYPE ty AS OBJECT (a NUMBER);", []string{"CREATE TABLE t (a NUMBER)", "CREATE TYPE ty AS OBJECT (a NUMBER)"}},
		{"division slash is not a terminator", "SELECT 4\n/ 2 FROM dual; SELECT 1 FROM dual;", []string{"SELECT 4\n/ 2 FROM dual", "SELECT 1 FROM dual"}},
		{"slash ends a plain statement", "SELECT 1 FROM dual\n/\nSELECT 2 FROM dual\n/", []string{"SELECT 1 FROM dual", "SELECT 2 FROM dual"}},
		{"q quote bracket", "SELECT q'[it's; here]' FROM dual; SELECT 2 FROM dual;", []string{"SELECT q'[it's; here]' FROM dual", "SELECT 2 FROM dual"}},
		{"q quote other delimiters", "SELECT Q'!a;b!', nq'{c;d}', q'<e;f>' FROM dual;", []string{"SELECT Q'!a;b!', nq'{c;d}', q'<e;f>' FROM dual"}},
		{"identifier ending in q is not a quote", "SELECT seq'a;b' FROM dual;", []string{"SELECT seq'a;b' FROM dual"}},
		{"comments hide terminators", "SELECT 1 -- a;\nFROM dual; /* b; */ SELECT 2 FROM dual;", []string{"SELECT 1 -- a;\nFROM dual", "SELECT 2 FROM dual"}},
		{"quoted identifier", "SELECT \"a;b\" FROM dual;", []string{"SELECT \"a;b\" FROM dual"}},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			var got []string
			for _, r := range Split(Oracle, tc.text) {
				got = append(got, r.Text(tc.text))
			}
			if !reflect.DeepEqual(got, tc.want) {
				t.Errorf("got %q\nwant %q", got, tc.want)
			}
		})
	}
}

func TestOracleTokenizeQQuote(t *testing.T) {
	text := "SELECT q'[a'b]' FROM dual"
	var literals []string
	for _, tok := range Tokenize(Oracle, text) {
		if tok.Kind == TokenString {
			literals = append(literals, tok.Text(text))
		}
	}
	if !reflect.DeepEqual(literals, []string{"'[a'b]'"}) {
		t.Fatalf("string tokens = %q", literals)
	}
}
