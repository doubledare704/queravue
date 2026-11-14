//go:build integration

package oracle

import (
	"context"
	"errors"
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

type collected struct {
	cols []engine.Column
	rows [][]engine.Value
}

func (c *collected) Columns(cols []engine.Column) error { c.cols = cols; return nil }
func (c *collected) Batch(rows [][]engine.Value) error {
	for _, r := range rows {
		c.rows = append(c.rows, append([]engine.Value(nil), r...))
	}
	return nil
}

func connect(t *testing.T) engine.Executor {
	t.Helper()
	tg := target()
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	c, err := tg.Engine.Connect(ctx, tg.Config, tg.Secret)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = c.Close() })
	ex, _ := engine.As[engine.Executor](c)
	return ex
}

func TestIntegrationTypeSamples(t *testing.T) {
	ex := connect(t)
	out := &collected{}
	_, err := ex.Execute(context.Background(), engine.Statement{SQL: `SELECT "plain_number", "price", "d", "ts", "tstz", "tsltz", "iv_ds", "iv_ym", "big_text", "big_ntext", "blob_data", "raw_data", "bf", "bd", ROWID FROM "type_samples" WHERE "id" = 1`}, out)
	if err != nil {
		t.Fatal(err)
	}
	kinds := []engine.ValueKind{engine.VDecimal, engine.VDecimal, engine.VTimestamptz, engine.VTimestamptz, engine.VTimestamptz, engine.VTimestamptz,
		engine.VText, engine.VText, engine.VText, engine.VText, engine.VBytes, engine.VBytes, engine.VFloat, engine.VFloat, engine.VText}
	for i, want := range kinds {
		if out.cols[i].Kind != want {
			t.Errorf("column %s kind = %v, want %v", out.cols[i].Name, out.cols[i].Kind, want)
		}
	}
	row := out.rows[0]
	if row[0].Str != "3.14159265358979323846" || row[1].Str != "12345678.9012" {
		t.Errorf("numbers = %q, %q", row[0].Str, row[1].Str)
	}
	if got := row[2].Time.Format("2006-01-02 15:04:05"); got != "2026-01-02 00:00:00" {
		t.Errorf("date = %s", got)
	}
	if got := row[4].Time.Format("15:04:05.000 -07:00"); got != "03:04:05.678 +02:00" {
		t.Errorf("timestamp with time zone = %s", got)
	}
	if row[6].Str != "+04 05:06:07.089000" || row[7].Str != "+02-03" {
		t.Errorf("intervals = %q, %q", row[6].Str, row[7].Str)
	}
	if n := len([]rune(row[8].Str)); n != 10000 {
		t.Errorf("clob has %d characters, want 10000", n)
	}
	if len(row[10].Bytes) != 3 || row[10].Bytes[1] != 0xFF || len(row[11].Bytes) != 16 {
		t.Errorf("blob = %v, raw = %v", row[10].Bytes, row[11].Bytes)
	}
	if row[12].Float != 1.5 || row[13].Float != 2.25 {
		t.Errorf("binary floats = %v, %v", row[12].Float, row[13].Float)
	}
	if len(row[14].Str) != 18 {
		t.Errorf("rowid = %q", row[14].Str)
	}
}

func TestIntegrationPLSQLBlock(t *testing.T) {
	ex := connect(t)
	for _, block := range []string{
		"BEGIN\n  NULL;\nEND;\n/",
		"DECLARE n NUMBER; BEGIN n := 1; END;",
	} {
		if _, err := ex.Execute(context.Background(), engine.Statement{SQL: block}, &collected{}); err != nil {
			t.Errorf("%q: %v", block, err)
		}
	}
}

func TestIntegrationSyntaxErrorHasPosition(t *testing.T) {
	ex := connect(t)
	_, err := ex.Execute(context.Background(), engine.Statement{SQL: "SELECT nope FROM dual"}, &collected{})
	var ee *engine.Error
	if !errors.As(err, &ee) || ee.Kind != engine.KindSQL || ee.Code != 904 {
		t.Fatalf("err = %v, want ORA-00904 as a SQL error", err)
	}
	if ee.Position != 8 {
		t.Errorf("position = %d, want 8", ee.Position)
	}
}

