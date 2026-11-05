package api

import (
	"context"
	"log/slog"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/sqlite"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/results"
	"github.com/doubledare704/queravue/core/internal/session"
)

type sqliteOpener struct{ path string }

func (o sqliteOpener) Open(ctx context.Context, _ string) (engine.Conn, engine.Descriptor, error) {
	e := sqlite.New()
	c, err := e.Connect(ctx, engine.Config{EngineID: sqlite.ID, Params: map[string]string{
		sqlite.ParamPath: o.path, sqlite.ParamCreateIfMissing: "true",
	}}, engine.Secret{})
	return c, e.Descriptor(), err
}

// execStream collects Execute events.
type execStream struct {
	grpc.ServerStream
	ctx    context.Context
	events []*queravuev1.ExecuteResponse
}

func (s *execStream) Context() context.Context { return s.ctx }
func (s *execStream) Send(e *queravuev1.ExecuteResponse) error {
	s.events = append(s.events, e)
	return nil
}

type copyStream struct {
	grpc.ServerStream
	ctx  context.Context
	text strings.Builder
	n    int
}

func (s *copyStream) Context() context.Context { return s.ctx }
func (s *copyStream) Send(e *queravuev1.CopyRangeResponse) error {
	s.text.WriteString(e.GetText())
	s.n++
	return nil
}

type fixture struct {
	q    *QueryService
	sess *session.Session
	res  *results.Manager
}

func newFixture(t *testing.T) *fixture {
	t.Helper()
	log := slog.New(slog.DiscardHandler)
	res, err := results.NewManager(t.TempDir(), 0, log)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(res.Shutdown)
	mgr := session.NewManager(sqliteOpener{filepath.Join(t.TempDir(), "t.db")}, session.WithLogger(log), session.WithOnClose(res.CloseSession))
	t.Cleanup(mgr.Shutdown)
	s, err := mgr.Open(context.Background(), "c")
	if err != nil {
		t.Fatal(err)
	}
	return &fixture{q: NewQueryService(mgr, res, log), sess: s, res: res}
}

func (f *fixture) exec(t *testing.T, req *queravuev1.ExecuteRequest) []*queravuev1.ExecuteResponse {
	t.Helper()
	req.SessionId = f.sess.ID
	st := &execStream{ctx: context.Background()}
	if err := f.q.Execute(req, st); err != nil {
		t.Fatalf("Execute: %v", err)
	}
	return st.events
}

func kinds(evs []*queravuev1.ExecuteResponse) string {
	var out []string
	for _, e := range evs {
		switch e.GetEvent().(type) {
		case *queravuev1.ExecuteResponse_Plan:
			out = append(out, "plan")
		case *queravuev1.ExecuteResponse_Started:
			out = append(out, "started")
		case *queravuev1.ExecuteResponse_Columns:
			out = append(out, "columns")
		case *queravuev1.ExecuteResponse_Rows:
			out = append(out, "rows")
		case *queravuev1.ExecuteResponse_Progress:
			out = append(out, "progress")
		case *queravuev1.ExecuteResponse_Summary:
			out = append(out, "summary")
		case *queravuev1.ExecuteResponse_Error:
			out = append(out, "error")
		}
	}
	return strings.Join(out, ",")
}

const series = "WITH RECURSIVE c(x) AS (SELECT 1 UNION ALL SELECT x+1 FROM c WHERE x < %d) SELECT x, 'v' || x AS s FROM c"

func seriesSQL(n string) string { return strings.Replace(series, "%d", n, 1) }

func TestExecuteStreamsFirstWindowThenFetch(t *testing.T) {
	f := newFixture(t)
	evs := f.exec(t, &queravuev1.ExecuteRequest{Text: seriesSQL("2300"), Mode: queravuev1.ExecuteMode_EXECUTE_MODE_ALL})
	if got := kinds(evs); !strings.HasPrefix(got, "plan,started,columns,rows") || !strings.HasSuffix(got, "progress,summary") {
		t.Fatalf("events = %s", got)
	}
	var rowEvents, rowsOnStream int
	for _, e := range evs {
		if w := e.GetRows(); w != nil {
			rowEvents++
			rowsOnStream += len(w.GetRows())
			if w.GetOffset() != 0 || len(w.GetRows()) != 500 {
				t.Errorf("window offset=%d rows=%d", w.GetOffset(), len(w.GetRows()))
			}
		}
	}
	if rowEvents != 1 || rowsOnStream != 500 {
		t.Errorf("rows on the stream: %d events, %d rows; want only the first window", rowEvents, rowsOnStream)
	}
	sum := evs[len(evs)-1].GetSummary()
	if sum.GetRowsSpooled() != 2300 || !sum.GetHasRows() || sum.GetTruncated() {
		t.Fatalf("summary = %v", sum)
	}
	id := evs[1].GetStarted().GetResultId()
	resp, err := f.q.FetchRows(context.Background(), &queravuev1.FetchRowsRequest{ResultId: id, Offset: 2000, Limit: 500})
	if err != nil {
		t.Fatal(err)
	}
	if len(resp.GetRows()) != 300 || !resp.GetDone() || resp.GetRows()[0].GetValues()[0].GetIntValue() != 2001 {
		t.Errorf("fetch = %d rows done=%v first=%v", len(resp.GetRows()), resp.GetDone(), resp.GetRows()[0])
	}
	// Close the result: its spool goes away.
	_, _ = f.q.CloseResult(context.Background(), &queravuev1.CloseResultRequest{ResultId: id})
	if _, err := f.q.FetchRows(context.Background(), &queravuev1.FetchRowsRequest{ResultId: id}); status.Code(err) != codes.NotFound {
		t.Errorf("fetch after close: %v", err)
	}
}

