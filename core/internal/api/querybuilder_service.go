package api

import (
	"context"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/querybuilder"
	"github.com/doubledare704/queravue/core/internal/session"
)

// QueryBuilderService implements queravuev1.QueryBuilderServiceServer.
type QueryBuilderService struct {
	queravuev1.UnimplementedQueryBuilderServiceServer

	sessions *session.Manager
}

// NewQueryBuilderService returns a QueryBuilderService backed by s.
func NewQueryBuilderService(s *session.Manager) *QueryBuilderService {
	return &QueryBuilderService{sessions: s}
}

func (q *QueryBuilderService) session(id string) (*session.Session, error) {
	sess, err := q.sessions.Get(id)
	if err != nil {
		return nil, status.Error(codes.NotFound, "session not found")
	}
	return sess, nil
}

// GenerateSql implements queravuev1.QueryBuilderServiceServer.
func (q *QueryBuilderService) GenerateSql(_ context.Context, req *queravuev1.GenerateSqlRequest) (*queravuev1.GenerateSqlResponse, error) { //nolint:revive // matches generated QueryBuilderServiceServer
	sess, err := q.session(req.GetSessionId())
	if err != nil {
		return nil, err
	}
	if sess.Dialect == nil {
		return &queravuev1.GenerateSqlResponse{
			Error: &queravuev1.QueryBuilderError{
				Kind:    queravuev1.QueryBuilderErrorKind_QUERY_BUILDER_ERROR_KIND_NOT_SQL,
				Message: "this connection does not use SQL",
			},
		}, nil
	}
	sql, qbErr := querybuilder.Generate(sess.Dialect, req.GetModel())
	if qbErr != nil {
		return &queravuev1.GenerateSqlResponse{Error: qbErr}, nil
	}
	return &queravuev1.GenerateSqlResponse{Sql: sql}, nil
}

// ParseSql implements queravuev1.QueryBuilderServiceServer.
func (q *QueryBuilderService) ParseSql(_ context.Context, req *queravuev1.ParseSqlRequest) (*queravuev1.ParseSqlResponse, error) { //nolint:revive // matches generated QueryBuilderServiceServer
	sess, err := q.session(req.GetSessionId())
	if err != nil {
		return nil, err
	}
	if sess.Dialect == nil {
		return &queravuev1.ParseSqlResponse{
			Error: &queravuev1.QueryBuilderError{
				Kind:    queravuev1.QueryBuilderErrorKind_QUERY_BUILDER_ERROR_KIND_NOT_SQL,
				Message: "this connection does not use SQL",
			},
		}, nil
	}
	model, commentsDropped, qbErr := querybuilder.Parse(sess.Dialect, req.GetSql())
	if qbErr != nil {
		return &queravuev1.ParseSqlResponse{CommentsDropped: commentsDropped, Error: qbErr}, nil
	}
	return &queravuev1.ParseSqlResponse{Model: model, CommentsDropped: commentsDropped}, nil
}
