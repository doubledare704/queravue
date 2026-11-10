package api_test

import (
	"context"
	"testing"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/doubledare704/queravue/core/internal/api"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/session"
)

type schemaGraphRecorder struct {
	grpc.ServerStream
	sent []*queravuev1.GetSchemaGraphResponse
}

func (r *schemaGraphRecorder) Context() context.Context { return context.Background() }

func (r *schemaGraphRecorder) Send(m *queravuev1.GetSchemaGraphResponse) error {
	r.sent = append(r.sent, m)
	return nil
}

func TestDiagramServiceReportsUnsupportedUntilImplemented(t *testing.T) {
	mgr := session.NewManager(fakeOpener{conn: &fakeValidatingConn{}})
	t.Cleanup(mgr.Shutdown)
	sess, err := mgr.Open(context.Background(), "test-conn")
	if err != nil {
		t.Fatal(err)
	}
	svc := api.NewDiagramService(mgr)
	want := queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_UNSUPPORTED

	graph := &schemaGraphRecorder{}
	if err := svc.GetSchemaGraph(&queravuev1.GetSchemaGraphRequest{SessionId: sess.ID}, graph); err != nil {
		t.Fatal(err)
	}
	if len(graph.sent) != 1 || !graph.sent[0].GetDone() || graph.sent[0].GetError().GetKind() != want {
		t.Errorf("GetSchemaGraph sent %v; want one done message with in-band UNSUPPORTED", graph.sent)
	}
	preview, err := svc.PreviewDiagramDDL(context.Background(), &queravuev1.PreviewDiagramDDLRequest{SessionId: sess.ID})
	if err != nil || preview.GetError().GetKind() != want {
		t.Errorf("PreviewDiagramDDL = %v, %v; want in-band UNSUPPORTED", preview, err)
	}
	apply, err := svc.ApplyDiagramDDL(context.Background(), &queravuev1.ApplyDiagramDDLRequest{SessionId: sess.ID})
	if err != nil || apply.GetError().GetKind() != want {
		t.Errorf("ApplyDiagramDDL = %v, %v; want in-band UNSUPPORTED", apply, err)
	}

	if err := svc.GetSchemaGraph(&queravuev1.GetSchemaGraphRequest{SessionId: "missing"}, graph); status.Code(err) != codes.NotFound {
		t.Errorf("unknown session code = %v, want NotFound", status.Code(err))
	}
	if _, err := svc.ApplyDiagramDDL(context.Background(), &queravuev1.ApplyDiagramDDLRequest{SessionId: "missing"}); status.Code(err) != codes.NotFound {
		t.Errorf("unknown session code = %v, want NotFound", status.Code(err))
	}
}
