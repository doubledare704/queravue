//go:build integration

package diagram_test

import (
	"context"
	"testing"
	"time"

	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"

	"github.com/doubledare704/queravue/core/internal/diagram"
	"github.com/doubledare704/queravue/core/internal/engine"
	mongoengine "github.com/doubledare704/queravue/core/internal/engine/mongo"
	"github.com/doubledare704/queravue/core/internal/session"
)

const libraryDB = "qv_it_diagram"

func mongoHostPort() string {
	return envOr("MONGO_HOST", "127.0.0.1") + ":" + envOr("MONGO_PORT", "27017")
}

type mongoOpener struct{}

func (mongoOpener) Open(ctx context.Context, _ string) (engine.Conn, engine.Descriptor, error) {
	e := mongoengine.New(mongoengine.VariantMongoDB)
	cfg := engine.Config{EngineID: mongoengine.ID, Params: map[string]string{
		mongoengine.ParamHosts: mongoHostPort(), mongoengine.ParamReplicaSet: "rs0", mongoengine.ParamDirect: "false",
		mongoengine.ParamDatabase: libraryDB,
	}}
	c, err := e.Connect(ctx, cfg, engine.Secret{})
	return c, e.Descriptor(), err
}

func seedLibrary(ctx context.Context, t *testing.T, store engine.DocumentStore) {
	t.Helper()
	client, err := mongo.Connect(options.Client().ApplyURI("mongodb://" + mongoHostPort() + "/?directConnection=true"))
	if err != nil {
		t.Fatal(err)
	}
	drop := func() { _ = client.Database(libraryDB).Drop(context.Background()) }
	drop()
	t.Cleanup(func() {
		drop()
		_ = client.Disconnect(context.Background())
	})
	insert := func(collection string, docs ...string) {
		if _, err := store.Insert(ctx, libraryDB, collection, docs, engine.WriteOptions{}); err != nil {
			t.Fatalf("insert into %s: %v", collection, err)
		}
	}
	insert("authors",
		`{"_id":{"$oid":"660000000000000000000001"},"name":"Le Guin"}`,
		`{"_id":{"$oid":"660000000000000000000002"},"name":"Lem","born":{"$numberInt":"1921"}}`)
	insert("books",
		`{"_id":"isbn-1","title":"The Dispossessed","authorId":{"$oid":"660000000000000000000001"}}`,
		`{"_id":"isbn-2","title":"Solaris","authorId":{"$oid":"660000000000000000000002"},"tags":["sf"]}`)
	insert("reviews",
		`{"book_id":"isbn-1","stars":{"$numberInt":"5"},"reviewer":{"_id":{"$oid":"660000000000000000000002"}}}`,
		`{"book_id":"isbn-2","stars":{"$numberInt":"4"},"authorId":"not-an-oid"}`)
}

func TestIntegrationMongoGraphIsInferredFromSamples(t *testing.T) {
	mgr := session.NewManager(mongoOpener{})
	t.Cleanup(mgr.Shutdown)
	sess, err := mgr.Open(context.Background(), "mongo")
	if err != nil {
		t.Fatalf("open: %v (docker compose -f dev/docker-compose.yml up -d --wait mongo)", err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	store, _ := engine.As[engine.DocumentStore](sess.Conn)
	seedLibrary(ctx, t, store)

	graph, err := diagram.Load(ctx, sess, diagram.Scope{Database: libraryDB, SampleSize: 50})
	if err != nil {
		t.Fatal(err)
	}
	byName := map[string]diagram.Table{}
	for _, tb := range graph.Tables {
		byName[tb.Name] = tb
	}
	books := byName["books"]
	if len(books.Columns) == 0 || books.Columns[0].Name != "_id" || books.Columns[0].TypeName != "string" || books.Columns[0].PrimaryKeyOrder != 1 {
		t.Errorf("books columns = %+v", books.Columns)
	}
	type edge struct{ column, to string }
	relations := func(tb diagram.Table) map[edge]float64 {
		out := map[edge]float64{}
		for _, r := range tb.Relations {
			if !r.Inferred {
				t.Errorf("%s: relation not marked inferred: %+v", tb.Name, r)
			}
			out[edge{r.Columns[0], r.ReferencedTable}] = r.Confidence
		}
		return out
	}
	if got := relations(books); len(got) != 1 || got[edge{"authorId", "authors"}] != 0.9 {
		t.Errorf("books relations = %v", got)
	}
	reviews := relations(byName["reviews"])
	if reviews[edge{"book_id", "books"}] != 0.6 {
		t.Errorf("reviews.book_id (string to string _id) = %v", reviews)
	}
	if _, ok := reviews[edge{"authorId", "authors"}]; ok {
		t.Error("a string authorId must not point at objectId _ids")
	}
	if len(byName["authors"].Relations) != 0 {
		t.Errorf("authors relations = %+v", byName["authors"].Relations)
	}
}

func TestIntegrationMongoGraphUsesTheDefaultDatabase(t *testing.T) {
	mgr := session.NewManager(mongoOpener{})
	t.Cleanup(mgr.Shutdown)
	sess, err := mgr.Open(context.Background(), "mongo")
	if err != nil {
		t.Fatalf("open: %v", err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	store, _ := engine.As[engine.DocumentStore](sess.Conn)
	seedLibrary(ctx, t, store)
	graph, err := diagram.Load(ctx, sess, diagram.Scope{})
	if err != nil || len(graph.Tables) != 3 {
		t.Fatalf("graph = %+v, %v", graph, err)
	}
}
