package api

import (
	"context"
	"errors"
	"log/slog"
	"strings"
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

// IndexService implements queravuev1.IndexServiceServer.
type IndexService struct {
	queravuev1.UnimplementedIndexServiceServer

	sessions    *session.Manager
	connections *connections.Service
	history     *history.Store
	cache       *schema.Cache
	log         *slog.Logger
}

// NewIndexService returns an IndexService handler.
func NewIndexService(s *session.Manager, c *connections.Service, h *history.Store, cache *schema.Cache, log *slog.Logger) *IndexService {
	if log == nil {
		log = slog.Default()
	}
	return &IndexService{sessions: s, connections: c, history: h, cache: cache, log: log}
}

func (i *IndexService) target(sessionID string, ref *queravuev1.TableRef) (*session.Session, error) {
	sess, err := i.sessions.Get(sessionID)
	if err != nil {
		return nil, status.Error(codes.NotFound, "session not found")
	}
	if ref.GetTable() == "" {
		return nil, status.Error(codes.InvalidArgument, "table reference is required")
	}
	return sess, nil
}

// ListIndexes implements the RPC.
func (i *IndexService) ListIndexes(ctx context.Context, req *queravuev1.ListIndexesRequest) (*queravuev1.ListIndexesResponse, error) {
	sess, err := i.target(req.GetSessionId(), req.GetTableRef())
	if err != nil {
		return nil, err
	}
	im, ok := engine.As[engine.IndexManager](sess.Conn)
	if !ok {
		return nil, status.Error(codes.FailedPrecondition, "connection cannot list indexes")
	}
	ref := req.GetTableRef()
	found, err := im.ListIndexes(ctx, ref.GetDatabase(), ref.GetSchema(), ref.GetTable())
	if err != nil {
		return &queravuev1.ListIndexesResponse{Error: toAdminError(err)}, nil
	}
	out := &queravuev1.ListIndexesResponse{Indexes: make([]*queravuev1.IndexInfo, 0, len(found))}
	for _, f := range found {
		out.Indexes = append(out.Indexes, indexInfoToProto(f))
	}
	return out, nil
}

// CreateIndex implements the RPC.
func (i *IndexService) CreateIndex(ctx context.Context, req *queravuev1.CreateIndexRequest) (*queravuev1.CreateIndexResponse, error) {
	sess, err := i.target(req.GetSessionId(), req.GetTableRef())
	if err != nil {
		return nil, err
	}
	ref := req.GetTableRef()
	spec := indexSpecFromProto(req.GetSpec())
	if spec.Name == "" && len(spec.Keys) > 0 && sess.Dialect != nil {
		spec.Name = sqldialect.DefaultIndexName(ref.GetTable(), spec.Keys)
	}
	if !req.GetDryRun() && !req.GetConfirmed() && isProduction(ctx, i.connections, sess) {
		return &queravuev1.CreateIndexResponse{Error: adminConfirmation("create index "+spec.Name,
			"This connection is flagged as production. Confirmation is required to create an index.")}, nil
	}

	if writer, ok := engine.As[engine.IndexWriter](sess.Conn); ok {
		started := time.Now()
		statement, name, err := writer.CreateIndex(ctx, ref.GetDatabase(), ref.GetSchema(), ref.GetTable(), spec, req.GetDryRun())
		if err != nil {
			i.record(sess, statement, started, req.GetDryRun(), err)
			return &queravuev1.CreateIndexResponse{Statement: statement, DryRun: req.GetDryRun(), Error: toAdminError(err)}, nil
		}
		i.finish(sess, ref, statement, started, req.GetDryRun())
		return &queravuev1.CreateIndexResponse{Statement: statement, DryRun: req.GetDryRun(), IndexName: name}, nil
	}

	if sess.Dialect == nil {
		return nil, status.Error(codes.FailedPrecondition, "connection cannot create indexes")
	}
	statement, warnings, err := sess.Dialect.CreateIndex(ref.GetDatabase(), ref.GetSchema(), ref.GetTable(), spec)
	if err != nil {
		return &queravuev1.CreateIndexResponse{DryRun: req.GetDryRun(), Error: adminInvalid(err.Error())}, nil
	}
	resp := &queravuev1.CreateIndexResponse{Statement: statement, DryRun: req.GetDryRun(), Warnings: warnings}
	if req.GetDryRun() {
		return resp, nil
	}
	if aerr := i.executeSQL(ctx, sess, ref, statement); aerr != nil {
		resp.Error = aerr
		return resp, nil
	}
	resp.IndexName = spec.Name
	return resp, nil
}

// DropIndex implements the RPC.
func (i *IndexService) DropIndex(ctx context.Context, req *queravuev1.DropIndexRequest) (*queravuev1.DropIndexResponse, error) {
	sess, err := i.target(req.GetSessionId(), req.GetTableRef())
	if err != nil {
		return nil, err
	}
	ref := req.GetTableRef()
	name := strings.TrimSpace(req.GetIndexName())
	if name == "" {
		return &queravuev1.DropIndexResponse{Error: adminInvalid("an index name is required")}, nil
	}
	if !req.GetDryRun() && !req.GetConfirmed() {
		return &queravuev1.DropIndexResponse{Error: adminConfirmation("drop index "+name,
			"Dropping an index can make queries slow until it is rebuilt. Confirmation is required.")}, nil
	}

	if writer, ok := engine.As[engine.IndexWriter](sess.Conn); ok {
		started := time.Now()
		statement, err := writer.DropIndex(ctx, ref.GetDatabase(), ref.GetSchema(), ref.GetTable(), name, req.GetDryRun())
		if err != nil {
			i.record(sess, statement, started, req.GetDryRun(), err)
			return &queravuev1.DropIndexResponse{Statement: statement, DryRun: req.GetDryRun(), Error: toAdminError(err)}, nil
		}
		i.finish(sess, ref, statement, started, req.GetDryRun())
		return &queravuev1.DropIndexResponse{Statement: statement, DryRun: req.GetDryRun()}, nil
	}

	if sess.Dialect == nil {
		return nil, status.Error(codes.FailedPrecondition, "connection cannot drop indexes")
	}
	statement := sess.Dialect.DropIndex(ref.GetDatabase(), ref.GetSchema(), ref.GetTable(), name)
	resp := &queravuev1.DropIndexResponse{Statement: statement, DryRun: req.GetDryRun()}
	if req.GetDryRun() {
		return resp, nil
	}
	if aerr := i.executeSQL(ctx, sess, ref, statement); aerr != nil {
		resp.Error = aerr
	}
	return resp, nil
}

func (i *IndexService) executeSQL(ctx context.Context, sess *session.Session, ref *queravuev1.TableRef, statement string) *queravuev1.AdminError {
	ex, ok := engine.As[engine.Executor](sess.Conn)
	if !ok {
		return &queravuev1.AdminError{Kind: queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_UNSUPPORTED, Message: "connection cannot execute statements"}
	}
	sctx, finish, err := sess.Begin(ctx)
	if err != nil {
		return toAdminError(err)
	}
	defer finish()
	started := time.Now()
	_, err = ex.Execute(sctx, engine.Statement{SQL: statement}, nilSink{})
	i.record(sess, statement, started, false, err)
	if err != nil {
		return toAdminError(err)
	}
	i.invalidate(sess, ref)
	return nil
}

func (i *IndexService) finish(sess *session.Session, ref *queravuev1.TableRef, statement string, started time.Time, dryRun bool) {
	if dryRun {
		return
	}
	i.record(sess, statement, started, false, nil)
	i.invalidate(sess, ref)
}

func (i *IndexService) invalidate(sess *session.Session, ref *queravuev1.TableRef) {
	if i.cache != nil {
		i.cache.Invalidate(sess.ID, ref)
	}
}

func (i *IndexService) record(sess *session.Session, statement string, started time.Time, dryRun bool, err error) {
	if i.history == nil || dryRun || statement == "" {
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
	_, _ = i.history.Append(context.Background(), e)
}

func indexSpecFromProto(p *queravuev1.IndexSpec) engine.IndexSpec {
	spec := engine.IndexSpec{
		Name: p.GetName(), Unique: p.GetUnique(), Method: p.GetMethod(), PartialPredicate: p.GetPartialPredicate(),
		IncludeColumns: p.GetIncludeColumns(), Options: p.GetOptions(),
	}
	for _, k := range p.GetKeys() {
		spec.Keys = append(spec.Keys, engine.IndexKey{Name: k.GetName(), Kind: indexKeyKindFromProto(k.GetKind()), IsExpression: k.GetIsExpression()})
	}
	return spec
}

func indexKeyKindFromProto(k queravuev1.IndexKeyKind) engine.IndexKeyKind {
	switch k {
	case queravuev1.IndexKeyKind_INDEX_KEY_KIND_DESCENDING:
		return engine.IndexKeyDescending
	case queravuev1.IndexKeyKind_INDEX_KEY_KIND_HASHED:
		return engine.IndexKeyHashed
	case queravuev1.IndexKeyKind_INDEX_KEY_KIND_TEXT:
		return engine.IndexKeyText
	case queravuev1.IndexKeyKind_INDEX_KEY_KIND_GEO_2DSPHERE:
		return engine.IndexKeyGeo2DSphere
	case queravuev1.IndexKeyKind_INDEX_KEY_KIND_UNSPECIFIED, queravuev1.IndexKeyKind_INDEX_KEY_KIND_ASCENDING:
		return engine.IndexKeyAscending
	}
	return engine.IndexKeyAscending
}

func indexKeyKindToProto(k engine.IndexKeyKind) queravuev1.IndexKeyKind {
	switch k {
	case engine.IndexKeyDescending:
		return queravuev1.IndexKeyKind_INDEX_KEY_KIND_DESCENDING
	case engine.IndexKeyHashed:
		return queravuev1.IndexKeyKind_INDEX_KEY_KIND_HASHED
	case engine.IndexKeyText:
		return queravuev1.IndexKeyKind_INDEX_KEY_KIND_TEXT
	case engine.IndexKeyGeo2DSphere:
		return queravuev1.IndexKeyKind_INDEX_KEY_KIND_GEO_2DSPHERE
	case engine.IndexKeyAscending:
		return queravuev1.IndexKeyKind_INDEX_KEY_KIND_ASCENDING
	}
	return queravuev1.IndexKeyKind_INDEX_KEY_KIND_ASCENDING
}

func indexInfoToProto(f engine.IndexInfo) *queravuev1.IndexInfo {
	spec := &queravuev1.IndexSpec{
		Name: f.Spec.Name, Unique: f.Spec.Unique, Method: f.Spec.Method, PartialPredicate: f.Spec.PartialPredicate,
		IncludeColumns: f.Spec.IncludeColumns, Options: f.Spec.Options,
	}
	for _, k := range f.Spec.Keys {
		spec.Keys = append(spec.Keys, &queravuev1.IndexKey{Name: k.Name, Kind: indexKeyKindToProto(k.Kind), IsExpression: k.IsExpression})
	}
	usage := &queravuev1.IndexUsage{Available: f.Usage.Available, Scans: f.Usage.Scans}
	if f.Usage.LastUsed != nil {
		ms := f.Usage.LastUsed.UnixMilli()
		usage.LastUsedUnixMs = &ms
	}
	if f.Usage.TrackingSince != nil {
		ms := f.Usage.TrackingSince.UnixMilli()
		usage.TrackingSinceUnixMs = &ms
	}
	return &queravuev1.IndexInfo{Spec: spec, IsPrimary: f.IsPrimary, SizeBytes: f.SizeBytes, Usage: usage}
}
