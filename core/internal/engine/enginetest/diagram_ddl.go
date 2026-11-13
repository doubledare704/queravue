package enginetest

import (
	"context"
	"strings"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

const (
	diagramParent  = "qv_diagram_parent"
	diagramChild   = "qv_diagram_child"
	diagramLines   = "qv_diagram_lines"
	diagramReturns = "qv_diagram_returns"
	diagramNotes   = "qv_diagram_notes"
)

// diagramDDL lists the child before the table it references, and the parent
// references itself, so the script only works if foreign keys come last.
func diagramDDL(t *testing.T, tg Target) {
	c := tg.connect(t)
	d, ok := sqldialect.Of(c)
	if !ok {
		t.Fatal("connection has no dialect")
	}
	inspector, ok := engine.As[engine.SchemaInspector](c)
	if !ok {
		t.Fatal("connection is not a SchemaInspector")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	cleanup := func() {
		for _, name := range []string{diagramChild, diagramParent} {
			exec(t, c, "DROP TABLE IF EXISTS "+d.QualifyTableIn(tg.Database, tg.Schema, name))
		}
	}
	cleanup()
	t.Cleanup(cleanup)

	reference := func(name, column, table string) sqldialect.ForeignKeySpec {
		return sqldialect.ForeignKeySpec{Name: name, Columns: []string{column}, RefSchema: tg.Schema, RefTable: table, RefColumns: []string{"id"}}
	}
	table := func(name string, fk sqldialect.ForeignKeySpec) sqldialect.TableChanges {
		return sqldialect.TableChanges{
			Target: sqldialect.Target{Database: tg.Database, Schema: tg.Schema, Table: name},
			Changes: []sqldialect.Change{sqldialect.CreateTable{Design: sqldialect.TableDesign{
				Columns: []sqldialect.ColumnSpec{
					{Name: "id", TypeName: "integer"},
					{Name: fk.Columns[0], TypeName: "integer", Nullable: true},
				},
				PrimaryKey:  []string{"id"},
				ForeignKeys: []sqldialect.ForeignKeySpec{fk},
			}}},
		}
	}
	script, err := sqldialect.BuildDiagramDDL(d, []sqldialect.TableChanges{
		table(diagramChild, reference("fk_qv_diagram_child_parent", "parent_id", diagramParent)),
		table(diagramParent, reference("fk_qv_diagram_parent_up", "up_id", diagramParent)),
	})
	if err != nil {
		t.Fatal(err)
	}
	for _, st := range script.Statements {
		exec(t, c, st.SQL)
	}
	for name, want := range map[string]string{diagramChild: diagramParent, diagramParent: diagramParent} {
		got, err := inspector.DescribeTable(ctx, tg.Database, tg.Schema, name)
		if err != nil {
			t.Fatalf("describe %s: %v", name, err)
		}
		if len(got.ForeignKeys) != 1 || got.ForeignKeys[0].ReferencedTable != want {
			t.Errorf("%s foreign keys = %+v, want one to %s", name, got.ForeignKeys, want)
		}
	}
}

// diagramCompositeDDL references a two-column primary key from a table drafted
// with it and from a table that already exists.
func diagramCompositeDDL(t *testing.T, tg Target) {
	c := tg.connect(t)
	d, ok := sqldialect.Of(c)
	if !ok {
		t.Fatal("connection has no dialect")
	}
	inspector, ok := engine.As[engine.SchemaInspector](c)
	if !ok {
		t.Fatal("connection is not a SchemaInspector")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	cleanup := func() {
		for _, name := range []string{diagramReturns, diagramNotes, diagramLines} {
			exec(t, c, "DROP TABLE IF EXISTS "+d.QualifyTableIn(tg.Database, tg.Schema, name))
		}
	}
	cleanup()
	t.Cleanup(cleanup)
	exec(t, c, "CREATE TABLE "+d.QualifyTableIn(tg.Database, tg.Schema, diagramNotes)+" (id integer PRIMARY KEY, order_no integer)")

	target := func(name string) sqldialect.Target {
		return sqldialect.Target{Database: tg.Database, Schema: tg.Schema, Table: name}
	}
	toLines := func(name string, columns ...string) sqldialect.ForeignKeySpec {
		return sqldialect.ForeignKeySpec{Name: name, Columns: columns, RefSchema: tg.Schema, RefTable: diagramLines, RefColumns: []string{"order_no", "line_no"}}
	}
	nullable := func(name string) sqldialect.ColumnSpec {
		return sqldialect.ColumnSpec{Name: name, TypeName: "integer", Nullable: true}
	}
	script, err := sqldialect.BuildDiagramDDL(d, []sqldialect.TableChanges{
		{Target: target(diagramReturns), Changes: []sqldialect.Change{sqldialect.CreateTable{Design: sqldialect.TableDesign{
			Columns:     []sqldialect.ColumnSpec{{Name: "id", TypeName: "integer"}, nullable("lines_order_no"), nullable("lines_line_no")},
			PrimaryKey:  []string{"id"},
			ForeignKeys: []sqldialect.ForeignKeySpec{toLines("fk_qv_diagram_returns_lines", "lines_order_no", "lines_line_no")},
		}}}},
		{Target: target(diagramNotes), Changes: []sqldialect.Change{
			sqldialect.AddColumn{Column: nullable("lines_line_no")},
			sqldialect.AddForeignKey{ForeignKey: toLines("fk_qv_diagram_notes_lines", "order_no", "lines_line_no")},
		}},
		{Target: target(diagramLines), Changes: []sqldialect.Change{sqldialect.CreateTable{Design: sqldialect.TableDesign{
			Columns:    []sqldialect.ColumnSpec{{Name: "order_no", TypeName: "integer"}, {Name: "line_no", TypeName: "integer"}},
			PrimaryKey: []string{"order_no", "line_no"},
		}}}},
	})
	if err != nil {
		t.Fatal(err)
	}
	for _, st := range script.Statements {
		exec(t, c, st.SQL)
	}
	for name, want := range map[string][]string{
		diagramReturns: {"lines_order_no", "lines_line_no"},
		diagramNotes:   {"order_no", "lines_line_no"},
	} {
		got, err := inspector.DescribeTable(ctx, tg.Database, tg.Schema, name)
		if err != nil {
			t.Fatalf("describe %s: %v", name, err)
		}
		if len(got.ForeignKeys) != 1 || got.ForeignKeys[0].ReferencedTable != diagramLines ||
			strings.Join(got.ForeignKeys[0].Columns, ",") != strings.Join(want, ",") ||
			strings.Join(got.ForeignKeys[0].ReferencedColumns, ",") != "order_no,line_no" {
			t.Errorf("%s foreign keys = %+v, want (%s) to %s (order_no, line_no)", name, got.ForeignKeys, strings.Join(want, ", "), diagramLines)
		}
	}
}
