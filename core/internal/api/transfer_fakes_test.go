package api_test

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"strings"
	"sync"
	"testing"

	"google.golang.org/grpc"
	"google.golang.org/protobuf/proto"

	"github.com/doubledare704/queravue/core/internal/api"
	"github.com/doubledare704/queravue/core/internal/connections"
	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/results"
	"github.com/doubledare704/queravue/core/internal/secrets"
	"github.com/doubledare704/queravue/core/internal/session"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

type xferConn struct {
	mu         sync.Mutex
	table      engine.TableDetails
	selectCols []engine.Column
	selectRows [][]engine.Value
	committed  [][]engine.Value
	loadCols   []string
	statements []string
	batches    int
	afterBatch func(batch int)
}

func (*xferConn) Ping(context.Context) error { return nil }
func (*xferConn) ServerInfo(context.Context) (engine.ServerInfo, error) {
	return engine.ServerInfo{}, nil
}
func (*xferConn) Close() error                { return nil }
func (*xferConn) Dialect() sqldialect.Dialect { return sqldialect.Postgres }

func (c *xferConn) DescribeTable(context.Context, string, string, string) (engine.TableDetails, error) {
	return c.table, nil
}
func (*xferConn) ListDatabases(context.Context) ([]string, error)       { return nil, nil }
func (*xferConn) ListSchemas(context.Context, string) ([]string, error) { return nil, nil }
func (*xferConn) ListObjects(context.Context, string, string) ([]engine.SchemaObject, error) {
	return nil, nil
}

func (c *xferConn) Execute(_ context.Context, stmt engine.Statement, sink engine.RowSink) (engine.Summary, error) {
	c.mu.Lock()
	c.statements = append(c.statements, stmt.SQL)
	c.mu.Unlock()
	if strings.Contains(stmt.SQL, "FAIL") {
		return engine.Summary{}, &engine.Error{Kind: engine.KindSQL, Engine: "fake", Op: "execute", Msg: "syntax error near FAIL"}
	}
	if !strings.HasPrefix(strings.TrimSpace(stmt.SQL), "SELECT") {
		return engine.Summary{RowsAffected: 1}, nil
	}
	if err := sink.Columns(c.selectCols); err != nil {
		return engine.Summary{}, err
	}
	for i := 0; i < len(c.selectRows); i += engine.MaxBatchRows {
		if err := sink.Batch(c.selectRows[i:min(i+engine.MaxBatchRows, len(c.selectRows))]); err != nil {
			return engine.Summary{}, err
		}
	}
	return engine.Summary{HasRows: true}, nil
}

func (c *xferConn) LoadRows(ctx context.Context, _ engine.LoadTarget, columns []string, src engine.RowBatchSource) (engine.LoadStats, error) {
	c.mu.Lock()
	c.loadCols = columns
	c.mu.Unlock()
	return engine.DriveLoad(ctx, "fake", "load", src.Next, func(b [][]engine.Value) int { return len(b) },
		func(_ context.Context, batch [][]engine.Value) (engine.LoadStats, error) {
			c.mu.Lock()
			defer c.mu.Unlock()
			seen := map[string]bool{}
			for _, row := range c.committed {
				seen[row[0].Str+fmt.Sprint(row[0].Int)] = true
			}
			for _, row := range batch {
				key := row[0].Str + fmt.Sprint(row[0].Int)
				if seen[key] {
					return engine.LoadStats{}, &engine.Error{Kind: engine.KindConstraint, Engine: "fake", Op: "load", Msg: "duplicate key on id"}
				}
				seen[key] = true
			}
			c.committed = append(c.committed, batch...)
			c.batches++
			if c.afterBatch != nil {
				c.afterBatch(c.batches)
			}
			return engine.LoadStats{Rows: uint64(len(batch)), Batches: 1}, nil
		})
}

func (c *xferConn) committedRows() [][]engine.Value {
	c.mu.Lock()
	defer c.mu.Unlock()
	return append([][]engine.Value(nil), c.committed...)
}

type xferDocConn struct {
	fakeDocConn
	loaded []engine.Document
}

func (c *xferDocConn) LoadDocuments(ctx context.Context, _, _ string, src engine.DocumentBatchSource) (engine.LoadStats, error) {
	return engine.DriveLoad(ctx, "fake", "load", src.Next, func(b []engine.Document) int { return len(b) },
		func(_ context.Context, batch []engine.Document) (engine.LoadStats, error) {
			c.loaded = append(c.loaded, batch...)
			return engine.LoadStats{Rows: uint64(len(batch)), Batches: 1}, nil
		})
}

type xferEnv struct {
	svc     *api.TransferService
	results *results.Manager
	session *session.Session
}

func newXferEnv(t *testing.T, conn engine.Conn, production bool) *xferEnv {
	t.Helper()
	var connSvc *connections.Service
	if production {
		store := connections.NewFileStore(t.TempDir())
		if err := store.Save([]connections.Connection{{ID: "c", Name: "prod", EngineID: "fake", Production: true}}); err != nil {
			t.Fatal(err)
		}
		reg, err := engine.NewRegistry()
		if err != nil {
			t.Fatal(err)
		}
		connSvc = connections.NewService(reg, store, secrets.NewMemory())
	}
	mgr := session.NewManager(fakeOpener{conn: conn})
	t.Cleanup(mgr.Shutdown)
	sess, err := mgr.Open(context.Background(), "c")
	if err != nil {
		t.Fatal(err)
	}
	res, err := results.NewManager(t.TempDir(), 0, nil)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(res.Shutdown)
	return &xferEnv{svc: api.NewTransferService(mgr, res, connSvc, nil), results: res, session: sess}
}

