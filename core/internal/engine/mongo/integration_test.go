//go:build integration

package mongo

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"os"
	"runtime"
	"strings"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func env(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}

// Uses the mongo service from dev/docker-compose.yml seeded with
// `docker compose --profile seed up mongo-seed`. Override with MONGO_HOST,
// MONGO_PORT.
func hostPort() string { return env("MONGO_HOST", "127.0.0.1") + ":" + env("MONGO_PORT", "27017") }

func fieldsConfig() engine.Config {
	return engine.Config{EngineID: ID, Params: map[string]string{
		ParamHosts: hostPort(), ParamReplicaSet: "rs0", ParamDirect: "false",
	}}
}

func connect(t *testing.T) *Conn {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	c, err := New(VariantMongoDB).Connect(ctx, fieldsConfig(), engine.Secret{})
	if err != nil {
		t.Fatalf("connect: %v (docker compose -f dev/docker-compose.yml up -d --wait mongo && ... --profile seed up mongo-seed)", err)
	}
	t.Cleanup(func() { _ = c.Close() })
	return c.(*Conn)
}

type collect struct {
	docs    []string
	keep    int
	n       int
	batches int
	maxB    int
	onBatch func(n int) error
}

func (c *collect) Batch(docs []engine.Document) error {
	c.batches++
	c.maxB = max(c.maxB, len(docs))
	c.n += len(docs)
	for _, d := range docs {
		if len(c.docs) < c.keep {
			c.docs = append(c.docs, d)
		}
	}
	if c.onBatch != nil {
		return c.onBatch(c.n)
	}
	return nil
}

func find(t *testing.T, c *Conn, o engine.FindOptions) []string {
	t.Helper()
	o.Database = "queravue"
	sink := &collect{keep: 1 << 30}
	if err := c.Find(context.Background(), o, sink); err != nil {
		t.Fatalf("find %+v: %v", o, err)
	}
	return sink.docs
}

func decode(t *testing.T, doc string) map[string]any {
	t.Helper()
	var m map[string]any
	if err := json.Unmarshal([]byte(doc), &m); err != nil {
		t.Fatalf("%s: %v", doc, err)
	}
	return m
}

func TestIntegrationConnectFieldsAndURI(t *testing.T) {
	c := connect(t)
	ctx := context.Background()
	if err := c.Ping(ctx); err != nil {
		t.Fatal(err)
	}
	info, err := c.ServerInfo(ctx)
	if err != nil || info.Product != "MongoDB" || !strings.HasPrefix(info.Version, "8.") {
		t.Fatalf("info = %+v, %v", info, err)
	}

	// Pasted URI -> fields -> connect.
	e := New(VariantMongoDB)
	cfg, sec, err := e.ParseURI("mongodb://" + hostPort() + "/queravue?replicaSet=rs0")
	if err != nil {
		t.Fatal(err)
	}
	c2, err := e.Connect(ctx, cfg, sec)
	if err != nil {
		t.Fatalf("connect via parsed URI: %v", err)
	}
	defer c2.Close()
	if err := c2.Ping(ctx); err != nil {
		t.Fatal(err)
	}
}

func TestIntegrationConnectionErrors(t *testing.T) {
	e := New(VariantMongoDB)
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	short, cancelShort := context.WithTimeout(ctx, 2*time.Second)
	defer cancelShort()
	_, err := e.Connect(short, engine.Config{EngineID: ID, Params: map[string]string{ParamHosts: "127.0.0.1:1"}}, engine.Secret{})
	if k := engine.KindOf(err); k != engine.KindNetwork && k != engine.KindTimeout {
		t.Fatalf("unreachable: kind %v (%v)", k, err)
	}
	// The dev server has no auth, so credentials are accepted or rejected
	// depending on the server; only assert that a failure never leaks the secret.
	_, err = e.Connect(ctx, engine.Config{EngineID: ID, Params: map[string]string{ParamHosts: hostPort(), ParamUsername: "nobody"}}, engine.NewSecret("s3cret-pw"))
	if err != nil && strings.Contains(err.Error(), "s3cret-pw") {
		t.Fatalf("error leaks the password: %v", err)
	}
	if k := engine.KindOf(err); err != nil && k != engine.KindAuth {
		t.Fatalf("bad credentials: kind %v (%v)", k, err)
	}
}

