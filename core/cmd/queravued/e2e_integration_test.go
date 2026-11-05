//go:build integration

package main

import (
	"context"
	"io"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/google/uuid"
	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/metadata"

	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

// startCore runs the core in-process on a fresh socket with configDir and
// returns a ConnectionService client plus a stop func.
func startCore(parent context.Context, t *testing.T, configDir, secrets string) (queravuev1.ConnectionServiceClient, context.Context, func()) {
	t.Helper()
	sockDir, err := os.MkdirTemp("", "qv")
	if err != nil {
		t.Fatal(err)
	}
	sock := filepath.Join(sockDir, "core.sock")
	stdinR, stdinW := io.Pipe()
	done := make(chan error, 1)
	go func() {
		done <- run([]string{"--exit-on-stdin-eof", "--config-dir", configDir, "--secrets", secrets},
			env(map[string]string{"QUERAVUE_SOCKET": sock, "QUERAVUE_TOKEN": "tok"}), stdinR, io.Discard)
	}()
	waitForSocket(t, sock)
	cc, err := grpc.NewClient("unix://"+sock, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		t.Fatal(err)
	}
	ctx := metadata.AppendToOutgoingContext(parent, "authorization", "Bearer tok")
	stop := func() {
		_ = cc.Close()
		_ = stdinW.Close()
		select {
		case err := <-done:
			if err != nil {
				t.Errorf("run: %v", err)
			}
		case <-time.After(10 * time.Second):
			t.Error("core did not stop")
		}
		_ = os.RemoveAll(sockDir)
	}
	return queravuev1.NewConnectionServiceClient(cc), ctx, stop
}

// TestE2ESaveRestartReconnect covers the Iteration 1 exit criterion over real
// gRPC: create and test a Postgres and a SQLite connection, restart the core,
// reconnect both using the keychain, and check connections.json holds no
// password. Needs `make db-up` and QUERAVUE_IT_KEYCHAIN=1 (the password must
// survive a restart, so the in-memory store cannot be used).
func TestE2ESaveRestartReconnect(t *testing.T) {
	if os.Getenv("QUERAVUE_IT_KEYCHAIN") != "1" {
		t.Skip("set QUERAVUE_IT_KEYCHAIN=1 to use the real keychain")
	}
	configDir := t.TempDir()
	dbFile := filepath.Join(t.TempDir(), "local.db")
	pgPW := getenvOr("PG_PASSWORD", "queravue")

	client, ctx, stop := startCore(t.Context(), t, configDir, "keychain")
	pg, err := client.CreateConnection(ctx, &queravuev1.CreateConnectionRequest{
		Connection: &queravuev1.Connection{
			Name: "Docker PG", EngineId: "postgres", Folder: "Dev",
			Params: map[string]string{
				"host": getenvOr("PG_HOST", "127.0.0.1"), "port": getenvOr("PG_PORT", "5432"),
				"user": getenvOr("PG_USER", "queravue"), "database": getenvOr("PG_DB", "queravue"),
				"sslmode": "disable",
			},
		},
		Password: &pgPW,
	})
	if err != nil {
		t.Fatal(err)
	}
	pgID := pg.GetConnection().GetId()
	unique := "e2e-" + uuid.NewString()
	probe, err := client.CreateConnection(ctx, &queravuev1.CreateConnectionRequest{
		Connection: &queravuev1.Connection{Name: "probe", EngineId: "postgres", Params: map[string]string{"host": "h"}},
		Password:   &unique,
	})
	if err != nil {
		t.Fatal(err)
	}
	sq, err := client.CreateConnection(ctx, &queravuev1.CreateConnectionRequest{
		Connection: &queravuev1.Connection{
			Name: "Local SQLite", EngineId: "sqlite",
			Params: map[string]string{"path": dbFile, "create_if_missing": "true"},
		},
	})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() {
		// Remove keychain entries even if the test fails midway. t.Context()
		// is already cancelled when cleanups run.
		c, cctx, s := startCore(context.Background(), t, configDir, "keychain")
		for _, id := range []string{pgID, probe.GetConnection().GetId()} {
			if _, err := c.DeleteConnection(cctx, &queravuev1.DeleteConnectionRequest{Id: id}); err != nil {
				t.Errorf("cleanup delete %s: %v", id, err)
			}
		}
		s()
	})
	stop()

	raw, err := os.ReadFile(filepath.Join(configDir, "connections.json"))
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(raw), unique) || strings.Contains(string(raw), `"password"`) {
		t.Fatalf("connections.json contains a password:\n%s", raw)
	}

	// "Restart the app": a new core process state over the same config dir.
	client, ctx, stop = startCore(t.Context(), t, configDir, "keychain")
	defer stop()
	list, err := client.ListConnections(ctx, &queravuev1.ListConnectionsRequest{})
	if err != nil || len(list.GetConnections()) != 3 {
		t.Fatalf("list after restart = %v, %v", list, err)
	}
	for _, id := range []string{pgID, sq.GetConnection().GetId()} {
		res, err := client.TestConnection(ctx, &queravuev1.TestConnectionRequest{Id: id})
		if err != nil {
			t.Fatal(err)
		}
		if !res.GetOk() {
			t.Fatalf("reconnect %s: %v", id, res.GetError())
		}
		t.Logf("%s %s · connect %d ms · ping %d ms", res.GetServer().GetProduct(), res.GetServer().GetVersion(), res.GetConnectMs(), res.GetLatencyMs())
	}
}

func getenvOr(k, def string) string {
	if v := os.Getenv(k); v != "" {
		return v
	}
	return def
}
