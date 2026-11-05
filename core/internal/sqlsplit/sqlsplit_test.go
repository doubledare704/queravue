package sqlsplit

import (
	"reflect"
	"testing"
	"unicode/utf8"
)

func texts(d Dialect, s string) []string {
	var out []string
	for _, r := range Split(d, s) {
		out = append(out, r.Text(s))
	}
	return out
}

func TestSplit(t *testing.T) {
	tests := []struct {
		name string
		d    Dialect
		in   string
		want []string
	}{
		{"empty", Postgres, "", nil},
		{"only comments", Postgres, "-- hi\n/* x */  ;  ", nil},
		{"two", Postgres, "select 1; select 2;", []string{"select 1", "select 2"}},
		{"no trailing semicolon", Postgres, "select 1;\nselect 2", []string{"select 1", "select 2"}},
		{"semicolon in string", Postgres, "select 'a;b'; select 2", []string{"select 'a;b'", "select 2"}},
		{"doubled quote", Postgres, "select 'it''s; ok'; x", []string{"select 'it''s; ok'", "x"}},
		{"quoted ident", Postgres, `select "a;b" from t; y`, []string{`select "a;b" from t`, "y"}},
		{"line comment", Postgres, "select 1 -- ; no\n; select 2", []string{"select 1", "select 2"}},
		{"block comment", Postgres, "select /* ; */ 1; select 2", []string{"select /* ; */ 1", "select 2"}},
		{"nested comment", Postgres, "select /* a /* ; */ ; */ 1; z", []string{"select /* a /* ; */ ; */ 1", "z"}},
		{"dollar", Postgres, "do $$ begin; end; $$; select 1", []string{"do $$ begin; end; $$", "select 1"}},
		{"tagged dollar", Postgres, "create function f() returns int as $fn$ select 1; $$ ; $fn$ language sql; select 2",
			[]string{"create function f() returns int as $fn$ select 1; $$ ; $fn$ language sql", "select 2"}},
		{"param not dollar quote", Postgres, "select $1; select $2", []string{"select $1", "select $2"}},
		{"ident with dollar", Postgres, "select a$b; select 1", []string{"select a$b", "select 1"}},
		{"E string escape", Postgres, `select E'a\'; b'; select 2`, []string{`select E'a\'; b'`, "select 2"}},
		{"plain string backslash", Postgres, `select 'a\'; select 2`, []string{`select 'a\'`, "select 2"}},
		{"ident ending in e", Postgres, `select name'x;y'; z`, []string{`select name'x;y'`, "z"}},
		{"unterminated string", Postgres, "select 'abc; def", []string{"select 'abc; def"}},
		{"unterminated comment", Postgres, "select 1; /* abc; def", []string{"select 1"}},
		{"unterminated dollar", Postgres, "select $$abc; def", []string{"select $$abc; def"}},
		{"begin atomic", Postgres,
			"create function f() returns int language sql begin atomic select case when true then 1 end; select 2; end; select 3",
			[]string{"create function f() returns int language sql begin atomic select case when true then 1 end; select 2; end", "select 3"}},
		{"plain begin is a statement", Postgres, "begin; select 1; commit", []string{"begin", "select 1", "commit"}},
		{"unicode", Postgres, "select 'héllo; 😀'; select 2", []string{"select 'héllo; 😀'", "select 2"}},
		{"empty statements", Postgres, ";;select 1;;", []string{"select 1"}},
		{"sqlite trigger", SQLite,
			"create trigger t after insert on a begin insert into b values (new.id); update c set x = case when 1 then 2 end; end; select 1",
			[]string{"create trigger t after insert on a begin insert into b values (new.id); update c set x = case when 1 then 2 end; end", "select 1"}},
		{"sqlite temp trigger", SQLite,
			"create temp trigger t before delete on a begin select 1; end;select 2",
			[]string{"create temp trigger t before delete on a begin select 1; end", "select 2"}},
		{"sqlite begin transaction", SQLite, "begin; select 1; end", []string{"begin", "select 1", "end"}},
		{"sqlite brackets", SQLite, "select [a;b]; select `c;d`", []string{"select [a;b]", "select `c;d`"}},
		{"sqlite comments don't nest", SQLite, "select /* a /* b */ 1; select 2", []string{"select /* a /* b */ 1", "select 2"}},
		{"sqlite dollar is not special", SQLite, "select $$; select 2", []string{"select $$", "select 2"}},
		{"column named end", SQLite, "create trigger t after insert on a begin select new.end; end; select 1",
			[]string{"create trigger t after insert on a begin select new.end; end", "select 1"}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := texts(tt.d, tt.in)
			if !reflect.DeepEqual(got, tt.want) {
				t.Errorf("Split(%q)\n got %q\nwant %q", tt.in, got, tt.want)
			}
		})
	}
}

