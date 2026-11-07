package enginetest

import (
	"context"
	"errors"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

const (
	parentTable  = "qv_ddl_parent"
	childTable   = "qv_ddl_child"
	renamedTable = "qv_ddl_renamed"
)

func ddlRoundTrip(t *testing.T, tg Target) {
	c := tg.connect(t)
	d, ok := sqldialect.Of(c)
	if !ok {
		t.Fatal("connection has no dialect")
	}
	inspector, ok := engine.As[engine.SchemaInspector](c)
	if !ok {
		t.Fatal("connection is not a SchemaInspector")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 90*time.Second)
	defer cancel()

	cleanup := func() {
		for _, name := range []string{childTable, renamedTable, parentTable} {
			exec(t, c, "DROP TABLE IF EXISTS "+d.QualifyTableIn(tg.Database, tg.Schema, name))
		}
	}
	cleanup()
	t.Cleanup(cleanup)

	run := func(table string, current *engine.TableDetails, changes ...sqldialect.Change) (sqldialect.Script, error) {
		t.Helper()
		script, err := sqldialect.BuildDDL(d, sqldialect.Target{Database: tg.Database, Schema: tg.Schema, Table: table}, current, changes)
		if err != nil {
			return script, err
		}
		for _, st := range script.Statements {
			exec(t, c, st.SQL)
		}
		return script, nil
	}
	describe := func(table string) engine.TableDetails {
		t.Helper()
		got, err := inspector.DescribeTable(ctx, tg.Database, tg.Schema, table)
		if err != nil {
			t.Fatalf("describe %s: %v", table, err)
		}
		return got
	}
	column := func(td engine.TableDetails, name string) (engine.ColumnDef, bool) {
		for _, col := range td.Columns {
			if col.Name == name {
				return col, true
			}
		}
		return engine.ColumnDef{}, false
	}

	if _, err := run(parentTable, nil, sqldialect.CreateTable{Design: sqldialect.TableDesign{
		Columns:    []sqldialect.ColumnSpec{{Name: "id", TypeName: "integer", Identity: true}},
		PrimaryKey: []string{"id"},
	}}); err != nil {
		t.Fatal(err)
	}
	if _, err := run(childTable, nil, sqldialect.CreateTable{Design: sqldialect.TableDesign{
		Columns: []sqldialect.ColumnSpec{
			{Name: "id", TypeName: "integer", Identity: true},
			{Name: "parent_id", TypeName: "integer"},
			{Name: "label", TypeName: "varchar(50)", Nullable: true},
		},
		PrimaryKey: []string{"id"},
		ForeignKeys: []sqldialect.ForeignKeySpec{{
			Name: "fk_qv_ddl_child_parent", Columns: []string{"parent_id"}, RefSchema: tg.Schema, RefTable: parentTable, RefColumns: []string{"id"},
			OnDelete: engine.ReferentialCascade,
		}},
		Indexes: []engine.IndexSpec{{Name: "ix_qv_ddl_child_label", Keys: []engine.IndexKey{{Name: "label"}}}},
	}}); err != nil {
		t.Fatal(err)
	}

	created := describe(childTable)
	if id, ok := column(created, "id"); !ok || !id.Identity || !id.IsPrimaryKey {
		t.Errorf("id = %+v, want an identity primary key", id)
	}
	if len(created.ForeignKeys) != 1 || created.ForeignKeys[0].OnDelete != engine.ReferentialCascade || created.ForeignKeys[0].ReferencedTable != parentTable {
		t.Errorf("foreign keys = %+v", created.ForeignKeys)
	}

	if _, err := run(childTable, &created, sqldialect.AddColumn{Column: sqldialect.ColumnSpec{Name: "extra", TypeName: "varchar(20)", Nullable: true}}); err != nil {
		t.Fatal(err)
	}
	if _, err := run(childTable, nil, sqldialect.RenameColumn{From: "label", To: "title"}); err != nil {
		t.Fatal(err)
	}
	renamed := describe(childTable)
	if _, ok := column(renamed, "title"); !ok {
		t.Fatalf("columns after rename = %+v", renamed.Columns)
	}
	if _, ok := column(renamed, "extra"); !ok {
		t.Fatalf("columns after add = %+v", renamed.Columns)
	}

	alter := sqldialect.AlterColumn{
		Before: sqldialect.ColumnSpec{Name: "extra", TypeName: "varchar(20)", Nullable: true},
		After:  sqldialect.ColumnSpec{Name: "extra", TypeName: "varchar(80)", Nullable: true},
	}
	if _, err := run(childTable, &renamed, alter); err != nil {
		var unsupported *sqldialect.UnsupportedError
		if !errors.As(err, &unsupported) {
			t.Fatal(err)
		}
		t.Logf("alter column is unsupported here: %v", err)
	} else if extra, _ := column(describe(childTable), "extra"); extra.TypeName == "" || extra.TypeName == "varchar(20)" || extra.TypeName == "character varying(20)" {
		t.Errorf("extra is still %q after the alter", extra.TypeName)
	}

	if _, err := run(childTable, nil, sqldialect.DropColumn{Name: "extra"}); err != nil {
		t.Fatal(err)
	}
	if _, ok := column(describe(childTable), "extra"); ok {
		t.Error("extra is still there after DROP COLUMN")
	}

	current := describe(childTable)
	if _, err := run(childTable, &current, sqldialect.DropConstraint{Name: "fk_qv_ddl_child_parent"}); err != nil {
		var unsupported *sqldialect.UnsupportedError
		if !errors.As(err, &unsupported) {
			t.Fatal(err)
		}
		t.Logf("drop constraint is unsupported here: %v", err)
	} else if fks := describe(childTable).ForeignKeys; len(fks) != 0 {
		t.Errorf("foreign keys after drop = %+v", fks)
	}

	if _, err := run(childTable, nil, sqldialect.RenameTable{NewName: renamedTable}); err != nil {
		t.Fatal(err)
	}
	describe(renamedTable)
	if _, err := run(renamedTable, nil, sqldialect.DropTable{}); err != nil {
		t.Fatal(err)
	}
	if _, err := inspector.DescribeTable(ctx, tg.Database, tg.Schema, renamedTable); !isKind(err, engine.KindNotFound) {
		t.Errorf("describe after drop: %v, want not found", err)
	}
}
