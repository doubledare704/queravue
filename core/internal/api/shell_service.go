package api

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/durationpb"

	"github.com/doubledare704/queravue/core/internal/connections"
	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/history"
	"github.com/doubledare704/queravue/core/internal/session"
	"github.com/doubledare704/queravue/core/internal/shell"
)

// ShellService implements queravuev1.ShellServiceServer on top of
// internal/shell.
type ShellService struct {
	queravuev1.UnimplementedShellServiceServer

	sessions    *session.Manager
	connections *connections.Service
	log         *slog.Logger
	history     *history.Store
	shellOpts   shell.Options

	mu     sync.Mutex
	shells map[string]*openShell
}

type openShell struct {
	sh        *shell.Shell
	sessionID string
	connID    string
}

// SetHistory records shell evaluations in the query history.
func (s *ShellService) SetHistory(h *history.Store) { s.history = h }

// SetOptions sets the limits applied to new shells (output cap, timeout).
func (s *ShellService) SetOptions(o shell.Options) { s.shellOpts = o }

// NewShellService returns a ShellService. connections may be nil, in which
// case no connection counts as production.
func NewShellService(sessions *session.Manager, c *connections.Service, log *slog.Logger) *ShellService {
	if log == nil {
		log = slog.Default()
	}
	return &ShellService{sessions: sessions, connections: c, log: log, shells: map[string]*openShell{}}
}

func (s *ShellService) production(ctx context.Context, sess *session.Session) bool {
	if s.connections == nil || sess.ConnectionID == "" {
		return false
	}
	c, err := s.connections.Get(ctx, sess.ConnectionID)
	return err == nil && c.Production
}

func (s *ShellService) dropOrphans() {
	for id, o := range s.shells {
		if _, err := s.sessions.Get(o.sessionID); err != nil {
			o.sh.Close()
			delete(s.shells, id)
		}
	}
}

func (s *ShellService) lookup(shellID string) (*openShell, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	s.dropOrphans()
	o, ok := s.shells[shellID]
	if !ok {
		return nil, status.Error(codes.NotFound, "shell not found")
	}
	return o, nil
}

// OpenShell implements the RPC.
func (s *ShellService) OpenShell(ctx context.Context, req *queravuev1.OpenShellRequest) (*queravuev1.OpenShellResponse, error) {
	sess, err := s.sessions.Get(req.GetSessionId())
	if err != nil {
		return nil, status.Error(codes.NotFound, "session not found")
	}
	backend, ok := engine.As[engine.ShellBackend](sess.Conn)
	if !ok {
		return nil, status.Error(codes.FailedPrecondition, "connection does not support the shell")
	}
	opts := s.shellOpts
	opts.Database = req.GetDatabase()
	opts.Production = s.production(ctx, sess)
	sh, err := shell.New(backend, opts)
	if err != nil {
		return nil, status.Error(codes.Internal, err.Error())
	}
	id := uuid.NewString()
	s.mu.Lock()
	s.dropOrphans()
	s.shells[id] = &openShell{sh: sh, sessionID: sess.ID, connID: sess.ConnectionID}
	s.mu.Unlock()
	return &queravuev1.OpenShellResponse{ShellId: id, Database: opts.Database}, nil
}

type evalSink struct {
	stream queravuev1.ShellService_EvalServer
	err    error
	n      uint64
}

func (e *evalSink) send(m *queravuev1.EvalResponse) {
	if e.err == nil {
		e.err = e.stream.Send(m)
	}
}

func (e *evalSink) Print(level shell.Level, text string) {
	e.n++
	e.send(&queravuev1.EvalResponse{Event: &queravuev1.EvalResponse_Print{Print: &queravuev1.PrintLine{Text: text, Level: printLevel(level)}}})
}

