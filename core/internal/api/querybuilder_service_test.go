package api_test

import (
	"context"
	"testing"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/proto"

	"github.com/doubledare704/queravue/core/internal/api"
	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/session"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

type fakeSQLBuilderConn struct {
	fakeValidatingConn
	dialect sqldialect.Dialect
}

func (f *fakeSQLBuilderConn) Dialect() sqldialect.Dialect { return f.dialect }

func queryBuilderEnv(t *testing.T, conn engine.Conn) (*api.QueryBuilderService, *session.Session) {
	t.Helper()
	mgr := session.NewManager(fakeOpener{conn: conn})
	t.Cleanup(mgr.Shutdown)
	sess, err := mgr.Open(context.Background(), "qb-conn")
	if err != nil {
		t.Fatal(err)
	}
	return api.NewQueryBuilderService(mgr), sess
}

func TestQueryBuilderServiceGenerateAndParseSql(t *testing.T) {
	svc, sess := queryBuilderEnv(t, &fakeSQLBuilderConn{dialect: sqldialect.Postgres})
	model := &queravuev1.SqlQueryModel{
		From: &queravuev1.SqlTableRef{Schema: "public", Table: "orders", Alias: "o"},
		Select: []*queravuev1.SqlSelectItem{
			{Expression: &queravuev1.SqlSelectItem_Column{Column: &queravuev1.SqlColumnRef{TableAlias: "o", Column: "id"}}},
		},
		Limit: proto.Uint64(10),
	}

	genResp, err := svc.GenerateSql(context.Background(), &queravuev1.GenerateSqlRequest{
		SessionId: sess.ID,
		Model:     model,
	})
	if err != nil {
		t.Fatalf("GenerateSql: %v", err)
	}
	if genResp.GetError() != nil {
		t.Fatalf("unexpected error: %v", genResp.GetError())
	}
	wantSQL := `SELECT "o"."id" FROM "public"."orders" AS "o" LIMIT 10`
	if genResp.GetSql() != wantSQL {
		t.Fatalf("sql = %q, want %q", genResp.GetSql(), wantSQL)
	}

	parseResp, err := svc.ParseSql(context.Background(), &queravuev1.ParseSqlRequest{
		SessionId: sess.ID,
		Sql:       "-- header\n" + genResp.GetSql(),
	})
	if err != nil {
		t.Fatalf("ParseSql: %v", err)
	}
	if parseResp.GetError() != nil {
		t.Fatalf("unexpected parse error: %v", parseResp.GetError())
	}
	if !parseResp.GetCommentsDropped() {
		t.Errorf("comments_dropped = false, want true")
	}
	if !proto.Equal(parseResp.GetModel(), model) {
		t.Errorf("model mismatch:\ngot:  %v\nwant: %v", parseResp.GetModel(), model)
	}
}

func TestQueryBuilderServiceErrors(t *testing.T) {
	sqlSvc, sqlSess := queryBuilderEnv(t, &fakeSQLBuilderConn{dialect: sqldialect.Postgres})

	if _, err := sqlSvc.GenerateSql(context.Background(), &queravuev1.GenerateSqlRequest{SessionId: "missing"}); status.Code(err) != codes.NotFound {
		t.Errorf("missing session GenerateSql code = %v, want NotFound", status.Code(err))
	}
	if _, err := sqlSvc.ParseSql(context.Background(), &queravuev1.ParseSqlRequest{SessionId: "missing"}); status.Code(err) != codes.NotFound {
		t.Errorf("missing session ParseSql code = %v, want NotFound", status.Code(err))
	}

	parseResp, err := sqlSvc.ParseSql(context.Background(), &queravuev1.ParseSqlRequest{
		SessionId: sqlSess.ID,
		Sql:       "WITH x AS (SELECT 1) SELECT * FROM x",
	})
	if err != nil {
		t.Fatalf("ParseSql: %v", err)
	}
	if parseResp.GetError().GetKind() != queravuev1.QueryBuilderErrorKind_QUERY_BUILDER_ERROR_KIND_UNSUPPORTED_CONSTRUCT {
		t.Errorf("kind = %v, want UNSUPPORTED_CONSTRUCT", parseResp.GetError().GetKind())
	}

	nonSQLSvc, nonSQLSess := queryBuilderEnv(t, &fakeValidatingConn{})
	genNonSQL, err := nonSQLSvc.GenerateSql(context.Background(), &queravuev1.GenerateSqlRequest{
		SessionId: nonSQLSess.ID,
		Model:     &queravuev1.SqlQueryModel{From: &queravuev1.SqlTableRef{Table: "users"}},
	})
	if err != nil {
		t.Fatalf("GenerateSql non-SQL: %v", err)
	}
	if genNonSQL.GetError().GetKind() != queravuev1.QueryBuilderErrorKind_QUERY_BUILDER_ERROR_KIND_NOT_SQL {
		t.Errorf("kind = %v, want NOT_SQL", genNonSQL.GetError().GetKind())
	}

	parseNonSQL, err := nonSQLSvc.ParseSql(context.Background(), &queravuev1.ParseSqlRequest{
		SessionId: nonSQLSess.ID,
		Sql:       "SELECT * FROM users",
	})
	if err != nil {
		t.Fatalf("ParseSql non-SQL: %v", err)
	}
	if parseNonSQL.GetError().GetKind() != queravuev1.QueryBuilderErrorKind_QUERY_BUILDER_ERROR_KIND_NOT_SQL {
		t.Errorf("kind = %v, want NOT_SQL", parseNonSQL.GetError().GetKind())
	}

	generated, err := sqlSvc.GenerateMongoQuery(context.Background(), &queravuev1.GenerateMongoQueryRequest{Model: &queravuev1.MongoFindModel{}})
	if err != nil || generated.GetFilterEjson() != "{}" {
		t.Fatalf("GenerateMongoQuery = %v, %v", generated, err)
	}
	parsed, err := sqlSvc.ParseMongoQuery(context.Background(), &queravuev1.ParseMongoQueryRequest{FilterEjson: generated.GetFilterEjson()})
	if err != nil || parsed.GetModel() == nil {
		t.Fatalf("ParseMongoQuery = %v, %v", parsed, err)
	}
	for _, tc := range []struct {
		name    string
		request *queravuev1.ParseMongoQueryRequest
		kind    queravuev1.QueryBuilderErrorKind
	}{
		{"invalid JSON", &queravuev1.ParseMongoQueryRequest{FilterEjson: `{"x":}`}, queravuev1.QueryBuilderErrorKind_QUERY_BUILDER_ERROR_KIND_PARSE},
		{"unsupported projection", &queravuev1.ParseMongoQueryRequest{ProjectionEjson: `{"x":{"$slice":2}}`}, queravuev1.QueryBuilderErrorKind_QUERY_BUILDER_ERROR_KIND_UNSUPPORTED_CONSTRUCT},
		{"unsupported sort", &queravuev1.ParseMongoQueryRequest{SortEjson: `{"x":{"$meta":"textScore"}}`}, queravuev1.QueryBuilderErrorKind_QUERY_BUILDER_ERROR_KIND_UNSUPPORTED_CONSTRUCT},
	} {
		t.Run(tc.name, func(t *testing.T) {
			response, err := sqlSvc.ParseMongoQuery(context.Background(), tc.request)
			if err != nil || response.GetError().GetKind() != tc.kind {
				t.Fatalf("ParseMongoQuery = %v, %v", response, err)
			}
		})
	}
}