func TestIntegrationSchemaTree(t *testing.T) {
	c := connect(t)
	ctx := context.Background()
	dbs, err := c.ListDatabases(ctx)
	if err != nil || !contains(dbs, "queravue") || !contains(dbs, "admin") {
		t.Fatalf("databases = %v, %v", dbs, err)
	}
	if s, _ := c.ListSchemas(ctx, "queravue"); len(s) != 0 {
		t.Errorf("schemas = %v, want none", s)
	}
	objs, err := c.ListObjects(ctx, "queravue", "")
	if err != nil {
		t.Fatal(err)
	}
	by := map[string]engine.SchemaObject{}
	for _, o := range objs {
		by[o.Name] = o
	}
	if by["users"].Type != engine.ObjectTypeCollection || by["users"].EstimatedRows != 5 {
		t.Errorf("users = %+v", by["users"])
	}
	if by["paid_orders"].Type != engine.ObjectTypeView {
		t.Errorf("paid_orders = %+v", by["paid_orders"])
	}
	if !by["audit_log"].Capped {
		t.Errorf("audit_log = %+v", by["audit_log"])
	}
	if n := by["events"].EstimatedRows; n != 1_000_000 {
		t.Errorf("events estimate = %d", n)
	}
	d, err := c.DescribeTable(ctx, "queravue", "", "orders")
	if err != nil || !d.CanEdit || d.Type != engine.ObjectTypeCollection {
		t.Errorf("describe = %+v, %v", d, err)
	}
}

func TestIntegrationFindFilterSortProjectionPage(t *testing.T) {
	c := connect(t)
	docs := find(t, c, engine.FindOptions{Collection: "orders", Filter: `{"status":"paid"}`, Sort: `{"_id":-1}`,
		Projection: `{"status":1,"total":1}`, Limit: 5})
	if len(docs) != 5 {
		t.Fatalf("got %d docs", len(docs))
	}
	first := decode(t, docs[0])
	if _, has := first["items"]; has {
		t.Errorf("projection not applied: %v", first)
	}
	if first["status"] != "paid" {
		t.Errorf("filter not applied: %v", first)
	}
	// Decimal128 survives as $numberDecimal.
	if _, ok := first["total"].(map[string]any)["$numberDecimal"]; !ok {
		t.Errorf("total = %v", first["total"])
	}

	// Descending _id: the first page and the next page must not overlap.
	p1 := find(t, c, engine.FindOptions{Collection: "orders", Sort: `{"_id":-1}`, Projection: `{"_id":1}`, Limit: 10})
	p2 := find(t, c, engine.FindOptions{Collection: "orders", Sort: `{"_id":-1}`, Projection: `{"_id":1}`, Skip: 10, Limit: 10})
	if p1[0] != `{"_id":{"$numberInt":"200"}}` && !strings.Contains(p1[0], `"200"`) {
		t.Errorf("p1[0] = %s", p1[0])
	}
	if p1[9] == p2[0] || len(p2) != 10 {
		t.Errorf("pages overlap or short: %s / %s (%d)", p1[9], p2[0], len(p2))
	}

	// Relaxed filter text with an operator, matched against Int32 values.
	if n := len(find(t, c, engine.FindOptions{Collection: "users", Filter: `{"age": {"$gte": 70}}`})); n != 2 {
		t.Errorf("age>=70: %d docs, want 2", n)
	}
	// Views are browsable too.
	if n := len(find(t, c, engine.FindOptions{Collection: "paid_orders"})); n != 50 {
		t.Errorf("paid_orders: %d docs", n)
	}
}

