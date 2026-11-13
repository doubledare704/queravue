package sqldialect_test

import (
	"errors"
	"strings"
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

func simpleTable(name string, refs ...string) sqldialect.TableChanges {
	design := sqldialect.TableDesign{
		Columns:    []sqldialect.ColumnSpec{{Name: "id", TypeName: "integer"}},
		PrimaryKey: []string{"id"},
	}
	for _, ref := range refs {
		col := ref + "_id"
		design.Columns = append(design.Columns, sqldialect.ColumnSpec{Name: col, TypeName: "integer", Nullable: true})
		design.ForeignKeys = append(design.ForeignKeys, sqldialect.ForeignKeySpec{
			Name: "fk_" + name + "_" + ref, Columns: []string{col}, RefTable: ref, RefColumns: []string{"id"},
		})
	}
	return sqldialect.TableChanges{
		Target:  sqldialect.Target{Table: name},
		Changes: []sqldialect.Change{sqldialect.CreateTable{Design: design}},
	}
}

func summaries(s sqldialect.Script) string {
	out := make([]string, len(s.Statements))
	for i, st := range s.Statements {
		out[i] = st.Summary
	}
	return strings.Join(out, " | ")
}

func TestDiagramDDLCreatesTablesBeforeTheirForeignKeys(t *testing.T) {
	addNote := sqldialect.TableChanges{
		Target:  sqldialect.Target{Table: "customers"},
		Current: &engine.TableDetails{},
		Changes: []sqldialect.Change{
			sqldialect.AddForeignKey{ForeignKey: sqldialect.ForeignKeySpec{Name: "fk_customers_orders", Columns: []string{"last_order"}, RefTable: "orders", RefColumns: []string{"id"}}},
			sqldialect.AddColumn{Column: sqldialect.ColumnSpec{Name: "last_order", TypeName: "integer", Nullable: true}},
		},
	}
	script, err := sqldialect.BuildDiagramDDL(sqldialect.Postgres, []sqldialect.TableChanges{
		addNote,
		simpleTable("orders", "customers", "items"),
		simpleTable("items", "orders"),
	})
	if err != nil {
		t.Fatal(err)
	}
	want := "Create table orders | Create table items | Add column last_order on customers | " +
		"Add foreign key fk_orders_customers on orders | Add foreign key fk_orders_items on orders | " +
		"Add foreign key fk_items_orders on items | Add foreign key fk_customers_orders on customers"
	if got := summaries(script); got != want {
		t.Errorf("order:\n%s\nwant:\n%s", got, want)
	}
	if strings.Contains(script.Statements[0].SQL, "FOREIGN KEY") {
		t.Errorf("create kept its foreign key: %s", script.Statements[0].SQL)
	}
	if script.Statements[3].SQL != `ALTER TABLE "orders" ADD CONSTRAINT "fk_orders_customers" FOREIGN KEY ("customers_id") REFERENCES "customers" ("id");` {
		t.Errorf("foreign key = %s", script.Statements[3].SQL)
	}
	if !script.Transactional || len(script.Warnings) != 0 {
		t.Errorf("transactional = %v, warnings = %v", script.Transactional, script.Warnings)
	}
}

func TestDiagramDDLOnSQLiteKeepsForeignKeysInlineAndCreatesReferencedTablesFirst(t *testing.T) {
	script, err := sqldialect.BuildDiagramDDL(sqldialect.SQLite, []sqldialect.TableChanges{
		simpleTable("order_items", "orders", "products"),
		simpleTable("orders", "customers"),
		simpleTable("customers"),
		simpleTable("products"),
		simpleTable("a", "b"),
		simpleTable("b", "a"),
	})
	if err != nil {
		t.Fatal(err)
	}
	if got, want := summaries(script), "Create table customers | Create table orders | Create table products | Create table order_items | Create table b | Create table a"; got != want {
		t.Errorf("order:\n%s\nwant:\n%s", got, want)
	}
	if !strings.Contains(script.Statements[3].SQL, `FOREIGN KEY ("orders_id") REFERENCES "orders"`) {
		t.Errorf("foreign key not inline: %s", script.Statements[3].SQL)
	}
}

func TestDiagramDDLOnMySQLWarnsOnceAndIsNotTransactional(t *testing.T) {
	script, err := sqldialect.BuildDiagramDDL(sqldialect.MySQL, []sqldialect.TableChanges{simpleTable("a", "b"), simpleTable("b")})
	if err != nil {
		t.Fatal(err)
	}
	if script.Transactional || len(script.Warnings) != 1 || len(script.Statements) != 3 {
		t.Errorf("script = %+v", script)
	}
}

func TestDiagramDDLRejectsInvalidRequests(t *testing.T) {
	existing := sqldialect.TableChanges{
		Target:  sqldialect.Target{Table: "orders"},
		Current: &engine.TableDetails{},
		Changes: []sqldialect.Change{sqldialect.AddForeignKey{ForeignKey: sqldialect.ForeignKeySpec{Columns: []string{"c"}, RefTable: "t", RefColumns: []string{"id"}}}},
	}
	cases := []struct {
		name        string
		d           sqldialect.Dialect
		tables      []sqldialect.TableChanges
		unsupported bool
		contains    string
	}{
		{"nothing", sqldialect.Postgres, nil, false, "no changes"},
		{"twice", sqldialect.Postgres, []sqldialect.TableChanges{simpleTable("a"), simpleTable("a")}, false, "more than once"},
		{"unnamed", sqldialect.Postgres, []sqldialect.TableChanges{{Changes: simpleTable("a").Changes}}, false, "needs a name"},
		{"empty", sqldialect.Postgres, []sqldialect.TableChanges{{Target: sqldialect.Target{Table: "a"}}}, false, "a: no changes"},
		{"sqlite fk on an existing column without its definition", sqldialect.SQLite, []sqldialect.TableChanges{existing}, true, "orders: SQLite cannot change this table in place, and the table's definition is not available"},
		{"no columns", sqldialect.Postgres, []sqldialect.TableChanges{{Target: sqldialect.Target{Table: "a"}, Changes: []sqldialect.Change{sqldialect.CreateTable{}}}}, false, "a: change 1: a table needs at least one column"},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			_, err := sqldialect.BuildDiagramDDL(tc.d, tc.tables)
			var u *sqldialect.UnsupportedError
			if err == nil || errors.As(err, &u) != tc.unsupported || !strings.Contains(err.Error(), tc.contains) {
				t.Errorf("err = %v, want unsupported=%v containing %q", err, tc.unsupported, tc.contains)
			}
		})
	}
}
