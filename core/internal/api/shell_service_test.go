package api_test

import (
	"context"
	"testing"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/doubledare704/queravue/core/internal/api"
	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/session"
)

type fakeShellConn struct{ docs []string }

func (*fakeShellConn) Ping(context.Context) error { return nil }
func (*fakeShellConn) ServerInfo(context.Context) (engine.ServerInfo, error) {
	return engine.ServerInfo{}, nil
}
func (*fakeShellConn) Close() error { return nil }
func (*fakeShellConn) RunCommand(context.Context, string, engine.Document) (engine.Document, error) {
	return `{"ok":{"$numberInt":"1"}}`, nil
}

func (c *fakeShellConn) OpenCursor(context.Context, engine.CursorSpec) (engine.DocCursor, error) {
	return &fakeDocCursor{docs: c.docs}, nil
}

type fakeDocCursor struct {
	docs []string
	i    int
}

func (c *fakeDocCursor) Next(context.Context) (engine.Document, bool, error) {
	if c.i >= len(c.docs) {
		return "", false, nil
	}
	c.i++
	return c.docs[c.i-1], true, nil
}
func (*fakeDocCursor) Close() error { return nil }

type shellOpener struct{ conn engine.Conn }

func (o shellOpener) Open(context.Context, string) (engine.Conn, engine.Descriptor, error) {
	return o.conn, engine.Descriptor{ID: "fake", Capabilities: []engine.Capability{engine.CapConnect, engine.CapShell}}, nil
}

type evalStream struct {
	grpc.ServerStream
	ctx  context.Context
	msgs []*queravuev1.EvalResponse
}

func (s *evalStream) Context() context.Context { return s.ctx }
func (s *evalStream) Send(m *queravuev1.EvalResponse) error {
	s.msgs = append(s.msgs, m)
	return nil
}

type fetchStream struct {
	grpc.ServerStream
	ctx  context.Context
	msgs []*queravuev1.FetchCursorResponse
}

func (s *fetchStream) Context() context.Context { return s.ctx }
func (s *fetchStream) Send(m *queravuev1.FetchCursorResponse) error {
	s.msgs = append(s.msgs, m)
	return nil
}

func newShellService(t *testing.T, conn engine.Conn) (*api.ShellService, *session.Manager, string) {
	t.Helper()
	mgr := session.NewManager(shellOpener{conn: conn})
	t.Cleanup(mgr.Shutdown)
	sess, err := mgr.Open(context.Background(), "c")
	if err != nil {
		t.Fatal(err)
	}
	svc := api.NewShellService(mgr, nil, nil)
	t.Cleanup(svc.Shutdown)
	return svc, mgr, sess.ID
}

func openShell(t *testing.T, svc *api.ShellService, sessionID string) string {
	t.Helper()
	resp, err := svc.OpenShell(context.Background(), &queravuev1.OpenShellRequest{SessionId: sessionID, Database: "d"})
	if err != nil {
		t.Fatal(err)
	}
	return resp.GetShellId()
}

func TestShellServiceEvalStreamsEventsInOrder(t *testing.T) {
	svc, _, sid := newShellService(t, &fakeShellConn{})
	shellID := openShell(t, svc, sid)
	st := &evalStream{ctx: context.Background()}
	if err := svc.Eval(&queravuev1.EvalRequest{ShellId: shellID, Code: `print("hi"); 1 + 1`}, st); err != nil {
		t.Fatal(err)
	}
	if len(st.msgs) != 3 {
		t.Fatalf("got %d events, want 3", len(st.msgs))
	}
	if st.msgs[0].GetPrint().GetText() != "hi" {
		t.Errorf("print = %v", st.msgs[0])
	}
	if st.msgs[1].GetResult().GetScalar() != `{"$numberInt":"2"}` {
		t.Errorf("result = %v", st.msgs[1])
	}
	if st.msgs[2].GetDone() == nil {
		t.Errorf("last event = %v", st.msgs[2])
	}
}

func TestShellServiceEvalErrorCarriesPosition(t *testing.T) {
	svc, _, sid := newShellService(t, &fakeShellConn{})
	shellID := openShell(t, svc, sid)
	st := &evalStream{ctx: context.Background()}
	if err := svc.Eval(&queravuev1.EvalRequest{ShellId: shellID, Code: "var a = 1;\nnull.x"}, st); err != nil {
		t.Fatal(err)
	}
	e := st.msgs[len(st.msgs)-1].GetError()
	if e == nil || e.GetKind() != queravuev1.ShellErrorKind_SHELL_ERROR_KIND_RUNTIME || e.GetLine() != 2 {
		t.Fatalf("error event = %v", e)
	}
}

