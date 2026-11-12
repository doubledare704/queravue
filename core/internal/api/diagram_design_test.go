package api_test

import (
	"context"
	"strings"
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

func draftTable(name string, refs ...string) *queravuev1.TableChanges {
	design := &queravuev1.TableDesign{
		Columns:           []*queravuev1.ColumnSpec{{Name: "id", TypeName: "INTEGER"}},
		PrimaryKeyColumns: []string{"id"},
	}
	for _, ref := range refs {
		col := ref + "_id"
		design.Columns = append(design.Columns, &queravuev1.ColumnSpec{Name: col, TypeName: "INTEGER", Nullable: true})
		design.ForeignKeys = append(design.ForeignKeys, &queravuev1.ForeignKeySpec{
			Name: "fk_" + name + "_" + ref, Columns: []string{col},
			ReferencedTable: &queravuev1.TableRef{Table: ref}, ReferencedColumns: []string{"id"},
		})
	}
	return &queravuev1.TableChanges{
		TableRef: &queravuev1.TableRef{Table: name},
		Changes:  []*queravuev1.SchemaChange{{Change: &queravuev1.SchemaChange_CreateTable{CreateTable: &queravuev1.CreateTable{Design: design}}}},
	}
}

func execSQL(t *testing.T, e indexEnv, sql string) error {
	t.Helper()
	ex, _ := engine.As[engine.Executor](e.sess.Conn)
	_, err := ex.Execute(context.Background(), engine.Statement{SQL: sql}, nilSink{})
	return err
}

func TestDiagramPreviewOrdersTablesAndRunsNothing(t *testing.T) {
	e := setupIndexEnv(t, false)
	resp, err := e.diagram.PreviewDiagramDDL(context.Background(), &queravuev1.PreviewDiagramDDLRequest{
		SessionId: e.sess.ID,
		Tables:    []*queravuev1.TableChanges{draftTable("lines", "invoices", "orders"), draftTable("invoices")},
	})
	if err != nil || resp.GetError() != nil {
		t.Fatalf("PreviewDiagramDDL: %v %v", err, resp.GetError())
	}
	var summaries []string
	for _, st := range resp.GetStatements() {
		summaries = append(summaries, st.GetSummary())
	}
	if got := strings.Join(summaries, " | "); got != "Create table invoices | Create table lines" || !resp.GetTransactional() {
		t.Errorf("statements = %s, transactional = %v", got, resp.GetTransactional())
	}
	if got := columnNames(t, e, "invoices"); len(got) != 0 {
		t.Errorf("preview created a table: %v", got)
	}
}

func TestDiagramApplyCreatesRelatedTablesWithWorkingForeignKeys(t *testing.T) {
	e := setupIndexEnv(t, false)
	resp, err := e.diagram.ApplyDiagramDDL(context.Background(), &queravuev1.ApplyDiagramDDLRequest{
		SessionId: e.sess.ID,
		Tables:    []*queravuev1.TableChanges{draftTable("lines", "invoices", "orders"), draftTable("invoices")},
	})
	if err != nil || resp.GetError() != nil || resp.GetExecutedStatements() != 2 {
		t.Fatalf("ApplyDiagramDDL: %v %+v", err, resp)
	}
	if got := columnNames(t, e, "lines"); strings.Join(got, ",") != "id,invoices_id,orders_id" {
		t.Errorf("lines columns = %v", got)
	}
	if err := execSQL(t, e, "PRAGMA foreign_keys = ON"); err != nil {
		t.Fatal(err)
	}
	if err := execSQL(t, e, "INSERT INTO lines (id, invoices_id) VALUES (1, 42)"); err == nil {
		t.Error("a line pointing at a missing invoice was accepted")
	}
	entries, _, err := e.history.List(context.Background(), "", "", 10, 0)
	if err != nil || len(entries) < 2 {
		t.Errorf("history = %+v %v", entries, err)
	}
}

func TestDiagramApplyRollsBackEveryTableWhenOneFails(t *testing.T) {
	e := setupIndexEnv(t, false)
	resp, _ := e.diagram.ApplyDiagramDDL(context.Background(), &queravuev1.ApplyDiagramDDLRequest{
		SessionId: e.sess.ID,
		Tables:    []*queravuev1.TableChanges{draftTable("invoices"), draftTable("orders")},
	})
	if resp.GetError() == nil || resp.GetExecutedStatements() != 0 {
		t.Fatalf("creating an existing table: %+v", resp)
	}
	if got := columnNames(t, e, "invoices"); len(got) != 0 {
		t.Errorf("invoices survived the rollback: %v", got)
	}
}

func TestDiagramApplyOnProductionNeedsConfirmation(t *testing.T) {
	e := setupIndexEnv(t, true)
	req := &queravuev1.ApplyDiagramDDLRequest{SessionId: e.sess.ID, Tables: []*queravuev1.TableChanges{draftTable("invoices")}}
	refused, _ := e.diagram.ApplyDiagramDDL(context.Background(), req)
	if refused.GetError().GetKind() != queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_CONFIRMATION_REQUIRED || len(refused.GetStatements()) != 1 {
		t.Fatalf("unconfirmed: %+v", refused)
	}
	req.Confirmed = true
	if done, _ := e.diagram.ApplyDiagramDDL(context.Background(), req); done.GetError() != nil || done.GetExecutedStatements() != 1 {
		t.Errorf("confirmed: %+v", done)
	}
}

func TestDiagramDDLReportsInvalidAndUnsupportedChangesInBand(t *testing.T) {
	e := setupIndexEnv(t, false)
	addForeignKey := &queravuev1.TableChanges{
		TableRef: orders(),
		Changes: []*queravuev1.SchemaChange{{Change: &queravuev1.SchemaChange_AddForeignKey{AddForeignKey: &queravuev1.AddForeignKey{
			ForeignKey: &queravuev1.ForeignKeySpec{Columns: []string{"customer"}, ReferencedTable: &queravuev1.TableRef{Table: "invoices"}, ReferencedColumns: []string{"id"}},
		}}}},
	}
	cases := []struct {
		name   string
		tables []*queravuev1.TableChanges
		want   queravuev1.AdminErrorKind
	}{
		{"nothing", nil, queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_INVALID},
		{"twice", []*queravuev1.TableChanges{draftTable("a"), draftTable("a")}, queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_INVALID},
		{"empty step", []*queravuev1.TableChanges{{TableRef: &queravuev1.TableRef{Table: "a"}, Changes: []*queravuev1.SchemaChange{{}}}}, queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_INVALID},
		{"sqlite foreign key on an existing table", []*queravuev1.TableChanges{draftTable("invoices"), addForeignKey}, queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_UNSUPPORTED},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			resp, err := e.diagram.PreviewDiagramDDL(context.Background(), &queravuev1.PreviewDiagramDDLRequest{SessionId: e.sess.ID, Tables: tc.tables})
			if err != nil || resp.GetError().GetKind() != tc.want {
				t.Errorf("got %v %v, want %v", resp.GetError(), err, tc.want)
			}
		})
	}
}
