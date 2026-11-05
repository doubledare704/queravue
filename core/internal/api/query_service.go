package api

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"time"
	"unicode/utf8"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/durationpb"

	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/results"
	"github.com/doubledare704/queravue/core/internal/session"
	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

// Limits and pacing for QueryService.
const (
	defaultFetchRows = 500
	maxFetchRows     = 5000
	progressEvery    = 100 * time.Millisecond
	copyChunkBytes   = 64 << 10
)

// QueryService implements queravuev1.QueryServiceServer. It is thin: it
// splits text, drives the engine into a spool and forwards events.
type QueryService struct {
	queravuev1.UnimplementedQueryServiceServer

	sessions *session.Manager
	results  *results.Manager
	log      *slog.Logger
}

// NewQueryService returns a handler.
func NewQueryService(s *session.Manager, r *results.Manager, log *slog.Logger) *QueryService {
	if log == nil {
		log = slog.Default()
	}
	return &QueryService{sessions: s, results: r, log: log}
}

// Execute implements the RPC.
func (h *QueryService) Execute(req *queravuev1.ExecuteRequest, stream queravuev1.QueryService_ExecuteServer) error {
	sess, err := h.sessions.Get(req.GetSessionId())
	if err != nil {
		return status.Error(codes.NotFound, "session not found")
	}
	ctx, finish, err := sess.Begin(stream.Context())
	switch {
	case errors.Is(err, session.ErrBusy):
		return status.Error(codes.FailedPrecondition, "the session is already running a statement")
	case err != nil:
		return status.Error(codes.NotFound, "session not found")
	}
	defer finish()

	send := func(ev *queravuev1.ExecuteResponse) error { return sendEvent(stream, ev) }
	ex, ok := engine.As[engine.Executor](sess.Conn)
	if !ok {
		return send(errEvent(0, queravuev1.QueryErrorKind_QUERY_ERROR_KIND_UNSUPPORTED, "this connection cannot run statements", nil, 0))
	}

	text := req.GetText()
	om := sqlsplit.NewOffsetMap(text)
	stmts := selectStatements(sess.Dialect, text, om, req)
	plan := &queravuev1.StatementPlan{}
	for i, r := range stmts {
		plan.Statements = append(plan.Statements, &queravuev1.StatementRange{
			Index: uint32(i),
			Range: &queravuev1.TextRange{Start: uint32(om.ToUTF16(r.Start)), End: uint32(om.ToUTF16(r.End))}, //nolint:gosec // offsets are non-negative
		})
	}
	if err := send(&queravuev1.ExecuteResponse{Event: &queravuev1.ExecuteResponse_Plan{Plan: plan}}); err != nil {
		return err
	}

	var params []engine.Value
	if len(stmts) == 1 {
		for _, p := range req.GetParams() {
			params = append(params, results.ValueFromProto(p))
		}
	}
	for i, r := range stmts {
		cont, err := h.runStatement(ctx, stream, sess, ex, text, om, uint32(i), r, params)
		if err != nil {
			return err
		}
		if !cont {
			return nil
		}
	}
	return nil
}

// runStatement runs one statement and streams its events. It returns false
// when execution must stop (a failed statement); a non-nil error means the
// stream itself broke.
func (h *QueryService) runStatement(ctx context.Context, stream queravuev1.QueryService_ExecuteServer, sess *session.Session,
	ex engine.Executor, text string, om sqlsplit.OffsetMap, idx uint32, r sqlsplit.Range, params []engine.Value,
) (bool, error) {
	send := func(ev *queravuev1.ExecuteResponse) error { return sendEvent(stream, ev) }
	id, spool, err := h.results.Create(sess.ID)
	if err != nil {
		h.log.Error("create spool", "err", err)
		return false, send(errEvent(idx, queravuev1.QueryErrorKind_QUERY_ERROR_KIND_UNSPECIFIED, "could not create the result spool", nil, 0))
	}
	if err := send(&queravuev1.ExecuteResponse{Event: &queravuev1.ExecuteResponse_Started{
		Started: &queravuev1.StatementStarted{StatementIndex: idx, ResultId: id},
	}}); err != nil {
		h.results.Close(id)
		return false, err
	}

	sink := &streamSink{idx: idx, stream: stream, spool: spool, lastProgress: time.Now()}
	sum, execErr := ex.Execute(ctx, engine.Statement{SQL: r.Text(text), Params: params}, sink)
	if sink.sendErr != nil {
		return false, sink.sendErr // client is gone; the query was stopped by the sink error
	}
	if err := spool.Finish(); err != nil && execErr == nil {
		execErr = err
	}
	rows, _, truncated := spool.State()
	if execErr != nil {
		if stream.Context().Err() != nil {
			return false, status.FromContextError(stream.Context().Err()).Err()
		}
		var ee *engine.Error
		kind, msg := queravuev1.QueryErrorKind_QUERY_ERROR_KIND_UNSPECIFIED, "the statement failed"
		var pos *uint32
		if errors.As(execErr, &ee) {
			kind, msg = queryKind(ee.Kind), ee.Msg
			pos = errPosition(text, r, ee.Position, om)
		} else {
			h.log.Error("execute", "err", execErr)
		}
		return false, send(errEvent(idx, kind, msg, pos, sum.Duration))
	}
	if err := send(&queravuev1.ExecuteResponse{Event: &queravuev1.ExecuteResponse_Progress{
		Progress: &queravuev1.Progress{StatementIndex: idx, RowsSpooled: rows, Done: true},
	}}); err != nil {
		return false, err
	}
	affected := sum.RowsAffected
	if affected < 0 {
		affected = 0
	}
	return true, send(&queravuev1.ExecuteResponse{Event: &queravuev1.ExecuteResponse_Summary{Summary: &queravuev1.Summary{
		StatementIndex: idx,
		RowsAffected:   uint64(affected),
		RowsSpooled:    rows,
		Duration:       durationpb.New(sum.Duration),
		Notices:        sum.Notices,
		Truncated:      truncated,
		HasRows:        sum.HasRows,
	}}})
}

