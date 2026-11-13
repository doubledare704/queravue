//go:build integration

package postgres

import (
	"os"
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/enginetest"
)

func TestIntegrationSuitePostgres(t *testing.T) {
	params, secret := pgParams()
	e := New(VariantPostgres)
	enginetest.Run(t, enginetest.Target{
		Engine:      e,
		Config:      engine.Config{EngineID: IDPostgres, Params: params},
		Secret:      secret,
		Product:     "PostgreSQL",
		Database:    params[ParamDatabase],
		Schema:      "public",
		OtherSchema: postgresSchemas,
	})
}

// Uses the cockroachdb service from dev/docker-compose.yml, seeded with
// dev/seed/cockroachdb. Override with CRDB_HOST, CRDB_PORT, CRDB_USER,
// CRDB_PASSWORD, CRDB_DB.
func TestIntegrationSuiteCockroach(t *testing.T) {
	get := func(k, def string) string {
		if v := envOr(k); v != "" {
			return v
		}
		return def
	}
	e := New(VariantCockroach)
	db := get("CRDB_DB", "queravue")
	enginetest.Run(t, enginetest.Target{
		Engine: e,
		Config: engine.Config{EngineID: IDCockroach, Params: map[string]string{
			ParamHost:     get("CRDB_HOST", "127.0.0.1"),
			ParamPort:     get("CRDB_PORT", "26257"),
			ParamUser:     get("CRDB_USER", "root"),
			ParamDatabase: db,
			ParamSSLMode:  "disable",
		}},
		Secret:      engine.NewSecret(get("CRDB_PASSWORD", "")),
		Product:     "CockroachDB",
		Database:    db,
		Schema:      "public",
		OtherSchema: postgresSchemas,
	})
}

func envOr(k string) string { return os.Getenv(k) }

var postgresSchemas = &enginetest.SchemaFixture{
	Create: func(name string) []string { return []string{"CREATE SCHEMA " + name} },
	Drop:   func(name string) []string { return []string{"DROP SCHEMA IF EXISTS " + name + " CASCADE"} },
}
