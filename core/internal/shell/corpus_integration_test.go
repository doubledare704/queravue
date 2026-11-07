//go:build integration

package shell_test

import (
	"context"
	"flag"
	"fmt"
	"os"
	"path/filepath"
	"regexp"
	"runtime"
	"strings"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/mongo"
	"github.com/doubledare704/queravue/core/internal/shell"
)

var update = flag.Bool("update", false, "rewrite the expected .out files of the snippet corpus")

func env(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}

func connect(t *testing.T) engine.ShellBackend {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	cfg := engine.Config{EngineID: mongo.ID, Params: map[string]string{
		mongo.ParamHosts: env("MONGO_HOST", "127.0.0.1") + ":" + env("MONGO_PORT", "27017"), mongo.ParamReplicaSet: "rs0",
	}}
	c, err := mongo.New(mongo.VariantMongoDB).Connect(ctx, cfg, engine.Secret{})
	if err != nil {
		t.Fatalf("connect: %v (docker compose -f dev/docker-compose.yml up -d --wait mongo)", err)
	}
	t.Cleanup(func() { _ = c.Close() })
	b, ok := engine.As[engine.ShellBackend](c)
	if !ok {
		t.Fatal("mongo conn is not a ShellBackend")
	}
	return b
}

type transcript struct {
	b     strings.Builder
	shell *shell.Shell
	ctx   context.Context
}

func (r *transcript) Print(l shell.Level, text string) {
	prefix := "out"
	if l != shell.LevelLog {
		prefix = string(l)
	}
	fmt.Fprintf(&r.b, "%s: %s\n", prefix, text)
}

func (r *transcript) Result(res shell.Result) {
	switch res.Kind {
	case shell.ResultScalar:
		fmt.Fprintf(&r.b, "value: %s\n", res.Text)
	case shell.ResultDocument:
		fmt.Fprintf(&r.b, "doc: %s\n", res.Text)
	case shell.ResultWrite:
		fmt.Fprintf(&r.b, "write %s: %s\n", res.WriteOp, res.Text)
	case shell.ResultCursor:
		kind := "find"
		if res.Cursor.Spec.Kind == engine.CursorAggregate {
			kind = "aggregate"
		}
		fmt.Fprintf(&r.b, "cursor %s on %s\n", kind, res.Cursor.Spec.Collection)
		err := r.shell.FetchCursor(r.ctx, res.Cursor.ID, 0, 100, func(_ uint64, docs []engine.Document, _ bool) error {
			for _, d := range docs {
				fmt.Fprintf(&r.b, "  %s\n", d)
			}
			return nil
		})
		if err != nil {
			fmt.Fprintf(&r.b, "  fetch error: %v\n", err)
		}
	}
}

func (r *transcript) failure(e *shell.Error) {
	kinds := map[shell.ErrorKind]string{
		shell.KindRuntime: "runtime", shell.KindSyntax: "syntax", shell.KindConfirmationRequired: "confirmation",
		shell.KindOutputLimit: "output-limit", shell.KindTimeout: "timeout", shell.KindCanceled: "canceled",
		shell.KindServer: "server", shell.KindUnsupported: "unsupported",
	}
	fmt.Fprintf(&r.b, "error %s line %d: %s\n", kinds[e.Kind], e.Line, e.Message)
}

var nonWord = regexp.MustCompile(`[^a-z0-9]+`)

func dbName(file string) string {
	return "qv_corpus_" + nonWord.ReplaceAllString(strings.ToLower(strings.TrimSuffix(file, ".js")), "_")
}

func dropDatabases(ctx context.Context, b engine.ShellBackend, names ...string) {
	for _, n := range names {
		_, _ = b.RunCommand(ctx, n, `{"dropDatabase":{"$numberInt":"1"}}`)
	}
}

