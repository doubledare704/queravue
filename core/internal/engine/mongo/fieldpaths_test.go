package mongo

import (
	"testing"

	"go.mongodb.org/mongo-driver/v2/bson"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func rawDoc(t *testing.T, v any) bson.Raw {
	t.Helper()
	b, err := bson.Marshal(v)
	if err != nil {
		t.Fatal(err)
	}
	return b
}

func collectPaths(t *testing.T, opts engine.PathSampleOptions, docs ...any) engine.FieldPathSample {
	t.Helper()
	pc := newPathCollector(opts)
	for _, d := range docs {
		pc.addDocument(rawDoc(t, d))
	}
	return pc.result()
}

func pathsOf(s engine.FieldPathSample) map[string]engine.FieldPathStat {
	out := map[string]engine.FieldPathStat{}
	for _, p := range s.Paths {
		out[p.Path] = p
	}
	return out
}

func TestFieldPathsCoverNestedDocumentsAndArrays(t *testing.T) {
	s := collectPaths(t, engine.PathSampleOptions{},
		bson.D{{Key: "_id", Value: 1}, {Key: "address", Value: bson.D{{Key: "city", Value: "Oslo"}, {Key: "geo", Value: bson.D{{Key: "lat", Value: 1.5}}}}},
			{Key: "tags", Value: bson.A{"a", "b"}},
			{Key: "items", Value: bson.A{bson.D{{Key: "sku", Value: "x"}, {Key: "qty", Value: 2}}, bson.D{{Key: "sku", Value: "y"}}}}},
		bson.D{{Key: "_id", Value: 2}, {Key: "address", Value: bson.D{{Key: "city", Value: "Rome"}}}},
	)
	got := pathsOf(s)
	for _, want := range []string{"_id", "address", "address.city", "address.geo", "address.geo.lat", "tags", "tags.[]", "items", "items.[]", "items.[].sku", "items.[].qty"} {
		if _, ok := got[want]; !ok {
			t.Errorf("missing path %q in %v", want, s.Paths)
		}
	}
	if s.Sampled != 2 {
		t.Errorf("sampled = %d", s.Sampled)
	}
	if got["address.geo.lat"].Frequency != 0.5 || got["address.city"].Frequency != 1 {
		t.Errorf("frequencies = %v / %v", got["address.geo.lat"].Frequency, got["address.city"].Frequency)
	}
	if sku := got["items.[].sku"]; sku.Frequency != 0.5 || sku.Types[0].Count != 2 || sku.Types[0].Type != "string" || sku.Depth != 3 {
		t.Errorf("items.[].sku = %+v", sku)
	}
	if s.Paths[0].Path != "_id" {
		t.Errorf("first path = %q, want _id", s.Paths[0].Path)
	}
}

func TestFieldPathsMixedTypesAreCountedPerValue(t *testing.T) {
	s := collectPaths(t, engine.PathSampleOptions{},
		bson.D{{Key: "v", Value: 1}}, bson.D{{Key: "v", Value: "x"}}, bson.D{{Key: "v", Value: "y"}})
	v := pathsOf(s)["v"]
	if len(v.Types) != 2 || v.Types[0].Type != "string" || v.Types[0].Count != 2 || v.Types[1].Type != "int" {
		t.Errorf("types = %+v", v.Types)
	}
}

func TestFieldPathsStopAtMaxDepth(t *testing.T) {
	doc := bson.D{{Key: "a", Value: bson.D{{Key: "b", Value: bson.D{{Key: "c", Value: bson.D{{Key: "d", Value: 1}}}}}}}}
	got := pathsOf(collectPaths(t, engine.PathSampleOptions{MaxDepth: 3}, doc))
	if _, ok := got["a.b.c"]; !ok {
		t.Error("a.b.c should be reported at depth 3")
	}
	if _, ok := got["a.b.c.d"]; ok {
		t.Error("a.b.c.d is deeper than the limit")
	}
}

func TestFieldPathsReportTruncation(t *testing.T) {
	doc := bson.D{{Key: "a", Value: 1}, {Key: "b", Value: 2}, {Key: "c", Value: 3}}
	s := collectPaths(t, engine.PathSampleOptions{MaxPaths: 2}, doc)
	if len(s.Paths) != 2 || !s.Truncated {
		t.Errorf("paths = %d truncated = %v", len(s.Paths), s.Truncated)
	}
}

func TestFieldPathsHandleNestedArrays(t *testing.T) {
	got := pathsOf(collectPaths(t, engine.PathSampleOptions{}, bson.D{{Key: "m", Value: bson.A{bson.A{1, 2}, bson.A{3}}}}))
	if _, ok := got["m.[].[]"]; !ok {
		t.Errorf("paths = %v", got)
	}
}
