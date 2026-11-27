package enginetest

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"reflect"
	"strings"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
)

// DocumentLoaderTarget is a database under test for the DocumentLoader suite.
type DocumentLoaderTarget struct {
	Engine   engine.Engine
	Config   engine.Config
	Secret   engine.Secret
	Database string
	// Fixture is canonical EJSON, each document with a distinct int32 _id
	// starting at 1; nil means DefaultDocumentFixture.
	Fixture []engine.Document
	// DropCollection removes a collection the suite created.
	DropCollection func(ctx context.Context, conn engine.Conn, database, collection string) error
}

// DefaultDocumentFixture holds one value of every BSON type the Mongo family
// shares.
func DefaultDocumentFixture() []engine.Document {
	return []engine.Document{
		`{"_id":{"$numberInt":"1"},"text":"quotes \" backslash \\ tab \t unicode é 日本","empty":"","int32":{"$numberInt":"-7"},"int64":{"$numberLong":"9007199254740993"},"double":{"$numberDouble":"1.5"},"decimal":{"$numberDecimal":"12345.6789"},"flag":true,"nothing":null,"when":{"$date":{"$numberLong":"1700000000123"}},"oid":{"$oid":"507f1f77bcf86cd799439011"},"blob":{"$binary":{"base64":"AAEC/w==","subType":"00"}},"uuid":{"$binary":{"base64":"EjRWeJCrEjRWeJCrEjRWeA==","subType":"04"}},"nested":{"a":{"$numberInt":"1"},"deeper":{"list":[{"$numberInt":"1"},"two",null,{"k":true}]}},"list":["a",{"$numberLong":"2"},{"$numberDouble":"3.25"}],"emptyDoc":{},"emptyList":[]}`,
		`{"_id":{"$numberInt":"2"},"text":"second","regex":{"$regularExpression":{"pattern":"^a.*z$","options":"i"}},"minKey":{"$minKey":1},"maxKey":{"$maxKey":1}}`,
		`{"_id":{"$numberInt":"3"}}`,
	}
}

const (
	docBatchSize = 100
	docKeyBase   = 1000
)

// RunDocumentLoader checks the engine.DocumentLoader contract: a round trip
// of a fixture, an empty source, cancel and source errors that leave only
// committed batches, a duplicate key in the middle of a batch, and a batch
// larger than one insert.
func RunDocumentLoader(t *testing.T, tg DocumentLoaderTarget) {
	if !tg.Engine.Descriptor().HasCapability(engine.CapDocumentLoad) {
		t.Fatal("engine does not declare document_load")
	}
	if tg.Fixture == nil {
		tg.Fixture = DefaultDocumentFixture()
	}
	t.Run("RoundTripFixture", func(t *testing.T) { docRoundTrip(t, tg) })
	t.Run("EmptySource", func(t *testing.T) { docEmptySource(t, tg) })
	t.Run("CancelMidLoad", func(t *testing.T) { docCancelMidLoad(t, tg) })
	t.Run("SourceErrorMidLoad", func(t *testing.T) { docSourceError(t, tg) })
	t.Run("DuplicateKeyMidBatch", func(t *testing.T) { docDuplicateKey(t, tg) })
	t.Run("MalformedDocumentCommitsNothingFromItsBatch", func(t *testing.T) { docMalformed(t, tg) })
	t.Run("BatchLargerThanOneInsert", func(t *testing.T) { docLargeBatch(t, tg) })
}

type docSession struct {
	tg     DocumentLoaderTarget
	conn   engine.Conn
	loader engine.DocumentLoader
	store  engine.DocumentStore
}

func openDocLoader(t *testing.T, tg DocumentLoaderTarget) *docSession {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	c, err := tg.Engine.Connect(ctx, tg.Config, tg.Secret)
	if err != nil {
		t.Fatalf("connect: %v", err)
	}
	t.Cleanup(func() { _ = c.Close() })
	loader, ok := engine.As[engine.DocumentLoader](c)
	if !ok {
		t.Fatal("connection is not a DocumentLoader")
	}
	store, ok := engine.As[engine.DocumentStore](c)
	if !ok {
		t.Fatal("connection is not a DocumentStore")
	}
	return &docSession{tg: tg, conn: c, loader: loader, store: store}
}

