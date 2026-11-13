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
	cases := []struct {
		name   string
		tables []*queravuev1.TableChanges
		want   queravuev1.AdminErrorKind
	}{
		{"nothing", nil, queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_INVALID},
		{"twice", []*queravuev1.TableChanges{draftTable("a"), draftTable("a")}, queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_INVALID},
		{"empty step", []*queravuev1.TableChanges{{TableRef: &queravuev1.TableRef{Table: "a"}, Changes: []*queravuev1.SchemaChange{{}}}}, queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_INVALID},
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

func referenceFromOrders(column string, addColumn bool) *queravuev1.TableChanges {
	var changes []*queravuev1.SchemaChange
	if addColumn {
		changes = append(changes, &queravuev1.SchemaChange{Change: &queravuev1.SchemaChange_AddColumn{AddColumn: &queravuev1.AddColumn{
			Column: &queravuev1.ColumnSpec{Name: column, TypeName: "INTEGER", Nullable: true},
		}}})
	}
	changes = append(changes, &queravuev1.SchemaChange{Change: &queravuev1.SchemaChange_AddForeignKey{AddForeignKey: &queravuev1.AddForeignKey{
		ForeignKey: &queravuev1.ForeignKeySpec{
			Name: "fk_orders_invoices", Columns: []string{column},
			ReferencedTable: &queravuev1.TableRef{Table: "invoices"}, ReferencedColumns: []string{"id"},
		},
	}}})
	return &queravuev1.TableChanges{TableRef: orders(), Changes: changes}
}

func ordersForeignKeys(t *testing.T, e indexEnv) []string {
	t.Helper()
	details, err := e.schema.GetTableDetails(context.Background(), &queravuev1.GetTableDetailsRequest{SessionId: e.sess.ID, TableRef: orders(), Refresh: true})
	if err != nil {
		t.Fatal(err)
	}
	var out []string
	for _, fk := range details.GetForeignKeys() {
		out = append(out, strings.Join(fk.GetColumns(), ",")+"->"+fk.GetReferencedTable())
	}
	return out
}

func TestDiagramAddsAReferencingColumnToAnExistingSQLiteTable(t *testing.T) {
	e := setupIndexEnv(t, false)
	resp, err := e.diagram.ApplyDiagramDDL(context.Background(), &queravuev1.ApplyDiagramDDLRequest{
		SessionId: e.sess.ID,
		Tables:    []*queravuev1.TableChanges{referenceFromOrders("invoices_id", true), draftTable("invoices")},
	})
	if err != nil || resp.GetError() != nil || resp.GetExecutedStatements() != 2 {
		t.Fatalf("ApplyDiagramDDL: %v %+v", err, resp)
	}
	if got := resp.GetStatements()[1].GetSql(); !strings.Contains(got, `ADD COLUMN "invoices_id" INTEGER CONSTRAINT "fk_orders_invoices" REFERENCES "invoices"`) {
		t.Errorf("second statement = %s", got)
	}
	if got := ordersForeignKeys(t, e); strings.Join(got, " ") != "invoices_id->invoices" {
		t.Errorf("orders foreign keys = %v", got)
	}
	if err := execSQL(t, e, "PRAGMA foreign_keys = ON"); err != nil {
		t.Fatal(err)
	}
	if err := execSQL(t, e, "INSERT INTO orders (id, invoices_id) VALUES (99, 42)"); err == nil {
		t.Error("an order pointing at a missing invoice was accepted")
	}
}

func TestDiagramRebuildsAnExistingSQLiteColumnIntoAForeignKey(t *testing.T) {
	e := setupIndexEnv(t, false)
	if err := execSQL(t, e, "INSERT INTO orders (id, customer, note) VALUES (1, 7, 'kept'), (2, 8, 'also kept')"); err != nil {
		t.Fatal(err)
	}
	tables := []*queravuev1.TableChanges{draftTable("invoices"), referenceFromOrders("customer", false)}
	preview, err := e.diagram.PreviewDiagramDDL(context.Background(), &queravuev1.PreviewDiagramDDLRequest{SessionId: e.sess.ID, Tables: tables})
	if err != nil || preview.GetError() != nil {
		t.Fatalf("PreviewDiagramDDL: %v %v", err, preview.GetError())
	}
	if warnings := strings.Join(preview.GetWarnings(), " "); !strings.Contains(warnings, "not checked against the new foreign key") {
		t.Errorf("warnings = %q", warnings)
	}
	resp, err := e.diagram.ApplyDiagramDDL(context.Background(), &queravuev1.ApplyDiagramDDLRequest{SessionId: e.sess.ID, Tables: tables})
	if err != nil || resp.GetError() != nil || int(resp.GetExecutedStatements()) != len(preview.GetStatements()) {
		t.Fatalf("ApplyDiagramDDL: %v %+v", err, resp)
	}
	if got := ordersForeignKeys(t, e); strings.Join(got, " ") != "customer->invoices" {
		t.Errorf("orders foreign keys = %v", got)
	}
	if got := columnNames(t, e, "orders"); strings.Join(got, ",") != "id,customer,note" {
		t.Errorf("orders columns = %v", got)
	}
	ex, _ := engine.As[engine.Executor](e.sess.Conn)
	var rows countSink
	if _, err := ex.Execute(context.Background(), engine.Statement{SQL: "SELECT note FROM orders ORDER BY id"}, &rows); err != nil || rows.n != 2 {
		t.Errorf("rows after the rebuild = %d, %v", rows.n, err)
	}
	if err := execSQL(t, e, "DROP INDEX orders_customer"); err != nil {
		t.Errorf("the index was not recreated: %v", err)
	}
}

func TestDiagramRefusesASQLiteRebuildWhileForeignKeysAreEnforced(t *testing.T) {
	e := setupIndexEnv(t, false)
	if err := execSQL(t, e, "PRAGMA foreign_keys = ON"); err != nil {
		t.Fatal(err)
	}
	resp, err := e.diagram.PreviewDiagramDDL(context.Background(), &queravuev1.PreviewDiagramDDLRequest{
		SessionId: e.sess.ID,
		Tables:    []*queravuev1.TableChanges{draftTable("invoices"), referenceFromOrders("customer", false)},
	})
	if err != nil || resp.GetError().GetKind() != queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_UNSUPPORTED ||
		!strings.Contains(resp.GetError().GetMessage(), "foreign keys are enforced") {
		t.Errorf("got %v %v, want UNSUPPORTED naming enforced foreign keys", resp.GetError(), err)
	}
}

type countSink struct{ n int }

func (*countSink) Columns([]engine.Column) error { return nil }
func (s *countSink) Batch(rows [][]engine.Value) error {
	s.n += len(rows)
	return nil
}
