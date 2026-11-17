//go:build integration

package mongo

import (
	"context"
	"fmt"
	"os"
	"testing"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
	driver "go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"

	pb "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

func TestIntegrationGeneratedFilters(t *testing.T) {
	host := os.Getenv("MONGO_HOST")
	if host == "" {
		host = "127.0.0.1"
	}
	port := os.Getenv("MONGO_PORT")
	if port == "" {
		port = "27017"
	}
	client, err := driver.Connect(options.Client().ApplyURI("mongodb://" + host + ":" + port + "/?directConnection=true"))
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	defer func() { _ = client.Disconnect(context.Background()) }()
	db := client.Database(fmt.Sprintf("queravue_filter_builder_%d", time.Now().UnixNano()))
	defer func() { _ = db.Drop(context.Background()) }()
	coll := db.Collection("test")
	_, err = coll.InsertMany(ctx, []any{bson.D{{Key: "name", Value: "Ada"}, {Key: "age", Value: int32(30)}}, bson.D{{Key: "name", Value: "Bob"}, {Key: "age", Value: int32(10)}}})
	if err != nil {
		t.Fatal(err)
	}
	for _, tc := range []struct {
		op    pb.MongoOperator
		value string
		want  int64
	}{{pb.MongoOperator_MONGO_OPERATOR_GT, `{"$numberInt":"18"}`, 1}, {pb.MongoOperator_MONGO_OPERATOR_LTE, `{"$numberInt":"30"}`, 2}, {pb.MongoOperator_MONGO_OPERATOR_NE, `{"$numberInt":"10"}`, 1}} {
		t.Run(tc.op.String(), func(t *testing.T) {
			m := &pb.MongoFindModel{Filter: &pb.MongoCondition{Node: &pb.MongoCondition_Field{Field: &pb.MongoFieldCondition{Path: "age", Op: tc.op, ValueEjson: tc.value}}}}
			text, _, _, err := Generate(m)
			if err != nil {
				t.Fatal(err)
			}
			d, err := document(text)
			if err != nil {
				t.Fatal(err)
			}
			count, err := coll.CountDocuments(ctx, d)
			if err != nil || count != tc.want {
				t.Fatalf("count = %d, %v; want %d", count, err, tc.want)
			}
		})
	}
	t.Run("combined operators", func(t *testing.T) {
		model, err := Parse(`{"age":{"$gt":18,"$lt":40}}`, "", "")
		if err != nil {
			t.Fatal(err)
		}
		text, _, _, err := Generate(model)
		if err != nil {
			t.Fatal(err)
		}
		filter, err := document(text)
		if err != nil {
			t.Fatal(err)
		}
		count, err := coll.CountDocuments(ctx, filter)
		if err != nil || count != 1 {
			t.Fatalf("count = %d, %v; want 1", count, err)
		}
	})
}