func TestIntegrationParseErrorsAreTyped(t *testing.T) {
	c := connect(t)
	for _, tc := range []struct {
		name string
		o    engine.FindOptions
		in   engine.Input
	}{
		{"filter", engine.FindOptions{Collection: "users", Filter: `{"a": ]}`}, engine.InputFilter},
		{"sort", engine.FindOptions{Collection: "users", Sort: `{"a" 1}`}, engine.InputSort},
		{"projection", engine.FindOptions{Collection: "users", Projection: `{`}, engine.InputProjection},
	} {
		tc.o.Database = "queravue"
		err := c.Find(context.Background(), tc.o, &collect{})
		var e *engine.Error
		if !errors.As(err, &e) || e.Kind != engine.KindParse || e.Input != tc.in {
			t.Errorf("%s: err = %v", tc.name, err)
		}
	}
}

func TestIntegrationEJSONTypesFromSeed(t *testing.T) {
	c := connect(t)
	docs := find(t, c, engine.FindOptions{Collection: "users", Filter: `{"name":"Ada Lovelace"}`})
	if len(docs) != 1 {
		t.Fatalf("docs = %d", len(docs))
	}
	ada := decode(t, docs[0])
	want := map[string]string{
		"_id": "$oid", "age": "$numberInt", "visits": "$numberLong", "score": "$numberDouble", "balance": "$numberDecimal",
		"joined": "$date", "session": "$binary", "avatar": "$binary",
	}
	for k, wrap := range want {
		m, ok := ada[k].(map[string]any)
		if !ok {
			t.Errorf("%s = %v, want {%s}", k, ada[k], wrap)
			continue
		}
		if _, ok := m[wrap]; !ok {
			t.Errorf("%s = %v, want {%s}", k, m, wrap)
		}
	}
	if b := ada["session"].(map[string]any)["$binary"].(map[string]any); b["subType"] != "04" {
		t.Errorf("uuid binary = %v", b)
	}
	if ada["visits"].(map[string]any)["$numberLong"] != "9007199254740993" {
		t.Errorf("visits lost precision: %v", ada["visits"])
	}
	// Mixed-type and exotic values.
	grace := decode(t, find(t, c, engine.FindOptions{Collection: "users", Filter: `{"_id":"string-id-3"}`})[0])
	for _, k := range []string{"pattern", "stamp", "lo", "hi"} {
		if _, ok := grace[k].(map[string]any); !ok {
			t.Errorf("%s = %v", k, grace[k])
		}
	}
}

func TestIntegrationStream100kAndCancel(t *testing.T) {
	c := connect(t)
	sink := &collect{}
	if err := c.Find(context.Background(), engine.FindOptions{Database: "queravue", Collection: "events", Limit: 100_000, MaxTimeMS: 60_000}, sink); err != nil {
		t.Fatal(err)
	}
	if sink.n != 100_000 || sink.maxB > engine.MaxDocBatch {
		t.Fatalf("n=%d maxBatch=%d", sink.n, sink.maxB)
	}

	// Cancel mid-stream through the context.
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	cs := &collect{onBatch: func(n int) error {
		if n >= 5_000 {
			cancel()
		}
		return nil
	}}
	err := c.Find(ctx, engine.FindOptions{Database: "queravue", Collection: "events"}, cs)
	if engine.KindOf(err) != engine.KindCanceled {
		t.Fatalf("err = %v, want canceled", err)
	}
	if cs.n > 50_000 {
		t.Errorf("read %d docs after cancel", cs.n)
	}

	// ErrStopDocs ends the find cleanly.
	ss := &collect{onBatch: func(int) error { return engine.ErrStopDocs }}
	if err := c.Find(context.Background(), engine.FindOptions{Database: "queravue", Collection: "events"}, ss); err != nil || ss.n != engine.MaxDocBatch {
		t.Errorf("stop: err=%v n=%d", err, ss.n)
	}
	// The connection still works afterwards.
	if err := c.Ping(context.Background()); err != nil {
		t.Fatal(err)
	}
}

