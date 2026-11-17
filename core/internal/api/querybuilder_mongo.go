package api

import (
	"context"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

// GenerateMongoQuery implements queravuev1.QueryBuilderServiceServer.
func (q *QueryBuilderService) GenerateMongoQuery(_ context.Context, _ *queravuev1.GenerateMongoQueryRequest) (*queravuev1.GenerateMongoQueryResponse, error) {
	return nil, status.Error(codes.Unimplemented, "not implemented")
}

// ParseMongoQuery implements queravuev1.QueryBuilderServiceServer.
func (q *QueryBuilderService) ParseMongoQuery(_ context.Context, _ *queravuev1.ParseMongoQueryRequest) (*queravuev1.ParseMongoQueryResponse, error) {
	return nil, status.Error(codes.Unimplemented, "not implemented")
}
