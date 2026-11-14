package diagram_test

import (
	"context"
	"errors"
	"strings"
	"sync"
	"testing"

	"github.com/doubledare704/queravue/core/internal/diagram"
	"github.com/doubledare704/queravue/core/internal/engine"
)

// checkedConn samples orders.customerId and tags.[] as guesses at customers
// and tags, and answers the checks from fixed documents.
type checkedConn struct {
	sampledConn
	orders     []engine.Document
	found      map[string]uint64
	countErr   error
	mu         sync.Mutex
	finds      []engine.FindOptions
	countCalls []string
}

func (*checkedConn) ListObjects(context.Context, string, string) ([]engine.SchemaObject, error) {
	return []engine.SchemaObject{
		{Name: "customers", Type: engine.ObjectTypeCollection},
		{Name: "tags", Type: engine.ObjectTypeCollection},
		{Name: "orders", Type: engine.ObjectTypeCollection},
	}, nil
}

func (*checkedConn) SampleFieldPaths(_ context.Context, _, collection string, _ engine.PathSampleOptions) (engine.FieldPathSample, error) {
	oid := []engine.FieldType{{Type: "objectId", Count: 3}}
	paths := []engine.FieldPathStat{{Path: "_id", Frequency: 1, Types: oid}}
	if collection == "orders" {
		paths = append(paths,
			engine.FieldPathStat{Path: "customerId", Frequency: 1, Types: oid},
			engine.FieldPathStat{Path: "tagIds.[]", Frequency: 1, Types: oid})
	}
	return engine.FieldPathSample{Paths: paths, Sampled: 3}, nil
}

func (c *checkedConn) Find(_ context.Context, opt engine.FindOptions, sink engine.DocSink) error {
	c.mu.Lock()
	c.finds = append(c.finds, opt)
	c.mu.Unlock()
	if err := sink.Batch(c.orders); err != nil && !errors.Is(err, engine.ErrStopDocs) {
		return err
	}
	return nil
}

func (c *checkedConn) Count(_ context.Context, _, collection, filter string, _ uint32) (engine.Count, error) {
	c.mu.Lock()
	c.countCalls = append(c.countCalls, collection+" "+filter)
	c.mu.Unlock()
	if c.countErr != nil {
		return engine.Count{}, c.countErr
	}
	return engine.Count{N: c.found[collection], Exact: true}, nil
}

var checkedOrders = []engine.Document{
	`{"_id":{"$oid":"a1"},"customerId":{"$oid":"c1"},"tagIds":[{"$oid":"t1"},{"$oid":"t2"}]}`,
	`{"_id":{"$oid":"a2"},"customerId":{"$oid":"c2"},"tagIds":[{"$oid":"t2"},{"$oid":"t3"},{"$oid":"t4"},{"$oid":"t5"}]}`,
}

func orderGuesses(t *testing.T, conn *checkedConn) map[string]float64 {
	t.Helper()
	g, err := diagram.Load(context.Background(), open(t, conn), diagram.Scope{})
	if err != nil {
		t.Fatal(err)
	}
	out := map[string]float64{}
	for _, r := range g.Tables[2].Relations {
		out[r.ReferencedTable] = r.Confidence
	}
	return out
}

func TestGuessesAreCheckedAgainstTheTargetCollection(t *testing.T) {
	conn := &checkedConn{orders: checkedOrders, found: map[string]uint64{"customers": 2, "tags": 4}}
	got := orderGuesses(t, conn)
	if got["customers"] != 0.95 {
		t.Errorf("customers, every value found = %v, want 0.95", got["customers"])
	}
	if got["tags"] != 0.72 {
		t.Errorf("tags, 4 of 5 found = %v, want 0.9 * 0.8", got["tags"])
	}
	var filters []string
	for _, f := range conn.finds {
		filters = append(filters, f.Filter+" "+f.Projection)
	}
	joined := strings.Join(filters, "\n")
	if !strings.Contains(joined, `{"tagIds": {"$exists": true, "$ne": null}} {"tagIds": 1}`) {
		t.Errorf("finds drop the array marker from the path:\n%s", joined)
	}
	if calls := strings.Join(conn.countCalls, "\n"); !strings.Contains(calls, `tags {"_id": {"$in": [{"$oid":"t1"}, {"$oid":"t2"}, {"$oid":"t3"}, {"$oid":"t4"}, {"$oid":"t5"}]}}`) {
		t.Errorf("counts:\n%s", calls)
	}
}

func TestAGuessWithFewValuesFoundIsDropped(t *testing.T) {
	got := orderGuesses(t, &checkedConn{orders: checkedOrders, found: map[string]uint64{"customers": 0, "tags": 2}})
	if len(got) != 0 {
		t.Errorf("guesses = %v, want both dropped", got)
	}
}

func TestAGuessThatCannotBeCheckedKeepsItsConfidence(t *testing.T) {
	for name, conn := range map[string]*checkedConn{
		"count fails":  {orders: checkedOrders, countErr: errors.New("timeout")},
		"no documents": {found: map[string]uint64{}},
		"not EJSON":    {orders: []engine.Document{`{`}},
	} {
		got := orderGuesses(t, conn)
		if got["customers"] != 0.9 || got["tags"] != 0.9 {
			t.Errorf("%s: guesses = %v, want the name-and-type confidence", name, got)
		}
	}
}
