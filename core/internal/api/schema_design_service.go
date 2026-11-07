package api

import (
	"context"
	"errors"
	"log/slog"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/doubledare704/queravue/core/internal/connections"
	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/history"
	"github.com/doubledare704/queravue/core/internal/schema"
	"github.com/doubledare704/queravue/core/internal/session"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

// DDLTransactionality is implemented by Conns whose DDL transactionality differs from their dialect's.
type DDLTransactionality interface {
	TransactionalDDL() bool
}

// SchemaDesignService implements queravuev1.SchemaDesignServiceServer.
type SchemaDesignService struct {
	queravuev1.UnimplementedSchemaDesignServiceServer

	sessions    *session.Manager
	connections *connections.Service
	history     *history.Store
	cache       *schema.Cache
	log         *slog.Logger
}

// NewSchemaDesignService returns a SchemaDesignService handler.
func NewSchemaDesignService(s *session.Manager, c *connections.Service, h *history.Store, cache *schema.Cache, log *slog.Logger) *SchemaDesignService {
	if log == nil {
		log = slog.Default()
	}
	return &SchemaDesignService{sessions: s, connections: c, history: h, cache: cache, log: log}
}

type designPlan struct {
	sess          *session.Session
	script        sqldialect.Script
	transactional bool
	destructive   bool
}

func (s *SchemaDesignService) plan(ctx context.Context, sessionID string, ref *queravuev1.TableRef, changes []*queravuev1.SchemaChange) (*designPlan, *queravuev1.AdminError, error) {
	sess, err := s.sessions.Get(sessionID)
	if err != nil {
		return nil, nil, status.Error(codes.NotFound, "session not found")
	}
	if ref.GetTable() == "" {
		return nil, nil, status.Error(codes.InvalidArgument, "table reference is required")
	}
	if sess.Dialect == nil {
		return nil, nil, status.Error(codes.FailedPrecondition, "connection cannot design tables")
	}
	converted := make([]sqldialect.Change, 0, len(changes))
	for _, c := range changes {
		ch, err := changeFromProto(c)
		if err != nil {
			return nil, adminInvalid(err.Error()), nil
		}
		converted = append(converted, ch)
	}
	target := sqldialect.Target{Database: ref.GetDatabase(), Schema: ref.GetSchema(), Table: ref.GetTable()}
	script, err := sqldialect.BuildDDL(sess.Dialect, target, s.currentTable(ctx, sess, ref, converted), converted)
	if err != nil {
		var unsupported *sqldialect.UnsupportedError
		if errors.As(err, &unsupported) {
			return nil, &queravuev1.AdminError{Kind: queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_UNSUPPORTED, Message: err.Error()}, nil
		}
		return nil, adminInvalid(err.Error()), nil
	}
	p := &designPlan{sess: sess, script: script, transactional: script.Transactional}
	if t, ok := engine.As[DDLTransactionality](sess.Conn); ok && !t.TransactionalDDL() {
		p.transactional = false
		if script.Transactional {
			p.script.Warnings = append(p.script.Warnings, "This server limits schema changes inside a transaction, so statements run one at a time. If one fails, the earlier ones stay applied.")
		}
	}
	for _, st := range script.Statements {
		p.destructive = p.destructive || st.Destructive
	}
	return p, nil, nil
}

func (s *SchemaDesignService) currentTable(ctx context.Context, sess *session.Session, ref *queravuev1.TableRef, changes []sqldialect.Change) *engine.TableDetails {
	if _, creating := changes[0].(sqldialect.CreateTable); creating {
		return nil
	}
	inspector, ok := engine.As[engine.SchemaInspector](sess.Conn)
	if !ok {
		return nil
	}
	details, err := inspector.DescribeTable(ctx, ref.GetDatabase(), ref.GetSchema(), ref.GetTable())
	if err != nil {
		return nil
	}
	return &details
}

// PreviewDDL implements the RPC.
func (s *SchemaDesignService) PreviewDDL(ctx context.Context, req *queravuev1.PreviewDDLRequest) (*queravuev1.PreviewDDLResponse, error) {
	if len(req.GetChanges()) == 0 {
		return &queravuev1.PreviewDDLResponse{Error: adminInvalid("no changes to preview")}, nil
	}
	p, aerr, err := s.plan(ctx, req.GetSessionId(), req.GetTableRef(), req.GetChanges())
	if err != nil {
		return nil, err
	}
	if aerr != nil {
		return &queravuev1.PreviewDDLResponse{Error: aerr}, nil
	}
	return &queravuev1.PreviewDDLResponse{Statements: statementsToProto(p.script.Statements), Warnings: p.script.Warnings, Transactional: p.transactional}, nil
}

// ApplyDDL implements the RPC.
func (s *SchemaDesignService) ApplyDDL(ctx context.Context, req *queravuev1.ApplyDDLRequest) (*queravuev1.ApplyDDLResponse, error) {
	if len(req.GetChanges()) == 0 {
		return &queravuev1.ApplyDDLResponse{Error: adminInvalid("no changes to apply")}, nil
	}
	p, aerr, err := s.plan(ctx, req.GetSessionId(), req.GetTableRef(), req.GetChanges())
	if err != nil {
		return nil, err
	}
	if aerr != nil {
		return &queravuev1.ApplyDDLResponse{Error: aerr}, nil
	}
	resp := &queravuev1.ApplyDDLResponse{Statements: statementsToProto(p.script.Statements), Transactional: p.transactional}
	if !req.GetConfirmed() {
		switch {
		case p.destructive:
			resp.Error = adminConfirmation("apply schema changes", "These changes can remove data or structure. Confirmation is required.")
			return resp, nil
		case isProduction(ctx, s.connections, p.sess):
			resp.Error = adminConfirmation("apply schema changes", "This connection is flagged as production. Confirmation is required to change its schema.")
			return resp, nil
		}
	}
	ex, ok := engine.As[engine.Executor](p.sess.Conn)
	if !ok {
		return nil, status.Error(codes.FailedPrecondition, "connection cannot execute statements")
	}
	sctx, finish, err := p.sess.Begin(ctx)
	if err != nil {
		resp.Error = toAdminError(err)
		return resp, nil
	}
	defer finish()

	ref := req.GetTableRef()
	if p.transactional {
		resp.ExecutedStatements, resp.Error = s.runInTransaction(sctx, ex, p)
	} else {
		resp.ExecutedStatements, resp.Error = s.runOneByOne(sctx, ex, p)
	}
	if resp.ExecutedStatements > 0 && s.cache != nil {
		s.cache.Invalidate(p.sess.ID, ref)
	}
	return resp, nil
}

func (s *SchemaDesignService) runInTransaction(ctx context.Context, ex engine.Executor, p *designPlan) (uint32, *queravuev1.AdminError) {
	if _, err := ex.Execute(ctx, engine.Statement{SQL: p.sess.Dialect.Begin()}, nilSink{}); err != nil {
		return 0, toAdminError(err)
	}
	for _, st := range p.script.Statements {
		started := time.Now()
		_, err := ex.Execute(ctx, engine.Statement{SQL: st.SQL}, nilSink{})
		s.record(p.sess, st.SQL, started, err)
		if err != nil {
			_, _ = ex.Execute(ctx, engine.Statement{SQL: "ROLLBACK;"}, nilSink{})
			return 0, toAdminError(err)
		}
	}
	if _, err := ex.Execute(ctx, engine.Statement{SQL: "COMMIT;"}, nilSink{}); err != nil {
		_, _ = ex.Execute(ctx, engine.Statement{SQL: "ROLLBACK;"}, nilSink{})
		return 0, toAdminError(err)
	}
	return uint32(len(p.script.Statements)), nil //nolint:gosec // statement count is small
}

func (s *SchemaDesignService) runOneByOne(ctx context.Context, ex engine.Executor, p *designPlan) (uint32, *queravuev1.AdminError) {
	var done uint32
	for _, st := range p.script.Statements {
		started := time.Now()
		_, err := ex.Execute(ctx, engine.Statement{SQL: st.SQL}, nilSink{})
		s.record(p.sess, st.SQL, started, err)
		if err != nil {
			return done, toAdminError(err)
		}
		done++
	}
	return done, nil
}

func (s *SchemaDesignService) record(sess *session.Session, statement string, started time.Time, err error) {
	if s.history == nil {
		return
	}
	e := history.Entry{ConnectionID: sess.ConnectionID, QueryText: statement, StartedAt: started, Duration: time.Since(started)}
	if err != nil {
		e.Error = "failed"
		var ee *engine.Error
		if errors.As(err, &ee) {
			e.Error = ee.Msg
		}
	}
	_, _ = s.history.Append(context.Background(), e)
}

func statementsToProto(in []sqldialect.Statement) []*queravuev1.DdlStatement {
	out := make([]*queravuev1.DdlStatement, len(in))
	for i, st := range in {
		out[i] = &queravuev1.DdlStatement{Sql: st.SQL, Destructive: st.Destructive, Summary: st.Summary}
	}
	return out
}
