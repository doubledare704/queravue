package sqlite

import (
	"context"
	"errors"
	"path/filepath"
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func indexFixture(t *testing.T) (engine.IndexManager, engine.StatsProvider) {
	t.Helper()
	c, err := connect(t, map[string]string{ParamPath: filepath.Join(t.TempDir(), "i.db"), ParamCreateIfMissing: "true"})
	if err != nil {
		t.Fatal(err)
	}
	ex, _ := engine.As[engine.Executor](c)
	for _, stmt := range []string{
		`CREATE TABLE orders (id INTEGER PRIMARY KEY, customer INTEGER, created TEXT, note TEXT)`,
		`CREATE INDEX orders_customer_created ON orders (customer, created DESC)`,
		`CREATE UNIQUE INDEX orders_note ON orders (note) WHERE note IS NOT NULL`,
		`CREATE INDEX orders_lower_note ON orders (lower(note))`,
	} {
		if _, err := ex.Execute(context.Background(), engine.Statement{SQL: stmt}, &collectSink{}); err != nil {
			t.Fatal(err)
		}
	}
	im, ok := engine.As[engine.IndexManager](c)
	if !ok {
		t.Fatal("no IndexManager")
	}
	sp, ok := engine.As[engine.StatsProvider](c)
	if !ok {
		t.Fatal("no StatsProvider")
	}
	return im, sp
}

func TestListIndexes(t *testing.T) {
	im, _ := indexFixture(t)
	got, err := im.ListIndexes(context.Background(), "", "main", "orders")
	if err != nil {
		t.Fatal(err)
	}
	byName := map[string]engine.IndexInfo{}
	for _, ix := range got {
		byName[ix.Spec.Name] = ix
	}

	composite := byName["orders_customer_created"]
	if len(composite.Spec.Keys) != 2 || composite.Spec.Keys[0].Name != "customer" ||
		composite.Spec.Keys[1].Name != "created" || composite.Spec.Keys[1].Kind != engine.IndexKeyDescending {
		t.Errorf("composite keys = %+v", composite.Spec.Keys)
	}
	partial := byName["orders_note"]
	if !partial.Spec.Unique || partial.Spec.PartialPredicate != "note IS NOT NULL" {
		t.Errorf("partial = %+v", partial.Spec)
	}
	if expr := byName["orders_lower_note"]; len(expr.Spec.Keys) != 1 || !expr.Spec.Keys[0].IsExpression {
		t.Errorf("expression index keys = %+v", expr.Spec.Keys)
	}
	for _, ix := range got {
		if ix.Usage.Available {
			t.Errorf("%s: sqlite has no usage statistics", ix.Spec.Name)
		}
	}
}

func TestListIndexesUnknownTable(t *testing.T) {
	im, _ := indexFixture(t)
	_, err := im.ListIndexes(context.Background(), "", "main", "missing")
	var ee *engine.Error
	if !errors.As(err, &ee) || ee.Kind != engine.KindNotFound {
		t.Fatalf("error = %v, want not found", err)
	}
}

func TestTableStatsUnknownTable(t *testing.T) {
	_, sp := indexFixture(t)
	_, err := sp.TableStats(context.Background(), "", "main", "missing")
	var ee *engine.Error
	if !errors.As(err, &ee) || ee.Kind != engine.KindNotFound {
		t.Fatalf("error = %v, want not found", err)
	}
}

func TestTableStatsReportsPages(t *testing.T) {
	_, sp := indexFixture(t)
	st, err := sp.TableStats(context.Background(), "", "main", "orders")
	if err != nil {
		t.Fatal(err)
	}
	keys := map[string]bool{}
	for _, e := range st.Extras {
		keys[e.Key] = true
	}
	if !keys["page_size"] || !keys["page_count"] {
		t.Errorf("extras = %+v", st.Extras)
	}
}
