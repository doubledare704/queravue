//go:build integration

package oracle

import (
	"context"
	"fmt"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/enginetest"
)

func env(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}

// Uses the oracle service from dev/docker-compose.yml; the seed loads on its
// first start. Override with ORACLE_HOST, ORACLE_PORT, ORACLE_SERVICE,
// ORACLE_USER, ORACLE_APP_PASSWORD.
func target() enginetest.Target {
	service := env("ORACLE_SERVICE", "FREEPDB1")
	user := env("ORACLE_USER", "queravue")
	return enginetest.Target{
		Engine: New(),
		Config: engine.Config{EngineID: ID, Params: map[string]string{
			ParamHost:    env("ORACLE_HOST", "127.0.0.1"),
			ParamPort:    env("ORACLE_PORT", "1521"),
			ParamService: service,
			ParamUser:    user,
		}},
		Secret:   engine.NewSecret(env("ORACLE_APP_PASSWORD", "queravue")),
		Product:  "Oracle Database",
		Database: service,
		Schema:   strings.ToUpper(user),
		Series: func(n int) string {
			return fmt.Sprintf(`SELECT "id" AS n FROM "million_items" WHERE "id" <= %d ORDER BY "id"`, n)
		},
		Ident: func(name string) string { return `"` + name + `"` },
	}
}

func TestIntegrationSuiteOracle(t *testing.T) {
	enginetest.Run(t, target())
}

func TestIntegrationBadPassword(t *testing.T) {
	tg := target()
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	_, err := tg.Engine.Connect(ctx, tg.Config, engine.NewSecret("wrong"))
	if engine.KindOf(err) != engine.KindAuth {
		t.Fatalf("err = %v, want auth", err)
	}
}

func TestIntegrationCrossSchemaForeignKey(t *testing.T) {
	tg := target()
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	admin, err := tg.Engine.Connect(ctx, engine.Config{EngineID: ID, Params: map[string]string{
		ParamHost: env("ORACLE_HOST", "127.0.0.1"), ParamPort: env("ORACLE_PORT", "1521"),
		ParamService: tg.Database, ParamUser: "sys", ParamRole: RoleSysDBA,
	}}, engine.NewSecret(env("ORACLE_PASSWORD", "Queravue_dev1")))
	if err != nil {
		t.Fatalf("connect as sysdba: %v", err)
	}
	t.Cleanup(func() { _ = admin.Close() })
	app, err := tg.Engine.Connect(ctx, tg.Config, tg.Secret)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = app.Close() })

	run := func(c engine.Conn, stmt string) {
		t.Helper()
		ex, _ := engine.As[engine.Executor](c)
		runCtx, stop := context.WithTimeout(context.Background(), 30*time.Second)
		defer stop()
		if _, err := ex.Execute(runCtx, engine.Statement{SQL: stmt}, discard{}); err != nil {
			t.Fatalf("%s: %v", stmt, err)
		}
	}
	cleanup := func() {
		run(admin, `DROP USER IF EXISTS "qv_it_ext" CASCADE`)
		run(app, `DROP TABLE IF EXISTS "qv_ext_child"`)
	}
	cleanup()
	t.Cleanup(cleanup)
	run(admin, `CREATE USER "qv_it_ext" NO AUTHENTICATION QUOTA UNLIMITED ON USERS`)
	run(admin, `CREATE TABLE "qv_it_ext"."qv_ext_parent" ("id" INT PRIMARY KEY)`)
	run(admin, `GRANT REFERENCES ON "qv_it_ext"."qv_ext_parent" TO `+tg.Schema)
	run(app, `CREATE TABLE "qv_ext_child" ("id" INT PRIMARY KEY, "parent_id" INT, CONSTRAINT "fk_qv_ext_other" FOREIGN KEY ("parent_id") REFERENCES "qv_it_ext"."qv_ext_parent" ("id"))`)

	lister, _ := engine.As[engine.RelationLister](app)
	relations, err := lister.ListRelations(ctx, tg.Database, tg.Schema)
	if err != nil {
		t.Fatal(err)
	}
	for _, r := range relations {
		if r.Table == "qv_ext_child" {
			if r.ReferencedSchema != "qv_it_ext" || r.ReferencedTable != "qv_ext_parent" {
				t.Errorf("relation = %+v, want a reference to qv_it_ext.qv_ext_parent", r)
			}
			return
		}
	}
	t.Error("qv_ext_child has no listed relation")
}

type discard struct{}

func (discard) Columns([]engine.Column) error { return nil }
func (discard) Batch([][]engine.Value) error  { return nil }
