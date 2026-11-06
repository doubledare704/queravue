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

// fakeDocConn is a Conn with a DocumentStore backed by canned results.
type fakeDocConn struct {
	docs     []string
	findErr  error
	replace  func(id, doc string, w engine.WriteOptions) (string, error)
	findOpts engine.FindOptions
}

func (*fakeDocConn) Ping(context.Context) error { return nil }
func (*fakeDocConn) ServerInfo(context.Context) (engine.ServerInfo, error) {
	return engine.ServerInfo{}, nil
}
func (*fakeDocConn) Close() error { return nil }

func (f *fakeDocConn) Find(_ context.Context, o engine.FindOptions, sink engine.DocSink) error {
	f.findOpts = o
	if f.findErr != nil {
		return f.findErr
	}
	for i := 0; i < len(f.docs); i += 2 {
		if err := sink.Batch(f.docs[i:min(i+2, len(f.docs))]); err != nil {
			return err
		}
	}
	return nil
}
func (*fakeDocConn) Count(context.Context, string, string, string, uint32) (engine.Count, error) {
	return engine.Count{N: 7, Exact: true}, nil
}
func (*fakeDocConn) Insert(context.Context, string, string, []engine.Document, engine.WriteOptions) ([]engine.Document, error) {
	return []engine.Document{`{"$numberInt":"1"}`}, nil
}
func (f *fakeDocConn) Replace(_ context.Context, _, _ string, id, doc engine.Document, w engine.WriteOptions) (engine.Document, error) {
	return f.replace(id, doc, w)
}
func (*fakeDocConn) UpdateFields(context.Context, string, string, engine.Document, engine.Document, []string, engine.WriteOptions) (engine.Document, error) {
	return "{}", nil
}
func (*fakeDocConn) Delete(context.Context, string, string, []engine.Document, engine.WriteOptions) (uint64, error) {
	return 2, nil
}
func (*fakeDocConn) SampleFields(context.Context, string, string, uint32) (engine.FieldSample, error) {
	return engine.FieldSample{Sampled: 3, Fields: []engine.FieldStat{{Name: "_id", Frequency: 1, Types: []engine.FieldType{{Type: "objectId", Count: 3}}}}}, nil
}

type fakeDocOpener struct{ conn engine.Conn }

func (o fakeDocOpener) Open(context.Context, string) (engine.Conn, engine.Descriptor, error) {
	return o.conn, engine.Descriptor{ID: "fake", Capabilities: []engine.Capability{engine.CapConnect, engine.CapDocumentStore}}, nil
}

type findStream struct {
	grpc.ServerStream
	ctx  context.Context
	msgs []*queravuev1.FindResponse
}

func (s *findStream) Context() context.Context { return s.ctx }
func (s *findStream) Send(m *queravuev1.FindResponse) error {
	s.msgs = append(s.msgs, m)
	return nil
}

func newDocService(t *testing.T, conn engine.Conn) (*api.DocumentService, string) {
	t.Helper()
	mgr := session.NewManager(fakeDocOpener{conn: conn})
	t.Cleanup(mgr.Shutdown)
	sess, err := mgr.Open(context.Background(), "c")
	if err != nil {
		t.Fatal(err)
	}
	return api.NewDocumentService(mgr, nil, nil), sess.ID
}

func TestDocumentServiceFindBatches(t *testing.T) {
	conn := &fakeDocConn{docs: []string{"a", "b", "c"}}
	svc, sid := newDocService(t, conn)
	st := &findStream{ctx: context.Background()}
	if err := svc.Find(&queravuev1.FindRequest{SessionId: sid, Database: "d", Collection: "c", Filter: "{}"}, st); err != nil {
		t.Fatal(err)
	}
	if len(st.msgs) != 3 { // 2 + 1 + final done batch
		t.Fatalf("got %d messages, want 3", len(st.msgs))
	}
	b2 := st.msgs[1].GetBatch()
	if b2.GetOffset() != 2 || len(b2.GetDocuments()) != 1 {
		t.Errorf("second batch = %+v", b2)
	}
	if last := st.msgs[2].GetBatch(); !last.GetDone() || last.GetOffset() != 3 {
		t.Errorf("last batch = %+v", last)
	}
	if conn.findOpts.MaxTimeMS == 0 {
		t.Error("default max time not applied")
	}
}

func TestDocumentServiceFindParseError(t *testing.T) {
	perr := &engine.Error{Kind: engine.KindParse, Engine: "fake", Op: "parse", Msg: "bad", Input: engine.InputSort, Position: 4}
	svc, sid := newDocService(t, &fakeDocConn{findErr: perr})
	st := &findStream{ctx: context.Background()}
	if err := svc.Find(&queravuev1.FindRequest{SessionId: sid}, st); err != nil {
		t.Fatal(err)
	}
	e := st.msgs[0].GetError()
	if e.GetKind() != queravuev1.DocumentErrorKind_DOCUMENT_ERROR_KIND_PARSE ||
		e.GetInput() != queravuev1.DocumentInput_DOCUMENT_INPUT_SORT || e.GetPosition() != 4 {
		t.Errorf("error = %+v", e)
	}
}

func TestDocumentServiceConflict(t *testing.T) {
	cur := `{"_id":1}`
	conn := &fakeDocConn{replace: func(_, _ string, w engine.WriteOptions) (string, error) {
		if w.Expected == nil {
			return "{}", nil
		}
		return "", &engine.Error{Kind: engine.KindConflict, Msg: "changed", Current: &cur}
	}}
	svc, sid := newDocService(t, conn)
	exp := `{"_id":0}`
	resp, err := svc.ReplaceDocument(context.Background(), &queravuev1.ReplaceDocumentRequest{SessionId: sid, Id: "1", Document: "{}", ExpectedDocument: &exp})
	if err != nil {
		t.Fatal(err)
	}
	if resp.GetError().GetKind() != queravuev1.DocumentErrorKind_DOCUMENT_ERROR_KIND_CONFLICT || resp.GetError().GetCurrentDocument() != cur {
		t.Errorf("error = %+v", resp.GetError())
	}
	// Overwrite: no expected document.
	resp, err = svc.ReplaceDocument(context.Background(), &queravuev1.ReplaceDocumentRequest{SessionId: sid, Id: "1", Document: "{}"})
	if err != nil || resp.GetError() != nil {
		t.Errorf("overwrite = %+v, %v", resp, err)
	}
}

func TestDocumentServiceSessionErrors(t *testing.T) {
	svc, _ := newDocService(t, &fakeDocConn{})
	_, err := svc.Count(context.Background(), &queravuev1.CountRequest{SessionId: "nope"})
	if status.Code(err) != codes.NotFound {
		t.Errorf("unknown session: %v", err)
	}
}