func TestIntegrationStream1MMemory(t *testing.T) {
	c := connect(t)
	runtime.GC()
	var base runtime.MemStats
	runtime.ReadMemStats(&base)
	var peak uint64
	sink := &collect{onBatch: func(n int) error {
		if n%(50*engine.MaxDocBatch) == 0 {
			var m runtime.MemStats
			runtime.ReadMemStats(&m)
			peak = max(peak, m.HeapAlloc)
		}
		return nil
	}}
	start := time.Now()
	if err := c.Find(context.Background(), engine.FindOptions{Database: "queravue", Collection: "events", MaxTimeMS: 300_000}, sink); err != nil {
		t.Fatal(err)
	}
	if sink.n != 1_000_000 {
		t.Fatalf("docs = %d", sink.n)
	}
	t.Logf("1M docs in %v; heap %d MB -> peak %d MB", time.Since(start), base.HeapAlloc>>20, peak>>20)
	const window = 32 << 20 // one batch is far below 1 MB
	if peak > base.HeapAlloc+window {
		t.Errorf("heap grew from %d MB to %d MB while streaming 1M docs", base.HeapAlloc>>20, peak>>20)
	}
}

func TestIntegrationCount(t *testing.T) {
	c := connect(t)
	ctx := context.Background()
	est, err := c.Count(ctx, "queravue", "events", "", 5000)
	if err != nil || est.Exact || est.N != 1_000_000 {
		t.Errorf("estimate = %+v, %v", est, err)
	}
	ex, err := c.Count(ctx, "queravue", "orders", `{"status":"paid"}`, 5000)
	if err != nil || !ex.Exact || ex.N != 50 {
		t.Errorf("exact = %+v, %v", ex, err)
	}
	if v, err := c.Count(ctx, "queravue", "paid_orders", "", 5000); err != nil || v.N != 50 {
		t.Errorf("view count = %+v, %v", v, err)
	}
	_, err = c.Count(ctx, "queravue", "orders", `{`, 5000)
	if engine.KindOf(err) != engine.KindParse {
		t.Errorf("err = %v", err)
	}
}

func TestIntegrationSampleFields(t *testing.T) {
	c := connect(t)
	s, err := c.SampleFields(context.Background(), "queravue", "users", 100)
	if err != nil || s.Sampled != 5 || s.UsedFallback {
		t.Fatalf("sample = %+v, %v", s, err)
	}
	by := map[string]engine.FieldStat{}
	for _, f := range s.Fields {
		by[f.Name] = f
	}
	if s.Fields[0].Name != "_id" || by["_id"].Frequency != 1 {
		t.Errorf("first = %+v", s.Fields[0])
	}
	if len(by["_id"].Types) < 3 { // objectId, string, int, long
		t.Errorf("_id types = %+v", by["_id"].Types)
	}
	if got := by["age"].Types; len(got) < 2 { // int, double? string
		t.Errorf("age types = %+v", got)
	}
	if f := by["nickname"].Frequency; f != 0.2 {
		t.Errorf("nickname frequency = %v", f)
	}
	// A view works either with $sample or the fallback.
	if v, err := c.SampleFields(context.Background(), "queravue", "paid_orders", 10); err != nil || v.Sampled != 10 {
		t.Errorf("view sample = %+v, %v", v, err)
	}
}

// scratch returns a fresh collection name and drops it afterwards.
func scratch(t *testing.T, c *Conn) string {
	t.Helper()
	name := fmt.Sprintf("scratch_%d", time.Now().UnixNano())
	t.Cleanup(func() {
		_ = c.client.Database("queravue").Collection(name).Drop(context.Background())
	})
	return name
}

