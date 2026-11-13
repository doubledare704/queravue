package sqlite

import (
	"context"
	"path/filepath"
	"reflect"
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func graphFixture(t *testing.T) engine.RelationLister {
	t.Helper()
	c, err := connect(t, map[string]string{"path": filepath.Join(t.TempDir(), "g.db"), "create_if_missing": "true"})
	if err != nil {
		t.Fatal(err)
	}
	for _, stmt := range []string{
		"CREATE TABLE customers (id INTEGER PRIMARY KEY, name TEXT NOT NULL, email VARCHAR(80))",
		"CREATE TABLE products (sku TEXT NOT NULL, rev INTEGER NOT NULL, title TEXT, PRIMARY KEY (sku, rev))",
		`CREATE TABLE orders (id INTEGER PRIMARY KEY,
			customer_id INTEGER NOT NULL REFERENCES customers ON DELETE CASCADE,
			note TEXT)`,
		`CREATE TABLE order_items (order_id INTEGER NOT NULL REFERENCES orders(id),
			sku TEXT NOT NULL, rev INTEGER NOT NULL, qty INTEGER,
			FOREIGN KEY (sku, rev) REFERENCES products(sku, rev) ON UPDATE SET NULL)`,
		"CREATE VIEW order_notes AS SELECT id, note FROM orders",
	} {
		if _, err := c.(*Conn).db.Exec(stmt); err != nil {
			t.Fatal(err)
		}
	}
	return c.(engine.RelationLister)
}

func TestListKeyedColumnsReportsKeysAndNullability(t *testing.T) {
	cols, err := graphFixture(t).ListKeyedColumns(context.Background(), "", "")
	if err != nil {
		t.Fatal(err)
	}
	byColumn := map[string]engine.KeyedColumn{}
	var order []string
	for _, c := range cols {
		byColumn[c.Table+"."+c.Name] = c
		order = append(order, c.Table+"."+c.Name)
	}
	wantOrder := []string{
		"customers.id", "customers.name", "customers.email",
		"order_items.order_id", "order_items.sku", "order_items.rev", "order_items.qty",
		"order_notes.id", "order_notes.note",
		"orders.id", "orders.customer_id", "orders.note",
		"products.sku", "products.rev", "products.title",
	}
	if !reflect.DeepEqual(order, wantOrder) {
		t.Fatalf("columns = %v\nwant %v", order, wantOrder)
	}
	for name, want := range map[string]engine.KeyedColumn{
		"customers.id":    {TypeName: "INTEGER", Nullable: true, PrimaryKeyOrder: 1},
		"customers.name":  {TypeName: "TEXT"},
		"customers.email": {TypeName: "VARCHAR(80)", Nullable: true},
		"products.sku":    {TypeName: "TEXT", PrimaryKeyOrder: 1},
		"products.rev":    {TypeName: "INTEGER", PrimaryKeyOrder: 2},
		"order_items.qty": {TypeName: "INTEGER", Nullable: true},
	} {
		got := byColumn[name]
		if got.TypeName != want.TypeName || got.Nullable != want.Nullable || got.PrimaryKeyOrder != want.PrimaryKeyOrder {
			t.Errorf("%s = %+v, want %+v", name, got, want)
		}
	}
}

func TestListRelationsFoldsCompositeKeysResolvesImplicitKeysAndKeepsActions(t *testing.T) {
	rels, err := graphFixture(t).ListRelations(context.Background(), "", "")
	if err != nil {
		t.Fatal(err)
	}
	type summary struct {
		table, refTable string
		cols, refCols   []string
		onDelete        engine.ReferentialAction
		onUpdate        engine.ReferentialAction
	}
	var got []summary
	for _, r := range rels {
		if r.Name == "" || r.ReferencedSchema != "" {
			t.Errorf("relation %+v needs a name and no schema, as it stays in main", r)
		}
		got = append(got, summary{r.Table, r.ReferencedTable, r.Columns, r.ReferencedColumns, r.OnDelete, r.OnUpdate})
	}
	want := []summary{
		{"order_items", "products", []string{"sku", "rev"}, []string{"sku", "rev"}, engine.ReferentialNoAction, engine.ReferentialSetNull},
		{"order_items", "orders", []string{"order_id"}, []string{"id"}, engine.ReferentialNoAction, engine.ReferentialNoAction},
		{"orders", "customers", []string{"customer_id"}, []string{"id"}, engine.ReferentialCascade, engine.ReferentialNoAction},
	}
	if !reflect.DeepEqual(got, want) {
		t.Errorf("relations = %+v\nwant %+v", got, want)
	}
}
