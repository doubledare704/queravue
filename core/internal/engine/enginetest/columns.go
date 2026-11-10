package enginetest

import (
	"context"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func bulkColumns(t *testing.T, tg Target) {
	c := tg.connect(t)
	lister, ok := engine.As[engine.ColumnLister](c)
	if !ok {
		t.Fatal("connection is not a ColumnLister")
	}
	si, _ := engine.As[engine.SchemaInspector](c)
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	schema := tg.Schema
	if schema == "" {
		schemas, err := si.ListSchemas(ctx, tg.Database)
		if err != nil || len(schemas) == 0 {
			t.Fatalf("ListSchemas = %v, %v", schemas, err)
		}
		schema = schemas[0]
	}
	started := time.Now()
	refs, err := lister.ListColumns(ctx, tg.Database, schema)
	if err != nil {
		t.Fatal(err)
	}
	t.Logf("ListColumns(%q): %d columns in %s", schema, len(refs), time.Since(started))
	byTable := map[string][]string{}
	for _, r := range refs {
		if r.TypeName == "" {
			t.Errorf("column %s.%s has no type name", r.Table, r.Name)
		}
		byTable[r.Table] = append(byTable[r.Table], r.Name)
	}
	for _, table := range []string{"customers", "orders", "order_items", "customer_order_summary_view"} {
		d, err := si.DescribeTable(ctx, tg.Database, schema, table)
		if err != nil {
			t.Fatal(err)
		}
		var want []string
		for _, col := range d.Columns {
			want = append(want, col.Name)
		}
		got := byTable[table]
		if len(got) != len(want) {
			t.Errorf("%s columns = %v, want %v", table, got, want)
			continue
		}
		for i := range want {
			if got[i] != want[i] {
				t.Errorf("%s columns = %v, want %v", table, got, want)
				break
			}
		}
	}
}