const allTypesDoc = `{"_id":{"$oid":"650000000000000000000099"},` +
	`"i32":{"$numberInt":"7"},"i64":{"$numberLong":"9007199254740993"},"dbl":{"$numberDouble":"1.5"},` +
	`"dec":{"$numberDecimal":"3.14159265358979323846"},"date":{"$date":{"$numberLong":"1700000000000"}},` +
	`"uuid":{"$binary":{"base64":"D4+tW9nLRp+hZXCGdyiVDg==","subType":"04"}},"bin":{"$binary":{"base64":"aGVsbG8=","subType":"00"}},` +
	`"ts":{"$timestamp":{"t":1700000000,"i":2}},"re":{"$regularExpression":{"pattern":"^a","options":"i"}},` +
	`"min":{"$minKey":1},"max":{"$maxKey":1},"nul":null,"b":true,"s":"héllo 😀",` +
	`"nested":{"a":[{"$numberInt":"1"},{"$numberLong":"2"},{"x":{"$numberDouble":"3.0"}}]}}`

func TestIntegrationCRUDAndTypeRoundTrip(t *testing.T) {
	c := connect(t)
	ctx := context.Background()
	coll := scratch(t, c)

	ids, err := c.Insert(ctx, "queravue", coll, []engine.Document{allTypesDoc, `{"name":"no id"}`}, engine.WriteOptions{})
	if err != nil || len(ids) != 2 || ids[0] != `{"$oid":"650000000000000000000099"}` {
		t.Fatalf("insert = %v, %v", ids, err)
	}
	if !strings.HasPrefix(ids[1], `{"$oid":`) {
		t.Errorf("generated id = %s", ids[1])
	}

	// Insert -> find returns exactly what was inserted, type for type.
	got, err := c.Count(ctx, "queravue", coll, "", 5000)
	if err != nil || got.N != 2 {
		t.Fatalf("count = %+v, %v", got, err)
	}
	var back []string
	if err := c.Find(ctx, engine.FindOptions{Database: "queravue", Collection: coll, Filter: `{"_id":{"$oid":"650000000000000000000099"}}`}, collectInto(&back)); err != nil {
		t.Fatal(err)
	}
	if len(back) != 1 || back[0] != allTypesDoc {
		t.Fatalf("round trip differs:\n got  %v\n want %s", back, allTypesDoc)
	}

	// Replace with an expected document.
	id := ids[0]
	edited := strings.Replace(allTypesDoc, `"s":"héllo 😀"`, `"s":"changed"`, 1)
	stored, err := c.Replace(ctx, "queravue", coll, id, edited, engine.WriteOptions{Expected: &back[0]})
	if err != nil || stored != edited {
		t.Fatalf("replace = %v, %v", stored, err)
	}

	// Conflict: another writer changes the doc; a stale replace is rejected.
	if _, err := c.UpdateFields(ctx, "queravue", coll, id, `{"i32":{"$numberInt":"8"}}`, nil, engine.WriteOptions{}); err != nil {
		t.Fatal(err)
	}
	_, err = c.Replace(ctx, "queravue", coll, id, `{"s":"mine"}`, engine.WriteOptions{Expected: &edited})
	var ce *engine.Error
	if !errors.As(err, &ce) || ce.Kind != engine.KindConflict || ce.Current == nil || !strings.Contains(*ce.Current, `"i32":{"$numberInt":"8"}`) {
		t.Fatalf("err = %v, want conflict with current document", err)
	}
	// Nothing was overwritten.
	if cur := find2(t, c, coll, id); !strings.Contains(cur, `"s":"changed"`) {
		t.Errorf("stored doc was overwritten: %s", cur)
	}
	// Overwrite = resend without the expected document.
	if _, err := c.Replace(ctx, "queravue", coll, id, `{"s":"mine"}`, engine.WriteOptions{}); err != nil {
		t.Fatal(err)
	}
	if cur := find2(t, c, coll, id); cur != `{"_id":{"$oid":"650000000000000000000099"},"s":"mine"}` {
		t.Errorf("after overwrite: %s", cur)
	}

	// A type change by another writer is a conflict too (Int32 5 -> Int64 5).
	if _, err := c.Replace(ctx, "queravue", coll, id, `{"n":{"$numberInt":"5"}}`, engine.WriteOptions{}); err != nil {
		t.Fatal(err)
	}
	was := find2(t, c, coll, id)
	if _, err := c.Replace(ctx, "queravue", coll, id, `{"n":{"$numberLong":"5"}}`, engine.WriteOptions{}); err != nil {
		t.Fatal(err)
	}
	if _, err := c.Replace(ctx, "queravue", coll, id, `{"n":{"$numberInt":"6"}}`, engine.WriteOptions{Expected: &was}); engine.KindOf(err) != engine.KindConflict {
		t.Errorf("type change not detected: %v", err)
	}

	// UpdateFields: set + unset, other fields untouched.
	out, err := c.UpdateFields(ctx, "queravue", coll, id, `{"extra.deep":{"$numberLong":"1"}}`, []string{"n"}, engine.WriteOptions{})
	if err != nil || out != `{"_id":{"$oid":"650000000000000000000099"},"extra":{"deep":{"$numberLong":"1"}}}` {
		t.Errorf("update = %s, %v", out, err)
	}

	// Bare numbers are rejected on the document write path.
	if _, err := c.Insert(ctx, "queravue", coll, []engine.Document{`{"x":1}`}, engine.WriteOptions{}); engine.KindOf(err) != engine.KindParse {
		t.Errorf("bare number accepted: %v", err)
	}
	// Not found / deleted-document conflict.
	if _, err := c.Replace(ctx, "queravue", coll, `{"$oid":"650000000000000000000abc"}`, `{}`, engine.WriteOptions{}); engine.KindOf(err) != engine.KindNotFound {
		t.Errorf("missing doc: %v", err)
	}

	// Delete.
	n, err := c.Delete(ctx, "queravue", coll, ids, engine.WriteOptions{})
	if err != nil || n != 2 {
		t.Fatalf("delete = %d, %v", n, err)
	}
	if k, _ := c.Count(ctx, "queravue", coll, `{}`, 5000); k.N != 0 {
		t.Errorf("count after delete = %d", k.N)
	}
	// Deleted behind our back -> conflict with no current document.
	_, err = c.Replace(ctx, "queravue", coll, id, `{}`, engine.WriteOptions{Expected: &was})
	if !errors.As(err, &ce) || ce.Kind != engine.KindConflict || ce.Current != nil {
		t.Errorf("deleted doc: %v", err)
	}
}

