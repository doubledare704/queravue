package format

import (
	"errors"
	"flag"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

var update = flag.Bool("update", false, "rewrite golden files")

type corpusCase struct{ name, input string }

var dialects = []struct {
	name string
	d    sqlsplit.Dialect
}{
	{"postgres", sqlsplit.Postgres},
	{"mysql", sqlsplit.MySQL},
	{"mssql", sqlsplit.MSSQL},
	{"oracle", sqlsplit.Oracle},
	{"sqlite", sqlsplit.SQLite},
}

func readCorpus(t *testing.T, file string) []corpusCase {
	t.Helper()
	raw, err := os.ReadFile(filepath.Join("testdata", file))
	if err != nil {
		t.Fatal(err)
	}
	var cases []corpusCase
	for _, block := range strings.Split("\n"+string(raw), "\n=== ")[1:] {
		name, body, _ := strings.Cut(block, "\n")
		cases = append(cases, corpusCase{name: name, input: strings.TrimSuffix(body, "\n")})
	}
	return cases
}

func corpusFor(t *testing.T, dialect string) []corpusCase {
	return append(readCorpus(t, "common.in"), readCorpus(t, dialect+".in")...)
}

func TestGoldenCorpus(t *testing.T) {
	for _, dl := range dialects {
		t.Run(dl.name, func(t *testing.T) {
			cases := corpusFor(t, dl.name)
			if len(cases) < 40 {
				t.Fatalf("corpus has %d statements, want at least 40", len(cases))
			}
			var out strings.Builder
			for _, c := range cases {
				got, err := Format(dl.d, c.input, Options{})
				if err != nil {
					t.Fatalf("%s: %v", c.name, err)
				}
				out.WriteString("=== " + c.name + "\n" + c.input + "\n---\n" + got + "\n")
			}
			path := filepath.Join("testdata", dl.name+".golden")
			if *update {
				if err := os.WriteFile(path, []byte(out.String()), 0o600); err != nil {
					t.Fatal(err)
				}
				return
			}
			want, err := os.ReadFile(path)
			if err != nil {
				t.Fatal(err)
			}
			if string(want) != out.String() {
				t.Errorf("golden mismatch for %s; review with git diff after running: go test ./internal/format -update\n%s", dl.name, firstDifference(string(want), out.String()))
			}
		})
	}
}

func firstDifference(want, got string) string {
	wl, gl := strings.Split(want, "\n"), strings.Split(got, "\n")
	for i := 0; i < len(wl) && i < len(gl); i++ {
		if wl[i] != gl[i] {
			return "line " + itoa(i+1) + "\nwant: " + wl[i] + "\ngot:  " + gl[i]
		}
	}
	return "length differs"
}

func itoa(n int) string {
	var b []byte
	for ; n > 0; n /= 10 {
		b = append([]byte{byte('0' + n%10)}, b...)
	}
	return string(b)
}

var optionSets = map[string]Options{
	"default":  {},
	"lower":    {KeywordCase: CaseLower},
	"preserve": {KeywordCase: CasePreserve},
	"leading":  {CommaStyle: CommaLeading},
	"narrow":   {MaxLineWidth: 40, IndentWidth: 4},
	"wide":     {MaxLineWidth: 400, IndentWidth: 1},
}

func TestInvariantsHoldForEveryCorpusStatement(t *testing.T) {
	for _, dl := range dialects {
		for setName, opts := range optionSets {
			t.Run(dl.name+"/"+setName, func(t *testing.T) {
				for _, c := range corpusFor(t, dl.name) {
					once, err := Format(dl.d, c.input, opts)
					if err != nil {
						t.Fatalf("%s: %v", c.name, err)
					}
					twice, err := Format(dl.d, once, opts)
					if err != nil || twice != once {
						t.Errorf("%s: not idempotent\nonce:\n%s\ntwice:\n%s", c.name, once, twice)
					}
					if !equivalent(dl.d, c.input, once) {
						t.Errorf("%s: tokens changed\ninput:  %s\noutput: %s", c.name, c.input, once)
					}
					if strings.HasPrefix(c.name, "not formatted") {
						if once != c.input {
							t.Errorf("%s: unsupported statement changed: %q", c.name, once)
						}
						continue
					}
					for _, r := range sqlsplit.Split(dl.d, c.input) {
						stmt := c.input[r.Start:r.End]
						direct, ok := render(dl.d, stmt, opts.normalized())
						if kept := formatStatement(dl.d, stmt, opts.normalized()); ok && direct != kept {
							t.Errorf("%s: the self-check rejected the formatter output\ndirect:\n%s\nkept:\n%s", c.name, direct, kept)
						}
					}
				}
			})
		}
	}
}

func TestOptions(t *testing.T) {
	const in = "select a, b from t where x = 1 and y in (select id from u where z = 1)"
	tests := []struct {
		name string
		opts Options
		want string
	}{
		{"upper", Options{}, "SELECT a, b\nFROM t\nWHERE x = 1 AND y IN (SELECT id FROM u WHERE z = 1)"},
		{"lower", Options{KeywordCase: CaseLower}, "select a, b\nfrom t\nwhere x = 1 and y in (select id from u where z = 1)"},
		{"preserve", Options{KeywordCase: CasePreserve}, "select a, b\nfrom t\nwhere x = 1 and y in (select id from u where z = 1)"},
		{"narrow trailing", Options{MaxLineWidth: 40, IndentWidth: 4},
			"SELECT a, b\nFROM t\nWHERE x = 1\n    AND y IN (\n        SELECT id\n        FROM u\n        WHERE z = 1\n    )"},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			got, err := Format(sqlsplit.Postgres, in, tc.opts)
			if err != nil || got != tc.want {
				t.Errorf("got %q (err %v)\nwant %q", got, err, tc.want)
			}
		})
	}
}

