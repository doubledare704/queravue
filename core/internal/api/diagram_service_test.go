package api_test

import (
	"context"
	"fmt"
	"testing"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/doubledare704/queravue/core/internal/api"
	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/session"
)

type schemaGraphRecorder struct {
	grpc.ServerStream
	ctx  context.Context
	sent []*queravuev1.GetSchemaGraphResponse
}

func (r *schemaGraphRecorder) Context() context.Context {
	if r.ctx != nil {
		return r.ctx
	}
	return context.Background()
}

func (r *schemaGraphRecorder) Send(m *queravuev1.GetSchemaGraphResponse) error {
	r.sent = append(r.sent, m)
	return nil
}

type fakeGraphConn struct {
	fakeValidatingConn
	tables int
}

func (*fakeGraphConn) ListDatabases(context.Context) ([]string, error)       { return nil, nil }
func (*fakeGraphConn) ListSchemas(context.Context, string) ([]string, error) { return nil, nil }
func (*fakeGraphConn) DescribeTable(context.Context, string, string, string) (engine.TableDetails, error) {
	return engine.TableDetails{}, nil
}

func (f *fakeGraphConn) ListObjects(context.Context, string, string) ([]engine.SchemaObject, error) {
	out := make([]engine.SchemaObject, f.tables)
	for i := range out {
		out[i] = engine.SchemaObject{Name: fmt.Sprintf("t%03d", i), Type: engine.ObjectTypeView, EstimatedRows: int64(i)}
	}
	return out, nil
}

func (f *fakeGraphConn) ListKeyedColumns(context.Context, string, string) ([]engine.KeyedColumn, error) {
	out := make([]engine.KeyedColumn, 0, f.tables*2)
	for i := range f.tables {
		table := fmt.Sprintf("t%03d", i)
		out = append(out,
			engine.KeyedColumn{Table: table, Name: "id", TypeName: "int", PrimaryKeyOrder: 1},
			engine.KeyedColumn{Table: table, Name: "parent_id", TypeName: "int", Nullable: true})
	}
	return out, nil
}

func (f *fakeGraphConn) ListRelations(context.Context, string, string) ([]engine.TableRelation, error) {
	return []engine.TableRelation{{Table: "t001", ForeignKeyDef: engine.ForeignKeyDef{
		Name: "fk_parent", Columns: []string{"parent_id"}, ReferencedSchema: "public", ReferencedTable: "t000",
		ReferencedColumns: []string{"id"}, OnDelete: engine.ReferentialCascade,
	}}}, nil
}

func diagramEnv(t *testing.T, conn engine.Conn) (*api.DiagramService, *session.Session) {
	t.Helper()
	mgr := session.NewManager(fakeOpener{conn: conn})
	t.Cleanup(mgr.Shutdown)
	sess, err := mgr.Open(context.Background(), "test-conn")
	if err != nil {
		t.Fatal(err)
	}
	return api.NewDiagramService(mgr, nil, nil), sess
}

