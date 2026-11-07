package shell

import (
	"context"
	"encoding/json"
	"fmt"
	"strings"
	"sync"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
)

type fakeBackend struct {
	mu       sync.Mutex
	commands []string
	reply    func(db, cmd string) (string, error)
	docs     []string
	opened   []engine.CursorSpec
}

func (f *fakeBackend) RunCommand(_ context.Context, db string, cmd engine.Document) (engine.Document, error) {
	f.mu.Lock()
	f.commands = append(f.commands, db+" "+cmd)
	f.mu.Unlock()
	if f.reply != nil {
		return f.reply(db, cmd)
	}
	return `{"ok":{"$numberInt":"1"}}`, nil
}

func (f *fakeBackend) OpenCursor(_ context.Context, spec engine.CursorSpec) (engine.DocCursor, error) {
	f.mu.Lock()
	f.opened = append(f.opened, spec)
	f.mu.Unlock()
	return &sliceCursor{docs: f.docs}, nil
}

type sliceCursor struct {
	docs []string
	i    int
}

func (c *sliceCursor) Next(ctx context.Context) (engine.Document, bool, error) {
	if err := ctx.Err(); err != nil {
		return "", false, err
	}
	if c.i >= len(c.docs) {
		return "", false, nil
	}
	c.i++
	return c.docs[c.i-1], true, nil
}
func (c *sliceCursor) Close() error { return nil }

type recorder struct{ lines []string }

func (r *recorder) Print(l Level, text string) { r.lines = append(r.lines, string(l)+": "+text) }
func (r *recorder) Result(res Result) {
	switch res.Kind {
	case ResultCursor:
		r.lines = append(r.lines, "cursor: "+res.Cursor.Spec.Collection)
	case ResultWrite:
		r.lines = append(r.lines, "write "+res.WriteOp+": "+res.Text)
	case ResultDocument:
		r.lines = append(r.lines, "doc: "+res.Text)
	default:
		r.lines = append(r.lines, "scalar: "+res.Text)
	}
}

func newShell(t *testing.T, b *fakeBackend, opt Options) *Shell {
	t.Helper()
	if opt.Database == "" {
		opt.Database = "test"
	}
	s, err := New(b, opt)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(s.Close)
	return s
}

func eval(t *testing.T, s *Shell, code string) ([]string, *Error) {
	t.Helper()
	r := &recorder{}
	_, err := s.Eval(context.Background(), code, false, r)
	return r.lines, err
}

func TestEvalTable(t *testing.T) {
	tests := []struct {
		name, code string
		want       []string
	}{
		{"scalar", `1 + 2`, []string{`scalar: {"$numberInt":"3"}`}},
		{"string", `"a"`, []string{`scalar: "a"`}},
		{"null", `null`, []string{`scalar: null`}},
		{"undefined prints nothing", `var x = 1`, nil},
		{"document", `({a: 1, b: "x"})`, []string{`doc: {"a":{"$numberInt":"1"},"b":"x"}`}},
		{"double", `1.5`, []string{`scalar: {"$numberDouble":"1.5"}`}},
		{"big integer is double", `3000000000`, []string{`scalar: {"$numberDouble":"3000000000.0"}`}},
		{"objectid", `ObjectId("5f1d7f3e9b1c2a0012345678")`, []string{`scalar: {"$oid":"5f1d7f3e9b1c2a0012345678"}`}},
		{"long", `NumberLong("9223372036854775807")`, []string{`scalar: {"$numberLong":"9223372036854775807"}`}},
		{"int32", `NumberInt(7)`, []string{`scalar: {"$numberInt":"7"}`}},
		{"decimal", `NumberDecimal("1.10")`, []string{`scalar: {"$numberDecimal":"1.10"}`}},
		{"date", `ISODate("2020-01-02T03:04:05Z")`, []string{`scalar: {"$date":{"$numberLong":"1577934245000"}}`}},
		{"date without zone is utc", `ISODate("2020-01-02T03:04:05")`, []string{`scalar: {"$date":{"$numberLong":"1577934245000"}}`}},
		{"uuid", `UUID("0123456789abcdef0123456789abcdef")`, []string{`scalar: {"$binary":{"base64":"ASNFZ4mrze8BI0VniavN7w==","subType":"04"}}`}},
		{"bindata", `BinData(0, "aGk=")`, []string{`scalar: {"$binary":{"base64":"aGk=","subType":"00"}}`}},
		{"timestamp", `Timestamp(10, 2)`, []string{`scalar: {"$timestamp":{"t":10,"i":2}}`}},
		{"minkey", `MinKey()`, []string{`scalar: {"$minKey":1}`}},
		{"regex", `/ab+c/i`, []string{`scalar: {"$regularExpression":{"pattern":"ab+c","options":"i"}}`}},
		{"print", `print("a", 1, {b: 2})`, []string{`log: a 1 { "b": 2 }`}},
		{"printjson", `printjson({a: [1, 2]})`, []string{"log: {\n  \"a\": [\n    1,\n    2\n  ]\n}"}},
		{"console levels", `console.warn("w"); console.error("e")`, []string{"warn: w", "error: e"}},
		{"variables persist across lines", "var n = 40;\nn + 2", []string{`scalar: {"$numberInt":"42"}`}},
		{"function and let", "let f = function(x) { return x * 2 };\nf(4)", []string{`scalar: {"$numberInt":"8"}`}},
		{"use line", "use shop\ndb.getName()", []string{"log: switched to db shop", `scalar: "shop"`}},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			s := newShell(t, &fakeBackend{}, Options{})
			got, err := eval(t, s, tc.code)
			if err != nil {
				t.Fatalf("error: %v", err)
			}
			if strings.Join(got, "|") != strings.Join(tc.want, "|") {
				t.Fatalf("got %q, want %q", got, tc.want)
			}
		})
	}
}

