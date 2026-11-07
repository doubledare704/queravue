package sqldialect_test

import (
	"errors"
	"strings"
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

func rebuildTable(createSQL string, blockers ...string) *engine.TableDetails {
	return &engine.TableDetails{
		Table: "items",
		Columns: []engine.ColumnDef{
			{Name: "id"}, {Name: "title"}, {Name: "qty"},
		},
		Rebuild: &engine.TableRebuild{
			CreateSQL:    createSQL,
			DependentSQL: []string{`CREATE INDEX "ix_title" ON "items" ("title")`},
			Blockers:     blockers,
		},
	}
}

const itemsSQL = `CREATE TABLE "items" (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  "title" text NOT NULL DEFAULT 'x' COLLATE NOCASE,
  qty integer CHECK (qty >= 0),
  UNIQUE (title),
  FOREIGN KEY (qty) REFERENCES other (id)
) STRICT`

func alter(name, from, to string) sqldialect.AlterColumn {
	return sqldialect.AlterColumn{
		Before: sqldialect.ColumnSpec{Name: name, TypeName: from, Nullable: true},
		After:  sqldialect.ColumnSpec{Name: name, TypeName: to, Nullable: true},
	}
}

func TestSQLiteRebuildKeepsEveryOtherConstraint(t *testing.T) {
	script, err := sqldialect.BuildDDL(sqldialect.SQLite, sqldialect.Target{Table: "items"}, rebuildTable(itemsSQL),
		[]sqldialect.Change{alter("qty", "integer", "bigint")})
	if err != nil {
		t.Fatal(err)
	}
	var sqls []string
	for _, s := range script.Statements {
		sqls = append(sqls, s.SQL)
		if !s.Destructive && s.Summary != "Recreate an index or trigger" {
			t.Errorf("%q should be destructive after a type change", s.Summary)
		}
	}
	want := []string{
		"CREATE TABLE \"qv_rebuild_items\" (\n  id INTEGER PRIMARY KEY AUTOINCREMENT,\n  \"title\" text NOT NULL DEFAULT 'x' COLLATE NOCASE,\n  qty bigint CHECK (qty >= 0),\n  UNIQUE (title),\n  FOREIGN KEY (qty) REFERENCES other (id)\n) STRICT;",
		`INSERT INTO "qv_rebuild_items" ("id", "title", "qty") SELECT "id", "title", "qty" FROM "items";`,
		`DROP TABLE "items";`,
		`ALTER TABLE "qv_rebuild_items" RENAME TO "items";`,
		`CREATE INDEX "ix_title" ON "items" ("title");`,
	}
	if strings.Join(sqls, "\n") != strings.Join(want, "\n") {
		t.Errorf("statements:\n%s\nwant:\n%s", strings.Join(sqls, "\n"), strings.Join(want, "\n"))
	}
	if len(script.Warnings) != 1 || !strings.Contains(script.Warnings[0], "rebuilds the table") {
		t.Errorf("warnings = %v", script.Warnings)
	}
}

func TestSQLiteRebuildRewritesNullabilityDefaultAndCollation(t *testing.T) {
	def := "'y'"
	collation := "BINARY"
	change := sqldialect.AlterColumn{
		Before: sqldialect.ColumnSpec{Name: "title", TypeName: "text", Nullable: false, Default: ptr("'x'"), Collation: ptr("NOCASE")},
		After:  sqldialect.ColumnSpec{Name: "title", TypeName: "text", Nullable: true, Default: &def, Collation: &collation},
	}
	script, err := sqldialect.BuildDDL(sqldialect.SQLite, sqldialect.Target{Table: "items"}, rebuildTable(itemsSQL), []sqldialect.Change{change})
	if err != nil {
		t.Fatal(err)
	}
	created := script.Statements[0].SQL
	if !strings.Contains(created, `"title" text COLLATE BINARY DEFAULT 'y',`) {
		t.Errorf("rewritten column: %s", created)
	}
	if script.Statements[0].Destructive {
		t.Error("a change without a type change is not destructive")
	}
}

func TestSQLiteRebuildRefusesWhatItCannotDoSafely(t *testing.T) {
	cases := []struct {
		name    string
		details *engine.TableDetails
		changes []sqldialect.Change
		reason  string
	}{
		{"no definition", &engine.TableDetails{Table: "items"}, []sqldialect.Change{alter("qty", "integer", "text")}, "not available"},
		{"blocked", rebuildTable(itemsSQL, `view "v" refers to the table`), []sqldialect.Change{alter("qty", "integer", "text")}, `view "v"`},
		{"with another change", rebuildTable(itemsSQL), []sqldialect.Change{alter("qty", "integer", "text"), sqldialect.DropColumn{Name: "title"}}, "on their own"},
		{"comment", rebuildTable("CREATE TABLE items (qty integer -- note\n)"), []sqldialect.Change{alter("qty", "integer", "text")}, "comment"},
		{"named constraint", rebuildTable("CREATE TABLE items (qty integer CONSTRAINT nn NOT NULL)"), []sqldialect.Change{alter("qty", "integer", "text")}, "named constraint"},
		{"generated column", rebuildTable("CREATE TABLE items (qty integer GENERATED ALWAYS AS (1) STORED)"), []sqldialect.Change{alter("qty", "integer", "text")}, "generated"},
		{"missing column", rebuildTable(itemsSQL), []sqldialect.Change{alter("nope", "integer", "text")}, ""},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			_, err := sqldialect.BuildDDL(sqldialect.SQLite, sqldialect.Target{Table: "items"}, tc.details, tc.changes)
			if err == nil {
				t.Fatal("expected an error")
			}
			var u *sqldialect.UnsupportedError
			if tc.reason != "" && (!errors.As(err, &u) || !strings.Contains(err.Error(), tc.reason)) {
				t.Errorf("error = %v, want unsupported containing %q", err, tc.reason)
			}
		})
	}
}
