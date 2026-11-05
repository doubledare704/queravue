//go:build integration

package connections

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"github.com/google/uuid"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/engines"
	"github.com/doubledare704/queravue/core/internal/secrets"
)

// secretStore returns the real OS keychain when QUERAVUE_IT_KEYCHAIN=1,
// otherwise an in-memory store (CI machines have no unlocked keychain).
func secretStore() secrets.Store {
	if os.Getenv("QUERAVUE_IT_KEYCHAIN") == "1" {
		return secrets.Keyring{}
	}
	return secrets.NewMemory()
}

func getenv(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}

// Create, test, "restart" and re-test a Postgres and a SQLite connection,
// checking connections.json never contains the password.
func TestIntegrationSaveRestartReconnect(t *testing.T) {
	ctx := t.Context()
	dir := t.TempDir()
	sec := secretStore()
	reg, err := engines.Registry()
	if err != nil {
		t.Fatal(err)
	}
	svc := NewService(reg, NewFileStore(dir), sec)

	pgPW := getenv("PG_PASSWORD", "queravue")
	pg, err := svc.Create(ctx, Connection{
		Name: "Docker PG", EngineID: "postgres", Folder: "Dev", Color: ColorBlue,
		Params: map[string]string{
			"host": getenv("PG_HOST", "127.0.0.1"), "port": getenv("PG_PORT", "5432"),
			"user": getenv("PG_USER", "queravue"), "database": getenv("PG_DB", "queravue"),
			"sslmode": "disable",
		},
	}, &pgPW)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = sec.Delete(pg.SecretRef) })

	dbFile := filepath.Join(t.TempDir(), "local.db")
	sq, err := svc.Create(ctx, Connection{
		Name: "Local SQLite", EngineID: "sqlite",
		Params: map[string]string{"path": dbFile, "create_if_missing": "true"},
	}, nil)
	if err != nil {
		t.Fatal(err)
	}

	// The JSON file holds references only. Use a password that cannot collide
	// with other field values for the on-disk check.
	unique := "it-" + uuid.NewString()
	probe, err := svc.Create(ctx, Connection{Name: "probe", EngineID: "postgres", Params: map[string]string{"host": "h"}}, &unique)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = sec.Delete(probe.SecretRef) })
	raw, err := os.ReadFile(filepath.Join(dir, FileName))
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(raw), unique) || strings.Contains(string(raw), `"password"`) {
		t.Fatalf("connections.json contains a password:\n%s", raw)
	}

	// Restart: a fresh service over the same dir and keychain.
	svc2 := NewService(reg, NewFileStore(dir), sec)
	for _, c := range []Connection{pg, sq} {
		res, err := svc2.Test(ctx, TestRequest{ID: c.ID})
		if err != nil {
			t.Fatalf("%s: %v", c.Name, err)
		}
		if res.Err != nil {
			t.Fatalf("%s: %v", c.Name, res.Err)
		}
		if res.Server.Version == "" || res.Latency <= 0 {
			t.Errorf("%s: result = %+v", c.Name, res)
		}
		t.Logf("%s: %s %s, connect %s, ping %s", c.Name, res.Server.Product, res.Server.Version, res.Connect, res.Latency)
	}

	// A wrong password typed while editing is classified as auth.
	bad := "wrong-" + uuid.NewString()
	res, _ := svc2.Test(ctx, TestRequest{ID: pg.ID, Password: &bad})
	if res.Err == nil || res.Err.Kind != engine.KindAuth || strings.Contains(res.Err.Msg, bad) {
		t.Errorf("wrong password = %+v", res.Err)
	}

	if err := svc2.Delete(ctx, pg.ID); err != nil {
		t.Fatal(err)
	}
	if _, err := sec.Get(pg.SecretRef); err == nil {
		t.Error("keychain entry survived delete")
	}
}