func TestExecuteModes(t *testing.T) {
	f := newFixture(t)
	text := "select 1 as a; select 2 as b;\nselect 3 as c"

	evs := f.exec(t, &queravuev1.ExecuteRequest{Text: text, CursorOffset: 18}) // inside the 2nd statement
	if got := kinds(evs); got != "plan,started,columns,rows,progress,summary" {
		t.Fatalf("cursor events = %s", got)
	}
	if c := evs[2].GetColumns().GetColumns()[0].GetName(); c != "b" {
		t.Errorf("ran column %q, want b", c)
	}
	if r := evs[0].GetPlan().GetStatements()[0].GetRange(); r.GetStart() != 15 || r.GetEnd() != 28 {
		t.Errorf("range = %v", r)
	}

	evs = f.exec(t, &queravuev1.ExecuteRequest{Text: text, Mode: queravuev1.ExecuteMode_EXECUTE_MODE_ALL})
	if n := len(evs[0].GetPlan().GetStatements()); n != 3 {
		t.Errorf("ALL planned %d statements", n)
	}
	// Selection splits the selected text itself: "select 2" without the rest.
	evs = f.exec(t, &queravuev1.ExecuteRequest{Text: text, Mode: queravuev1.ExecuteMode_EXECUTE_MODE_SELECTION,
		Selection: &queravuev1.TextRange{Start: 15, End: 23}})
	if p := evs[0].GetPlan().GetStatements(); len(p) != 1 || p[0].GetRange().GetStart() != 15 {
		t.Errorf("selection plan = %v", p)
	}
	evs = f.exec(t, &queravuev1.ExecuteRequest{Text: "  -- nothing\n", Mode: queravuev1.ExecuteMode_EXECUTE_MODE_ALL})
	if got := kinds(evs); got != "plan" {
		t.Errorf("empty text events = %s", got)
	}
}

func TestExecuteErrorStopsAndReportsPosition(t *testing.T) {
	f := newFixture(t)
	evs := f.exec(t, &queravuev1.ExecuteRequest{Text: "select 1; selekt 2; select 3", Mode: queravuev1.ExecuteMode_EXECUTE_MODE_ALL})
	last := evs[len(evs)-1]
	if got := kinds(evs); !strings.HasSuffix(got, "started,error") {
		t.Fatalf("events = %s", got)
	}
	e := last.GetError()
	if e.GetStatementIndex() != 1 || e.GetKind() != queravuev1.QueryErrorKind_QUERY_ERROR_KIND_SQL || e.GetMessage() == "" {
		t.Errorf("error = %v", e)
	}
	// Statement 3 never ran: only two Started events.
	n := 0
	for _, ev := range evs {
		if ev.GetStarted() != nil {
			n++
		}
	}
	if n != 2 {
		t.Errorf("started %d statements, want 2", n)
	}
}

func TestExecuteNonRowStatement(t *testing.T) {
	f := newFixture(t)
	f.exec(t, &queravuev1.ExecuteRequest{Text: "create table t(i int)", Mode: queravuev1.ExecuteMode_EXECUTE_MODE_ALL})
	evs := f.exec(t, &queravuev1.ExecuteRequest{Text: "insert into t values (1),(2),(3)", Mode: queravuev1.ExecuteMode_EXECUTE_MODE_ALL})
	if got := kinds(evs); got != "plan,started,progress,summary" {
		t.Fatalf("events = %s", got)
	}
	if s := evs[len(evs)-1].GetSummary(); s.GetRowsAffected() != 3 || s.GetHasRows() {
		t.Errorf("summary = %v", s)
	}
}

