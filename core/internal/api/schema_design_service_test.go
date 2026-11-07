package api_test

import (
	"context"
	"strings"
	"testing"

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

func TestSchemaDesignReportsUnsupportedAndInvalidChanges(t *testing.T) {
	e, ref := designEnv(t, false)
	alter := &queravuev1.SchemaChange{Change: &queravuev1.SchemaChange_AlterColumn{AlterColumn: &queravuev1.AlterColumn{
		Before: &queravuev1.ColumnSpec{Name: "note", TypeName: "TEXT", Nullable: true},
		After:  &queravuev1.ColumnSpec{Name: "note", TypeName: "VARCHAR(10)", Nullable: true},
	}}}
	resp, _ := e.design.PreviewDDL(context.Background(), &queravuev1.PreviewDDLRequest{SessionId: e.sess.ID, TableRef: ref, Changes: []*queravuev1.SchemaChange{alter}})
	if resp.GetError().GetKind() != queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_UNSUPPORTED || len(resp.GetStatements()) != 0 {
		t.Errorf("alter on SQLite: %+v", resp)
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