// streamSink writes rows to the spool and forwards the first window and
// throttled progress to the stream.
type streamSink struct {
	idx          uint32
	stream       queravuev1.QueryService_ExecuteServer
	spool        *results.Spool
	firstSent    bool
	lastProgress time.Time
	sendErr      error
}

func (s *streamSink) send(ev *queravuev1.ExecuteResponse) error {
	if err := sendEvent(s.stream, ev); err != nil {
		s.sendErr = err
		return err
	}
	return nil
}

func sendEvent(stream queravuev1.QueryService_ExecuteServer, ev *queravuev1.ExecuteResponse) error {
	if err := stream.Send(ev); err != nil {
		return fmt.Errorf("send event: %w", err)
	}
	return nil
}

func (s *streamSink) Columns(cols []engine.Column) error {
	pc := results.ColumnsToProto(cols)
	s.spool.SetColumns(pc)
	return s.send(&queravuev1.ExecuteResponse{Event: &queravuev1.ExecuteResponse_Columns{
		Columns: &queravuev1.Columns{StatementIndex: s.idx, Columns: pc},
	}})
}

func (s *streamSink) Batch(batch [][]engine.Value) error {
	rows := results.RowsToProto(batch)
	appendErr := s.spool.Append(rows)
	if appendErr != nil && !errors.Is(appendErr, results.ErrFull) {
		return appendErr
	}
	if !s.firstSent {
		s.firstSent = true
		if err := s.send(&queravuev1.ExecuteResponse{Event: &queravuev1.ExecuteResponse_Rows{
			Rows: &queravuev1.RowsWindow{StatementIndex: s.idx, Offset: 0, Rows: rows},
		}}); err != nil {
			return err
		}
		s.lastProgress = time.Now()
	} else if time.Since(s.lastProgress) >= progressEvery {
		s.lastProgress = time.Now()
		if err := s.send(&queravuev1.ExecuteResponse{Event: &queravuev1.ExecuteResponse_Progress{
			Progress: &queravuev1.Progress{StatementIndex: s.idx, RowsSpooled: s.spool.Total()},
		}}); err != nil {
			return err
		}
	}
	if appendErr != nil {
		return engine.ErrStop
	}
	return nil
}

func errEvent(idx uint32, kind queravuev1.QueryErrorKind, msg string, pos *uint32, d time.Duration) *queravuev1.ExecuteResponse {
	return &queravuev1.ExecuteResponse{Event: &queravuev1.ExecuteResponse_Error{Error: &queravuev1.ExecuteError{
		StatementIndex: idx, Kind: kind, Message: msg, Position: pos, Duration: durationpb.New(d),
	}}}
}

func queryKind(k engine.Kind) queravuev1.QueryErrorKind {
	switch k {
	case engine.KindSQL:
		return queravuev1.QueryErrorKind_QUERY_ERROR_KIND_SQL
	case engine.KindCanceled:
		return queravuev1.QueryErrorKind_QUERY_ERROR_KIND_CANCELED
	case engine.KindConnectionLost, engine.KindNetwork:
		return queravuev1.QueryErrorKind_QUERY_ERROR_KIND_CONNECTION
	}
	return queravuev1.QueryErrorKind_QUERY_ERROR_KIND_UNSPECIFIED
}

// errPosition maps a 1-based character position inside the statement to a
// UTF-16 offset in the request text.
func errPosition(text string, r sqlsplit.Range, pos int, om sqlsplit.OffsetMap) *uint32 {
	if pos <= 0 {
		return nil
	}
	stmt := r.Text(text)
	off := 0
	for n := 1; n < pos && off < len(stmt); n++ {
		_, size := utf8.DecodeRuneInString(stmt[off:])
		off += size
	}
	u := uint32(om.ToUTF16(r.Start + off)) //nolint:gosec // non-negative
	return &u
}

