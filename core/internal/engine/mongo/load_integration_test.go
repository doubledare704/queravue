//go:build integration

package mongo

import (
	"context"
	"strings"
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/enginetest"
)

func dropCollection(ctx context.Context, conn engine.Conn, database, collection string) error {
	client, err := conn.(*Conn).live("drop collection")
	if err != nil {
		return err
	}
	return client.Database(database).Collection(collection).Drop(ctx)
}

func TestIntegrationDocumentLoaderMongo(t *testing.T) {
	enginetest.RunDocumentLoader(t, enginetest.DocumentLoaderTarget{
		Engine:         New(VariantMongoDB),
		Config:         fieldsConfig(),
		Database:       "queravue",
		DropCollection: dropCollection,
	})
}

func TestSmokeDocumentDBLoadDocuments(t *testing.T) {
	loadDocumentsSmoke(t, "QV_DOCDB_URI", VariantDocumentDB)
}

func TestSmokeCosmosDBLoadDocuments(t *testing.T) {
	loadDocumentsSmoke(t, "QV_COSMOS_URI", VariantCosmos)
}

func loadDocumentsSmoke(t *testing.T, envVar string, v Variant) {
	uri := env(envVar, "")
	if uri == "" {
		t.Skipf("%s not set", envVar)
	}
	e := New(v)
	cfg, secret, err := e.ParseURI(uri)
	if err != nil {
		t.Fatalf("%s: %v", envVar, err)
	}
	enginetest.RunDocumentLoader(t, enginetest.DocumentLoaderTarget{
		Engine:         e,
		Config:         cfg,
		Secret:         secret,
		Database:       env(strings.Replace(envVar, "_URI", "_DB", 1), "queravue_smoke"),
		DropCollection: dropCollection,
	})
}
