package workspace

import (
	"reflect"
	"testing"
)

func TestParseHeader(t *testing.T) {
	tests := []struct {
		name string
		kind Kind
		in   string
		want Meta
	}{
		{"sql line comments", KindSQL, "-- title: Active users\n-- connection: analytics\n-- tags: reports, users\nSELECT 1;", Meta{Title: "Active users", Connection: "analytics", Tags: []string{"reports", "users"}}},
		{"sql block comment", KindSQL, "/*\n * title: Orders\n * description: Daily orders\n */\nSELECT 1;", Meta{Title: "Orders", Description: "Daily orders"}},
		{"sql block without stars", KindSQL, "/* title: T\nconnection: c */\nSELECT 1", Meta{Title: "T", Connection: "c"}},
		{"js line comments", KindMongo, "// title: Cleanup\n// connection: prod\ndb.t.find()", Meta{Title: "Cleanup", Connection: "prod"}},
		{"js block comment", KindMongo, "/*\n title: X\n tags: a,b\n*/\ndb.t.find()", Meta{Title: "X", Tags: []string{"a", "b"}}},
		{"leading blank lines", KindSQL, "\n\n-- title: T\nSELECT 1", Meta{Title: "T"}},
		{"key case and spacing", KindSQL, "--   Title:    Spaced   \nSELECT 1", Meta{Title: "Spaced"}},
		{"plain comment is not a header", KindSQL, "-- get all users\nSELECT 1", Meta{}},
		{"unknown keys only", KindSQL, "-- author: me\nSELECT 1", Meta{}},
		{"unknown keys are ignored beside known", KindSQL, "-- author: me\n-- title: T\nSELECT 1", Meta{Title: "T"}},
		{"header ends at blank line", KindSQL, "-- title: T\n\n-- connection: late\nSELECT 1", Meta{Title: "T"}},
		{"other comment style ignored", KindSQL, "// title: T\nSELECT 1", Meta{}},
		{"unterminated block", KindSQL, "/* title: T\nSELECT 1", Meta{}},
		{"crlf", KindSQL, "-- title: T\r\n-- tags: a\r\nSELECT 1", Meta{Title: "T", Tags: []string{"a"}}},
		{"empty", KindSQL, "", Meta{}},
		{"value with colon", KindSQL, "-- description: see http://x.y\nSELECT 1", Meta{Description: "see http://x.y"}},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			if got := ParseHeader(tc.kind, tc.in); !reflect.DeepEqual(got, tc.want) {
				t.Fatalf("got %+v, want %+v", got, tc.want)
			}
		})
	}
}

func TestApplyHeader(t *testing.T) {
	tests := []struct {
		name string
		kind Kind
		in   string
		meta Meta
		want string
	}{
		{"insert into plain sql", KindSQL, "SELECT 1;\n", Meta{Title: "T", Tags: []string{"a", "b"}}, "-- title: T\n-- tags: a, b\n\nSELECT 1;\n"},
		{"insert into plain js", KindMongo, "db.t.find()\n", Meta{Connection: "c"}, "// connection: c\n\ndb.t.find()\n"},
		{"zero meta leaves file alone", KindSQL, "SELECT 1;\n", Meta{}, "SELECT 1;\n"},
		{"insert into empty file", KindSQL, "", Meta{Title: "T"}, "-- title: T\n"},
		{"update in place", KindSQL, "-- title: Old\n-- connection: c\nSELECT 1", Meta{Title: "New", Connection: "c"}, "-- title: New\n-- connection: c\nSELECT 1"},
		{"append missing key", KindSQL, "-- title: T\nSELECT 1", Meta{Title: "T", Description: "d"}, "-- title: T\n-- description: d\nSELECT 1"},
		{"remove empty key", KindSQL, "-- title: T\n-- connection: c\nSELECT 1", Meta{Title: "T"}, "-- title: T\nSELECT 1"},
		{"remove whole header", KindSQL, "-- title: T\n\nSELECT 1", Meta{}, "SELECT 1"},
		{"keep unknown and free lines", KindSQL, "-- author: me\n-- title: Old\n-- note\nSELECT 1", Meta{Title: "New"}, "-- author: me\n-- title: New\n-- note\nSELECT 1"},
		{"block style kept", KindSQL, "/*\n * title: Old\n */\nSELECT 1", Meta{Title: "New", Tags: []string{"x"}}, "/*\n * title: New\n * tags: x\n */\nSELECT 1"},
		{"js block style kept", KindMongo, "/* title: Old */\ndb.t.find()", Meta{Title: "New"}, "/*\n * title: New\n */\ndb.t.find()"},
		{"duplicate key collapses", KindSQL, "-- title: A\n-- title: B\nSELECT 1", Meta{Title: "C"}, "-- title: C\nSELECT 1"},
		{"newlines in values are flattened", KindSQL, "SELECT 1", Meta{Title: "a\nb"}, "-- title: a b\n\nSELECT 1"},
		{"crlf preserved", KindSQL, "SELECT 1\r\nFROM t\r\n", Meta{Title: "T", Tags: []string{"a"}}, "-- title: T\r\n-- tags: a\r\n\r\nSELECT 1\r\nFROM t\r\n"},
		{"plain leading comment is kept", KindSQL, "-- explain\nSELECT 1", Meta{Title: "T"}, "-- title: T\n\n-- explain\nSELECT 1"},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			got := ApplyHeader(tc.kind, tc.in, tc.meta)
			if got != tc.want {
				t.Fatalf("got %q, want %q", got, tc.want)
			}
			if again := ApplyHeader(tc.kind, got, tc.meta); again != got {
				t.Fatalf("not idempotent: %q then %q", got, again)
			}
			if tc.meta.Title != "" && ParseHeader(tc.kind, got).Title != oneLine(tc.meta.Title) {
				t.Fatalf("written header does not parse back: %q", got)
			}
		})
	}
}

func TestKindOf(t *testing.T) {
	for name, want := range map[string]Kind{"a.sql": KindSQL, "a.mongo.js": KindMongo, "a.js": KindOther, "a.txt": KindOther, "mongo.js": KindOther, "q.SQL": KindOther} {
		if got := KindOf(name); got != want {
			t.Errorf("KindOf(%q) = %d, want %d", name, got, want)
		}
	}
}