func TestIntegrationCancelRunningStatement(t *testing.T) {
	ex := connect(t)
	for name, sql := range map[string]string{
		"PL/SQL busy loop": "BEGIN LOOP NULL; END LOOP; END;",
		"long DML":         `DELETE FROM "logs_no_pk" WHERE EXISTS (SELECT 1 FROM "million_items" a, "million_items" b WHERE a."val" + b."val" = -1)`,
		"query that computes before its first row": `SELECT COUNT(*) FROM "million_items" a, "million_items" b WHERE a."val" + b."val" = -1`,
	} {
		t.Run(name, func(t *testing.T) {
			ctx, cancel := context.WithTimeout(context.Background(), 600*time.Millisecond)
			defer cancel()
			started := time.Now()
			_, err := ex.Execute(ctx, engine.Statement{SQL: sql}, &collected{})
			took := time.Since(started)
			if engine.KindOf(err) != engine.KindCanceled {
				t.Fatalf("err = %v (kind %v), want canceled after %v", err, engine.KindOf(err), took)
			}
			t.Logf("cancelled after %v", took)
			if took > 10*time.Second {
				t.Errorf("cancel took %v", took)
			}
			out := &collected{}
			if _, err := ex.Execute(context.Background(), engine.Statement{SQL: "SELECT 1 FROM dual"}, out); err != nil || len(out.rows) != 1 {
				t.Errorf("session unusable after cancel: %v", err)
			}
		})
	}
}

func TestIntegrationTransactionControl(t *testing.T) {
	ex := connect(t)
	run := func(sql string) {
		t.Helper()
		if _, err := ex.Execute(context.Background(), engine.Statement{SQL: sql}, &collected{}); err != nil {
			t.Fatalf("%s: %v", sql, err)
		}
	}
	count := func() string {
		out := &collected{}
		if _, err := ex.Execute(context.Background(), engine.Statement{SQL: `SELECT COUNT(*) FROM "logs_no_pk"`}, out); err != nil {
			t.Fatal(err)
		}
		return out.rows[0][0].Str
	}
	before := count()
	run("SET TRANSACTION READ WRITE;")
	run(`INSERT INTO "logs_no_pk" ("level", "message") VALUES ('TX', 'rolled back')`)
	if count() == before {
		t.Error("the insert is invisible inside its own transaction")
	}
	run("ROLLBACK;")
	if got := count(); got != before {
		t.Errorf("after rollback count = %s, want %s", got, before)
	}
	run(`INSERT INTO "logs_no_pk" ("level", "message") VALUES ('TX', 'autocommitted')`)
	run(`DELETE FROM "logs_no_pk" WHERE "level" = 'TX'`)
	if got := count(); got != before {
		t.Errorf("after cleanup count = %s, want %s", got, before)
	}
}

func TestIntegrationSysdbaRole(t *testing.T) {
	tg := target()
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	c, err := tg.Engine.Connect(ctx, engine.Config{EngineID: ID, Params: map[string]string{
		ParamHost: env("ORACLE_HOST", "127.0.0.1"), ParamPort: env("ORACLE_PORT", "1521"),
		ParamService: tg.Database, ParamUser: "sys", ParamRole: RoleSysDBA,
	}}, engine.NewSecret(env("ORACLE_PASSWORD", "Queravue_dev1")))
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = c.Close() }()
	ex, _ := engine.As[engine.Executor](c)
	out := &collected{}
	if _, err := ex.Execute(ctx, engine.Statement{SQL: `SELECT SYS_CONTEXT('USERENV', 'SESSION_USER') FROM dual`}, out); err != nil || out.rows[0][0].Str != "SYS" {
		t.Errorf("session user = %v, err = %v", out.rows, err)
	}
	info, err := c.ServerInfo(ctx)
	if err != nil || info.Product != "Oracle Database" || info.Version == "" {
		t.Errorf("server info = %+v, %v", info, err)
	}
}

func TestIntegrationSystemSchemasHiddenByDefault(t *testing.T) {
	tg := target()
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	list := func(show string) []string {
		cfg := engine.Config{EngineID: ID, Params: map[string]string{}}
		for k, v := range tg.Config.Params {
			cfg.Params[k] = v
		}
		cfg.Params[ParamShowSystemSchema] = show
		c, err := tg.Engine.Connect(ctx, cfg, tg.Secret)
		if err != nil {
			t.Fatal(err)
		}
		defer func() { _ = c.Close() }()
		si, _ := engine.As[engine.SchemaInspector](c)
		schemas, err := si.ListSchemas(ctx, "")
		if err != nil {
			t.Fatal(err)
		}
		return schemas
	}
	hidden, shown := list("false"), list("true")
	has := func(ss []string, s string) bool {
		for _, x := range ss {
			if x == s {
				return true
			}
		}
		return false
	}
	if has(hidden, "SYS") || has(hidden, "SYSTEM") || !has(hidden, "QUERAVUE") {
		t.Errorf("default schemas = %v", hidden)
	}
	if !has(shown, "SYS") || len(shown) <= len(hidden) {
		t.Errorf("schemas with system ones = %v", shown)
	}
}