func TestCancelStopsStatement(t *testing.T) {
	f := newFixture(t)
	done := make(chan []*queravuev1.ExecuteResponse, 1)
	go func() {
		st := &execStream{ctx: context.Background()}
		_ = f.q.Execute(&queravuev1.ExecuteRequest{SessionId: f.sess.ID, Mode: queravuev1.ExecuteMode_EXECUTE_MODE_ALL,
			Text: "WITH RECURSIVE c(x) AS (SELECT 1 UNION ALL SELECT x+1 FROM c) SELECT count(*) FROM c"}, st)
		done <- st.events
	}()
	// While the statement runs, the session refuses a second one.
	time.Sleep(150 * time.Millisecond)
	st := &execStream{ctx: context.Background()}
	if err := f.q.Execute(&queravuev1.ExecuteRequest{SessionId: f.sess.ID, Text: "select 1"}, st); status.Code(err) != codes.FailedPrecondition {
		t.Fatalf("second Execute while busy: %v", err)
	}
	if _, err := f.q.Cancel(context.Background(), &queravuev1.CancelRequest{SessionId: f.sess.ID}); err != nil {
		t.Fatal(err)
	}
	select {
	case evs := <-done:
		e := evs[len(evs)-1].GetError()
		if e == nil || e.GetKind() != queravuev1.QueryErrorKind_QUERY_ERROR_KIND_CANCELED {
			t.Errorf("last event = %v", evs[len(evs)-1])
		}
	case <-time.After(5 * time.Second):
		t.Fatal("Cancel did not stop the statement")
	}
	// Session is reusable.
	if got := kinds(f.exec(t, &queravuev1.ExecuteRequest{Text: "select 1"})); !strings.HasSuffix(got, "summary") {
		t.Errorf("after cancel: %s", got)
	}
}

func TestCopyRange(t *testing.T) {
	f := newFixture(t)
	evs := f.exec(t, &queravuev1.ExecuteRequest{Text: seriesSQL("1200"), Mode: queravuev1.ExecuteMode_EXECUTE_MODE_ALL})
	id := evs[1].GetStarted().GetResultId()
	cs := &copyStream{ctx: context.Background()}
	err := f.q.CopyRange(&queravuev1.CopyRangeRequest{
		ResultId: id, RowRange: &queravuev1.RowRange{Start: 498, End: 503},
		ColumnIndices: []uint32{1, 0}, Format: queravuev1.CopyFormat_COPY_FORMAT_CSV, IncludeHeader: true,
	}, cs)
	if err != nil {
		t.Fatal(err)
	}
	want := "s,x\nv499,499\nv500,500\nv501,501\nv502,502\nv503,503\n"
	if cs.text.String() != want {
		t.Errorf("copy = %q, want %q", cs.text.String(), want)
	}

	// A big copy is chunked and complete.
	big := f.exec(t, &queravuev1.ExecuteRequest{Text: seriesSQL("30000"), Mode: queravuev1.ExecuteMode_EXECUTE_MODE_ALL})
	cs = &copyStream{ctx: context.Background()}
	if err := f.q.CopyRange(&queravuev1.CopyRangeRequest{ResultId: big[1].GetStarted().GetResultId(), Format: queravuev1.CopyFormat_COPY_FORMAT_TSV}, cs); err != nil {
		t.Fatal(err)
	}
	if lines := strings.Count(cs.text.String(), "\n"); lines != 30000 || cs.n < 2 {
		t.Errorf("lines=%d chunks=%d", lines, cs.n)
	}
}

func TestSessionServiceOpenClose(t *testing.T) {
	log := slog.New(slog.DiscardHandler)
	res, _ := results.NewManager(t.TempDir(), 0, log)
	defer res.Shutdown()
	mgr := session.NewManager(sqliteOpener{filepath.Join(t.TempDir(), "x.db")}, session.WithLogger(log), session.WithOnClose(res.CloseSession))
	defer mgr.Shutdown()
	h := NewSessionService(mgr)
	resp, err := h.Open(context.Background(), &queravuev1.OpenRequest{ConnectionId: "c"})
	if err != nil || resp.GetSessionId() == "" || resp.GetServerInfo().GetProduct() != "SQLite" {
		t.Fatalf("Open: %v %v", resp, err)
	}
	if !strings.Contains(strings.Join(resp.GetCapabilities(), ","), "execute") {
		t.Errorf("capabilities = %v", resp.GetCapabilities())
	}
	if _, err := h.Close(context.Background(), &queravuev1.CloseRequest{SessionId: resp.GetSessionId()}); err != nil {
		t.Fatal(err)
	}
	if mgr.Len() != 0 {
		t.Error("session still open")
	}
	q := NewQueryService(mgr, res, log)
	err = q.Execute(&queravuev1.ExecuteRequest{SessionId: resp.GetSessionId()}, &execStream{ctx: context.Background()})
	if status.Code(err) != codes.NotFound {
		t.Errorf("Execute on closed session: %v", err)
	}
}