func TestVariablesPersistBetweenEvals(t *testing.T) {
	s := newShell(t, &fakeBackend{}, Options{})
	if _, err := eval(t, s, "var counter = 1; let again = 2; const third = 3"); err != nil {
		t.Fatal(err)
	}
	got, err := eval(t, s, "counter + again + third")
	if err != nil || len(got) != 1 || got[0] != `scalar: {"$numberInt":"6"}` {
		t.Fatalf("got %v, %v", got, err)
	}
}

func TestErrors(t *testing.T) {
	tests := []struct {
		name, code string
		kind       ErrorKind
		line       int
	}{
		{"syntax", "var a = ;", KindSyntax, 1},
		{"runtime with line", "var a = 1;\nvar b = 2;\nnull.x", KindRuntime, 3},
		{"thrown", "throw new Error('boom')", KindRuntime, 1},
		{"load", "load('x.js')", KindUnsupported, 1},
		{"require", "require('fs')", KindUnsupported, 1},
		{"bad objectid", "ObjectId('zz')", KindRuntime, 1},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			s := newShell(t, &fakeBackend{}, Options{})
			_, err := eval(t, s, tc.code)
			if err == nil {
				t.Fatal("want error")
			}
			if err.Kind != tc.kind || err.Line != tc.line {
				t.Fatalf("got kind %d line %d (%s), want kind %d line %d", err.Kind, err.Line, err.Message, tc.kind, tc.line)
			}
		})
	}
}

func TestSandboxHasNoHostAccess(t *testing.T) {
	s := newShell(t, &fakeBackend{}, Options{})
	for _, name := range []string{"process", "fetch", "XMLHttpRequest", "fs", "Buffer", "setTimeout"} {
		got, err := eval(t, s, "typeof "+name)
		if err != nil || len(got) != 1 || got[0] != `scalar: "undefined"` {
			t.Errorf("typeof %s: got %v, %v", name, got, err)
		}
	}
}

func TestCancelInfiniteLoop(t *testing.T) {
	s := newShell(t, &fakeBackend{}, Options{})
	ctx, cancel := context.WithCancel(context.Background())
	go func() { time.Sleep(50 * time.Millisecond); cancel() }()
	_, err := s.Eval(ctx, "while (true) {}", false, &recorder{})
	if err == nil || err.Kind != KindCanceled {
		t.Fatalf("got %v", err)
	}
	if got, err := eval(t, s, "1"); err != nil || len(got) != 1 {
		t.Fatalf("shell unusable after cancel: %v %v", got, err)
	}
}

