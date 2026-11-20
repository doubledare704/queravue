package mongosql

import (
	"os"
	"path/filepath"
	"strings"
	"testing"
)

const minimumComparableCases = 60

type comparableCase struct {
	name    string
	ordered bool
	sql     string
}

func readComparableCases(t testing.TB) []comparableCase {
	t.Helper()
	list, err := os.ReadFile(filepath.Join("testdata", "comparable.txt"))
	if err != nil {
		t.Fatal(err)
	}
	var cases []comparableCase
	for _, line := range strings.Split(strings.TrimSpace(string(list)), "\n") {
		name, ordered := strings.CutSuffix(strings.TrimSpace(line), " ordered")
		sql, err := os.ReadFile(filepath.Join("testdata", "corpus", name+".sql"))
		if err != nil {
			t.Fatalf("comparable case %q: %v", name, err)
		}
		cases = append(cases, comparableCase{name: name, ordered: ordered, sql: string(sql)})
	}
	return cases
}

func TestComparableCasesTranslate(t *testing.T) {
	cases := readComparableCases(t)
	if len(cases) < minimumComparableCases {
		t.Errorf("%d comparable cases, want at least %d", len(cases), minimumComparableCases)
	}
	for _, c := range cases {
		if resp := Translate(corpusDatabase, c.sql); resp.GetError() != nil {
			t.Errorf("%s does not translate: %v", c.name, resp.GetError())
		}
	}
}
