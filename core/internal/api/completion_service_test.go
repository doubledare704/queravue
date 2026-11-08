package api_test

import (
	"context"
	"testing"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/doubledare704/queravue/core/internal/api"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/session"
)

func TestCompletionServiceReportsUnsupportedUntilImplemented(t *testing.T) {
	mgr := session.NewManager(fakeOpener{conn: &fakeValidatingConn{}})
	t.Cleanup(mgr.Shutdown)
	sess, err := mgr.Open(context.Background(), "test-conn")
	if err != nil {
		t.Fatal(err)
	}
	svc := api.NewCompletionService(mgr)
	want := queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_UNSUPPORTED

	complete, err := svc.Complete(context.Background(), &queravuev1.CompleteRequest{SessionId: sess.ID})
	if err != nil || complete.GetError().GetKind() != want {
		t.Errorf("Complete = %v, %v; want in-band UNSUPPORTED", complete, err)
	}
	format, err := svc.FormatSQL(context.Background(), &queravuev1.FormatSQLRequest{SessionId: sess.ID})
	if err != nil || format.GetError().GetKind() != want {
		t.Errorf("FormatSQL = %v, %v; want in-band UNSUPPORTED", format, err)
	}
	if _, err := svc.Complete(context.Background(), &queravuev1.CompleteRequest{SessionId: "missing"}); status.Code(err) != codes.NotFound {
		t.Errorf("unknown session code = %v, want NotFound", status.Code(err))
	}
}
