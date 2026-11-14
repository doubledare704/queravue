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
		if r.ReferencedSchema != "" {
			t.Errorf("%s.%s references its own schema as %q, want empty", r.Table, r.Name, r.ReferencedSchema)
		}
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
		for i := range wantFKs {
			if wantFKs[i].ReferencedSchema == schema {
				wantFKs[i].ReferencedSchema = ""
			}
		}
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

const (
	crossSchemaName = "qv_it_ext"
	// CrossSchemaParent is created in both schemas; a fixture that cannot
	// drop a schema with its tables drops this one first.
	CrossSchemaParent = "qv_ext_parent"
	crossChild        = "qv_ext_child"
)

// crossSchemaRelations checks that a foreign key into another schema names
// that schema, even when the listed schema has a table of the same name.
func crossSchemaRelations(t *testing.T, tg Target) {
	c := tg.connect(t)
	lister, _ := engine.As[engine.RelationLister](c)
	local := tg.Schema
	dropAll := func() {
		ex, _ := engine.As[engine.Executor](c)
		ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
		defer cancel()
		statements := []string{
			"DROP TABLE IF EXISTS " + local + "." + tg.id(crossChild),
			"DROP TABLE IF EXISTS " + local + "." + tg.id(CrossSchemaParent),
		}
		for _, sql := range append(statements, tg.OtherSchema.Drop(crossSchemaName)...) {
			_, _ = ex.Execute(ctx, engine.Statement{SQL: sql}, &collector{})
		}
	}
	dropAll()
	t.Cleanup(dropAll)
	for _, sql := range tg.OtherSchema.Create(crossSchemaName) {
		ex, _ := engine.As[engine.Executor](c)
		if _, err := ex.Execute(context.Background(), engine.Statement{SQL: sql}, &collector{}); err != nil {
			t.Fatalf("%s: %v (MySQL and MariaDB: apply the grant in dev/seed/<engine>/02_test_grants.sql)", sql, err)
		}
	}
	id, other := tg.id, tg.id(crossSchemaName)
	for _, sql := range append([]string{},
		"CREATE TABLE "+other+"."+id(CrossSchemaParent)+" ("+id("id")+" INT PRIMARY KEY)",
		"CREATE TABLE "+local+"."+id(CrossSchemaParent)+" ("+id("id")+" INT PRIMARY KEY)",
		"CREATE TABLE "+local+"."+id(crossChild)+" ("+id("id")+" INT PRIMARY KEY, "+id("parent_id")+" INT, "+id("local_id")+" INT, "+
			"CONSTRAINT "+id("fk_qv_ext_other")+" FOREIGN KEY ("+id("parent_id")+") REFERENCES "+other+"."+id(CrossSchemaParent)+" ("+id("id")+"), "+
			"CONSTRAINT "+id("fk_qv_ext_local")+" FOREIGN KEY ("+id("local_id")+") REFERENCES "+local+"."+id(CrossSchemaParent)+" ("+id("id")+"))",
	) {
		exec(t, c, sql)
	}

	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	relations, err := lister.ListRelations(ctx, tg.Database, local)
	if err != nil {
		t.Fatal(err)
	}
	got := map[string]string{}
	for _, r := range relations {
		if r.Table == crossChild && r.ReferencedTable == CrossSchemaParent {
			got[r.Columns[0]] = r.ReferencedSchema
		}
	}
	want := map[string]string{"parent_id": crossSchemaName, "local_id": ""}
	if !reflect.DeepEqual(got, want) {
		t.Errorf("referenced schemas by column = %v, want %v", got, want)
	}
}