func (s *docSession) collection(t *testing.T, name string) string {
	t.Helper()
	drop := func() {
		ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
		defer cancel()
		if err := s.tg.DropCollection(ctx, s.conn, s.tg.Database, name); err != nil {
			t.Errorf("drop %s: %v", name, err)
		}
	}
	drop()
	t.Cleanup(drop)
	return name
}

func (s *docSession) load(ctx context.Context, collection string, src engine.DocumentBatchSource) (engine.LoadStats, error) {
	return s.loader.LoadDocuments(ctx, s.tg.Database, collection, src)
}

func (s *docSession) all(t *testing.T, collection string) []engine.Document {
	t.Helper()
	sink := &docCollector{}
	opt := engine.FindOptions{Database: s.tg.Database, Collection: collection, Sort: `{"_id":1}`}
	if err := s.store.Find(context.Background(), opt, sink); err != nil {
		t.Fatalf("find: %v", err)
	}
	return sink.docs
}

type docCollector struct{ docs []engine.Document }

func (c *docCollector) Batch(docs []engine.Document) error {
	c.docs = append(c.docs, docs...)
	return nil
}

type documentSource struct {
	batches [][]engine.Document
	next    int
	before  func(i int)
	failAt  int
	failErr error
}

func (s *documentSource) Next(context.Context) ([]engine.Document, error) {
	i := s.next
	s.next++
	if s.before != nil {
		s.before(i)
	}
	if s.failErr != nil && i == s.failAt {
		return nil, s.failErr
	}
	if i >= len(s.batches) {
		return nil, io.EOF
	}
	return s.batches[i], nil
}

func documentID(n int) string { return fmt.Sprintf(`{"$numberInt":"%d"}`, n) }

func keyedDocuments(batches int) [][]engine.Document {
	out := make([][]engine.Document, batches)
	for b := range out {
		out[b] = make([]engine.Document, docBatchSize)
		for r := range out[b] {
			n := docKeyBase + b*docBatchSize + r + 1
			out[b][r] = fmt.Sprintf(`{"_id":%s,"label":"label-%d","n":{"$numberInt":"%d"}}`, documentID(n), n, r)
		}
	}
	return out
}

func docRoundTrip(t *testing.T, tg DocumentLoaderTarget) {
	s := openDocLoader(t, tg)
	name := s.collection(t, "qv_load_roundtrip")
	split := len(tg.Fixture) - 1
	src := &documentSource{batches: [][]engine.Document{tg.Fixture[:split], tg.Fixture[split:]}}
	stats, err := s.load(context.Background(), name, src)
	if err != nil {
		t.Fatal(err)
	}
	if stats.Rows != uint64(len(tg.Fixture)) || stats.Batches != 2 {
		t.Errorf("stats = %+v, want %d documents in 2 batches", stats, len(tg.Fixture))
	}
	got := s.all(t, name)
	if len(got) != len(tg.Fixture) {
		t.Fatalf("read back %d documents, want %d", len(got), len(tg.Fixture))
	}
	for i := range got {
		if !ejsonEqual(got[i], tg.Fixture[i]) {
			t.Errorf("document %d = %s, want %s", i, got[i], tg.Fixture[i])
		}
	}
}

func docEmptySource(t *testing.T, tg DocumentLoaderTarget) {
	s := openDocLoader(t, tg)
	name := s.collection(t, "qv_load_empty")
	stats, err := s.load(context.Background(), name, &documentSource{})
	if err != nil || stats != (engine.LoadStats{}) {
		t.Fatalf("stats = %+v, err = %v", stats, err)
	}
	if n := len(s.all(t, name)); n != 0 {
		t.Errorf("%d documents after an empty load", n)
	}
}

func docCancelMidLoad(t *testing.T, tg DocumentLoaderTarget) {
	s := openDocLoader(t, tg)
	name := s.collection(t, "qv_load_cancel")
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	src := &documentSource{batches: keyedDocuments(10), before: func(i int) {
		if i == 3 {
			cancel()
		}
	}}
	stats, err := s.load(ctx, name, src)
	if engine.KindOf(err) != engine.KindCanceled || !errors.Is(err, context.Canceled) {
		t.Fatalf("err = %v, want a cancelled error", err)
	}
	if want := uint64(3 * docBatchSize); stats.Rows != want || stats.Batches != 3 {
		t.Errorf("stats = %+v, want %d documents in 3 batches", stats, want)
	}
	if n := uint64(len(s.all(t, name))); n != stats.Rows {
		t.Errorf("%d documents stored, stats say %d", n, stats.Rows)
	}
}