// selectStatements picks the statements to run for the request's mode.
func selectStatements(d sqlsplit.Dialect, text string, om sqlsplit.OffsetMap, req *queravuev1.ExecuteRequest) []sqlsplit.Range {
	mode := req.GetMode()
	if mode == queravuev1.ExecuteMode_EXECUTE_MODE_SELECTION {
		s, e := om.ToByte(int(req.GetSelection().GetStart())), om.ToByte(int(req.GetSelection().GetEnd()))
		if s < e {
			// Split the selected text itself, so a partial statement runs as selected.
			sub := sqlsplit.Split(d, text[s:e])
			for i := range sub {
				sub[i].Start += s
				sub[i].End += s
				sub[i].TermEnd += s
			}
			return sub
		}
		mode = queravuev1.ExecuteMode_EXECUTE_MODE_STATEMENT_AT_CURSOR
	}
	all := sqlsplit.Split(d, text)
	if mode == queravuev1.ExecuteMode_EXECUTE_MODE_ALL {
		return all
	}
	if i, ok := sqlsplit.At(all, om.ToByte(int(req.GetCursorOffset()))); ok {
		return all[i : i+1]
	}
	return nil
}

// FetchRows implements the RPC.
func (h *QueryService) FetchRows(_ context.Context, req *queravuev1.FetchRowsRequest) (*queravuev1.FetchRowsResponse, error) {
	sp, err := h.results.Get(req.GetResultId())
	if err != nil {
		return nil, status.Error(codes.NotFound, "result not found")
	}
	limit := int(req.GetLimit())
	if limit <= 0 {
		limit = defaultFetchRows
	}
	limit = min(limit, maxFetchRows)
	rows, err := sp.ReadRows(req.GetOffset(), limit)
	if err != nil {
		if errors.Is(err, results.ErrClosed) {
			return nil, status.Error(codes.NotFound, "result not found")
		}
		h.log.Error("fetch rows", "err", err)
		return nil, status.Error(codes.Internal, "could not read the result")
	}
	total, done, _ := sp.State()
	return &queravuev1.FetchRowsResponse{Offset: req.GetOffset(), Rows: rows, RowsSpooled: total, Done: done}, nil
}

// Cancel implements the RPC.
func (h *QueryService) Cancel(_ context.Context, req *queravuev1.CancelRequest) (*queravuev1.CancelResponse, error) {
	if s, err := h.sessions.Get(req.GetSessionId()); err == nil {
		s.Cancel()
	}
	return &queravuev1.CancelResponse{}, nil
}

// CloseResult implements the RPC.
func (h *QueryService) CloseResult(_ context.Context, req *queravuev1.CloseResultRequest) (*queravuev1.CloseResultResponse, error) {
	h.results.Close(req.GetResultId())
	return &queravuev1.CloseResultResponse{}, nil
}

// CopyRange implements the RPC.
func (h *QueryService) CopyRange(req *queravuev1.CopyRangeRequest, stream queravuev1.QueryService_CopyRangeServer) error {
	sp, err := h.results.Get(req.GetResultId())
	if err != nil {
		return status.Error(codes.NotFound, "result not found")
	}
	total := sp.Total()
	start := req.GetRowRange().GetStart()
	end := req.GetRowRange().GetEnd()
	if end == 0 || end > total {
		end = total
	}
	f := results.NewFormatter(req.GetFormat(), sp.Columns(), req.GetColumnIndices(), req.GetIncludeHeader())
	buf := f.Buffer()
	f.Begin()
	var written uint64
	flush := func() error {
		if buf.Len() == 0 {
			return nil
		}
		err := stream.Send(&queravuev1.CopyRangeResponse{Text: buf.String(), RowsWritten: written})
		buf.Reset()
		if err != nil {
			return fmt.Errorf("send chunk: %w", err)
		}
		return nil
	}
	for pos := start; pos < end; {
		if err := stream.Context().Err(); err != nil {
			return status.FromContextError(err).Err()
		}
		rows, err := sp.ReadRows(pos, int(min(end-pos, results.PageRows)))
		if err != nil {
			if errors.Is(err, results.ErrClosed) {
				return status.Error(codes.NotFound, "result not found")
			}
			h.log.Error("copy range", "err", err)
			return status.Error(codes.Internal, "could not read the result")
		}
		if len(rows) == 0 {
			break
		}
		for _, r := range rows {
			f.Row(r)
			written++
		}
		pos += uint64(len(rows))
		if buf.Len() >= copyChunkBytes {
			if err := flush(); err != nil {
				return err
			}
		}
	}
	f.End()
	return flush()
}
