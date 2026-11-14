//go:build duckdb

package duckdb

import (
	"context"
	"path/filepath"
	"slices"
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/sqlbuilder"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

func TestIndexColumns(t *testing.T) {
	tests := map[string][]string{
		`CREATE INDEX ix ON t(a);`:                         {"a"},
		`CREATE UNIQUE INDEX ix ON main.t(a, "b c");`:      {"a", "b c"},
		`CREATE INDEX ix ON "my(t)"("we""ird", lower(x));`: {`we"ird`, "lower(x)"},
		`CREATE INDEX ix ON t;`:                            nil,
	}
	for ddl, want := range tests {
		if got := indexColumns(ddl); !slices.Equal(got, want) {
			t.Errorf("indexColumns(%s) = %v, want %v", ddl, got, want)
		}
	}
}

func TestSchemasAndObjects(t *testing.T) {
	_, c := seededFile(t)
	query(t, c, "CREATE SCHEMA analytics")
	query(t, c, "CREATE TABLE analytics.events (id BIGINT PRIMARY KEY, kind VARCHAR)")
	query(t, c, "CREATE VIEW analytics.recent AS SELECT * FROM analytics.events")
	si, _ := engine.As[engine.SchemaInspector](c)
	ctx := context.Background()

	schemas, _ := si.ListSchemas(ctx, "queravue")
	if !slices.Equal(schemas, []string{"analytics", "main"}) {
		t.Errorf("schemas = %v", schemas)
	}
	objects, err := si.ListObjects(ctx, "", "analytics")
	if err != nil || len(objects) != 2 || objects[0].Name != "events" || objects[0].Type != engine.ObjectTypeTable || objects[1].Type != engine.ObjectTypeView {
		t.Errorf("objects = %+v, %v", objects, err)
	}
	view, err := si.DescribeTable(ctx, "", "analytics", "recent")
	if err != nil || view.CanEdit || view.EditDisabledReason == "" || len(view.Columns) != 2 {
		t.Errorf("view = %+v, %v", view, err)
	}
	dbs, _ := si.ListDatabases(ctx)
	if !slices.Equal(dbs, []string{"queravue"}) {
		t.Errorf("databases = %v, want only the opened file", dbs)
	}
}

func TestAttachedDatabases(t *testing.T) {
	_, c := seededFile(t)
	otherPath := filepath.Join(t.TempDir(), "other.duckdb")
	query(t, c, "ATTACH '"+otherPath+"' AS other")
	query(t, c, "CREATE TABLE other.main.parent (id INTEGER PRIMARY KEY, name VARCHAR NOT NULL)")
	query(t, c, "CREATE TABLE other.main.child (id INTEGER PRIMARY KEY, parent_id INTEGER REFERENCES parent (id))")
	query(t, c, "CREATE SCHEMA other.extra")
	query(t, c, "CREATE TABLE other.extra.notes (n VARCHAR)")
	si, _ := engine.As[engine.SchemaInspector](c)
	ctx := context.Background()

	dbs, _ := si.ListDatabases(ctx)
	if !slices.Equal(dbs, []string{"other", "queravue"}) {
		t.Fatalf("databases = %v", dbs)
	}
	schemas, _ := si.ListSchemas(ctx, "other")
	if !slices.Equal(schemas, []string{"extra", "main"}) {
		t.Errorf("schemas of other = %v", schemas)
	}
	objects, _ := si.ListObjects(ctx, "other", "main")
	if len(objects) != 2 || objects[0].Name != "child" || objects[1].Name != "parent" {
		t.Errorf("objects of other.main = %+v", objects)
	}
	if objects, _ = si.ListObjects(ctx, "other", "extra"); len(objects) != 1 || objects[0].Name != "notes" {
		t.Errorf("objects of other.extra = %+v", objects)
	}
	d, err := si.DescribeTable(ctx, "other", "main", "child")
	if err != nil || len(d.ForeignKeys) != 1 || d.ForeignKeys[0].ReferencedTable != "parent" || !d.CanEdit {
		t.Fatalf("child = %+v, %v", d, err)
	}
	if _, err := si.DescribeTable(ctx, "queravue", "main", "parent"); engine.KindOf(err) != engine.KindNotFound {
		t.Errorf("a table of the other database is visible here: %v", err)
	}

	lister, _ := engine.As[engine.RelationLister](c)
	relations, err := lister.ListRelations(ctx, "other", "main")
	if err != nil || len(relations) != 1 || relations[0].Table != "child" || relations[0].ReferencedTable != "parent" {
		t.Errorf("relations of other = %+v, %v", relations, err)
	}
	keyed, _ := lister.ListKeyedColumns(ctx, "other", "main")
	if len(keyed) != 4 || keyed[0].Table != "child" || keyed[0].PrimaryKeyOrder != 1 || keyed[1].Name != "parent_id" || !keyed[1].Nullable || keyed[3].Name != "name" || keyed[3].Nullable {
		t.Errorf("keyed columns of other = %+v", keyed)
	}
	columns, _ := engine.As[engine.ColumnLister](c)
	refs, _ := columns.ListColumns(ctx, "other", "extra")
	if len(refs) != 1 || refs[0].Table != "notes" || refs[0].TypeName != "VARCHAR" {
		t.Errorf("columns of other.extra = %+v", refs)
	}
	d2, _ := sqldialect.Of(c)
	got, _ := query(t, c, "SELECT count(*) FROM "+d2.QualifyTableIn("other", "main", "parent"))
	if got.rows[0][0].Int != 0 {
		t.Errorf("count = %+v", got.rows)
	}
}

func TestEditabilityRules(t *testing.T) {
	c := connectTo(t, map[string]string{ParamPath: MemoryPath})
	query(t, c, "CREATE TABLE keyed (a INTEGER PRIMARY KEY)")
	query(t, c, "CREATE TABLE unique_not_null (a INTEGER NOT NULL UNIQUE, b INTEGER)")
	query(t, c, "CREATE TABLE unique_nullable (a INTEGER UNIQUE, b INTEGER)")
	query(t, c, "CREATE TABLE bare (a INTEGER)")
	si, _ := engine.As[engine.SchemaInspector](c)
	for table, want := range map[string]bool{"keyed": true, "unique_not_null": true, "unique_nullable": false, "bare": false} {
		d, err := si.DescribeTable(context.Background(), "", "main", table)
		if err != nil || d.CanEdit != want || (!want && d.EditDisabledReason == "") {
			t.Errorf("%s: CanEdit = %v (%q), want %v, %v", table, d.CanEdit, d.EditDisabledReason, want, err)
		}
	}
}

func TestEditByCompositeKey(t *testing.T) {
	_, c := seededFile(t)
	d, _ := sqldialect.Of(c)
	ref := &queravuev1.TableRef{Schema: "main", Table: "order_items"}
	integer := func(n int64) *queravuev1.Value {
		return &queravuev1.Value{Kind: &queravuev1.Value_IntValue{IntValue: n}}
	}
	text := func(s string) *queravuev1.Value {
		return &queravuev1.Value{Kind: &queravuev1.Value_TextValue{TextValue: s}}
	}
	plans, _, err := sqlbuilder.BuildApplyChanges(d, ref, []*queravuev1.RowChange{{
		Type:   queravuev1.RowChangeType_ROW_CHANGE_TYPE_UPDATE,
		Keys:   []*queravuev1.ColumnValue{{Column: "order_id", Value: integer(1)}, {Column: "item_id", Value: integer(2)}},
		Values: []*queravuev1.ColumnValue{{Column: "product_name", Value: text("Keycap Set v2")}},
	}})
	if err != nil {
		t.Fatal(err)
	}
	if _, sum := query(t, c, plans[0].Statement.SQL, plans[0].Statement.Params...); sum.RowsAffected != 1 {
		t.Errorf("affected = %d", sum.RowsAffected)
	}
	got, _ := query(t, c, "SELECT product_name FROM order_items WHERE order_id = 1 AND item_id = 2")
	if got.rows[0][0].Str != "Keycap Set v2" {
		t.Errorf("row = %+v", got.rows)
	}
}

func TestForeignKeyViolationIsAConstraintError(t *testing.T) {
	_, c := seededFile(t)
	ex, _ := engine.As[engine.Executor](c)
	_, err := ex.Execute(context.Background(), engine.Statement{SQL: "INSERT INTO orders (customer_id) VALUES (999)"}, &collector{})
	if engine.KindOf(err) != engine.KindSQL {
		t.Errorf("err = %v (kind %v), want sql", err, engine.KindOf(err))
	}
}