func TestAt(t *testing.T) {
	in := "select 1;  \n\n select 2;\nselect 3"
	r := Split(Postgres, in)
	tests := []struct {
		cursor int
		want   int
	}{
		{0, 0}, {5, 0}, {9, 0}, // inside, and right after the first ';'
		{10, 0}, {12, 0}, // gap after statement 0
		{14, 1}, {20, 1}, {in2(in, "select 2;"), 1}, // inside statement 1, right after its ';'
		{len(in), 2},
	}
	for _, tt := range tests {
		got, ok := At(r, tt.cursor)
		if !ok || got != tt.want {
			t.Errorf("At(%d) = %d, %v; want %d", tt.cursor, got, ok, tt.want)
		}
	}
	if _, ok := At(nil, 0); ok {
		t.Error("At(nil) ok")
	}
	if i, _ := At(Split(Postgres, "  \n select 1"), 0); i != 0 {
		t.Errorf("cursor before first statement = %d", i)
	}
}

func in2(s, sub string) int {
	for i := range s {
		if len(s)-i >= len(sub) && s[i:i+len(sub)] == sub {
			return i + len(sub)
		}
	}
	return -1
}

func TestOverlapping(t *testing.T) {
	in := "select 1; select 2; select 3"
	r := Split(Postgres, in)
	got := Overlapping(r, 12, 22)
	if !reflect.DeepEqual(got, []int{1, 2}) {
		t.Errorf("Overlapping = %v", got)
	}
}

func TestOffsetMap(t *testing.T) {
	s := "a😀é;b"
	m := NewOffsetMap(s)
	// bytes: a(0) 😀(1..5) é(5..7) ;(7) b(8)
	for _, tt := range []struct{ b, u int }{{0, 0}, {1, 1}, {5, 3}, {7, 4}, {8, 5}, {9, 6}} {
		if got := m.ToUTF16(tt.b); got != tt.u {
			t.Errorf("ToUTF16(%d) = %d, want %d", tt.b, got, tt.u)
		}
		if got := m.ToByte(tt.u); got != min(tt.b, len(s)) {
			t.Errorf("ToByte(%d) = %d, want %d", tt.u, got, tt.b)
		}
	}
	if got := m.ToByte(2); got != 1 { // middle of the surrogate pair
		t.Errorf("ToByte(2) = %d, want 1", got)
	}
	if got := m.ToByte(99); got != len(s) {
		t.Errorf("ToByte(99) = %d", got)
	}
	a := NewOffsetMap("abc")
	if a.ToUTF16(2) != 2 || a.ToByte(2) != 2 || a.ToByte(10) != 3 {
		t.Error("ascii fast path")
	}
}

func FuzzSplit(f *testing.F) {
	for _, s := range []string{"select 1;", "$$ a; $$;", "/* /* */", "E'\\'", "create trigger t after insert on a begin select 1; end;", "'", "😀;"} {
		f.Add(s)
	}
	f.Fuzz(func(t *testing.T, s string) {
		for _, d := range []Dialect{Postgres, SQLite} {
			prev := 0
			for _, r := range Split(d, s) {
				if r.Start < prev || r.Start >= r.End || r.End > r.TermEnd || r.TermEnd > len(s) {
					t.Fatalf("bad range %+v after %d in %q", r, prev, s)
				}
				if utf8.ValidString(s) && (!utf8.ValidString(s[r.Start:r.End])) {
					t.Fatalf("range splits a rune: %+v in %q", r, s)
				}
				prev = r.TermEnd
			}
		}
	})
}
