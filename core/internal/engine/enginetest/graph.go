package enginetest

import (
	"context"
	"reflect"
	"slices"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
)

// schemaGraph checks that the bulk listings agree with DescribeTable for the
// seed tables: same columns, keys, nullability and foreign keys.
func schemaGraph(t *testing.T, tg Target) {
	c := tg.connect(t)
	lister, ok := engine.As[engine.RelationLister](c)
	if !ok {
		t.Fatal("connection is not a RelationLister")
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
	columns, err := lister.ListKeyedColumns(ctx, tg.Database, schema)
	if err != nil {
		t.Fatal(err)
	}
	columnsTook := time.Since(started)
	started = time.Now()
	relations, err := lister.ListRelations(ctx, tg.Database, schema)
	if err != nil {
		t.Fatal(err)
	}
	t.Logf("schema %q: %d keyed columns in %s, %d relations in %s",
		schema, len(columns), columnsTook, len(relations), time.Since(started))

	type keyed struct {
		Name     string
		Nullable bool
		PKOrder  int
	}
	columnsOf := map[string][]keyed{}
	for _, col := range columns {
		if col.TypeName == "" {
			t.Errorf("column %s.%s has no type name", col.Table, col.Name)
		}
		columnsOf[col.Table] = append(columnsOf[col.Table], keyed{col.Name, col.Nullable, col.PrimaryKeyOrder})
	}
	relationsOf := map[string][]engine.ForeignKeyDef{}
	for _, r := range relations {
		relationsOf[r.Table] = append(relationsOf[r.Table], r.ForeignKeyDef)
	}
	byName := func(a, b engine.ForeignKeyDef) int {
		return slices.Compare([]string{a.Name}, []string{b.Name})
	}

	sawRelation := false
	for _, table := range []string{"customers", "orders", "order_items", "customer_order_summary_view"} {
		d, err := si.DescribeTable(ctx, tg.Database, schema, table)
		if err != nil {
			t.Fatal(err)
		}
		var want []keyed
		for _, col := range d.Columns {
			want = append(want, keyed{col.Name, col.Nullable, col.PrimaryKeyOrder})
		}
		if got := columnsOf[table]; !reflect.DeepEqual(got, want) {
			t.Errorf("%s keyed columns = %+v\nwant %+v", table, got, want)
		}
		got, wantFKs := slices.Clone(relationsOf[table]), slices.Clone(d.ForeignKeys)
		slices.SortFunc(got, byName)
		slices.SortFunc(wantFKs, byName)
		if len(got) != 0 || len(wantFKs) != 0 {
			sawRelation = true
			if !reflect.DeepEqual(got, wantFKs) {
				t.Errorf("%s relations = %+v\nwant %+v", table, got, wantFKs)
			}
		}
	}
	if !sawRelation {
		t.Error("the seed has foreign keys, but none was listed or described")
	}
}
