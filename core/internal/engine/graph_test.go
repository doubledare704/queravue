package engine_test

import (
	"reflect"
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func TestRelationRowsFoldsColumnRowsIntoRelations(t *testing.T) {
	var rows engine.RelationRows
	toCustomers := engine.ForeignKeyDef{ReferencedTable: "customers", OnDelete: engine.ReferentialCascade}
	toProducts := engine.ForeignKeyDef{ReferencedTable: "products"}
	rows.Add("order_items", "fk_order", engine.ForeignKeyDef{ReferencedTable: "orders"}, "order_id", "id")
	rows.Add("order_items", "fk_product", toProducts, "product_sku", "sku")
	rows.Add("order_items", "fk_product", toProducts, "product_rev", "rev")
	rows.Add("orders", "fk_product", toCustomers, "customer_id", "id")

	got := rows.Relations()
	want := []engine.TableRelation{
		{Table: "order_items", ForeignKeyDef: engine.ForeignKeyDef{Name: "fk_order", ReferencedTable: "orders", Columns: []string{"order_id"}, ReferencedColumns: []string{"id"}}},
		{Table: "order_items", ForeignKeyDef: engine.ForeignKeyDef{Name: "fk_product", ReferencedTable: "products", Columns: []string{"product_sku", "product_rev"}, ReferencedColumns: []string{"sku", "rev"}}},
		{Table: "orders", ForeignKeyDef: engine.ForeignKeyDef{Name: "fk_product", ReferencedTable: "customers", OnDelete: engine.ReferentialCascade, Columns: []string{"customer_id"}, ReferencedColumns: []string{"id"}}},
	}
	if !reflect.DeepEqual(got, want) {
		t.Errorf("relations = %+v\nwant %+v", got, want)
	}
}
