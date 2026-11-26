//go:build integration

package mongosql

import (
	"context"
	"fmt"
	"os"
	"testing"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
	mdb "go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"

	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

func envOrDefault(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}

func connectMongo(t *testing.T, databaseName string) *mdb.Database {
	t.Helper()
	uri := fmt.Sprintf("mongodb://%s:%s/?directConnection=true", envOrDefault("MONGO_HOST", "127.0.0.1"), envOrDefault("MONGO_PORT", "27017"))
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	client, err := mdb.Connect(options.Client().ApplyURI(uri))
	if err != nil {
		t.Fatalf("connect: %v", err)
	}
	if err := client.Ping(ctx, nil); err != nil {
		t.Fatalf("ping: %v (docker compose -f dev/docker-compose.yml up -d --wait mongo)", err)
	}
	db := client.Database(databaseName)
	if err := db.Drop(ctx); err != nil {
		t.Fatalf("drop %s: %v", databaseName, err)
	}
	t.Cleanup(func() {
		cleanup, cancel := context.WithTimeout(context.Background(), 20*time.Second)
		defer cancel()
		_ = db.Drop(cleanup)
		_ = client.Disconnect(cleanup)
	})
	return db
}

func runOnMongo(ctx context.Context, db *mdb.Database, resp *queravuev1.TranslateMongoSqlResponse) ([]bson.D, error) {
	collection := db.Collection(resp.GetCollection())
	if resp.GetKind() == queravuev1.MongoSqlResultKind_MONGO_SQL_RESULT_KIND_AGGREGATE {
		var wrapped struct {
			Stages []bson.D `bson:"stages"`
		}
		if err := bson.UnmarshalExtJSON([]byte(`{"stages":`+resp.GetPipelineEjson()+`}`), true, &wrapped); err != nil {
			return nil, fmt.Errorf("decode pipeline: %w", err)
		}
		cursor, err := collection.Aggregate(ctx, mdb.Pipeline(wrapped.Stages))
		if err != nil {
			return nil, fmt.Errorf("aggregate %s: %w", resp.GetPipelineEjson(), err)
		}
		var docs []bson.D
		return docs, cursor.All(ctx, &docs)
	}
	var filter, projection, sort bson.D
	for text, target := range map[string]*bson.D{resp.GetFilterEjson(): &filter, resp.GetProjectionEjson(): &projection, resp.GetSortEjson(): &sort} {
		if text == "" {
			continue
		}
		if err := bson.UnmarshalExtJSON([]byte(text), true, target); err != nil {
			return nil, fmt.Errorf("decode %s: %w", text, err)
		}
	}
	find := options.Find().SetSkip(int64(resp.GetSkip()))
	if projection != nil {
		find.SetProjection(projection)
	}
	if sort != nil {
		find.SetSort(sort)
	}
	if resp.Limit != nil {
		find.SetLimit(int64(*resp.Limit))
	}
	cursor, err := collection.Find(ctx, filter, find)
	if err != nil {
		return nil, fmt.Errorf("find: %w", err)
	}
	var docs []bson.D
	return docs, cursor.All(ctx, &docs)
}

func translateAndRun(t *testing.T, db *mdb.Database, sql string) ([]bson.D, *queravuev1.TranslateMongoSqlResponse) {
	t.Helper()
	resp := Translate(db.Name(), sql)
	if resp.GetError() != nil {
		t.Fatalf("translate %q: %v", sql, resp.GetError())
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()
	docs, err := runOnMongo(ctx, db, resp)
	if err != nil {
		t.Fatalf("run %q: %v", sql, err)
	}
	return docs, resp
}

func documentValue(doc bson.D, key string) (any, bool) {
	for _, e := range doc {
		if e.Key == key {
			return e.Value, true
		}
	}
	return nil, false
}
