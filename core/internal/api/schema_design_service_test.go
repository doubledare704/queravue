package api_test

import (
	"context"
	"strings"
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

func designEnv(t *testing.T, production bool) (indexEnv, *queravuev1.TableRef) {
	t.Helper()
	return setupIndexEnv(t, production), orders()
}

func addColumn(name, typeName string) *queravuev1.SchemaChange {
	return &queravuev1.SchemaChange{Change: &queravuev1.SchemaChange_AddColumn{AddColumn: &queravuev1.AddColumn{
		Column: &queravuev1.ColumnSpec{Name: name, TypeName: typeName, Nullable: true},
	}}}
}

func dropColumn(name string) *queravuev1.SchemaChange {
	return &queravuev1.SchemaChange{Change: &queravuev1.SchemaChange_DropColumn{DropColumn: &queravuev1.DropColumn{Name: name}}}
}

func columnNames(t *testing.T, e indexEnv, table string) []string {
	t.Helper()
	details, err := e.schema.GetTableDetails(context.Background(), &queravuev1.GetTableDetailsRequest{SessionId: e.sess.ID, TableRef: &queravuev1.TableRef{Table: table}})
	if err != nil {
		t.Fatal(err)
	}
	var names []string
	for _, c := range details.GetColumns() {
		names = append(names, c.GetName())
	}
	return names
}

func TestSchemaDesignPreviewRunsNothing(t *testing.T) {
	e, ref := designEnv(t, false)
	resp, err := e.design.PreviewDDL(context.Background(), &queravuev1.PreviewDDLRequest{SessionId: e.sess.ID, TableRef: ref, Changes: []*queravuev1.SchemaChange{addColumn("email", "TEXT")}})
	if err != nil || resp.GetError() != nil {
		t.Fatalf("PreviewDDL: %v %v", err, resp.GetError())
	}
	if len(resp.GetStatements()) != 1 || resp.GetStatements()[0].GetSql() != `ALTER TABLE "orders" ADD COLUMN "email" TEXT;` || !resp.GetTransactional() {
		t.Errorf("response = %+v", resp)
	}
	if got := columnNames(t, e, "orders"); len(got) != 3 {
		t.Errorf("preview changed the table: %v", got)
	}
}

func TestSchemaDesignApplyAddsColumnAndRecordsHistory(t *testing.T) {
	e, ref := designEnv(t, false)
	resp, err := e.design.ApplyDDL(context.Background(), &queravuev1.ApplyDDLRequest{SessionId: e.sess.ID, TableRef: ref, Changes: []*queravuev1.SchemaChange{addColumn("email", "TEXT")}})
	if err != nil || resp.GetError() != nil {
		t.Fatalf("ApplyDDL: %v %v", err, resp.GetError())
	}
	if resp.GetExecutedStatements() != 1 {
		t.Errorf("executed = %d", resp.GetExecutedStatements())
	}
	if got := columnNames(t, e, "orders"); len(got) != 4 || got[3] != "email" {
		t.Errorf("columns = %v", got)
	}
	entries, _, err := e.history.List(context.Background(), "", "", 10, 0)
	if err != nil || len(entries) == 0 || !strings.HasPrefix(entries[0].QueryText, "ALTER TABLE") {
		t.Errorf("history = %+v %v", entries, err)
	}
}

func TestSchemaDesignDestructiveChangeNeedsConfirmation(t *testing.T) {
	e, ref := designEnv(t, false)
	req := &queravuev1.ApplyDDLRequest{SessionId: e.sess.ID, TableRef: ref, Changes: []*queravuev1.SchemaChange{dropColumn("note")}}
	refused, _ := e.design.ApplyDDL(context.Background(), req)
	if refused.GetError().GetKind() != queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_CONFIRMATION_REQUIRED || refused.GetExecutedStatements() != 0 {
		t.Fatalf("unconfirmed drop: %+v", refused)
	}
	if got := columnNames(t, e, "orders"); len(got) != 3 {
		t.Fatalf("a refused drop changed the table: %v", got)
	}
	req.Confirmed = true
	if resp, _ := e.design.ApplyDDL(context.Background(), req); resp.GetError() != nil {
		t.Fatalf("confirmed drop: %+v", resp.GetError())
	}
	if got := columnNames(t, e, "orders"); len(got) != 2 {
		t.Errorf("columns after drop = %v", got)
	}
}

func TestSchemaDesignProductionNeedsConfirmationEvenForSafeChanges(t *testing.T) {
	e, ref := designEnv(t, true)
	req := &queravuev1.ApplyDDLRequest{SessionId: e.sess.ID, TableRef: ref, Changes: []*queravuev1.SchemaChange{addColumn("email", "TEXT")}}
	resp, _ := e.design.ApplyDDL(context.Background(), req)
	if resp.GetError().GetKind() != queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_CONFIRMATION_REQUIRED {
		t.Fatalf("error = %+v", resp.GetError())
	}
	req.Confirmed = true
	if resp, _ := e.design.ApplyDDL(context.Background(), req); resp.GetError() != nil {
		t.Fatalf("confirmed apply: %+v", resp.GetError())
	}
}

func TestSchemaDesignFailedStatementRollsBackTheWholeScript(t *testing.T) {
	e, ref := designEnv(t, false)
	resp, _ := e.design.ApplyDDL(context.Background(), &queravuev1.ApplyDDLRequest{
		SessionId: e.sess.ID, TableRef: ref, Confirmed: true,
		Changes: []*queravuev1.SchemaChange{addColumn("email", "TEXT"), dropColumn("no_such_column")},
	})
	if resp.GetError() == nil || resp.GetExecutedStatements() != 0 {
		t.Fatalf("response = %+v", resp)
	}
	if got := columnNames(t, e, "orders"); len(got) != 3 {
		t.Errorf("the first statement survived the failure: %v", got)
	}
}

func TestSchemaDesignCreatesTable(t *testing.T) {
	e, _ := designEnv(t, false)
	ref := &queravuev1.TableRef{Table: "customers"}
	create := &queravuev1.SchemaChange{Change: &queravuev1.SchemaChange_CreateTable{CreateTable: &queravuev1.CreateTable{Design: &queravuev1.TableDesign{
		Columns: []*queravuev1.ColumnSpec{
			{Name: "id", TypeName: "INTEGER", Identity: true},
			{Name: "name", TypeName: "TEXT"},
		},
		PrimaryKeyColumns: []string{"id"},
		Indexes:           []*queravuev1.IndexSpec{{Name: "customers_name", Keys: []*queravuev1.IndexKey{{Name: "name"}}}},
	}}}}
	resp, err := e.design.ApplyDDL(context.Background(), &queravuev1.ApplyDDLRequest{SessionId: e.sess.ID, TableRef: ref, Changes: []*queravuev1.SchemaChange{create}})
	if err != nil || resp.GetError() != nil || resp.GetExecutedStatements() != 2 {
		t.Fatalf("ApplyDDL: %v %+v", err, resp)
	}
	if got := columnNames(t, e, "customers"); len(got) != 2 {
		t.Errorf("columns = %v", got)
	}
}

func alterNote(from, to string) *queravuev1.SchemaChange {
	return &queravuev1.SchemaChange{Change: &queravuev1.SchemaChange_AlterColumn{AlterColumn: &queravuev1.AlterColumn{
		Before: &queravuev1.ColumnSpec{Name: "note", TypeName: from, Nullable: true},
		After:  &queravuev1.ColumnSpec{Name: "note", TypeName: to, Nullable: true},
	}}}
}

func TestSchemaDesignReportsUnsupportedAndInvalidChanges(t *testing.T) {
	e, ref := designEnv(t, false)
	mixed, _ := e.design.PreviewDDL(context.Background(), &queravuev1.PreviewDDLRequest{
		SessionId: e.sess.ID, TableRef: ref, Changes: []*queravuev1.SchemaChange{alterNote("TEXT", "VARCHAR(10)"), {Change: &queravuev1.SchemaChange_DropColumn{DropColumn: &queravuev1.DropColumn{Name: "customer"}}}},
	})
	if mixed.GetError().GetKind() != queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_UNSUPPORTED || len(mixed.GetStatements()) != 0 {
		t.Errorf("alter combined with another change: %+v", mixed)
	}
	empty, _ := e.design.PreviewDDL(context.Background(), &queravuev1.PreviewDDLRequest{SessionId: e.sess.ID, TableRef: ref})
	if empty.GetError().GetKind() != queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_INVALID {
		t.Errorf("no changes: %+v", empty.GetError())
	}
	unset, _ := e.design.PreviewDDL(context.Background(), &queravuev1.PreviewDDLRequest{SessionId: e.sess.ID, TableRef: ref, Changes: []*queravuev1.SchemaChange{{}}})
	if unset.GetError().GetKind() != queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_INVALID {
		t.Errorf("empty change: %+v", unset.GetError())
	}
}

func runSQL(t *testing.T, e indexEnv, sql string) error {
	t.Helper()
	ex, _ := engine.As[engine.Executor](e.sess.Conn)
	_, err := ex.Execute(context.Background(), engine.Statement{SQL: sql}, nilSink{})
	return err
}

func TestSchemaDesignAltersASQLiteColumnByRebuildingTheTable(t *testing.T) {
	e, _ := designEnv(t, false)
	for _, stmt := range []string{
		`CREATE TABLE stock (id INTEGER PRIMARY KEY, sku TEXT NOT NULL UNIQUE, qty INTEGER CHECK (qty >= 0), note TEXT)`,
		`CREATE INDEX stock_note ON stock (note)`,
		`INSERT INTO stock (sku, qty, note) VALUES ('a', 1, 'x'), ('b', 2, NULL)`,
	} {
		if err := runSQL(t, e, stmt); err != nil {
			t.Fatal(err)
		}
	}
	ref := &queravuev1.TableRef{Table: "stock"}
	resp, err := e.design.ApplyDDL(context.Background(), &queravuev1.ApplyDDLRequest{
		SessionId: e.sess.ID, TableRef: ref, Confirmed: true,
		Changes: []*queravuev1.SchemaChange{alterNote("TEXT", "VARCHAR(40)")},
	})
	if err != nil || resp.GetError() != nil || !resp.GetTransactional() {
		t.Fatalf("ApplyDDL: %v %+v", err, resp)
	}
	if got := columnNames(t, e, "stock"); len(got) != 4 || got[3] != "note" {
		t.Errorf("columns = %v", got)
	}
	if err := runSQL(t, e, `INSERT INTO stock (sku, qty) VALUES ('c', -1)`); err == nil {
		t.Error("the CHECK constraint did not survive the rebuild")
	}
	if err := runSQL(t, e, `INSERT INTO stock (sku, qty) VALUES ('a', 5)`); err == nil {
		t.Error("the UNIQUE constraint did not survive the rebuild")
	}
	if err := runSQL(t, e, `INSERT INTO stock (sku, qty) VALUES (NULL, 5)`); err == nil {
		t.Error("NOT NULL did not survive the rebuild")
	}
	details, err := e.schema.GetTableDetails(context.Background(), &queravuev1.GetTableDetailsRequest{SessionId: e.sess.ID, TableRef: ref, Refresh: true})
	if err != nil {
		t.Fatal(err)
	}
	if got := details.GetColumns()[3].GetTypeName(); got != "VARCHAR(40)" {
		t.Errorf("note type = %q", got)
	}
	var indexed bool
	for _, ix := range details.GetIndexes() {
		indexed = indexed || ix.GetName() == "stock_note"
	}
	if !indexed {
		t.Error("the index was not recreated")
	}
}

func TestSchemaDesignRebuildFailureRollsBack(t *testing.T) {
	e, _ := designEnv(t, false)
	for _, stmt := range []string{
		`CREATE TABLE stock (id INTEGER PRIMARY KEY, note TEXT)`,
		`INSERT INTO stock (note) VALUES (NULL)`,
	} {
		if err := runSQL(t, e, stmt); err != nil {
			t.Fatal(err)
		}
	}
	notNull := &queravuev1.SchemaChange{Change: &queravuev1.SchemaChange_AlterColumn{AlterColumn: &queravuev1.AlterColumn{
		Before: &queravuev1.ColumnSpec{Name: "note", TypeName: "TEXT", Nullable: true},
		After:  &queravuev1.ColumnSpec{Name: "note", TypeName: "TEXT", Nullable: false},
	}}}
	resp, _ := e.design.ApplyDDL(context.Background(), &queravuev1.ApplyDDLRequest{
		SessionId: e.sess.ID, TableRef: &queravuev1.TableRef{Table: "stock"}, Confirmed: true, Changes: []*queravuev1.SchemaChange{notNull},
	})
	if resp.GetError() == nil {
		t.Fatal("NOT NULL over an existing NULL was accepted")
	}
	if got := columnNames(t, e, "stock"); len(got) != 2 {
		t.Errorf("columns after the rollback = %v", got)
	}
	if err := runSQL(t, e, `SELECT * FROM qv_rebuild_stock`); err == nil {
		t.Error("the temporary table was left behind")
	}
	if err := runSQL(t, e, `INSERT INTO stock (note) VALUES (NULL)`); err != nil {
		t.Errorf("the original table is not intact: %v", err)
	}
}
