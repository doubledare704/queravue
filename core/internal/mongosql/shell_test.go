package mongosql

import (
	"context"
	"errors"
	"os"
	"path/filepath"
	"strings"
	"testing"

	"go.mongodb.org/mongo-driver/v2/bson"

	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/shell"
)

type unusedBackend struct{}

func (unusedBackend) RunCommand(context.Context, string, engine.Document) (engine.Document, error) {
	return `{"ok":{"$numberInt":"1"}}`, nil
}

func (unusedBackend) OpenCursor(context.Context, engine.CursorSpec) (engine.DocCursor, error) {
	return nil, errors.New("the test opens no cursors")
}

type cursorRecorder struct{ spec *engine.CursorSpec }

func (r *cursorRecorder) Print(shell.Level, string) {}

func (r *cursorRecorder) Result(res shell.Result) {
	if res.Kind == shell.ResultCursor {
		r.spec = &res.Cursor.Spec
	}
}

func TestShellCodeOpensTheTranslatedFind(t *testing.T) {
	sh, err := shell.New(unusedBackend{}, shell.Options{Database: "other"})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(sh.Close)
	files, err := filepath.Glob(filepath.Join("testdata", "corpus", "*.sql"))
	if err != nil {
		t.Fatal(err)
	}
	for _, file := range files {
		src, err := os.ReadFile(file)
		if err != nil {
			t.Fatal(err)
		}
		resp := Translate(corpusDatabase, string(src))
		if resp.GetKind() != queravuev1.MongoSqlResultKind_MONGO_SQL_RESULT_KIND_FIND {
			continue
		}
		t.Run(strings.TrimSuffix(filepath.Base(file), ".sql"), func(t *testing.T) {
			rec := &cursorRecorder{}
			if _, evalErr := sh.Eval(context.Background(), resp.GetShellCode(), false, rec); evalErr != nil {
				t.Fatalf("eval %s: %v", resp.GetShellCode(), evalErr)
			}
			if rec.spec == nil {
				t.Fatalf("%s opened no cursor", resp.GetShellCode())
			}
			got := rec.spec
			if got.Database != resp.GetDatabase() || got.Collection != resp.GetCollection() {
				t.Errorf("namespace = %s.%s, want %s.%s", got.Database, got.Collection, resp.GetDatabase(), resp.GetCollection())
			}
			assertSameDocument(t, "filter", got.Filter, resp.GetFilterEjson())
			assertSameDocument(t, "projection", got.Projection, resp.GetProjectionEjson())
			assertSameDocument(t, "sort", got.Sort, resp.GetSortEjson())
			if got.Skip != resp.GetSkip() || got.Limit != resp.GetLimit() {
				t.Errorf("skip, limit = %d, %d, want %d, %d", got.Skip, got.Limit, resp.GetSkip(), resp.GetLimit())
			}
		})
	}
}

func assertSameDocument(t *testing.T, what, got, want string) {
	t.Helper()
	if got == "" && want == "" {
		return
	}
	if canonical(t, got) != canonical(t, want) {
		t.Errorf("%s = %s, want %s", what, got, want)
	}
}

func canonical(t *testing.T, text string) string {
	t.Helper()
	if text == "" {
		text = "{}"
	}
	var d bson.D
	if err := bson.UnmarshalExtJSON([]byte(text), false, &d); err != nil {
		t.Fatalf("parse %s: %v", text, err)
	}
	out, err := bson.MarshalExtJSON(d, true, false)
	if err != nil {
		t.Fatal(err)
	}
	return string(out)
}