func TestGetSchemaGraphStreamsBatchesThenDone(t *testing.T) {
	svc, sess := diagramEnv(t, &fakeGraphConn{tables: 120})
	rec := &schemaGraphRecorder{}
	if err := svc.GetSchemaGraph(&queravuev1.GetSchemaGraphRequest{SessionId: sess.ID}, rec); err != nil {
		t.Fatal(err)
	}
	if len(rec.sent) != 4 {
		t.Fatalf("messages = %d, want 3 batches and a final one", len(rec.sent))
	}
	var tables []*queravuev1.GraphTable
	for i, m := range rec.sent[:3] {
		tables = append(tables, m.GetTables()...)
		if m.GetDone() || m.GetTablesTotal() != 120 || int(m.GetTablesDone()) != len(tables) {
			t.Errorf("batch %d: done=%v total=%d done_count=%d after %d tables", i, m.GetDone(), m.GetTablesTotal(), m.GetTablesDone(), len(tables))
		}
	}
	last := rec.sent[3]
	if !last.GetDone() || last.GetError() != nil || last.GetTablesDone() != 120 || len(last.GetTables()) != 0 {
		t.Errorf("final message = %v", last)
	}
	if len(tables) != 120 {
		t.Fatalf("tables = %d, want 120", len(tables))
	}
	second := tables[1]
	if second.GetName() != "t001" || second.GetType() != queravuev1.SchemaObjectType_SCHEMA_OBJECT_TYPE_VIEW || second.GetRowCountEstimate() != 1 {
		t.Errorf("table = %v", second)
	}
	if cols := second.GetColumns(); len(cols) != 2 || cols[0].GetPrimaryKeyOrder() != 1 || !cols[1].GetNullable() || cols[1].GetTypeName() != "int" {
		t.Errorf("columns = %v", second.GetColumns())
	}
	rels := second.GetRelations()
	if len(rels) != 1 || rels[0].GetReferencedTable() != "t000" || rels[0].GetInferred() ||
		rels[0].GetOnDelete() != queravuev1.ReferentialAction_REFERENTIAL_ACTION_CASCADE {
		t.Errorf("relations = %v", rels)
	}
}

func TestGetSchemaGraphOfEmptySchemaIsOneDoneMessage(t *testing.T) {
	svc, sess := diagramEnv(t, &fakeGraphConn{})
	rec := &schemaGraphRecorder{}
	if err := svc.GetSchemaGraph(&queravuev1.GetSchemaGraphRequest{SessionId: sess.ID}, rec); err != nil {
		t.Fatal(err)
	}
	if len(rec.sent) != 1 || !rec.sent[0].GetDone() || rec.sent[0].GetError() != nil {
		t.Errorf("sent = %v", rec.sent)
	}
}

func TestGetSchemaGraphReportsFailuresInBand(t *testing.T) {
	unsupported, sess := diagramEnv(t, &fakeValidatingConn{})
	rec := &schemaGraphRecorder{}
	if err := unsupported.GetSchemaGraph(&queravuev1.GetSchemaGraphRequest{SessionId: sess.ID}, rec); err != nil {
		t.Fatal(err)
	}
	if len(rec.sent) != 1 || !rec.sent[0].GetDone() ||
		rec.sent[0].GetError().GetKind() != queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_UNSUPPORTED {
		t.Errorf("without RelationLister: %v", rec.sent)
	}

	svc, busy := diagramEnv(t, &fakeGraphConn{tables: 3})
	_, finish, err := busy.Begin(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	defer finish()
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	cancelled := &schemaGraphRecorder{ctx: ctx}
	if err := svc.GetSchemaGraph(&queravuev1.GetSchemaGraphRequest{SessionId: busy.ID}, cancelled); err != nil {
		t.Fatal(err)
	}
	if len(cancelled.sent) != 1 || cancelled.sent[0].GetError().GetKind() != queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_CANCELED {
		t.Errorf("cancelled while the session was busy: %v", cancelled.sent)
	}

	if err := svc.GetSchemaGraph(&queravuev1.GetSchemaGraphRequest{SessionId: "missing"}, rec); status.Code(err) != codes.NotFound {
		t.Errorf("unknown session code = %v, want NotFound", status.Code(err))
	}
}

func TestDiagramDDLWithoutADesignServiceIsUnsupported(t *testing.T) {
	svc, sess := diagramEnv(t, &fakeValidatingConn{})
	want := queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_UNSUPPORTED
	preview, err := svc.PreviewDiagramDDL(context.Background(), &queravuev1.PreviewDiagramDDLRequest{SessionId: sess.ID})
	if err != nil || preview.GetError().GetKind() != want {
		t.Errorf("PreviewDiagramDDL = %v, %v; want in-band UNSUPPORTED", preview, err)
	}
	if _, err := svc.ApplyDiagramDDL(context.Background(), &queravuev1.ApplyDiagramDDLRequest{SessionId: "missing"}); status.Code(err) != codes.NotFound {
		t.Errorf("unknown session code = %v, want NotFound", status.Code(err))
	}
}