func docSourceError(t *testing.T, tg DocumentLoaderTarget) {
	s := openDocLoader(t, tg)
	name := s.collection(t, "qv_load_source_error")
	boom := errors.New("line 301 is malformed")
	stats, err := s.load(context.Background(), name, &documentSource{batches: keyedDocuments(10), failAt: 3, failErr: boom})
	if !errors.Is(err, boom) {
		t.Fatalf("err = %v, want the source error", err)
	}
	if want := uint64(3 * docBatchSize); stats.Rows != want {
		t.Errorf("stats.Rows = %d, want %d", stats.Rows, want)
	}
	if n := uint64(len(s.all(t, name))); n != stats.Rows {
		t.Errorf("%d documents stored, stats say %d", n, stats.Rows)
	}
}

func docDuplicateKey(t *testing.T, tg DocumentLoaderTarget) {
	s := openDocLoader(t, tg)
	name := s.collection(t, "qv_load_duplicate")
	batches := keyedDocuments(5)
	batches[2][50] = fmt.Sprintf(`{"_id":%s,"label":"label-secret"}`, documentID(docKeyBase+5))
	stats, err := s.load(context.Background(), name, &documentSource{batches: batches})
	if engine.KindOf(err) != engine.KindConstraint {
		t.Fatalf("err = %v, want a constraint error", err)
	}
	if stats.Rows < 2*docBatchSize {
		t.Errorf("stats.Rows = %d, want at least the two clean batches", stats.Rows)
	}
	if n := uint64(len(s.all(t, name))); n != stats.Rows {
		t.Errorf("%d documents stored, stats say %d", n, stats.Rows)
	}
	if strings.Contains(err.Error(), "label-") || strings.Contains(err.Error(), fmt.Sprint(docKeyBase+5)) {
		t.Errorf("error message quotes document data: %v", err)
	}
}

func docMalformed(t *testing.T, tg DocumentLoaderTarget) {
	s := openDocLoader(t, tg)
	name := s.collection(t, "qv_load_malformed")
	batches := keyedDocuments(3)
	batches[1][10] = `{"_id": 42}`
	stats, err := s.load(context.Background(), name, &documentSource{batches: batches})
	var e *engine.Error
	if !errors.As(err, &e) || e.Kind != engine.KindParse || !e.HasIndex || e.DocumentIndex != 10 {
		t.Fatalf("err = %#v, want a parse error at document 10", err)
	}
	if want := uint64(docBatchSize); stats.Rows != want {
		t.Errorf("stats.Rows = %d, want %d", stats.Rows, want)
	}
	if n := uint64(len(s.all(t, name))); n != stats.Rows {
		t.Errorf("%d documents stored, stats say %d", n, stats.Rows)
	}
}

func docLargeBatch(t *testing.T, tg DocumentLoaderTarget) {
	s := openDocLoader(t, tg)
	name := s.collection(t, "qv_load_large")
	padding := strings.Repeat("x", 1<<20)
	batch := make([]engine.Document, 6)
	for i := range batch {
		batch[i] = fmt.Sprintf(`{"_id":%s,"padding":"%s"}`, documentID(docKeyBase+i+1), padding)
	}
	stats, err := s.load(context.Background(), name, &documentSource{batches: [][]engine.Document{batch}})
	if err != nil {
		t.Fatal(err)
	}
	if stats.Rows != uint64(len(batch)) || stats.Batches < 2 {
		t.Errorf("stats = %+v, want %d documents split over several inserts", stats, len(batch))
	}
	if n := len(s.all(t, name)); n != len(batch) {
		t.Errorf("%d documents stored, want %d", n, len(batch))
	}
}

func ejsonEqual(a, b string) bool {
	var x, y any
	if json.Unmarshal([]byte(a), &x) != nil || json.Unmarshal([]byte(b), &y) != nil {
		return a == b
	}
	return reflect.DeepEqual(x, y)
}
