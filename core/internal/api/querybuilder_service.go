package api

import (
	"context"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
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

// GenerateSql implements queravuev1.QueryBuilderServiceServer.
func (q *QueryBuilderService) GenerateSql(_ context.Context, _ *queravuev1.GenerateSqlRequest) (*queravuev1.GenerateSqlResponse, error) { //nolint:revive // matches generated QueryBuilderServiceServer
	return nil, status.Error(codes.Unimplemented, "not implemented")
}

// ParseSql implements queravuev1.QueryBuilderServiceServer.
func (q *QueryBuilderService) ParseSql(_ context.Context, _ *queravuev1.ParseSqlRequest) (*queravuev1.ParseSqlResponse, error) { //nolint:revive // matches generated QueryBuilderServiceServer
	return nil, status.Error(codes.Unimplemented, "not implemented")
}