func (e *evalSink) Result(r shell.Result) {
	item := &queravuev1.ResultItem{}
	switch r.Kind {
	case shell.ResultScalar:
		item.Value = &queravuev1.ResultItem_Scalar{Scalar: r.Text}
	case shell.ResultDocument:
		item.Value = &queravuev1.ResultItem_Document{Document: r.Text}
	case shell.ResultWrite:
		item.Value = &queravuev1.ResultItem_Write{Write: &queravuev1.WriteResult{Operation: r.WriteOp, Result: r.Text}}
	case shell.ResultCursor:
		item.Value = &queravuev1.ResultItem_Cursor{Cursor: cursorHandle(r.Cursor)}
	}
	e.n++
	e.send(&queravuev1.EvalResponse{Event: &queravuev1.EvalResponse_Result{Result: item}})
}

func printLevel(l shell.Level) queravuev1.PrintLevel {
	switch l {
	case shell.LevelInfo:
		return queravuev1.PrintLevel_PRINT_LEVEL_INFO
	case shell.LevelWarn:
		return queravuev1.PrintLevel_PRINT_LEVEL_WARN
	case shell.LevelError:
		return queravuev1.PrintLevel_PRINT_LEVEL_ERROR
	}
	return queravuev1.PrintLevel_PRINT_LEVEL_LOG
}

func cursorHandle(h *shell.Handle) *queravuev1.CursorHandle {
	kind := queravuev1.CursorKind_CURSOR_KIND_FIND
	if h.Spec.Kind == engine.CursorAggregate {
		kind = queravuev1.CursorKind_CURSOR_KIND_AGGREGATE
	}
	return &queravuev1.CursorHandle{
		CursorId: h.ID, Kind: kind, Database: h.Spec.Database, Collection: h.Spec.Collection,
		Filter: h.Spec.Filter, Sort: h.Spec.Sort, Projection: h.Spec.Projection,
		Skip: h.Spec.Skip, Limit: h.Spec.Limit, Pipeline: h.Spec.Pipeline,
	}
}

func shellErrorKind(k shell.ErrorKind) queravuev1.ShellErrorKind {
	switch k {
	case shell.KindSyntax:
		return queravuev1.ShellErrorKind_SHELL_ERROR_KIND_SYNTAX
	case shell.KindRuntime:
		return queravuev1.ShellErrorKind_SHELL_ERROR_KIND_RUNTIME
	case shell.KindConfirmationRequired:
		return queravuev1.ShellErrorKind_SHELL_ERROR_KIND_CONFIRMATION_REQUIRED
	case shell.KindOutputLimit:
		return queravuev1.ShellErrorKind_SHELL_ERROR_KIND_OUTPUT_LIMIT
	case shell.KindTimeout:
		return queravuev1.ShellErrorKind_SHELL_ERROR_KIND_TIMEOUT
	case shell.KindCanceled:
		return queravuev1.ShellErrorKind_SHELL_ERROR_KIND_CANCELED
	case shell.KindServer:
		return queravuev1.ShellErrorKind_SHELL_ERROR_KIND_SERVER
	case shell.KindUnsupported:
		return queravuev1.ShellErrorKind_SHELL_ERROR_KIND_UNSUPPORTED
	}
	return queravuev1.ShellErrorKind_SHELL_ERROR_KIND_UNSPECIFIED
}

func sendEval(stream queravuev1.ShellService_EvalServer, m *queravuev1.EvalResponse) error {
	if err := stream.Send(m); err != nil {
		return fmt.Errorf("shell: send: %w", err)
	}
	return nil
}

