//go:build integration

// The suite lives in enginetest, which reaches dataformat and so this package:
// these tests must be an external package to avoid an import cycle.
package mongo_test

import (
	"context"
	"errors"
	"os"
	"strings"
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/enginetest"
	"github.com/doubledare704/queravue/core/internal/engine/mongo"
)

func env(key, def string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return def
}

func localConfig() engine.Config {
	host := env("MONGO_HOST", "127.0.0.1") + ":" + env("MONGO_PORT", "27017")
	return engine.Config{EngineID: mongo.ID, Params: map[string]string{
		mongo.ParamHosts: host, mongo.ParamReplicaSet: "rs0", mongo.ParamDirect: "false",
	}}
}

const codeNamespaceNotFound = 26

func dropCollection(ctx context.Context, conn engine.Conn, database, collection string) error {
	_, err := conn.(engine.ShellBackend).RunCommand(ctx, database, `{"drop":"`+collection+`"}`)
	var e *engine.Error
	if errors.As(err, &e) {
		msg := strings.ToLower(e.Msg)
		if e.Code == codeNamespaceNotFound || strings.Contains(msg, "not found") || strings.Contains(msg, "does not exist") {
			return nil
		}
	}
	return err
}

func TestIntegrationDocumentLoaderMongo(t *testing.T) {
	enginetest.RunDocumentLoader(t, enginetest.DocumentLoaderTarget{
		Engine:         mongo.New(mongo.VariantMongoDB),
		Config:         localConfig(),
		Database:       "queravue",
		DropCollection: dropCollection,
	})
}

func TestSmokeDocumentDBLoadDocuments(t *testing.T) {
	loadDocumentsSmoke(t, "QV_DOCDB_URI", mongo.VariantDocumentDB)
}

func TestSmokeCosmosDBLoadDocuments(t *testing.T) {
	loadDocumentsSmoke(t, "QV_COSMOS_URI", mongo.VariantCosmos)
}

func loadDocumentsSmoke(t *testing.T, envVar string, v mongo.Variant) {
	uri := env(envVar, "")
	if uri == "" {
		t.Skipf("%s not set", envVar)
	}
	e := mongo.New(v)
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
