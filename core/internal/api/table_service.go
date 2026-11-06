package api

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/durationpb"

	"github.com/doubledare704/queravue/core/internal/connections"
	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/history"
	"github.com/doubledare704/queravue/core/internal/results"
	"github.com/doubledare704/queravue/core/internal/session"
	"github.com/doubledare704/queravue/core/internal/sqlbuilder"
)

// TableService implements queravuev1.TableServiceServer.
type TableService struct {
	queravuev1.UnimplementedTableServiceServer

	sessions    *session.Manager
	results     *results.Manager
	connections *connections.Service
	history     *history.Store
	log         *slog.Logger
}

// NewTableService returns a TableService handler.
func NewTableService(s *session.Manager, r *results.Manager, c *connections.Service, h *history.Store, log *slog.Logger) *TableService {
	if log == nil {
		log = slog.Default()
	}
	return &TableService{
		sessions:    s,
		results:     r,
		connections: c,
		history:     h,
		log:         log,
	}
}

// OpenTable implements the RPC.
func (t *TableService) OpenTable(req *queravuev1.OpenTableRequest, stream queravuev1.TableService_OpenTableServer) error {
	sess, err := t.sessions.Get(req.GetSessionId())
	if err != nil {
		return status.Error(codes.NotFound, "session not found")
	}

	ex, ok := engine.As[engine.Executor](sess.Conn)
	if !ok {
		return status.Error(codes.FailedPrecondition, "connection cannot execute statements")
	}

	dialect := sqlbuilder.DialectPostgres
	if sess.Desc.Family == "sqlite" {
		dialect = sqlbuilder.DialectSQLite
	}

	sqlText, params, err := sqlbuilder.BuildSelect(dialect, req.GetTableRef(), req.GetFilter(), req.GetSort(), req.GetPageSize())
	if err != nil {
		return status.Errorf(codes.InvalidArgument, "build select query: %v", err)
	}

	ctx, finish, err := sess.Begin(stream.Context())
	switch {
	case errors.Is(err, session.ErrBusy):
		return status.Error(codes.FailedPrecondition, "session is busy running another statement")
	case err != nil:
		return status.Error(codes.NotFound, "session not found")
	}
	defer finish()

	id, spool, err := t.results.Create(sess.ID)
	if err != nil {
		t.log.Error("create spool", "err", err)
		return status.Error(codes.Internal, "could not create result spool")
	}

	send := func(event *queravuev1.ExecuteResponse) error {
		return stream.Send(&queravuev1.OpenTableResponse{
			Sql:   sqlText,
			Event: event,
		})
	}

	if err := send(&queravuev1.ExecuteResponse{Event: &queravuev1.ExecuteResponse_Started{
		Started: &queravuev1.StatementStarted{StatementIndex: 0, ResultId: id},
	}}); err != nil {
		t.results.Close(id)
		return err
	}

	sink := &tableStreamSink{
		stream:       stream,
		spool:        spool,
		sqlText:      sqlText,
		lastProgress: time.Now(),
	}

	sum, execErr := ex.Execute(ctx, engine.Statement{SQL: sqlText, Params: params}, sink)
	if sink.sendErr != nil {
		return sink.sendErr
	}

	if err := spool.Finish(); err != nil && execErr == nil {
		execErr = err
	}

	rows, _, truncated := spool.State()

	// Record execution in query history
	if t.history != nil {
		var errStr string
		if execErr != nil {
			errStr = execErr.Error()
		}
		_, _ = t.history.Append(context.Background(), history.Entry{
			ConnectionID: sess.ConnectionID,
			QueryText:    sqlText,
			StartedAt:    time.Now().Add(-sum.Duration),
			Duration:     sum.Duration,
			RowsAffected: rows,
			Error:        errStr,
		})
	}

	if execErr != nil {
		if stream.Context().Err() != nil {
			return status.FromContextError(stream.Context().Err()).Err()
		}
		kind, msg := queravuev1.QueryErrorKind_QUERY_ERROR_KIND_UNSPECIFIED, "query failed"
		var ee *engine.Error
		if errors.As(execErr, &ee) {
			kind, msg = queryKind(ee.Kind), ee.Msg
		}
		return send(errEvent(0, kind, msg, nil, sum.Duration))
	}

	if err := send(&queravuev1.ExecuteResponse{Event: &queravuev1.ExecuteResponse_Progress{
		Progress: &queravuev1.Progress{StatementIndex: 0, RowsSpooled: rows, Done: true},
	}}); err != nil {
		return err
	}

	return send(&queravuev1.ExecuteResponse{Event: &queravuev1.ExecuteResponse_Summary{
		Summary: &queravuev1.Summary{
			StatementIndex: 0,
			RowsAffected:   0,
			RowsSpooled:    rows,
			Duration:       durationpb.New(sum.Duration),
			Notices:        sum.Notices,
			Truncated:      truncated,
			HasRows:        sum.HasRows,
		},
	}})
}