func TestLeadingCommas(t *testing.T) {
	in := "select customers.id, customers.first_name, customers.last_name, customers.email_address, customers.created_at from customers"
	trailing, _ := Format(sqlsplit.Postgres, in, Options{})
	leading, _ := Format(sqlsplit.Postgres, in, Options{CommaStyle: CommaLeading})
	if !strings.Contains(trailing, "customers.id,\n") || strings.Contains(trailing, "\n  ,") {
		t.Errorf("trailing style wrong:\n%s", trailing)
	}
	if !strings.Contains(leading, "\n  , customers.first_name") || strings.Contains(leading, ",\n") {
		t.Errorf("leading style wrong:\n%s", leading)
	}
}

func TestUnsupportedStatementsPassThrough(t *testing.T) {
	for _, in := range []string{
		"create  table t ( a int )",
		"MERGE INTO t USING u ON t.id=u.id WHEN MATCHED THEN UPDATE SET a=1",
		"select (1",
		"select 1)",
		"pragma   foreign_keys = on",
		"  ",
		"",
	} {
		got, err := Format(sqlsplit.Postgres, in, Options{})
		if err != nil || got != in {
			t.Errorf("Format(%q) = %q, %v; want unchanged", in, got, err)
		}
	}
}

func TestTextBetweenStatementsIsKept(t *testing.T) {
	in := "-- header\nselect a from t;\n\n\n/* mid */\nselect  b  from u;\n-- tail\n"
	got, err := Format(sqlsplit.Postgres, in, Options{})
	want := "-- header\nSELECT a\nFROM t;\n\n\n/* mid */\nSELECT b\nFROM u;\n-- tail\n"
	if err != nil || got != want {
		t.Errorf("got %q (err %v)\nwant %q", got, err, want)
	}
}

func TestUnterminatedInputIsASyntaxError(t *testing.T) {
	tests := []struct {
		in     string
		offset int
	}{
		{"select 'abc", 7},
		{"select a from \"t", 14},
		{"select [x", 7},
		{"select 1 /* open", 9},
	}
	for _, tc := range tests {
		d := sqlsplit.MSSQL
		_, err := Format(d, tc.in, Options{})
		var se *SyntaxError
		if !errors.As(err, &se) || se.Offset != tc.offset {
			t.Errorf("Format(%q) error = %v, want SyntaxError at %d", tc.in, err, tc.offset)
		}
	}
}

func TestCommentsAreNeverChanged(t *testing.T) {
	in := "select a, -- keep   this\n  b /*  and   this */ from t -- end"
	got, err := Format(sqlsplit.Postgres, in, Options{})
	if err != nil {
		t.Fatal(err)
	}
	for _, c := range []string{"-- keep   this", "/*  and   this */", "-- end"} {
		if !strings.Contains(got, c) {
			t.Errorf("comment %q lost or changed:\n%s", c, got)
		}
	}
}

func TestStringsAndIdentifiersKeepTheirCase(t *testing.T) {
	in := `select "Select", 'FROM where', Name, [Order] from Users`
	got, _ := Format(sqlsplit.MSSQL, in, Options{KeywordCase: CaseUpper})
	for _, keep := range []string{`"Select"`, `'FROM where'`, "Name", "[Order]", "Users"} {
		if !strings.Contains(got, keep) {
			t.Errorf("%s changed:\n%s", keep, got)
		}
	}
}

func FuzzFormat(f *testing.F) {
	for _, dl := range []string{"postgres", "mysql", "mssql", "sqlite"} {
		raw, err := os.ReadFile(filepath.Join("testdata", dl+".in"))
		if err != nil {
			f.Fatal(err)
		}
		for _, block := range strings.Split("\n"+string(raw), "\n=== ")[1:] {
			_, body, _ := strings.Cut(block, "\n")
			f.Add(strings.TrimSuffix(body, "\n"), byte(0))
		}
	}
	f.Fuzz(func(t *testing.T, text string, which byte) {
		d := dialects[int(which)%len(dialects)].d
		once, err := Format(d, text, Options{})
		if err != nil {
			return
		}
		if !equivalent(d, text, once) {
			t.Fatalf("tokens changed:\n%q\n%q", text, once)
		}
		twice, err := Format(d, once, Options{})
		if err != nil || twice != once {
			t.Fatalf("not idempotent:\n%q\n%q", once, twice)
		}
	})
}
