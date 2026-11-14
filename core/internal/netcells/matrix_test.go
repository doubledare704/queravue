//go:build integration

package netcells

import (
	"context"
	"errors"
	"fmt"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/connections"
	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/netpath"
)

const matrixItems = 10_000

type matrixEngine struct {
	id, port, user, password, database, query string
}

func TestConnectivityMatrix(t *testing.T) {
	name, path := os.Getenv("QV_MATRIX_ENGINE"), os.Getenv("QV_MATRIX_PATH")
	if name == "" {
		t.Skip("select a cell with QV_MATRIX_ENGINE and QV_MATRIX_PATH")
	}
	engines := map[string]matrixEngine{
		"postgres":      {"postgres", "5432", "queravue", "queravue", "queravue", "SELECT generate_series(1, 10000)"},
		"cockroachdb":   {"cockroachdb", "26257", "root", "", "defaultdb", "SELECT generate_series(1, 10000)"},
		"mysql":         {"mysql", "3306", "queravue", "queravue", "queravue", digitQuery},
		"mariadb":       {"mariadb", "3306", "queravue", "queravue", "queravue", digitQuery},
		"tidb":          {"tidb", "4000", "root", "", "test", digitQuery},
		"mssql":         {"mssql", "1433", "sa", "Queravue_dev1", "master", digitQuery},
		"oracle":        {"oracle", "1521", "queravue", "queravue", "", "SELECT LEVEL FROM dual CONNECT BY LEVEL <= 10000"},
		"clickhouse":    {"clickhouse", "9000", "queravue", "queravue", "queravue", "SELECT number FROM numbers(10000)"},
		"mongo":         {"mongodb", "27017", "", "", "", ""},
		"documentdb":    {"documentdb", "10260", "queravue", "Queravue_dev1", "", ""},
		"redis":         {"redis", "6379", "", "queravue", "", ""},
		"redis-cluster": {"redis", "7100", "", "", "", ""},
		"valkey":        {"valkey", "6379", "", "queravue", "", ""},
		"sqlite":        {id: "sqlite", query: "WITH RECURSIVE seq(n) AS (SELECT 1 UNION ALL SELECT n+1 FROM seq WHERE n<10000) SELECT n FROM seq"},
		"duckdb":        {id: "duckdb", query: "SELECT range FROM range(10000)"},
	}
	e, ok := engines[name]
	if !ok {
		t.Fatalf("unknown matrix engine %q", name)
	}
	if path != "direct" && path != "tls" && path != "ssh" {
		t.Fatalf("unknown matrix path %q", path)
	}
	if e.port == "" && path != "direct" {
		t.Skip("n/a: file engine")
	}
	host, port := "localhost", os.Getenv("QV_MATRIX_PORT")
	if path == "ssh" {
		host, port = name, e.port
	}
	if e.port != "" && port == "" {
		t.Fatal("QV_MATRIX_PORT must name the published database port")
	}

	draft := connections.Connection{Name: name, EngineID: e.id}
	sec := connections.Secrets{Password: str(e.password)}
	if e.port == "" {
		draft.Params = map[string]string{"path": filepath.Join(t.TempDir(), name+".db"), "create_if_missing": "true"}
	} else {
		draft.TLS = &connections.TLSSettings{Mode: netpath.TLSDisable}
		if path == "tls" {
			draft.TLS = tlsFiles(netpath.TLSVerifyFull)
			if name == "cockroachdb" {
				draft.TLS.ClientCertFile = filepath.Join(tlsDir, "cockroach", "client.root.crt")
				draft.TLS.ClientKeyFile = filepath.Join(tlsDir, "cockroach", "client.root.key")
			}
		}
		if name == "mssql" && path != "tls" {
			// SQL Server encrypts the login packet even when data encryption is optional.
			draft.TLS = &connections.TLSSettings{Mode: netpath.TLSPrefer}
		}
		if path == "ssh" {
			if os.Getenv("QV_MATRIX_SSH_PORT") == "" {
				t.Fatal("QV_MATRIX_SSH_PORT must name the published bastion port")
			}
			draft.SSH = bastion(netpath.SSHAuthPassword)
			sec.SSH.Password = str(bastionPass)
		}
		draft.Params = matrixParams(name, host, port, e)
	}

	svc := newService(t)
	result := testTrusting(t, svc, connections.TestRequest{Draft: &draft, Secrets: sec, Password: sec.Password, Timeout: 30 * time.Second})
	if result.Err != nil {
		t.Fatalf("connection test failed: %v (steps %+v)", result.Err, result.Steps)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()
	profile, err := svc.CreateWith(ctx, draft, sec)
	if err != nil {
		t.Fatal(err)
	}
	conn, _, release, err := svc.OpenReleasing(ctx, profile.ID)
	if err != nil {
		t.Fatal(err)
	}
	defer func() {
		_ = conn.Close()
		if release != nil {
			release()
		}
	}()
	if err := conn.Ping(ctx); err != nil {
		t.Fatalf("ping: %v", err)
	}
	stream := matrixStream(ctx, t, conn, e.query)
	n := 0
	if err := stream(ctx, func(count int) { n += count }); err != nil || n != matrixItems {
		t.Fatalf("streamed %d of %d items: %v", n, matrixItems, err)
	}

	op, stop := context.WithCancel(ctx)
	defer stop()
	n = 0
	err = stream(op, func(count int) {
		n += count
		stop()
	})
	if (engine.KindOf(err) != engine.KindCanceled && !errors.Is(err, context.Canceled)) || n <= 0 || n >= matrixItems {
		t.Fatalf("cancel after %d items: %v", n, err)
	}
	// Some drivers discard the statement connection after cancellation.
	if err := conn.Ping(ctx); err != nil {
		fresh, _, release, openErr := svc.OpenReleasing(ctx, profile.ID)
		if openErr != nil {
			t.Fatalf("ping after cancel: %v; reconnect: %v", err, openErr)
		}
		defer func() {
			_ = fresh.Close()
			if release != nil {
				release()
			}
		}()
		if err := fresh.Ping(ctx); err != nil {
			t.Fatalf("ping after reconnect: %v", err)
		}
	}
}

const digitQuery = `WITH digits AS (
	SELECT 0 AS n UNION ALL SELECT 1 UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4
	UNION ALL SELECT 5 UNION ALL SELECT 6 UNION ALL SELECT 7 UNION ALL SELECT 8 UNION ALL SELECT 9
)
SELECT a.n + 10*b.n + 100*c.n + 1000*d.n FROM digits a CROSS JOIN digits b CROSS JOIN digits c CROSS JOIN digits d`

func matrixParams(name, host, port string, e matrixEngine) map[string]string {
	switch name {
	case "mongo", "documentdb":
		p := map[string]string{"hosts": host + ":" + port, "username": e.user}
		if name == "mongo" {
			p["replica_set"] = "rs0"
		}
		return p
	case "redis", "redis-cluster", "valkey":
		p := map[string]string{"hosts": host + ":" + port}
		if name == "redis-cluster" {
			p["mode"] = "cluster"
		}
		return p
	case "oracle":
		return map[string]string{"host": host, "port": port, "user": e.user, "service_name": "FREEPDB1"}
	default:
		return map[string]string{"host": host, "port": port, "user": e.user, "database": e.database}
	}
}

type rowCount func(int) error

func (r rowCount) Columns([]engine.Column) error { return nil }
func (r rowCount) Batch(rows [][]engine.Value) error {
	return r(len(rows))
}

type docCount func(int) error

func (d docCount) Batch(docs []engine.Document) error {
	return d(len(docs))
}

func matrixStream(ctx context.Context, t *testing.T, conn engine.Conn, query string) func(context.Context, func(int)) error {
	t.Helper()
	switch c := conn.(type) {
	case engine.Executor:
		return func(ctx context.Context, count func(int)) error {
			_, err := c.Execute(ctx, engine.Statement{SQL: query}, rowCount(func(n int) error { count(n); return ctx.Err() }))
			return err
		}
	case engine.DocumentStore:
		const db = "queravue_matrix"
		coll := fmt.Sprintf("items_%d", time.Now().UnixNano())
		for start := 0; start < matrixItems; start += 500 {
			docs := make([]engine.Document, 0, 500)
			for n := start; n < start+500; n++ {
				docs = append(docs, fmt.Sprintf(`{"_id":{"$numberInt":"%d"}}`, n))
			}
			if _, err := c.Insert(ctx, db, coll, docs, engine.WriteOptions{}); err != nil {
				t.Fatalf("seed documents: %v", err)
			}
		}
		return func(ctx context.Context, count func(int)) error {
			return c.Find(ctx, engine.FindOptions{Database: db, Collection: coll, BatchSize: 500}, docCount(func(n int) error { count(n); return ctx.Err() }))
		}
	case engine.KeyValueStore:
		prefix := fmt.Sprintf("queravue:matrix:%d:", time.Now().UnixNano())
		for n := range matrixItems {
			key := []byte(fmt.Sprintf("%s%d", prefix, n))
			if _, err := c.ExecuteCommand(ctx, 0, [][]byte{[]byte("SET"), key, []byte("1"), []byte("EX"), []byte("600")}); err != nil {
				t.Fatalf("seed key: %v", err)
			}
		}
		return func(ctx context.Context, count func(int)) error {
			return c.ScanKeys(ctx, engine.ScanOptions{Pattern: prefix + "*", PageSize: 500}, func(page engine.ScanPage) error {
				count(len(page.Keys))
				return ctx.Err()
			})
		}
	default:
		t.Fatalf("no streaming capability on %T", conn)
		return nil
	}
}
