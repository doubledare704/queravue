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
	refs          []*queravuev1.TableRef
}

func (s *SchemaDesignService) designSession(sessionID string) (*session.Session, error) {
	sess, err := s.sessions.Get(sessionID)
	if err != nil {
		return nil, status.Error(codes.NotFound, "session not found")
	}
	if sess.Dialect == nil {
		return nil, status.Error(codes.FailedPrecondition, "connection cannot design tables")
	}
	return sess, nil
}

func convertChanges(changes []*queravuev1.SchemaChange) ([]sqldialect.Change, error) {
	converted := make([]sqldialect.Change, 0, len(changes))
	for _, c := range changes {
		ch, err := changeFromProto(c)
		if err != nil {
			return nil, err
		}
		converted = append(converted, ch)
	}
	return converted, nil
}

func scriptError(err error) *queravuev1.AdminError {
	var unsupported *sqldialect.UnsupportedError
	if errors.As(err, &unsupported) {
		return &queravuev1.AdminError{Kind: queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_UNSUPPORTED, Message: err.Error()}
	}
	return adminInvalid(err.Error())
}

func (s *SchemaDesignService) plan(ctx context.Context, sessionID string, ref *queravuev1.TableRef, changes []*queravuev1.SchemaChange) (*designPlan, *queravuev1.AdminError, error) {
	sess, err := s.designSession(sessionID)
	if err != nil {
		return nil, nil, err
	}
	if ref.GetTable() == "" {
		return nil, nil, status.Error(codes.InvalidArgument, "table reference is required")
	}
	converted, err := convertChanges(changes)
	if err != nil {
		return nil, adminInvalid(err.Error()), nil
	}
	script, err := sqldialect.BuildDDL(sess.Dialect, targetOf(ref), s.currentTable(ctx, sess, ref, converted), converted)
	if err != nil {
		return nil, scriptError(err), nil
	}
	return s.finishPlan(sess, script, []*queravuev1.TableRef{ref}), nil, nil
}

func (s *SchemaDesignService) planTables(ctx context.Context, sessionID string, tables []*queravuev1.TableChanges) (*designPlan, *queravuev1.AdminError, error) {
	sess, err := s.designSession(sessionID)
	if err != nil {
		return nil, nil, err
	}
	converted := make([]sqldialect.TableChanges, 0, len(tables))
	refs := make([]*queravuev1.TableRef, 0, len(tables))
	for _, t := range tables {
		changes, err := convertChanges(t.GetChanges())
		if err != nil {
			return nil, adminInvalid(t.GetTableRef().GetTable() + ": " + err.Error()), nil
		}
		tc := sqldialect.TableChanges{Target: targetOf(t.GetTableRef()), Changes: changes}
		if len(changes) > 0 && t.GetTableRef().GetTable() != "" {
			tc.Current = s.currentTable(ctx, sess, t.GetTableRef(), changes)
		}
		converted = append(converted, tc)
		refs = append(refs, t.GetTableRef())
	}
	script, err := sqldialect.BuildDiagramDDL(sess.Dialect, converted)
	if err != nil {
		return nil, scriptError(err), nil
	}
	return s.finishPlan(sess, script, refs), nil, nil
}

func targetOf(ref *queravuev1.TableRef) sqldialect.Target {
	return sqldialect.Target{Database: ref.GetDatabase(), Schema: ref.GetSchema(), Table: ref.GetTable()}
}

func (s *SchemaDesignService) finishPlan(sess *session.Session, script sqldialect.Script, refs []*queravuev1.TableRef) *designPlan {
	p := &designPlan{sess: sess, script: script, transactional: script.Transactional, refs: refs}
	if t, ok := engine.As[DDLTransactionality](sess.Conn); ok && !t.TransactionalDDL() {
		p.transactional = false
		if script.Transactional {
			p.script.Warnings = append(p.script.Warnings, "This server limits schema changes inside a transaction, so statements run one at a time. If one fails, the earlier ones stay applied.")
		}
	}
	for _, st := range script.Statements {
		p.destructive = p.destructive || st.Destructive
	}
	return p
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
	executed, transactional, aerr := s.run(ctx, p, req.GetConfirmed())
	return &queravuev1.ApplyDDLResponse{Statements: statementsToProto(p.script.Statements), ExecutedStatements: executed, Transactional: transactional, Error: aerr}, nil
}

func (s *SchemaDesignService) run(ctx context.Context, p *designPlan, confirmed bool) (uint32, bool, *queravuev1.AdminError) {
	if !confirmed {
		switch {
		case p.destructive:
			return 0, p.transactional, adminConfirmation("apply schema changes", "These changes can remove data or structure. Confirmation is required.")
		case isProduction(ctx, s.connections, p.sess):
			return 0, p.transactional, adminConfirmation("apply schema changes", "This connection is flagged as production. Confirmation is required to change its schema.")
		}
	}
	ex, ok := engine.As[engine.Executor](p.sess.Conn)
	if !ok {
		return 0, p.transactional, adminErr(queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_UNSUPPORTED, "connection cannot execute statements")
	}
	sctx, finish, err := p.sess.Begin(ctx)
	if err != nil {
		return 0, p.transactional, toAdminError(err)
	}
	defer finish()

	var executed uint32
	var aerr *queravuev1.AdminError
	if p.transactional {
		executed, aerr = s.runInTransaction(sctx, ex, p)
	} else {
		executed, aerr = s.runOneByOne(sctx, ex, p)
	}
	if executed > 0 && s.cache != nil {
		for _, ref := range p.refs {
			s.cache.Invalidate(p.sess.ID, ref)
		}
	}
	return executed, p.transactional, aerr
}

// PreviewDiagramDDL returns the ordered DDL for changes to several tables.
func (s *SchemaDesignService) PreviewDiagramDDL(ctx context.Context, req *queravuev1.PreviewDiagramDDLRequest) (*queravuev1.PreviewDiagramDDLResponse, error) {
	p, aerr, err := s.planTables(ctx, req.GetSessionId(), req.GetTables())
	if err != nil {
		return nil, err
	}
	if aerr != nil {
		return &queravuev1.PreviewDiagramDDLResponse{Error: aerr}, nil
	}
	return &queravuev1.PreviewDiagramDDLResponse{Statements: statementsToProto(p.script.Statements), Warnings: p.script.Warnings, Transactional: p.transactional}, nil
}

// ApplyDiagramDDL runs the ordered DDL for changes to several tables.
func (s *SchemaDesignService) ApplyDiagramDDL(ctx context.Context, req *queravuev1.ApplyDiagramDDLRequest) (*queravuev1.ApplyDiagramDDLResponse, error) {
	p, aerr, err := s.planTables(ctx, req.GetSessionId(), req.GetTables())
	if err != nil {
		return nil, err
	}
	if aerr != nil {
		return &queravuev1.ApplyDiagramDDLResponse{Error: aerr}, nil
	}
	executed, transactional, aerr := s.run(ctx, p, req.GetConfirmed())
	return &queravuev1.ApplyDiagramDDLResponse{Statements: statementsToProto(p.script.Statements), ExecutedStatements: executed, Transactional: transactional, Error: aerr}, nil
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