// Eval implements the RPC.
func (s *ShellService) Eval(req *queravuev1.EvalRequest, stream queravuev1.ShellService_EvalServer) error {
	o, err := s.lookup(req.GetShellId())
	if err != nil {
		return err
	}
	started := time.Now()
	sink := &evalSink{stream: stream}
	dur, evalErr := o.sh.Eval(stream.Context(), req.GetCode(), req.GetConfirmed(), sink)
	s.record(o, req.GetCode(), started, sink.n, evalErr)
	if sink.err != nil {
		return fmt.Errorf("shell: send: %w", sink.err)
	}
	if evalErr != nil {
		return sendEval(stream, &queravuev1.EvalResponse{Event: &queravuev1.EvalResponse_Error{Error: &queravuev1.ShellError{
			Kind: shellErrorKind(evalErr.Kind), Message: evalErr.Message, JsStack: evalErr.Stack,
			Line: uint32(evalErr.Line), Column: uint32(evalErr.Column), Operation: evalErr.Operation, //nolint:gosec // positions are small
		}}})
	}
	return sendEval(stream, &queravuev1.EvalResponse{Event: &queravuev1.EvalResponse_Done{Done: &queravuev1.EvalDone{Duration: durationpb.New(dur)}}})
}

func (s *ShellService) record(o *openShell, code string, start time.Time, n uint64, err *shell.Error) {
	if s.history == nil || strings.TrimSpace(code) == "" {
		return
	}
	e := history.Entry{ConnectionID: o.connID, QueryText: code, StartedAt: start, Duration: time.Since(start), RowsAffected: n}
	if err != nil && err.Kind != shell.KindConfirmationRequired {
		e.Error = err.Message
	}
	_, _ = s.history.Append(context.Background(), e)
}

// FetchCursor implements the RPC.
func (s *ShellService) FetchCursor(req *queravuev1.FetchCursorRequest, stream queravuev1.ShellService_FetchCursorServer) error {
	o, err := s.lookup(req.GetShellId())
	if err != nil {
		return err
	}
	ctx := stream.Context()
	err = o.sh.FetchCursor(ctx, req.GetCursorId(), req.GetSkip(), int(req.GetLimit()),
		func(offset uint64, docs []engine.Document, done bool) error {
			return stream.Send(&queravuev1.FetchCursorResponse{Batch: &queravuev1.DocumentBatch{
				Offset: offset, Documents: append([]string(nil), docs...), Done: done,
			}})
		})
	if err == nil {
		return nil
	}
	if ctx.Err() != nil {
		return status.FromContextError(ctx.Err()).Err()
	}
	var ee *engine.Error
	if errors.As(err, &ee) && ee.Kind == engine.KindNotFound {
		return status.Error(codes.NotFound, ee.Msg)
	}
	return grpcError(err)
}

// Cancel implements the RPC.
func (s *ShellService) Cancel(_ context.Context, req *queravuev1.ShellServiceCancelRequest) (*queravuev1.ShellServiceCancelResponse, error) {
	s.mu.Lock()
	o := s.shells[req.GetShellId()]
	s.mu.Unlock()
	if o != nil {
		o.sh.Cancel()
	}
	return &queravuev1.ShellServiceCancelResponse{}, nil
}

// CloseShell implements the RPC.
func (s *ShellService) CloseShell(_ context.Context, req *queravuev1.CloseShellRequest) (*queravuev1.CloseShellResponse, error) {
	s.mu.Lock()
	o := s.shells[req.GetShellId()]
	delete(s.shells, req.GetShellId())
	s.mu.Unlock()
	if o != nil {
		o.sh.Close()
	}
	return &queravuev1.CloseShellResponse{}, nil
}

// CloseSession closes the shells of a session that has ended, so their
// runtimes and cursors are freed at once instead of at the next shell call.
func (s *ShellService) CloseSession(sessionID string) {
	s.mu.Lock()
	defer s.mu.Unlock()
	for id, o := range s.shells {
		if o.sessionID == sessionID {
			o.sh.Close()
			delete(s.shells, id)
		}
	}
}

// Len returns the number of open shells.
func (s *ShellService) Len() int {
	s.mu.Lock()
	defer s.mu.Unlock()
	return len(s.shells)
}

// Shutdown closes every open shell.
func (s *ShellService) Shutdown() {
	s.mu.Lock()
	defer s.mu.Unlock()
	for id, o := range s.shells {
		o.sh.Close()
		delete(s.shells, id)
	}
}
