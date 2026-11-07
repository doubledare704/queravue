//go:build integration

package mongo

import (
	"context"
	"errors"
	"strings"
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func indexByName(t *testing.T, c *Conn, coll, name string) (engine.IndexInfo, bool) {
	t.Helper()
	got, err := c.ListIndexes(context.Background(), "queravue", "", coll)
	if err != nil {
		t.Fatal(err)
	}
	for _, ix := range got {
		if ix.Spec.Name == name {
			return ix, true
		}
	}
	return engine.IndexInfo{}, false
}

func TestIntegrationIndexLifecycle(t *testing.T) {
	c := connect(t)
	ctx := context.Background()
	coll := scratch(t, c)
	if _, err := c.Insert(ctx, "queravue", coll, []engine.Document{`{"a":{"$numberInt":"1"},"b":"x"}`}, engine.WriteOptions{}); err != nil {
		t.Fatal(err)
	}
	spec := engine.IndexSpec{
		Keys:             []engine.IndexKey{{Name: "a"}, {Name: "b", Kind: engine.IndexKeyDescending}},
		Unique:           true,
		PartialPredicate: `{"b": {"$exists": true}}`,
		Options:          map[string]string{"hidden": "true"},
	}

	statement, name, err := c.CreateIndex(ctx, "queravue", "", coll, spec, true)
	if err != nil {
		t.Fatal(err)
	}
	if name != "a_1_b_-1" || !strings.Contains(statement, "createIndex(") || !strings.Contains(statement, `"unique":true`) {
		t.Errorf("dry run: name=%q statement=%s", name, statement)
	}
	if _, ok := indexByName(t, c, coll, name); ok {
		t.Fatal("dry run created the index")
	}

	if _, _, err := c.CreateIndex(ctx, "queravue", "", coll, spec, false); err != nil {
		t.Fatal(err)
	}
	ix, ok := indexByName(t, c, coll, "a_1_b_-1")
	if !ok {
		t.Fatal("index not listed after create")
	}
	if !ix.Spec.Unique || len(ix.Spec.Keys) != 2 || ix.Spec.Keys[1].Kind != engine.IndexKeyDescending {
		t.Errorf("spec = %+v", ix.Spec)
	}
	if ix.Spec.PartialPredicate == "" || ix.Spec.Options["hidden"] != "true" {
		t.Errorf("partial = %q options = %v", ix.Spec.PartialPredicate, ix.Spec.Options)
	}
	if !ix.Usage.Available || ix.Usage.Scans == nil || ix.Usage.TrackingSince == nil {
		t.Errorf("usage = %+v", ix.Usage)
	}
	if ix.SizeBytes == nil {
		t.Error("size is missing")
	}
	if id, ok := indexByName(t, c, coll, "_id_"); !ok || !id.IsPrimary {
		t.Errorf("_id_ = %+v, %v", id, ok)
	}

	if _, err := c.DropIndex(ctx, "queravue", "", coll, "a_1_b_-1", false); err != nil {
		t.Fatal(err)
	}
	if _, ok := indexByName(t, c, coll, "a_1_b_-1"); ok {
		t.Error("index still listed after drop")
	}
}

func TestIntegrationIndexKinds(t *testing.T) {
	c := connect(t)
	ctx := context.Background()
	coll := scratch(t, c)
	for _, spec := range []engine.IndexSpec{
		{Name: "h", Keys: []engine.IndexKey{{Name: "a", Kind: engine.IndexKeyHashed}}},
		{Name: "t", Keys: []engine.IndexKey{{Name: "title", Kind: engine.IndexKeyText}}},
		{Name: "ttl", Keys: []engine.IndexKey{{Name: "at"}}, Options: map[string]string{"expireAfterSeconds": `{"$numberInt":"60"}`}},
	} {
		if _, _, err := c.CreateIndex(ctx, "queravue", "", coll, spec, false); err != nil {
			t.Fatalf("%s: %v", spec.Name, err)
		}
	}
	if ix, _ := indexByName(t, c, coll, "h"); len(ix.Spec.Keys) != 1 || ix.Spec.Keys[0].Kind != engine.IndexKeyHashed {
		t.Errorf("hashed = %+v", ix.Spec)
	}
	if ix, _ := indexByName(t, c, coll, "t"); len(ix.Spec.Keys) != 1 || ix.Spec.Keys[0].Name != "title" || ix.Spec.Keys[0].Kind != engine.IndexKeyText {
		t.Errorf("text = %+v", ix.Spec)
	}
	if ix, _ := indexByName(t, c, coll, "ttl"); ix.Spec.Options["expireAfterSeconds"] == "" {
		t.Errorf("ttl = %+v", ix.Spec)
	}
}

func TestIntegrationIndexErrors(t *testing.T) {
	c := connect(t)
	ctx := context.Background()
	coll := scratch(t, c)
	if _, err := c.DropIndex(ctx, "queravue", "", coll, "_id_", false); err == nil || !strings.Contains(err.Error(), "_id") {
		t.Errorf("dropping _id: %v", err)
	}
	if _, _, err := c.CreateIndex(ctx, "queravue", "", coll, engine.IndexSpec{}, false); err == nil {
		t.Error("an index without keys was accepted")
	}
	_, _, err := c.CreateIndex(ctx, "queravue", "", coll, engine.IndexSpec{Keys: []engine.IndexKey{{Name: "a"}}, PartialPredicate: `{"a":`}, true)
	var ee *engine.Error
	if !errors.As(err, &ee) || ee.Kind != engine.KindParse {
		t.Errorf("bad predicate: %v", err)
	}
}

func TestIntegrationTableStats(t *testing.T) {
	c := connect(t)
	st, err := c.TableStats(context.Background(), "queravue", "", "events")
	if err != nil {
		t.Fatal(err)
	}
	if st.EstimatedRows == nil || *st.EstimatedRows < 1_000_000 {
		t.Errorf("rows = %v", st.EstimatedRows)
	}
	if st.DataBytes == nil || st.IndexBytes == nil {
		t.Errorf("sizes = %v %v", st.DataBytes, st.IndexBytes)
	}
}