func TestCancelMethod(t *testing.T) {
	s := newShell(t, &fakeBackend{}, Options{})
	go func() { time.Sleep(50 * time.Millisecond); s.Cancel() }()
	_, err := s.Eval(context.Background(), "sleep(60000)", false, &recorder{})
	if err == nil || err.Kind != KindCanceled {
		t.Fatalf("got %v", err)
	}
}

func TestTimeout(t *testing.T) {
	s := newShell(t, &fakeBackend{}, Options{Timeout: 50 * time.Millisecond})
	_, err := eval(t, s, "while (true) {}")
	if err == nil || err.Kind != KindTimeout {
		t.Fatalf("got %v", err)
	}
}

func TestOutputLimit(t *testing.T) {
	s := newShell(t, &fakeBackend{}, Options{OutputCap: 100})
	got, err := eval(t, s, "for (var i = 0; i < 1000; i++) print('xxxxxxxxxx')")
	if err == nil || err.Kind != KindOutputLimit {
		t.Fatalf("got %v", err)
	}
	if len(got) > 11 {
		t.Fatalf("printed %d lines past the cap", len(got))
	}
}

func TestOutputLimitCannotBeCaught(t *testing.T) {
	s := newShell(t, &fakeBackend{}, Options{OutputCap: 50})
	_, err := eval(t, s, "try { for (var i = 0; i < 100; i++) print('xxxxxxxxxx') } catch (e) { print('caught') }")
	if err == nil || err.Kind != KindOutputLimit {
		t.Fatalf("got %v", err)
	}
}

func TestStackOverflowIsAnError(t *testing.T) {
	s := newShell(t, &fakeBackend{}, Options{})
	_, err := eval(t, s, "function f() { return f() + 1 }\nf()")
	if err == nil || err.Kind != KindRuntime {
		t.Fatalf("got %v", err)
	}
}

func TestCommandsAreEJSON(t *testing.T) {
	b := &fakeBackend{reply: func(_, _ string) (string, error) {
		return `{"n":{"$numberInt":"1"},"ok":{"$numberInt":"1"}}`, nil
	}}
	s := newShell(t, b, Options{})
	got, err := eval(t, s, `db.users.deleteOne({_id: 5, name: "a"})`)
	if err != nil {
		t.Fatal(err)
	}
	if want := `write deleteOne: {"acknowledged":true,"deletedCount":{"$numberInt":"1"}}`; len(got) != 1 || got[0] != want {
		t.Fatalf("got %v", got)
	}
	var cmd map[string]json.RawMessage
	_ = json.Unmarshal([]byte(strings.TrimPrefix(b.commands[0], "test ")), &cmd)
	if string(cmd["delete"]) != `"users"` {
		t.Fatalf("command: %s", b.commands[0])
	}
}

func TestInsertAddsObjectIDFirst(t *testing.T) {
	b := &fakeBackend{}
	s := newShell(t, b, Options{})
	got, err := eval(t, s, `var r = db.c.insertOne({a: 1}); typeof r.insertedId`)
	if err != nil || got[0] != `scalar: "object"` {
		t.Fatalf("%v %v", got, err)
	}
	if !strings.Contains(b.commands[0], `"documents":[{"_id":{"$oid":"`) {
		t.Fatalf("command: %s", b.commands[0])
	}
}

func TestCursorHandleForUnconsumedCursor(t *testing.T) {
	s := newShell(t, &fakeBackend{}, Options{})
	got, err := eval(t, s, `db.users.find({a: 1}).sort({b: -1}).limit(5)`)
	if err != nil || len(got) != 1 || got[0] != "cursor: users" {
		t.Fatalf("%v %v", got, err)
	}
}

