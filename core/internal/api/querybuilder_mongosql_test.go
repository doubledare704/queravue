package api_test

import (
	"context"
	"testing"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

type fakeDocConnWithDefaultDB struct {
	fakeDocConn
	defaultDB string
}

func (f *fakeDocConnWithDefaultDB) DefaultDatabase() string { return f.defaultDB }

func TestQueryBuilderServiceTranslateMongoSql(t *testing.T) {
	ctx := context.Background()
	svc, sess := queryBuilderEnv(t, &fakeDocConnWithDefaultDB{defaultDB: "shop"})

	resp, err := svc.TranslateMongoSql(ctx, &queravuev1.TranslateMongoSqlRequest{
		SessionId: sess.ID,
		Sql:       "SELECT name FROM users WHERE age > 30 LIMIT 5",
	})
	if err != nil {
		t.Fatalf("TranslateMongoSql: %v", err)
	}
	if resp.GetError() != nil {
		t.Fatalf("unexpected error: %v", resp.GetError())
	}
	want := `db.getSiblingDB("shop").users.find({"age":{"$gt":{"$numberInt":"30"}}}, {"name":true,"_id":false}).limit(5)`
	if resp.GetKind() != queravuev1.MongoSqlResultKind_MONGO_SQL_RESULT_KIND_FIND || resp.GetDatabase() != "shop" ||
		resp.GetCollection() != "users" || resp.GetShellCode() != want || resp.GetLimit() != 5 || len(resp.GetWarnings()) != 1 {
		t.Errorf("response = %v, want a find on shop.users with shell code %s and one warning", resp, want)
	}

	explicit, err := svc.TranslateMongoSql(ctx, &queravuev1.TranslateMongoSqlRequest{SessionId: sess.ID, Database: "archive", Sql: "SELECT * FROM users"})
	if err != nil || explicit.GetDatabase() != "archive" {
		t.Errorf("explicit database = %v, %v, want archive", explicit, err)
	}

	unsupported, err := svc.TranslateMongoSql(ctx, &queravuev1.TranslateMongoSqlRequest{SessionId: sess.ID, Sql: "SELECT * FROM a JOIN b ON a.x = b.y"})
	if err != nil {
		t.Fatalf("TranslateMongoSql: %v", err)
	}
	if e := unsupported.GetError(); e.GetKind() != queravuev1.QueryBuilderErrorKind_QUERY_BUILDER_ERROR_KIND_UNSUPPORTED_CONSTRUCT || e.GetOffset() != 16 {
		t.Errorf("error = %v, want UNSUPPORTED_CONSTRUCT at 16", e)
	}
}

func TestQueryBuilderServiceTranslateMongoSqlRejects(t *testing.T) {
	ctx := context.Background()
	docSvc, docSess := queryBuilderEnv(t, &fakeDocConnWithDefaultDB{})
	sqlSvc, sqlSess := queryBuilderEnv(t, &fakeValidatingConn{})
	for _, tc := range []struct {
		name string
		call func() error
		want codes.Code
	}{
		{"missing session", func() error {
			_, err := docSvc.TranslateMongoSql(ctx, &queravuev1.TranslateMongoSqlRequest{SessionId: "missing"})
			return err
		}, codes.NotFound},
		{"no default database", func() error {
			_, err := docSvc.TranslateMongoSql(ctx, &queravuev1.TranslateMongoSqlRequest{SessionId: docSess.ID, Sql: "SELECT * FROM t"})
			return err
		}, codes.InvalidArgument},
		{"not a document store", func() error {
			_, err := sqlSvc.TranslateMongoSql(ctx, &queravuev1.TranslateMongoSqlRequest{SessionId: sqlSess.ID, Database: "db", Sql: "SELECT * FROM t"})
			return err
		}, codes.FailedPrecondition},
	} {
		t.Run(tc.name, func(t *testing.T) {
			if got := status.Code(tc.call()); got != tc.want {
				t.Errorf("code = %v, want %v", got, tc.want)
			}
		})
	}
}