// ApplyChanges implements the RPC.
func (t *TableService) ApplyChanges(ctx context.Context, req *queravuev1.ApplyChangesRequest) (*queravuev1.ApplyChangesResponse, error) {
	sess, err := t.sessions.Get(req.GetSessionId())
	if err != nil {
		return nil, status.Error(codes.NotFound, "session not found")
	}

	ref := req.GetTableRef()
	if ref == nil || ref.GetTable() == "" {
		return nil, status.Error(codes.InvalidArgument, "table reference is required")
	}

	// 1. Verify table editability
	inspector, ok := engine.As[engine.SchemaInspector](sess.Conn)
	if !ok {
		return &queravuev1.ApplyChangesResponse{
			Success:      false,
			ErrorMessage: "engine does not support schema inspection",
		}, nil
	}

	details, err := inspector.DescribeTable(ctx, ref.GetDatabase(), ref.GetSchema(), ref.GetTable())
	if err != nil {
		return &queravuev1.ApplyChangesResponse{
			Success:      false,
			ErrorMessage: fmt.Sprintf("describe table: %v", err),
		}, nil
	}

	if !details.CanEdit {
		reason := details.EditDisabledReason
		if reason == "" {
			reason = "Table is read-only (no primary key or unique NOT NULL column)."
		}
		return &queravuev1.ApplyChangesResponse{
			Success:      false,
			ErrorMessage: reason,
		}, nil
	}

	// 2. Check production confirmation requirement
	if !req.GetDryRun() && t.connections != nil && sess.ConnectionID != "" {
		connProfile, err := t.connections.Get(ctx, sess.ConnectionID)
		if err == nil && connProfile.Production && !req.GetConfirmProduction() {
			return &queravuev1.ApplyChangesResponse{
				Success:      false,
				ErrorMessage: "This connection is flagged as production. Confirmation is required to apply changes.",
			}, nil
		}
	}

	// 3. Build SQL statements
	dialect := sqlbuilder.DialectPostgres
	if sess.Desc.Family == "sqlite" {
		dialect = sqlbuilder.DialectSQLite
	}

	plans, previewSQL, err := sqlbuilder.BuildApplyChanges(dialect, ref, req.GetChanges())
	if err != nil {
		return &queravuev1.ApplyChangesResponse{
			Success:      false,
			ErrorMessage: err.Error(),
		}, nil
	}

	// 4. Return preview on dry_run
	if req.GetDryRun() {
		return &queravuev1.ApplyChangesResponse{
			GeneratedSql: previewSQL,
			DryRun:       true,
			Success:      true,
		}, nil
	}

	// 5. Execute statements in a single transaction
	ex, ok := engine.As[engine.Executor](sess.Conn)
	if !ok {
		return &queravuev1.ApplyChangesResponse{
			Success:      false,
			ErrorMessage: "engine cannot execute statements",
		}, nil
	}

	sctx, finish, err := sess.Begin(ctx)
	if err != nil {
		return &queravuev1.ApplyChangesResponse{
			Success:      false,
			ErrorMessage: fmt.Sprintf("session begin: %v", err),
		}, nil
	}
	defer finish()

	var totalAffected int64
	startTime := time.Now()

	// Helper to rollback and record history on failure
	rollback := func(failErr error) (*queravuev1.ApplyChangesResponse, error) {
		_, _ = ex.Execute(sctx, engine.Statement{SQL: "ROLLBACK;"}, nilSink{})
		if t.history != nil {
			_, _ = t.history.Append(context.Background(), history.Entry{
				ConnectionID: sess.ConnectionID,
				QueryText:    previewSQL,
				StartedAt:    startTime,
				Duration:     time.Since(startTime),
				RowsAffected: 0,
				Error:        failErr.Error(),
			})
		}
		return &queravuev1.ApplyChangesResponse{
			GeneratedSql: previewSQL,
			Success:      false,
			ErrorMessage: fmt.Sprintf("%v (transaction rolled back)", failErr),
		}, nil
	}

	// Begin transaction
	if _, err := ex.Execute(sctx, engine.Statement{SQL: "BEGIN;"}, nilSink{}); err != nil {
		return rollback(fmt.Errorf("begin transaction: %w", err))
	}

	// Execute each statement
	for i, p := range plans {
		sum, err := ex.Execute(sctx, p.Statement, nilSink{})
		if err != nil {
			return rollback(fmt.Errorf("statement %d (%s): %w", i+1, p.PreviewSQL, err))
		}
		totalAffected += sum.RowsAffected
	}

	// Commit transaction
	if _, err := ex.Execute(sctx, engine.Statement{SQL: "COMMIT;"}, nilSink{}); err != nil {
		return rollback(fmt.Errorf("commit transaction: %w", err))
	}

	// Record success in history
	if t.history != nil {
		_, _ = t.history.Append(context.Background(), history.Entry{
			ConnectionID: sess.ConnectionID,
			QueryText:    previewSQL,
			StartedAt:    startTime,
			Duration:     time.Since(startTime),
			RowsAffected: uint64(totalAffected),
		})
	}

	return &queravuev1.ApplyChangesResponse{
		GeneratedSql: previewSQL,
		RowsAffected: uint64(totalAffected),
		Success:      true,
	}, nil
}