func TestCursorIteration(t *testing.T) {
	b := &fakeBackend{docs: []string{`{"_id":{"$numberInt":"1"}}`, `{"_id":{"$numberInt":"2"}}`, `{"_id":{"$numberInt":"3"}}`}}
	s := newShell(t, b, Options{})
	tests := map[string]string{
		"toArray":   `db.c.find().toArray().length`,
		"forEach":   `var n = 0; db.c.find().forEach(function (d) { n += d._id }); n`,
		"map":       `db.c.find().map(function (d) { return d._id * 2 }).toArray().join(",")`,
		"itcount":   `db.c.find().itcount()`,
		"hasNext":   `var c = db.c.find(); c.next(); c.next(); c.hasNext()`,
		"exhausted": `var c = db.c.find(); c.next(); c.next(); c.next(); c.hasNext()`,
	}
	want := map[string]string{
		"toArray":   `scalar: {"$numberInt":"3"}`,
		"forEach":   `scalar: {"$numberInt":"6"}`,
		"map":       `scalar: "2,4,6"`,
		"itcount":   `scalar: {"$numberInt":"3"}`,
		"hasNext":   `scalar: true`,
		"exhausted": `scalar: false`,
	}
	for name, code := range tests {
		t.Run(name, func(t *testing.T) {
			got, err := eval(t, s, code)
			if err != nil || len(got) != 1 || got[0] != want[name] {
				t.Fatalf("got %v, %v", got, err)
			}
		})
	}
}

func TestCursorModifiersAfterStartFail(t *testing.T) {
	s := newShell(t, &fakeBackend{docs: []string{`{}`}}, Options{})
	_, err := eval(t, s, `var c = db.c.find(); c.hasNext(); c.limit(1)`)
	if err == nil || !strings.Contains(err.Message, "already started") {
		t.Fatalf("got %v", err)
	}
}

func TestSpecReachesBackend(t *testing.T) {
	b := &fakeBackend{}
	s := newShell(t, b, Options{})
	if _, err := eval(t, s, `db.c.find({a: 1}, {b: 1}).sort({c: -1}).skip(2).limit(-3).batchSize(10).hint({a: 1}).toArray()`); err != nil {
		t.Fatal(err)
	}
	sp := b.opened[0]
	if sp.Collection != "c" || sp.Database != "test" || sp.Skip != 2 || sp.Limit != 3 || sp.BatchSize != 10 {
		t.Fatalf("%+v", sp)
	}
	if sp.Filter != `{"a":{"$numberInt":"1"}}` || sp.Sort != `{"c":{"$numberInt":"-1"}}` || sp.Projection != `{"b":{"$numberInt":"1"}}` {
		t.Fatalf("%+v", sp)
	}
}

func TestProductionGates(t *testing.T) {
	gated := []string{
		`db.c.deleteMany({})`, `db.c.deleteMany()`, `db.c.drop()`, `db.dropDatabase()`, `db.c.updateMany({}, {$set: {a: 1}})`,
		`db.adminCommand({dropDatabase: 1})`, `db.runCommand({delete: "c", deletes: []})`,
		`db.c.aggregate([{$out: "x"}])`, `db.c.bulkWrite([{deleteMany: {filter: {}}}])`,
	}
	for _, code := range gated {
		t.Run(code, func(t *testing.T) {
			b := &fakeBackend{}
			s := newShell(t, b, Options{Production: true})
			_, err := eval(t, s, "try { "+code+" } catch (e) {}\nprint('after')")
			if err == nil || err.Kind != KindConfirmationRequired || err.Operation == "" {
				t.Fatalf("got %v", err)
			}
			if len(b.commands) != 0 {
				t.Fatalf("gated operation reached the server: %v", b.commands)
			}
			r := &recorder{}
			if _, err := s.Eval(context.Background(), code, true, r); err != nil {
				t.Fatalf("confirmed run failed: %v", err)
			}
			if len(b.commands) == 0 && len(b.opened) == 0 {
				t.Fatal("confirmed operation did not run")
			}
		})
	}
}

func TestNotGatedOutsideProduction(t *testing.T) {
	b := &fakeBackend{}
	s := newShell(t, b, Options{})
	for _, code := range []string{`db.c.deleteMany({})`, `db.c.drop()`, `db.c.updateMany({}, {$set: {a: 1}})`} {
		if _, err := eval(t, s, code); err != nil {
			t.Errorf("%s: %v", code, err)
		}
	}
}

func TestDropDatabaseAlwaysAsks(t *testing.T) {
	s := newShell(t, &fakeBackend{}, Options{})
	_, err := eval(t, s, `db.dropDatabase()`)
	if err == nil || err.Kind != KindConfirmationRequired {
		t.Fatalf("got %v", err)
	}
}

