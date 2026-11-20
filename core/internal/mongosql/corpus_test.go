package mongosql

import (
	"bytes"
	"encoding/json"
	"flag"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"go.mongodb.org/mongo-driver/v2/bson"

	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

var update = flag.Bool("update", false, "rewrite the expected .mql.json files of the translation corpus")

const corpusDatabase = "shop"

const minimumCorpusSize = 50

type goldenLocation struct {
	Offset uint32 `json:"offset"`
	At     string `json:"at"`
}

type goldenWarning struct {
	Message string `json:"message"`
	goldenLocation
}

type goldenError struct {
	Kind    string `json:"kind"`
	Message string `json:"message"`
	goldenLocation
}

type golden struct {
	Kind       string          `json:"kind,omitempty"`
	Database   string          `json:"database,omitempty"`
	Collection string          `json:"collection,omitempty"`
	Filter     json.RawMessage `json:"filter,omitempty"`
	Projection json.RawMessage `json:"projection,omitempty"`
	Sort       json.RawMessage `json:"sort,omitempty"`
	Skip       uint64          `json:"skip,omitempty"`
	Limit      *uint64         `json:"limit,omitempty"`
	Shell      string          `json:"shell,omitempty"`
	Warnings   []goldenWarning `json:"warnings,omitempty"`
	Error      *goldenError    `json:"error,omitempty"`
}

func TestCorpus(t *testing.T) {
	files, err := filepath.Glob(filepath.Join("testdata", "corpus", "*.sql"))
	if err != nil {
		t.Fatal(err)
	}
	if len(files) < minimumCorpusSize {
		t.Errorf("corpus has %d cases, want at least %d", len(files), minimumCorpusSize)
	}
	for _, file := range files {
		name := strings.TrimSuffix(filepath.Base(file), ".sql")
		t.Run(name, func(t *testing.T) {
			src, err := os.ReadFile(file)
			if err != nil {
				t.Fatal(err)
			}
			sql := string(src)
			resp := Translate(corpusDatabase, sql)
			checkInvariants(t, name, sql, resp)
			got := renderGolden(t, sql, resp)
			want := strings.TrimSuffix(file, ".sql") + ".mql.json"
			if *update {
				if err := os.WriteFile(want, got, 0o600); err != nil {
					t.Fatal(err)
				}
				return
			}
			expected, err := os.ReadFile(want)
			if err != nil {
				t.Fatalf("%v (run go test -update)", err)
			}
			if !bytes.Equal(expected, got) {
				t.Errorf("translation differs from %s:\n got: %s\nwant: %s", want, got, expected)
			}
		})
	}
}

func checkInvariants(t *testing.T, name, sql string, resp *queravuev1.TranslateMongoSqlResponse) {
	t.Helper()
	wantsUnsupported := strings.HasPrefix(name, "unsupported_")
	wantsParseError := strings.HasPrefix(name, "parse_error_")
	switch e := resp.GetError(); {
	case wantsUnsupported && e.GetKind() != queravuev1.QueryBuilderErrorKind_QUERY_BUILDER_ERROR_KIND_UNSUPPORTED_CONSTRUCT,
		wantsParseError && e.GetKind() != queravuev1.QueryBuilderErrorKind_QUERY_BUILDER_ERROR_KIND_PARSE:
		t.Fatalf("error = %v, want the kind the case name promises", e)
	case !wantsUnsupported && !wantsParseError && e != nil:
		t.Fatalf("unexpected error: %v", e)
	case e != nil:
		if e.Offset == nil || int(e.GetOffset()) > len(sql) {
			t.Fatalf("error offset %v is outside the SQL text", e.Offset)
		}
		return
	}
	for _, doc := range []string{resp.GetFilterEjson(), resp.GetProjectionEjson(), resp.GetSortEjson()} {
		if doc == "" {
			continue
		}
		var d bson.D
		if err := bson.UnmarshalExtJSON([]byte(doc), true, &d); err != nil {
			t.Errorf("%s is not canonical EJSON: %v", doc, err)
		}
	}
}

func renderGolden(t *testing.T, sql string, resp *queravuev1.TranslateMongoSqlResponse) []byte {
	t.Helper()
	g := golden{}
	if e := resp.GetError(); e != nil {
		g.Error = &goldenError{
			Kind:           strings.TrimPrefix(e.GetKind().String(), "QUERY_BUILDER_ERROR_KIND_"),
			Message:        e.GetMessage(),
			goldenLocation: locate(sql, e.GetOffset()),
		}
	} else {
		g.Kind = strings.TrimPrefix(resp.GetKind().String(), "MONGO_SQL_RESULT_KIND_")
		g.Database = resp.GetDatabase()
		g.Collection = resp.GetCollection()
		g.Filter = rawJSON(resp.GetFilterEjson())
		g.Projection = rawJSON(resp.GetProjectionEjson())
		g.Sort = rawJSON(resp.GetSortEjson())
		g.Skip = resp.GetSkip()
		g.Limit = resp.Limit
		g.Shell = resp.GetShellCode()
		for _, w := range resp.GetWarnings() {
			g.Warnings = append(g.Warnings, goldenWarning{Message: w.GetMessage(), goldenLocation: locate(sql, w.GetOffset())})
		}
	}
	var out bytes.Buffer
	enc := json.NewEncoder(&out)
	enc.SetEscapeHTML(false)
	enc.SetIndent("", "  ")
	if err := enc.Encode(g); err != nil {
		t.Fatal(err)
	}
	return out.Bytes()
}

func rawJSON(text string) json.RawMessage {
	if text == "" {
		return nil
	}
	return json.RawMessage(text)
}

func locate(sql string, offset uint32) goldenLocation {
	rest := sql[offset:]
	if i := strings.IndexByte(rest, '\n'); i >= 0 {
		rest = rest[:i]
	}
	if len(rest) > 24 {
		rest = rest[:24]
	}
	return goldenLocation{Offset: offset, At: strings.ToValidUTF8(rest, "")}
}
