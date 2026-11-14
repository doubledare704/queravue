package enginetest

import (
	"context"
	"errors"
	"slices"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

const probeTable = "qv_index_probe"

func indexLifecycle(t *testing.T, tg Target) {
	c := tg.connect(t)
	im, ok := engine.As[engine.IndexManager](c)
	if !ok {
		t.Fatal("connection is not an IndexManager")
	}
	d, ok := sqldialect.Of(c)
	if !ok {
		t.Fatal("connection has no dialect")
	}
	table := d.QualifyTableIn(tg.Database, tg.Schema, probeTable)
	exec(t, c, "DROP TABLE IF EXISTS "+table)
	exec(t, c, "CREATE TABLE "+table+" ("+tg.id("a")+" INT NOT NULL, "+tg.id("b")+" VARCHAR(50), "+tg.id("c")+" INT)")
	t.Cleanup(func() { exec(t, c, "DROP TABLE IF EXISTS "+table) })

	create := func(spec engine.IndexSpec) {
		t.Helper()
		sql, _, err := d.CreateIndex(tg.Database, tg.Schema, probeTable, spec)
		if err != nil {
			t.Fatalf("build %s: %v", spec.Name, err)
		}
		exec(t, c, sql)
	}
	create(engine.IndexSpec{Name: "qv_probe_ab", Keys: []engine.IndexKey{{Name: "a"}, {Name: "b", Kind: engine.IndexKeyDescending}}})
	create(engine.IndexSpec{Name: "qv_probe_c", Unique: true, Keys: []engine.IndexKey{{Name: "c"}}})

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	list := func() map[string]engine.IndexInfo {
		t.Helper()
		got, err := im.ListIndexes(ctx, tg.Database, tg.Schema, probeTable)
		if err != nil {
			t.Fatal(err)
		}
		byName := map[string]engine.IndexInfo{}
		for _, ix := range got {
			byName[ix.Spec.Name] = ix
		}
		return byName
	}

	got := list()
	ab, ok := got["qv_probe_ab"]
	if !ok {
		t.Fatalf("qv_probe_ab is not listed: %v", names(got))
	}
	if keys := keyNames(ab.Spec.Keys); !slices.Equal(keys, []string{"a", "b"}) {
		t.Errorf("keys = %v, want [a b]", keys)
	}
	if ab.Spec.Unique || ab.IsPrimary {
		t.Errorf("qv_probe_ab = %+v", ab)
	}
	if u, ok := got["qv_probe_c"]; !ok || !u.Spec.Unique {
		t.Errorf("qv_probe_c = %+v, listed = %v", u, ok)
	}
	for _, ix := range got {
		if ix.Usage.Available && ix.Usage.Scans == nil {
			t.Errorf("%s reports usage as available without a scan count", ix.Spec.Name)
		}
	}

	exec(t, c, d.DropIndex(tg.Database, tg.Schema, probeTable, "qv_probe_ab"))
	if _, still := list()["qv_probe_ab"]; still {
		t.Error("qv_probe_ab is still listed after DROP INDEX")
	}
	if _, kept := list()["qv_probe_c"]; !kept {
		t.Error("dropping one index removed another")
	}
}

func onlineIndexBuild(t *testing.T, tg Target) {
	c := tg.connect(t)
	im, _ := engine.As[engine.IndexManager](c)
	d, ok := sqldialect.Of(c)
	if !ok {
		t.Fatal("connection has no dialect")
	}
	table := d.QualifyTableIn(tg.Database, tg.Schema, probeTable)
	exec(t, c, "DROP TABLE IF EXISTS "+table)
	exec(t, c, "CREATE TABLE "+table+" ("+tg.id("a")+" INT NOT NULL, "+tg.id("b")+" VARCHAR(50))")
	t.Cleanup(func() { exec(t, c, "DROP TABLE IF EXISTS "+table) })
	exec(t, c, "INSERT INTO "+table+" ("+tg.id("a")+", "+tg.id("b")+") VALUES (1, 'x'), (2, 'y')")

	spec := engine.IndexSpec{Name: "qv_probe_online", Keys: []engine.IndexKey{{Name: "b"}}, Options: map[string]string{sqldialect.OptionOnline: "true"}}
	sql, warnings, err := d.CreateIndex(tg.Database, tg.Schema, probeTable, spec)
	if err != nil {
		t.Fatalf("build: %v", err)
	}
	if len(warnings) == 0 {
		t.Error("an online build carries a warning")
	}
	exec(t, c, sql)

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	got, err := im.ListIndexes(ctx, tg.Database, tg.Schema, probeTable)
	if err != nil {
		t.Fatal(err)
	}
	for _, ix := range got {
		if ix.Spec.Name == "qv_probe_online" {
			return
		}
	}
	t.Errorf("the online index is not listed after %q", sql)
}

func listIndexesOfMissingTable(t *testing.T, tg Target) {
	c := tg.connect(t)
	im, _ := engine.As[engine.IndexManager](c)
	_, err := im.ListIndexes(context.Background(), tg.Database, tg.Schema, "qv_no_such_table")
	if !isKind(err, engine.KindNotFound) {
		t.Fatalf("error = %v, want not found", err)
	}
}

func tableStats(t *testing.T, tg Target) {
	c := tg.connect(t)
	sp, ok := engine.As[engine.StatsProvider](c)
	if !ok {
		t.Fatal("connection is not a StatsProvider")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	st, err := sp.TableStats(ctx, tg.Database, tg.Schema, "million_items")
	if err != nil {
		t.Fatal(err)
	}
	if st.EstimatedRows != nil && *st.EstimatedRows < 100_000 {
		t.Errorf("estimated rows = %d, want at least 100000", *st.EstimatedRows)
	}
	if st.EstimatedRows == nil && st.DataBytes == nil && len(st.Extras) == 0 {
		t.Error("stats are empty")
	}
	if _, err := sp.TableStats(ctx, tg.Database, tg.Schema, "qv_no_such_table"); !isKind(err, engine.KindNotFound) {
		t.Errorf("missing table: %v, want not found", err)
	}
}

func names(m map[string]engine.IndexInfo) []string {
	out := make([]string, 0, len(m))
	for k := range m {
		out = append(out, k)
	}
	slices.Sort(out)
	return out
}

func keyNames(keys []engine.IndexKey) []string {
	out := make([]string, len(keys))
	for i, k := range keys {
		out[i] = k.Name
	}
	return out
}

func isKind(err error, k engine.Kind) bool {
	var ee *engine.Error
	return errors.As(err, &ee) && ee.Kind == k
}