func TestProductionAllowsFilteredWrites(t *testing.T) {
	s := newShell(t, &fakeBackend{}, Options{Production: true})
	for _, code := range []string{`db.c.deleteMany({a: 1})`, `db.c.updateMany({a: 1}, {$set: {b: 1}})`, `db.c.insertOne({a: 1})`} {
		if _, err := eval(t, s, code); err != nil {
			t.Errorf("%s: %v", code, err)
		}
	}
}

func TestServerErrorKind(t *testing.T) {
	b := &fakeBackend{reply: func(string, string) (string, error) {
		return "", &engine.Error{Kind: engine.KindServer, Engine: "mongodb", Op: "run command", Msg: "boom", Code: 11000}
	}}
	s := newShell(t, b, Options{})
	_, err := eval(t, s, `db.c.insertOne({a: 1})`)
	if err == nil || err.Kind != KindServer || err.Message != "MongoServerError: boom" {
		t.Fatalf("got %+v", err)
	}
	got, _ := eval(t, s, `try { db.c.insertOne({a: 1}) } catch (e) { e.code }`)
	if len(got) != 1 || got[0] != `scalar: {"$numberInt":"11000"}` {
		t.Fatalf("got %v", got)
	}
}

func TestWriteErrorsBecomeExceptions(t *testing.T) {
	b := &fakeBackend{reply: func(string, string) (string, error) {
		return `{"n":{"$numberInt":"0"},"writeErrors":[{"index":{"$numberInt":"0"},"code":{"$numberInt":"11000"},"errmsg":"E11000 duplicate key"}],"ok":{"$numberInt":"1"}}`, nil
	}}
	s := newShell(t, b, Options{})
	_, err := eval(t, s, `db.c.insertOne({_id: 1})`)
	if err == nil || err.Kind != KindServer || !strings.Contains(err.Message, "E11000") {
		t.Fatalf("got %+v", err)
	}
}

func TestUpdateRequiresOperators(t *testing.T) {
	s := newShell(t, &fakeBackend{}, Options{})
	_, err := eval(t, s, `db.c.updateOne({a: 1}, {b: 2})`)
	if err == nil || !strings.Contains(err.Message, "atomic operators") {
		t.Fatalf("got %v", err)
	}
	_, err = eval(t, s, `db.c.replaceOne({a: 1}, {$set: {b: 2}})`)
	if err == nil || !strings.Contains(err.Message, "must not contain atomic operators") {
		t.Fatalf("got %v", err)
	}
}

func TestCollectionAccess(t *testing.T) {
	s := newShell(t, &fakeBackend{}, Options{})
	tests := map[string]string{
		`db.users.getName()`:                       `"users"`,
		`db["my-coll"].getName()`:                  `"my-coll"`,
		`db.getCollection("x").getName()`:          `"x"`,
		`db.a.b.getName()`:                         `"a.b"`,
		`db.users.getFullName()`:                   `"test.users"`,
		`db.getSiblingDB("o").users.getFullName()`: `"o.users"`,
		`db.getName()`:                             `"test"`,
	}
	for code, want := range tests {
		got, err := eval(t, s, code)
		if err != nil || len(got) != 1 || got[0] != "scalar: "+want {
			t.Errorf("%s: got %v, %v", code, got, err)
		}
	}
}

func TestFetchCursorPaging(t *testing.T) {
	b := &fakeBackend{docs: []string{`{"a":1}`, `{"a":2}`}}
	s := newShell(t, b, Options{})
	r := &recorder{}
	if _, err := s.Eval(context.Background(), `db.c.find({a: 1}).skip(4).limit(100)`, false, r); err != nil {
		t.Fatal(err)
	}
	var handle string
	s.handlesMu.Lock()
	for id := range s.handles {
		handle = id
	}
	s.handlesMu.Unlock()
	var total int
	err := s.FetchCursor(context.Background(), handle, 10, 20, func(_ uint64, docs []engine.Document, _ bool) error {
		total += len(docs)
		return nil
	})
	if err != nil || total != 2 {
		t.Fatalf("total %d, err %v", total, err)
	}
	sp := b.opened[len(b.opened)-1]
	if sp.Skip != 14 || sp.Limit != 20 {
		t.Fatalf("%+v", sp)
	}
	if err := s.FetchCursor(context.Background(), "nope", 0, 1, nil); err == nil {
		t.Fatal("want not found")
	}
	_ = fmt.Sprint()
}