func TestSnippetCorpus(t *testing.T) {
	files, err := filepath.Glob("testdata/corpus/*.js")
	if err != nil || len(files) == 0 {
		t.Fatalf("no corpus files: %v", err)
	}
	if len(files) < 60 {
		t.Fatalf("corpus has %d snippets, want at least 60", len(files))
	}
	backend := connect(t)
	for _, f := range files {
		name := filepath.Base(f)
		t.Run(strings.TrimSuffix(name, ".js"), func(t *testing.T) {
			code, err := os.ReadFile(f)
			if err != nil {
				t.Fatal(err)
			}
			ctx, cancel := context.WithTimeout(context.Background(), time.Minute)
			defer cancel()
			db := dbName(name)
			dropDatabases(ctx, backend, db, db+"_other", db+"_sibling")
			t.Cleanup(func() { dropDatabases(context.Background(), backend, db, db+"_other", db+"_sibling") })

			sh, err := shell.New(backend, shell.Options{Database: db})
			if err != nil {
				t.Fatal(err)
			}
			defer sh.Close()
			tr := &transcript{shell: sh, ctx: ctx}
			if _, evalErr := sh.Eval(ctx, strings.ReplaceAll(string(code), "$DB", db), true, tr); evalErr != nil {
				tr.failure(evalErr)
			}
			got := tr.b.String()
			want := strings.TrimSuffix(f, ".js") + ".out"
			if *update {
				if err := os.WriteFile(want, []byte(got), 0o644); err != nil {
					t.Fatal(err)
				}
				return
			}
			expected, err := os.ReadFile(want)
			if err != nil {
				t.Fatalf("missing %s (run with -update): %v", want, err)
			}
			if string(expected) != got {
				t.Fatalf("output differs from %s\n--- want\n%s--- got\n%s", want, expected, got)
			}
		})
	}
}

func TestCancelLongFind(t *testing.T) {
	backend := connect(t)
	db := "qv_corpus_cancel_find"
	ctx := context.Background()
	dropDatabases(ctx, backend, db)
	t.Cleanup(func() { dropDatabases(context.Background(), backend, db) })
	sh, err := shell.New(backend, shell.Options{Database: db})
	if err != nil {
		t.Fatal(err)
	}
	defer sh.Close()
	tr := &transcript{shell: sh, ctx: ctx}
	if _, e := sh.Eval(ctx, `db.c.insertMany([{a: 1}, {a: 2}, {a: 3}])`, false, tr); e != nil {
		t.Fatal(e)
	}
	go func() { time.Sleep(300 * time.Millisecond); sh.Cancel() }()
	started := time.Now()
	_, e := sh.Eval(ctx, `db.c.find({$where: "sleep(2000) || true"}).toArray()`, false, tr)
	if e == nil || e.Kind != shell.KindCanceled {
		t.Fatalf("got %v, want canceled", e)
	}
	if took := time.Since(started); took > 3*time.Second {
		t.Fatalf("cancel took %v", took)
	}
	if _, e := sh.Eval(ctx, `db.c.countDocuments()`, false, tr); e != nil {
		t.Fatalf("shell unusable after cancel: %v", e)
	}
}

func TestForEachKeepsMemoryFlat(t *testing.T) {
	backend := connect(t)
	db := "qv_corpus_memory"
	ctx := context.Background()
	dropDatabases(ctx, backend, db)
	t.Cleanup(func() { dropDatabases(context.Background(), backend, db) })
	sh, err := shell.New(backend, shell.Options{Database: db})
	if err != nil {
		t.Fatal(err)
	}
	defer sh.Close()
	tr := &transcript{shell: sh, ctx: ctx}
	const fill = `
for (var b = 0; b < 200; b++) {
  var docs = [];
  for (var i = 0; i < 1000; i++) docs.push({_id: b * 1000 + i, payload: "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx", n: i});
  db.big.insertMany(docs);
}
docs = null;`
	if _, e := sh.Eval(ctx, fill, false, tr); e != nil {
		t.Fatal(e)
	}
	heap := func() uint64 {
		var m runtime.MemStats
		runtime.GC()
		runtime.ReadMemStats(&m)
		return m.HeapAlloc
	}
	before := heap()
	var peak uint64
	stop := make(chan struct{})
	go func() {
		for {
			select {
			case <-stop:
				return
			case <-time.After(50 * time.Millisecond):
				var m runtime.MemStats
				runtime.ReadMemStats(&m)
				peak = max(peak, m.HeapAlloc)
			}
		}
	}()
	tr.b.Reset()
	if _, e := sh.Eval(ctx, `var seen = 0; db.big.find().forEach(function (d) { seen++ }); seen`, false, tr); e != nil {
		t.Fatal(e)
	}
	close(stop)
	if !strings.Contains(tr.b.String(), `"200000"`) {
		t.Fatalf("unexpected output: %s", tr.b.String())
	}
	if growth := int64(peak) - int64(before); growth > 60<<20 {
		t.Fatalf("heap grew by %d MiB while iterating 200k documents", growth>>20)
	}
}