type exportRecorder[T any] struct {
	grpc.ServerStream
	ctx    context.Context
	events []*queravuev1.ExportEvent
	onSend func(n int)
}

func (r *exportRecorder[T]) Context() context.Context {
	if r.ctx == nil {
		return context.Background()
	}
	return r.ctx
}

func (r *exportRecorder[T]) Send(m T) error {
	ev := eventOf(m)
	if chunk, ok := ev.GetEvent().(*queravuev1.ExportEvent_Chunk); ok {
		ev = &queravuev1.ExportEvent{Event: &queravuev1.ExportEvent_Chunk{Chunk: bytes.Clone(chunk.Chunk)}}
	}
	r.events = append(r.events, ev)
	if r.onSend != nil {
		r.onSend(len(r.events))
	}
	return nil
}

func eventOf(m any) *queravuev1.ExportEvent {
	switch v := m.(type) {
	case *queravuev1.ExportResultResponse:
		return v.GetEvent()
	case *queravuev1.ExportTableResponse:
		return v.GetEvent()
	case *queravuev1.ExportCollectionResponse:
		return v.GetEvent()
	}
	panic("unknown export response")
}

type exported struct {
	header  *queravuev1.ExportHeader
	body    []byte
	chunks  int
	maxSize int
	summary *queravuev1.ExportSummary
	err     *queravuev1.TransferError
}

func collectExport(events []*queravuev1.ExportEvent) exported {
	var out exported
	for _, ev := range events {
		switch e := ev.GetEvent().(type) {
		case *queravuev1.ExportEvent_Header:
			out.header = e.Header
		case *queravuev1.ExportEvent_Chunk:
			out.body = append(out.body, e.Chunk...)
			out.chunks++
			out.maxSize = max(out.maxSize, len(e.Chunk))
		case *queravuev1.ExportEvent_Summary:
			out.summary = e.Summary
		case *queravuev1.ExportEvent_Error:
			out.err = e.Error
		}
	}
	return out
}

func (e *xferEnv) exportTable(t *testing.T, req *queravuev1.ExportTableRequest) exported {
	t.Helper()
	req.SessionId = e.session.ID
	rec := &exportRecorder[*queravuev1.ExportTableResponse]{}
	if err := e.svc.ExportTable(req, rec); err != nil {
		t.Fatal(err)
	}
	return collectExport(rec.events)
}

type importStream struct {
	grpc.ServerStream
	ctx    context.Context
	in     []*queravuev1.ImportRequest
	next   int
	out    []*queravuev1.ImportResponse
	onRecv func(n int)
}

func (s *importStream) Context() context.Context {
	if s.ctx == nil {
		return context.Background()
	}
	return s.ctx
}

func (s *importStream) Recv() (*queravuev1.ImportRequest, error) {
	if s.onRecv != nil {
		s.onRecv(s.next)
	}
	if s.next >= len(s.in) {
		return nil, io.EOF
	}
	if err := s.Context().Err(); err != nil {
		return nil, err
	}
	m := s.in[s.next]
	s.next++
	return m, nil
}

func (s *importStream) Send(m *queravuev1.ImportResponse) error {
	s.out = append(s.out, proto.Clone(m).(*queravuev1.ImportResponse))
	return nil
}

func chunked(data string, size int) []*queravuev1.ImportRequest {
	var out []*queravuev1.ImportRequest
	for i := 0; i < len(data); i += size {
		out = append(out, &queravuev1.ImportRequest{Message: &queravuev1.ImportRequest_Chunk{Chunk: []byte(data[i:min(i+size, len(data))])}})
	}
	return out
}

func importMessages(hdr *queravuev1.ImportHeader, data string, chunkSize int) []*queravuev1.ImportRequest {
	return append([]*queravuev1.ImportRequest{{Message: &queravuev1.ImportRequest_Header{Header: hdr}}}, chunked(data, chunkSize)...)
}

type imported struct {
	summary  *queravuev1.ImportSummary
	err      *queravuev1.TransferError
	progress []*queravuev1.ImportProgress
}

func collectImport(out []*queravuev1.ImportResponse) imported {
	var res imported
	for _, m := range out {
		switch e := m.GetEvent().(type) {
		case *queravuev1.ImportResponse_Summary:
			res.summary = e.Summary
		case *queravuev1.ImportResponse_Error:
			res.err = e.Error
		case *queravuev1.ImportResponse_Progress:
			res.progress = append(res.progress, e.Progress)
		}
	}
	return res
}

func (e *xferEnv) runImport(t *testing.T, hdr *queravuev1.ImportHeader, data string, chunkSize int) imported {
	t.Helper()
	hdr.SessionId = e.session.ID
	s := &importStream{in: importMessages(hdr, data, chunkSize)}
	if err := e.svc.Import(s); err != nil {
		t.Fatal(err)
	}
	return collectImport(s.out)
}

func existingTable(name string) *queravuev1.ImportHeader_ExistingTable {
	return &queravuev1.ImportHeader_ExistingTable{ExistingTable: &queravuev1.TableRef{Schema: "public", Table: name}}
}

func rowsOf(rows [][]engine.Value) []*queravuev1.Row {
	return results.RowsToProto(rows)
}