func TestShellServiceCursorHandleAndFetch(t *testing.T) {
	svc, _, sid := newShellService(t, &fakeShellConn{docs: []string{`{"a":1}`, `{"a":2}`}})
	shellID := openShell(t, svc, sid)
	st := &evalStream{ctx: context.Background()}
	if err := svc.Eval(&queravuev1.EvalRequest{ShellId: shellID, Code: `db.c.find({a: 1})`}, st); err != nil {
		t.Fatal(err)
	}
	h := st.msgs[0].GetResult().GetCursor()
	if h == nil || h.GetKind() != queravuev1.CursorKind_CURSOR_KIND_FIND || h.GetCollection() != "c" || h.GetDatabase() != "d" {
		t.Fatalf("handle = %v", h)
	}
	fs := &fetchStream{ctx: context.Background()}
	if err := svc.FetchCursor(&queravuev1.FetchCursorRequest{ShellId: shellID, CursorId: h.GetCursorId(), Limit: 10}, fs); err != nil {
		t.Fatal(err)
	}
	var n int
	for _, m := range fs.msgs {
		n += len(m.GetBatch().GetDocuments())
	}
	if n != 2 || !fs.msgs[len(fs.msgs)-1].GetBatch().GetDone() {
		t.Fatalf("fetched %d documents, messages %v", n, fs.msgs)
	}
	err := svc.FetchCursor(&queravuev1.FetchCursorRequest{ShellId: shellID, CursorId: "nope"}, &fetchStream{ctx: context.Background()})
	if status.Code(err) != codes.NotFound {
		t.Fatalf("got %v, want NotFound", err)
	}
}

func TestShellServiceErrors(t *testing.T) {
	svc, mgr, sid := newShellService(t, &fakeShellConn{})
	if _, err := svc.OpenShell(context.Background(), &queravuev1.OpenShellRequest{SessionId: "nope"}); status.Code(err) != codes.NotFound {
		t.Errorf("unknown session: %v", err)
	}
	if err := svc.Eval(&queravuev1.EvalRequest{ShellId: "nope", Code: "1"}, &evalStream{ctx: context.Background()}); status.Code(err) != codes.NotFound {
		t.Errorf("unknown shell: %v", err)
	}

	noShell := session.NewManager(fakeDocOpener{conn: &fakeDocConn{}})
	t.Cleanup(noShell.Shutdown)
	sess, err := noShell.Open(context.Background(), "c")
	if err != nil {
		t.Fatal(err)
	}
	other := api.NewShellService(noShell, nil, nil)
	if _, err := other.OpenShell(context.Background(), &queravuev1.OpenShellRequest{SessionId: sess.ID}); status.Code(err) != codes.FailedPrecondition {
		t.Errorf("no capability: %v", err)
	}

	shellID := openShell(t, svc, sid)
	mgr.Close(sid)
	if err := svc.Eval(&queravuev1.EvalRequest{ShellId: shellID, Code: "1"}, &evalStream{ctx: context.Background()}); status.Code(err) != codes.NotFound {
		t.Errorf("shell of closed session: %v", err)
	}
}

func TestShellServiceCloseAndCancelAreIdempotent(t *testing.T) {
	svc, _, sid := newShellService(t, &fakeShellConn{})
	shellID := openShell(t, svc, sid)
	for range 2 {
		if _, err := svc.Cancel(context.Background(), &queravuev1.ShellServiceCancelRequest{ShellId: shellID}); err != nil {
			t.Fatal(err)
		}
		if _, err := svc.CloseShell(context.Background(), &queravuev1.CloseShellRequest{ShellId: shellID}); err != nil {
			t.Fatal(err)
		}
	}
}

func TestShellServiceClosesShellsWhenTheirSessionCloses(t *testing.T) {
	var svc *api.ShellService
	mgr := session.NewManager(shellOpener{conn: &fakeShellConn{}}, session.WithOnClose(func(id string) {
		if svc != nil {
			svc.CloseSession(id)
		}
	}))
	t.Cleanup(mgr.Shutdown)
	svc = api.NewShellService(mgr, nil, nil)
	t.Cleanup(svc.Shutdown)
	one, err := mgr.Open(context.Background(), "c")
	if err != nil {
		t.Fatal(err)
	}
	two, err := mgr.Open(context.Background(), "c")
	if err != nil {
		t.Fatal(err)
	}
	openShell(t, svc, one.ID)
	openShell(t, svc, one.ID)
	keep := openShell(t, svc, two.ID)
	if svc.Len() != 3 {
		t.Fatalf("Len = %d, want 3", svc.Len())
	}

	mgr.Close(one.ID)
	if svc.Len() != 1 {
		t.Fatalf("Len = %d after closing a session, want 1: its shells must go at once", svc.Len())
	}
	st := &evalStream{ctx: context.Background()}
	if err := svc.Eval(&queravuev1.EvalRequest{ShellId: keep, Code: "1"}, st); err != nil {
		t.Fatalf("the other session's shell broke: %v", err)
	}
}
