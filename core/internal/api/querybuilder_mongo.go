package api

import (
	"context"
	"encoding/json"
	"errors"
	"math"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/mongosql"
	"github.com/doubledare704/queravue/core/internal/querybuilder/mongo"
)

func (q *QueryBuilderService) GenerateMongoQuery(_ context.Context, req *queravuev1.GenerateMongoQueryRequest) (*queravuev1.GenerateMongoQueryResponse, error) { //nolint:revive // matches the service contract
	filter, projection, sort, err := mongo.Generate(req.GetModel())
	if err != nil {
		return &queravuev1.GenerateMongoQueryResponse{Error: &queravuev1.QueryBuilderError{Kind: queravuev1.QueryBuilderErrorKind_QUERY_BUILDER_ERROR_KIND_INVALID_MODEL, Message: err.Error()}}, nil
	}
	return &queravuev1.GenerateMongoQueryResponse{FilterEjson: filter, ProjectionEjson: projection, SortEjson: sort}, nil
}

func (q *QueryBuilderService) ParseMongoQuery(_ context.Context, req *queravuev1.ParseMongoQueryRequest) (*queravuev1.ParseMongoQueryResponse, error) { //nolint:revive // matches the service contract
	model, err := mongo.Parse(req.GetFilterEjson(), req.GetProjectionEjson(), req.GetSortEjson())
	if err != nil {
		kind := queravuev1.QueryBuilderErrorKind_QUERY_BUILDER_ERROR_KIND_PARSE
		if errors.Is(err, mongo.ErrUnsupported) {
			kind = queravuev1.QueryBuilderErrorKind_QUERY_BUILDER_ERROR_KIND_UNSUPPORTED_CONSTRUCT
		}
		var offset uint32
		var unsupported *mongo.UnsupportedError
		if errors.As(err, &unsupported) && unsupported.Offset >= 0 && int64(unsupported.Offset) <= math.MaxUint32 {
			offset = uint32(unsupported.Offset)
		}
		var syntax *json.SyntaxError
		if errors.As(err, &syntax) && syntax.Offset > 0 && syntax.Offset <= math.MaxUint32 {
			offset = uint32(syntax.Offset - 1)
		}
		return &queravuev1.ParseMongoQueryResponse{Error: &queravuev1.QueryBuilderError{Kind: kind, Message: err.Error(), Offset: &offset}}, nil
	}
	return &queravuev1.ParseMongoQueryResponse{Model: model}, nil
}

func (q *QueryBuilderService) TranslateMongoSql(_ context.Context, req *queravuev1.TranslateMongoSqlRequest) (*queravuev1.TranslateMongoSqlResponse, error) { //nolint:revive // matches the service contract
	sess, err := q.session(req.GetSessionId())
	if err != nil {
		return nil, err
	}
	if _, ok := engine.As[engine.DocumentStore](sess.Conn); !ok {
		return nil, status.Error(codes.FailedPrecondition, "connection is not a document store")
	}
	database := req.GetDatabase()
	if defaulter, ok := engine.As[engine.DefaultDatabaser](sess.Conn); ok && database == "" {
		database = defaulter.DefaultDatabase()
	}
	if database == "" {
		return nil, status.Error(codes.InvalidArgument, "no database: pass one or set a default database on the connection")
	}
	return mongosql.Translate(database, req.GetSql()), nil
}
