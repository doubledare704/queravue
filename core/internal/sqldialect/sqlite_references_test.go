package sqldialect_test

import (
	"errors"
	"reflect"
	"strings"
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

func addColumn(name string, nullable bool) sqldialect.AddColumn {
	return sqldialect.AddColumn{Column: sqldialect.ColumnSpec{Name: name, TypeName: "integer", Nullable: nullable}}
}

func addForeignKey(name string, columns []string, table string, refColumns ...string) sqldialect.AddForeignKey {
	return sqldialect.AddForeignKey{ForeignKey: sqldialect.ForeignKeySpec{
		Name: name, Columns: columns, RefTable: table, RefColumns: refColumns, OnDelete: engine.ReferentialSetNull,
	}}
}

func statementsOf(script sqldialect.Script) []string {
	var out []string
	for _, s := range script.Statements {
		out = append(out, s.SQL)
	}
	return out
}

func TestSQLiteAddsANewReferencingColumnInPlace(t *testing.T) {
	script, err := sqldialect.BuildDDL(sqldialect.SQLite, sqldialect.Target{Schema: "main", Table: "orders"}, &engine.TableDetails{},
		[]sqldialect.Change{
			addColumn("customers_id", true),
			addColumn("note", true),
			addForeignKey("fk_orders_customers", []string{"customers_id"}, "customers", "id"),
		})
	if err != nil {
		t.Fatal(err)
	}
	want := []string{
		`ALTER TABLE "orders" ADD COLUMN "customers_id" integer CONSTRAINT "fk_orders_customers" REFERENCES "customers" ("id") ON DELETE SET NULL;`,
		`ALTER TABLE "orders" ADD COLUMN "note" integer;`,
	}
	if got := statementsOf(script); !reflect.DeepEqual(got, want) {
		t.Errorf("statements = %q\nwant %q", got, want)
	}
	if !script.Transactional || script.Statements[0].Destructive || len(script.Warnings) != 0 {
		t.Errorf("script = %+v", script)
	}
	if got := script.Statements[0].Summary; got != "Add column customers_id referencing customers" {
		t.Errorf("summary = %q", got)
	}
}

func TestSQLiteRefusesAReferencingColumnThatDoesNotStartNull(t *testing.T) {
	zero := "0"
	for _, column := range []sqldialect.ColumnSpec{
		{Name: "customers_id", TypeName: "integer"},
		{Name: "customers_id", TypeName: "integer", Nullable: true, Default: &zero},
	} {
		_, err := sqldialect.BuildDDL(sqldialect.SQLite, sqldialect.Target{Table: "orders"}, &engine.TableDetails{},
			[]sqldialect.Change{sqldialect.AddColumn{Column: column}, addForeignKey("fk", []string{"customers_id"}, "customers", "id")})
		var u *sqldialect.UnsupportedError
		if !errors.As(err, &u) || !strings.Contains(u.Reason, "starts out NULL") {
			t.Errorf("%+v: err = %v, want the start-out-NULL refusal", column, err)
		}
	}
}

func TestSQLiteRebuildsToAddAForeignKeyOnAnExistingColumn(t *testing.T) {
	script, err := sqldialect.BuildDDL(sqldialect.SQLite, sqldialect.Target{Table: "items"}, rebuildTable(itemsSQL),
		[]sqldialect.Change{
			addColumn("owner_id", true),
			addForeignKey("fk_items_title", []string{"title"}, "titles", "name"),
		})
	if err != nil {
		t.Fatal(err)
	}
	want := []string{
		"CREATE TABLE \"qv_rebuild_items\" (\n  id INTEGER PRIMARY KEY AUTOINCREMENT,\n  \"title\" text NOT NULL DEFAULT 'x' COLLATE NOCASE,\n  qty integer CHECK (qty >= 0),\n" +
			"  \"owner_id\" integer,\n  UNIQUE (title),\n  FOREIGN KEY (qty) REFERENCES other (id),\n" +
			"  CONSTRAINT \"fk_items_title\" FOREIGN KEY (\"title\") REFERENCES \"titles\" (\"name\") ON DELETE SET NULL\n) STRICT;",
		`INSERT INTO "qv_rebuild_items" ("id", "title", "qty") SELECT "id", "title", "qty" FROM "items";`,
		`DROP TABLE "items";`,
		`ALTER TABLE "qv_rebuild_items" RENAME TO "items";`,
		`CREATE INDEX "ix_title" ON "items" ("title");`,
	}
	if got := statementsOf(script); !reflect.DeepEqual(got, want) {
		t.Errorf("statements:\n%s\nwant:\n%s", strings.Join(got, "\n"), strings.Join(want, "\n"))
	}
	if got := script.Statements[3].Summary; got != "Swap in the rebuilt table (adding column owner_id; adding foreign key fk_items_title)" {
		t.Errorf("summary = %q", got)
	}
	for _, s := range script.Statements {
		if s.Destructive {
			t.Errorf("%q is not destructive: no type changed", s.Summary)
		}
	}
	if len(script.Warnings) != 2 || !strings.Contains(script.Warnings[1], "not checked") {
		t.Errorf("warnings = %q", script.Warnings)
	}
}

func TestSQLiteRebuildsForAMultiColumnKeyOnNewColumns(t *testing.T) {
	script, err := sqldialect.BuildDDL(sqldialect.SQLite, sqldialect.Target{Table: "items"}, rebuildTable(itemsSQL),
		[]sqldialect.Change{
			addColumn("a", true), addColumn("b", true),
			addForeignKey("fk_pair", []string{"a", "b"}, "pairs", "x", "y"),
		})
	if err != nil {
		t.Fatal(err)
	}
	created := script.Statements[0].SQL
	if !strings.Contains(created, "\"a\" integer,\n  \"b\" integer,\n  UNIQUE (title)") ||
		!strings.Contains(created, `FOREIGN KEY ("a", "b") REFERENCES "pairs" ("x", "y")`) {
		t.Errorf("rebuilt table:\n%s", created)
	}
}

func TestSQLiteForeignKeyRebuildRefusals(t *testing.T) {
	tests := []struct {
		name    string
		current *engine.TableDetails
		changes []sqldialect.Change
		want    string
	}{
		{
			"other changes alongside",
			rebuildTable(itemsSQL),
			[]sqldialect.Change{addForeignKey("fk", []string{"title"}, "titles", "name"), sqldialect.DropColumn{Name: "qty"}},
			"only added columns can go with it",
		},
		{
			"foreign keys enforced",
			rebuildTable(itemsSQL, "foreign keys are enforced on this connection"),
			[]sqldialect.Change{addForeignKey("fk", []string{"title"}, "titles", "name")},
			"cannot be rebuilt safely: foreign keys are enforced",
		},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			_, err := sqldialect.BuildDDL(sqldialect.SQLite, sqldialect.Target{Table: "items"}, tt.current, tt.changes)
			var u *sqldialect.UnsupportedError
			if !errors.As(err, &u) || !strings.Contains(u.Reason, tt.want) {
				t.Errorf("err = %v, want %q", err, tt.want)
			}
		})
	}
}
