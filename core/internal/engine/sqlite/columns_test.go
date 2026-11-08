package sqlite

import (
	"context"
	"path/filepath"
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func TestListColumnsReturnsAllTablesAndViewsInOrder(t *testing.T) {
	path := filepath.Join(t.TempDir(), "c.db")
	c, err := connect(t, map[string]string{"path": path, "create_if_missing": "true"})
	if err != nil {
		t.Fatal(err)
	}
	db := c.(*Conn).db
	for _, stmt := range []string{
		"CREATE TABLE customers (id INTEGER PRIMARY KEY, name TEXT, email VARCHAR(80))",
		"CREATE TABLE orders (id INTEGER PRIMARY KEY, customer_id INTEGER, total NUMERIC)",
		"CREATE VIEW order_totals AS SELECT customer_id, total FROM orders",
	} {
		if _, err := db.Exec(stmt); err != nil {
			t.Fatal(err)
		}
	}
	refs, err := c.(engine.ColumnLister).ListColumns(context.Background(), "", "")
	if err != nil {
		t.Fatal(err)
	}
	var got []string
	for _, r := range refs {
		got = append(got, r.Table+"."+r.Name+":"+r.TypeName)
	}
	want := []string{
		"customers.id:INTEGER", "customers.name:TEXT", "customers.email:VARCHAR(80)",
		"order_totals.customer_id:INTEGER", "order_totals.total:NUMERIC",
		"orders.id:INTEGER", "orders.customer_id:INTEGER", "orders.total:NUMERIC",
	}
	if len(got) != len(want) {
		t.Fatalf("columns = %v, want %v", got, want)
	}
	for i := range want {
		if got[i] != want[i] {
			t.Errorf("column %d = %q, want %q", i, got[i], want[i])
		}
	}
}
