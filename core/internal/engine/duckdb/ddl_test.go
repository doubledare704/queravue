//go:build duckdb

package duckdb

import (
	"context"
	"errors"
	"slices"
	"strings"
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

type designer struct {
	t *testing.T
	c engine.Conn
	d sqldialect.Dialect
}

func newDesigner(t *testing.T, c engine.Conn) designer {
	d, _ := sqldialect.Of(c)
	return designer{t: t, c: c, d: d}
}

func (g designer) run(table string, current *engine.TableDetails, changes ...sqldialect.Change) (sqldialect.Script, error) {
	g.t.Helper()
	script, err := sqldialect.BuildDDL(g.d, sqldialect.Target{Schema: "main", Table: table}, current, changes)
	if err != nil {
		return script, err
	}
	for _, st := range script.Statements {
		query(g.t, g.c, st.SQL)
	}
	return script, nil
}

func (g designer) describe(table string) engine.TableDetails {
	g.t.Helper()
	si, _ := engine.As[engine.SchemaInspector](g.c)
	got, err := si.DescribeTable(context.Background(), "", "main", table)
	if err != nil {
		g.t.Fatalf("describe %s: %v", table, err)
	}
	return got
}

func column(td engine.TableDetails, name string) (engine.ColumnDef, bool) {
	i := slices.IndexFunc(td.Columns, func(c engine.ColumnDef) bool { return c.Name == name })
	if i < 0 {
		return engine.ColumnDef{}, false
	}
	return td.Columns[i], true
}

func TestDesignerSubsetRoundTrip(t *testing.T) {
	c := connectTo(t, map[string]string{ParamPath: MemoryPath})
	g := newDesigner(t, c)

	if _, err := g.run("parent", nil, sqldialect.CreateTable{Design: sqldialect.TableDesign{
		Columns:    []sqldialect.ColumnSpec{{Name: "id", TypeName: "integer", Identity: true}, {Name: "code", TypeName: "varchar(10)"}},
		PrimaryKey: []string{"id"},
		Uniques:    []sqldialect.UniqueSpec{{Name: "uq_parent_code", Columns: []string{"code"}}},
		Checks:     []sqldialect.CheckSpec{{Name: "ck_parent_code", Expression: "length(code) > 1"}},
	}}); err != nil {
		t.Fatal(err)
	}
	if _, err := g.run("child", nil, sqldialect.CreateTable{Design: sqldialect.TableDesign{
		Columns: []sqldialect.ColumnSpec{
			{Name: "id", TypeName: "integer", Identity: true},
			{Name: "parent_id", TypeName: "integer"},
			{Name: "label", TypeName: "varchar(50)", Nullable: true},
			{Name: "amount", TypeName: "decimal(10,2)", Default: ptr("0")},
		},
		PrimaryKey: []string{"id"},
		ForeignKeys: []sqldialect.ForeignKeySpec{{
			Name: "fk_child_parent", Columns: []string{"parent_id"}, RefSchema: "main", RefTable: "parent", RefColumns: []string{"id"},
			OnDelete: engine.ReferentialRestrict,
		}},
	}}); err != nil {
		t.Fatal(err)
	}

	query(t, c, "INSERT INTO parent (code) VALUES ('aa'), ('bb')")
	query(t, c, "INSERT INTO child (parent_id, label) VALUES (1, 'x'), (2, 'y')")
	if got, _ := query(t, c, "SELECT id FROM child ORDER BY id"); got.rows[1][0].Int != 2 {
		t.Errorf("identity ids = %+v", got.rows)
	}
	created := g.describe("child")
	if id, ok := column(created, "id"); !ok || !id.Identity || !id.IsPrimaryKey || id.Nullable {
		t.Errorf("id = %+v, want an identity primary key", id)
	}
	if len(created.ForeignKeys) != 1 || created.ForeignKeys[0].ReferencedTable != "parent" ||
		!slices.Equal(created.ForeignKeys[0].Columns, []string{"parent_id"}) || !slices.Equal(created.ForeignKeys[0].ReferencedColumns, []string{"id"}) {
		t.Errorf("foreign keys = %+v", created.ForeignKeys)
	}
	if uq := g.describe("parent").Indexes; !slices.ContainsFunc(uq, func(i engine.IndexDef) bool {
		return i.IsUnique && !i.IsPrimary && slices.Equal(i.Columns, []string{"code"})
	}) {
		t.Errorf("parent indexes = %+v", uq)
	}

	if _, err := g.run("child", &created, sqldialect.AddColumn{Column: sqldialect.ColumnSpec{Name: "extra", TypeName: "varchar(20)", Nullable: true}}); err != nil {
		t.Fatal(err)
	}
	if _, err := g.run("child", nil, sqldialect.RenameColumn{From: "label", To: "title"}); err != nil {
		t.Fatal(err)
	}
	renamed := g.describe("child")
	if _, ok := column(renamed, "title"); !ok {
		t.Fatalf("columns after rename = %+v", renamed.Columns)
	}
	alter := sqldialect.AlterColumn{
		Before: sqldialect.ColumnSpec{Name: "extra", TypeName: "varchar(20)", Nullable: true},
		After:  sqldialect.ColumnSpec{Name: "extra", TypeName: "varchar(80)", Nullable: true, Default: ptr("'n/a'")},
	}
	if _, err := g.run("child", &renamed, alter); err != nil {
		t.Fatal(err)
	}
	extra, _ := column(g.describe("child"), "extra")
	if extra.TypeName != "VARCHAR" || !extra.Nullable || extra.DefaultValue == nil || !strings.Contains(*extra.DefaultValue, "n/a") {
		t.Errorf("extra after alter = %+v", extra)
	}
	nullability := sqldialect.AlterColumn{
		Before: sqldialect.ColumnSpec{Name: "amount", TypeName: "decimal(10,2)", Default: ptr("0")},
		After:  sqldialect.ColumnSpec{Name: "amount", TypeName: "decimal(10,2)", Nullable: true, Default: ptr("0")},
	}
	if _, err := g.run("child", nil, nullability); err != nil {
		t.Fatal(err)
	}
	if amount, _ := column(g.describe("child"), "amount"); !amount.Nullable {
		t.Errorf("amount = %+v, want nullable", amount)
	}
	if _, err := g.run("child", nil, sqldialect.DropColumn{Name: "extra"}); err != nil {
		t.Fatal(err)
	}
	if _, ok := column(g.describe("child"), "extra"); ok {
		t.Error("extra is still there after DROP COLUMN")
	}

	if _, err := g.run("child", nil, sqldialect.AddIndex{Index: engine.IndexSpec{Name: "ix_child_title", Keys: []engine.IndexKey{{Name: "title"}, {Name: "amount"}}}}); err != nil {
		t.Fatal(err)
	}
	indexed := g.describe("child")
	if !slices.ContainsFunc(indexed.Indexes, func(i engine.IndexDef) bool {
		return i.Name == "ix_child_title" && slices.Equal(i.Columns, []string{"title", "amount"})
	}) {
		t.Errorf("indexes = %+v", indexed.Indexes)
	}
	if _, err := g.run("child", nil, sqldialect.DropIndex{Name: "ix_child_title"}); err != nil {
		t.Fatal(err)
	}
	if _, err := g.run("child", nil, sqldialect.RenameTable{NewName: "child_renamed"}); err != nil {
		t.Fatal(err)
	}
	g.describe("child_renamed")
	if _, err := g.run("child_renamed", nil, sqldialect.DropTable{}); err != nil {
		t.Fatal(err)
	}
	si, _ := engine.As[engine.SchemaInspector](c)
	if _, err := si.DescribeTable(context.Background(), "", "main", "child_renamed"); engine.KindOf(err) != engine.KindNotFound {
		t.Errorf("describe after drop: %v, want not found", err)
	}
}

func TestDesignerRefusesWhatDuckDBCannotDo(t *testing.T) {
	c := connectTo(t, map[string]string{ParamPath: MemoryPath})
	g := newDesigner(t, c)
	fk := sqldialect.ForeignKeySpec{Name: "fk", Columns: []string{"a"}, RefTable: "r", RefColumns: []string{"id"}}
	cascading := fk
	cascading.OnDelete = engine.ReferentialCascade
	tests := map[string][]sqldialect.Change{
		"add foreign key":          {sqldialect.AddForeignKey{ForeignKey: fk}},
		"add check":                {sqldialect.AddCheck{Check: sqldialect.CheckSpec{Expression: "a > 0"}}},
		"drop constraint":          {sqldialect.DropConstraint{Name: "x"}},
		"cascading foreign key":    {sqldialect.CreateTable{Design: sqldialect.TableDesign{Columns: []sqldialect.ColumnSpec{{Name: "a", TypeName: "integer"}}, ForeignKeys: []sqldialect.ForeignKeySpec{cascading}}}},
		"identity with default":    {sqldialect.CreateTable{Design: sqldialect.TableDesign{Columns: []sqldialect.ColumnSpec{{Name: "a", TypeName: "integer", Identity: true, Default: ptr("1")}}}}},
		"identity switched on/off": {sqldialect.AlterColumn{Before: sqldialect.ColumnSpec{Name: "a", TypeName: "integer"}, After: sqldialect.ColumnSpec{Name: "a", TypeName: "integer", Identity: true}}},
	}
	for name, changes := range tests {
		t.Run(name, func(t *testing.T) {
			_, err := g.run("t", nil, changes...)
			var unsupported *sqldialect.UnsupportedError
			if !errors.As(err, &unsupported) {
				t.Fatalf("err = %v, want an UnsupportedError", err)
			}
		})
	}
}

func TestDesignerWarnsAboutDependencyLimits(t *testing.T) {
	c := connectTo(t, map[string]string{ParamPath: MemoryPath})
	g := newDesigner(t, c)
	query(t, c, "CREATE TABLE t (id INTEGER PRIMARY KEY, a INTEGER)")
	script, err := g.run("t", nil, sqldialect.RenameColumn{From: "a", To: "b"})
	if err != nil || len(script.Warnings) != 1 || !strings.Contains(script.Warnings[0], "depends on") {
		t.Errorf("warnings = %v, %v", script.Warnings, err)
	}
}

func TestDiagramDDLOrdersReferencedTablesFirst(t *testing.T) {
	c := connectTo(t, map[string]string{ParamPath: MemoryPath})
	g := newDesigner(t, c)
	target := func(name string) sqldialect.Target { return sqldialect.Target{Schema: "main", Table: name} }
	reference := func(name, column, table string, refColumns ...string) sqldialect.ForeignKeySpec {
		return sqldialect.ForeignKeySpec{Name: name, Columns: []string{column}, RefSchema: "main", RefTable: table, RefColumns: refColumns}
	}
	create := func(name string, columns []string, key []string, fks ...sqldialect.ForeignKeySpec) sqldialect.TableChanges {
		specs := make([]sqldialect.ColumnSpec, len(columns))
		for i, n := range columns {
			specs[i] = sqldialect.ColumnSpec{Name: n, TypeName: "integer", Nullable: !slices.Contains(key, n)}
		}
		return sqldialect.TableChanges{Target: target(name), Changes: []sqldialect.Change{sqldialect.CreateTable{Design: sqldialect.TableDesign{Columns: specs, PrimaryKey: key, ForeignKeys: fks}}}}
	}
	script, err := sqldialect.BuildDiagramDDL(g.d, []sqldialect.TableChanges{
		create("returns", []string{"id", "order_no", "line_no"}, []string{"id"}),
		create("child", []string{"id", "parent_id"}, []string{"id"}, reference("fk_child_parent", "parent_id", "parent", "id")),
		create("parent", []string{"id", "up_id"}, []string{"id"}, reference("fk_parent_up", "up_id", "parent", "id")),
		create("lines", []string{"order_no", "line_no"}, []string{"order_no", "line_no"}),
	})
	if err != nil {
		t.Fatal(err)
	}
	for _, st := range script.Statements {
		query(t, c, st.SQL)
	}
	child := g.describe("child")
	if len(child.ForeignKeys) != 1 || child.ForeignKeys[0].ReferencedTable != "parent" {
		t.Errorf("child foreign keys = %+v", child.ForeignKeys)
	}
	if up := g.describe("parent").ForeignKeys; len(up) != 1 || up[0].ReferencedTable != "parent" {
		t.Errorf("parent foreign keys = %+v", up)
	}

	_, err = sqldialect.BuildDiagramDDL(g.d, []sqldialect.TableChanges{{Target: target("child"), Changes: []sqldialect.Change{
		sqldialect.AddForeignKey{ForeignKey: reference("fk_late", "id", "lines", "order_no")},
	}}})
	var unsupported *sqldialect.UnsupportedError
	if !errors.As(err, &unsupported) {
		t.Errorf("a foreign key on an existing table: %v, want an UnsupportedError", err)
	}
}

func TestCompositeForeignKeyOnCreate(t *testing.T) {
	c := connectTo(t, map[string]string{ParamPath: MemoryPath})
	g := newDesigner(t, c)
	query(t, c, "CREATE TABLE lines (order_no INTEGER, line_no INTEGER, PRIMARY KEY (order_no, line_no))")
	if _, err := g.run("returns", nil, sqldialect.CreateTable{Design: sqldialect.TableDesign{
		Columns:     []sqldialect.ColumnSpec{{Name: "id", TypeName: "integer"}, {Name: "o", TypeName: "integer", Nullable: true}, {Name: "l", TypeName: "integer", Nullable: true}},
		PrimaryKey:  []string{"id"},
		ForeignKeys: []sqldialect.ForeignKeySpec{{Name: "fk_returns_lines", Columns: []string{"o", "l"}, RefSchema: "main", RefTable: "lines", RefColumns: []string{"order_no", "line_no"}}},
	}}); err != nil {
		t.Fatal(err)
	}
	fks := g.describe("returns").ForeignKeys
	if len(fks) != 1 || !slices.Equal(fks[0].Columns, []string{"o", "l"}) || !slices.Equal(fks[0].ReferencedColumns, []string{"order_no", "line_no"}) {
		t.Errorf("foreign keys = %+v", fks)
	}
}

func ptr(s string) *string { return &s }