type nilSink struct{}

func (nilSink) Columns([]engine.Column) error { return nil }
func (nilSink) Batch([][]engine.Value) error  { return nil }

type tableStreamSink struct {
	stream       queravuev1.TableService_OpenTableServer
	spool        *results.Spool
	sqlText      string
	firstSent    bool
	lastProgress time.Time
	sendErr      error
}

func (s *tableStreamSink) send(ev *queravuev1.ExecuteResponse) error {
	if err := s.stream.Send(&queravuev1.OpenTableResponse{
		Sql:   s.sqlText,
		Event: ev,
	}); err != nil {
		s.sendErr = err
		return fmt.Errorf("send event: %w", err)
	}
	return nil
}

func (s *tableStreamSink) Columns(cols []engine.Column) error {
	pc := results.ColumnsToProto(cols)
	s.spool.SetColumns(pc)
	return s.send(&queravuev1.ExecuteResponse{Event: &queravuev1.ExecuteResponse_Columns{
		Columns: &queravuev1.Columns{StatementIndex: 0, Columns: pc},
	}})
}

func (s *tableStreamSink) Batch(batch [][]engine.Value) error {
	rows := results.RowsToProto(batch)
	appendErr := s.spool.Append(rows)
	if appendErr != nil && !errors.Is(appendErr, results.ErrFull) {
		return appendErr
	}
	if !s.firstSent {
		s.firstSent = true
		if err := s.send(&queravuev1.ExecuteResponse{Event: &queravuev1.ExecuteResponse_Rows{
			Rows: &queravuev1.RowsWindow{StatementIndex: 0, Offset: 0, Rows: rows},
		}}); err != nil {
			return err
		}
		s.lastProgress = time.Now()
	} else if time.Since(s.lastProgress) >= progressEvery {
		s.lastProgress = time.Now()
		if err := s.send(&queravuev1.ExecuteResponse{Event: &queravuev1.ExecuteResponse_Progress{
			Progress: &queravuev1.Progress{StatementIndex: 0, RowsSpooled: s.spool.Total()},
		}}); err != nil {
			return err
		}
	}
	if appendErr != nil {
		return engine.ErrStop
	}
	return nil
}