func TestIntegrationDuplicateKeyIsServerError(t *testing.T) {
	c := connect(t)
	coll := scratch(t, c)
	doc := engine.Document(`{"_id":{"$numberInt":"1"}}`)
	if _, err := c.Insert(context.Background(), "queravue", coll, []engine.Document{doc}, engine.WriteOptions{}); err != nil {
		t.Fatal(err)
	}
	_, err := c.Insert(context.Background(), "queravue", coll, []engine.Document{doc}, engine.WriteOptions{})
	if engine.KindOf(err) != engine.KindServer {
		t.Errorf("err = %v", err)
	}
}

func collectInto(out *[]string) engine.DocSink {
	return sinkFunc(func(d []string) { *out = append(*out, d...) })
}

type sinkFunc func([]string)

func (f sinkFunc) Batch(d []engine.Document) error { f(d); return nil }

func find2(t *testing.T, c *Conn, coll, id string) string {
	t.Helper()
	var got []string
	if err := c.Find(context.Background(), engine.FindOptions{Database: "queravue", Collection: coll, Filter: `{"_id":` + id + `}`}, collectInto(&got)); err != nil || len(got) != 1 {
		t.Fatalf("find %s: %v %v", id, got, err)
	}
	return got[0]
}

func contains(ss []string, s string) bool {
	for _, x := range ss {
		if x == s {
			return true
		}
	}
	return false
}
