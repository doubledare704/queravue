//go:build integration

package redis

import (
	"context"
	"fmt"
	"net"
	"os"
	"runtime"
	"sync/atomic"
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

func redisTarget() enginetest.KVTarget {
	return enginetest.KVTarget{
		Engine: New(VariantRedis),
		Config: engine.Config{EngineID: ID, Params: map[string]string{
			ParamHosts: net.JoinHostPort(env("REDIS_HOST", "127.0.0.1"), env("REDIS_PORT", "6379")),
		}},
		Secret:  engine.NewSecret(env("REDIS_PASSWORD", "queravue")),
		Product: "Redis",
	}
}

func clusterTarget() enginetest.KVTarget {
	return enginetest.KVTarget{
		Engine: New(VariantRedis),
		Config: engine.Config{EngineID: ID, Params: map[string]string{
			ParamMode:  ModeCluster,
			ParamHosts: env("REDIS_CLUSTER_HOSTS", "127.0.0.1:7000,127.0.0.1:7001,127.0.0.1:7002"),
		}},
		Product: "Redis",
	}
}

func connect(t *testing.T, tg enginetest.KVTarget) engine.Conn {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	c, err := tg.Engine.Connect(ctx, tg.Config, tg.Secret)
	if err != nil {
		t.Fatalf("connect: %v (docker compose -f dev/docker-compose.yml up -d --wait redis)", err)
	}
	t.Cleanup(func() { _ = c.Close() })
	return c
}

func TestIntegrationSuiteRedis(t *testing.T) {
	enginetest.RunKeyValue(t, redisTarget())
}

func TestIntegrationSuiteValkeySmoke(t *testing.T) {
	tg := redisTarget()
	tg.Engine = New(VariantValkey)
	tg.Config.EngineID = IDValkey
	tg.Config.Params[ParamHosts] = net.JoinHostPort(env("VALKEY_HOST", "127.0.0.1"), env("VALKEY_PORT", "6380"))
	tg.Product = "Valkey"
	c := connect(t, tg)
	info, err := c.ServerInfo(context.Background())
	if err != nil || info.Product != "Valkey" || info.Version == "" {
		t.Fatalf("info = %+v, err = %v", info, err)
	}
	kv, _ := engine.As[engine.KeyValueStore](c)
	ctx := context.Background()
	key := []byte(fmt.Sprintf("smoke:%d", time.Now().UnixNano()))
	defer func() { _, _ = kv.DeleteKeys(ctx, 0, [][]byte{key}) }()
	if err := kv.WriteValue(ctx, 0, key, engine.WriteOp{Kind: engine.WriteSetString, Value: []byte("valkey")}); err != nil {
		t.Fatal(err)
	}
	page, err := kv.ReadValue(ctx, engine.ReadOptions{Key: key})
	if err != nil || string(page.String) != "valkey" {
		t.Fatalf("read = %+v, err = %v", page, err)
	}
	var scanned int
	if err := kv.ScanKeys(ctx, engine.ScanOptions{Pattern: "smoke:*"}, func(p engine.ScanPage) error { scanned += len(p.Keys); return nil }); err != nil || scanned != 1 {
		t.Fatalf("scan found %d, err = %v", scanned, err)
	}
	if r, err := kv.ExecuteCommand(ctx, 0, [][]byte{[]byte("PING")}); err != nil || string(r.Bytes) != "PONG" {
		t.Fatalf("PING = %+v, err = %v", r, err)
	}
}

func TestIntegrationBadPassword(t *testing.T) {
	tg := redisTarget()
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	_, err := tg.Engine.Connect(ctx, tg.Config, engine.NewSecret("wrong"))
	if engine.KindOf(err) != engine.KindAuth {
		t.Fatalf("err = %v, want auth", err)
	}
}

func TestIntegrationNoPassword(t *testing.T) {
	tg := redisTarget()
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	_, err := tg.Engine.Connect(ctx, tg.Config, engine.Secret{})
	if engine.KindOf(err) != engine.KindAuth {
		t.Fatalf("err = %v, want auth", err)
	}
}

func TestIntegrationUnreachableHost(t *testing.T) {
	tg := redisTarget()
	tg.Config.Params[ParamHosts] = "127.0.0.1:1"
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	_, err := tg.Engine.Connect(ctx, tg.Config, tg.Secret)
	if k := engine.KindOf(err); k != engine.KindNetwork {
		t.Fatalf("err = %v, want network", err)
	}
}

func TestIntegrationSecondDatabase(t *testing.T) {
	tg := redisTarget()
	c := connect(t, tg)
	kv, _ := engine.As[engine.KeyValueStore](c)
	ctx := context.Background()
	key := []byte(fmt.Sprintf("db1:%d", time.Now().UnixNano()))
	if err := kv.WriteValue(ctx, 1, key, engine.WriteOp{Kind: engine.WriteSetString, Value: []byte("one")}); err != nil {
		t.Fatal(err)
	}
	defer func() { _, _ = kv.DeleteKeys(ctx, 1, [][]byte{key}) }()
	if _, err := kv.KeyInfo(ctx, 0, key); engine.KindOf(err) != engine.KindNotFound {
		t.Errorf("key leaked into db 0: %v", err)
	}
	if info, err := kv.KeyInfo(ctx, 1, key); err != nil || info.Type != engine.KeyTypeString {
		t.Errorf("db 1 info = %+v, err = %v", info, err)
	}
	dbs, err := kv.ListDatabases(ctx)
	if err != nil || len(dbs.Databases) < 2 || dbs.Databases[1].Index != 1 {
		t.Errorf("databases = %+v, err = %v", dbs, err)
	}
}

func TestIntegrationEverySocketUsesTheSessionDialer(t *testing.T) {
	tg := redisTarget()
	var dials atomic.Int32
	d := &net.Dialer{Timeout: 5 * time.Second}
	tg.Config.Net.Dial = func(ctx context.Context, network, addr string) (net.Conn, error) {
		dials.Add(1)
		return d.DialContext(ctx, network, addr)
	}
	c := connect(t, tg)
	kv, _ := engine.As[engine.KeyValueStore](c)
	if _, err := kv.KeyInfo(context.Background(), 2, []byte("x")); engine.KindOf(err) != engine.KindNotFound {
		t.Fatal(err)
	}
	if err := c.Ping(context.Background()); err != nil || dials.Load() < 2 {
		t.Fatalf("dials = %d, err = %v", dials.Load(), err)
	}
}

func TestIntegrationScan1MKeysKeepsMemoryFlat(t *testing.T) {
	tg := redisTarget()
	c := connect(t, tg)
	kv, _ := engine.As[engine.KeyValueStore](c)

	var before runtime.MemStats
	runtime.GC()
	runtime.ReadMemStats(&before)
	peak := before.HeapAlloc
	var pages, keys int
	start := time.Now()
	err := kv.ScanKeys(context.Background(), engine.ScanOptions{Pattern: "scan:*", PageSize: 500}, func(p engine.ScanPage) error {
		keys += len(p.Keys)
		if pages++; pages%200 == 0 {
			var m runtime.MemStats
			runtime.GC()
			runtime.ReadMemStats(&m)
			peak = max(peak, m.HeapAlloc)
		}
		return nil
	})
	if err != nil {
		t.Fatal(err)
	}
	growth := int64(peak) - int64(before.HeapAlloc)
	t.Logf("scanned %d keys in %d pages in %s; peak live heap grew %d KiB", keys, pages, time.Since(start).Round(time.Millisecond), growth>>10)
	if keys != 1_000_000 {
		t.Fatalf("scanned %d keys, want 1,000,000", keys)
	}
	if growth > 16<<20 {
		t.Fatalf("live heap grew by %d MiB during the scan", growth>>20)
	}
}

func TestIntegrationClusterSuite(t *testing.T) {
	tg := clusterTarget()
	ctx, cancel := context.WithTimeout(context.Background(), 20*time.Second)
	defer cancel()
	probe, err := tg.Engine.Connect(ctx, tg.Config, tg.Secret)
	if err != nil {
		t.Skipf("no cluster (docker compose -f dev/docker-compose.yml --profile redis-cluster up -d --wait redis-cluster): %v", err)
	}
	_ = probe.Close()
	c := connect(t, tg)
	kv, _ := engine.As[engine.KeyValueStore](c)
	if info, err := c.ServerInfo(ctx); err != nil || info.Product != "Redis" {
		t.Fatalf("info = %+v, err = %v", info, err)
	}
	keys := make([][]byte, 300)
	for i := range keys {
		keys[i] = []byte(fmt.Sprintf("cluster:%d:%d", time.Now().UnixNano(), i))
		if err := kv.WriteValue(ctx, 0, keys[i], engine.WriteOp{Kind: engine.WriteSetString, Value: []byte("v")}); err != nil {
			t.Fatal(err)
		}
	}
	defer func() { _, _ = kv.DeleteKeys(ctx, 0, keys) }()
	var found, pages int
	if err := kv.ScanKeys(ctx, engine.ScanOptions{Pattern: "cluster:*", PageSize: 50}, func(p engine.ScanPage) error {
		found += len(p.Keys)
		pages++
		return nil
	}); err != nil {
		t.Fatal(err)
	}
	if found != len(keys) {
		t.Fatalf("scan across masters found %d of %d keys in %d pages", found, len(keys), pages)
	}
	dbs, err := kv.ListDatabases(ctx)
	if err != nil || dbs.DatabaseLimit != 1 || dbs.Databases[0].KeyCount < uint64(len(keys)) {
		t.Fatalf("databases = %+v, err = %v", dbs, err)
	}
	if _, err := kv.KeyInfo(ctx, 1, keys[0]); engine.KindOf(err) != engine.KindUnsupported {
		t.Errorf("database 1 err = %v, want unsupported", err)
	}
	if info, err := kv.KeyInfo(ctx, 0, keys[0]); err != nil || info.Type != engine.KeyTypeString {
		t.Errorf("key info = %+v, err = %v", info, err)
	}
	if n, err := kv.DeleteKeys(ctx, 0, keys); err != nil || n != uint64(len(keys)) {
		t.Errorf("deleted %d, err = %v", n, err)
	}
	if _, err := kv.Publish(ctx, "cluster:chan", []byte("x")); err != nil {
		t.Errorf("publish: %v", err)
	}
}

func TestIntegrationReadOnlyACLUser(t *testing.T) {
	tg := redisTarget()
	tg.Config.Params[ParamUsername] = "viewer"
	tg.Secret = engine.NewSecret("viewer")
	c := connect(t, tg)
	kv, _ := engine.As[engine.KeyValueStore](c)
	ctx := context.Background()
	info, err := kv.KeyInfo(ctx, 0, []byte("hash:user:1"))
	if err != nil || info.Type != engine.KeyTypeHash || info.Length != 4 {
		t.Fatalf("info = %+v, err = %v", info, err)
	}
	if info.MemoryBytes != nil {
		t.Errorf("MEMORY USAGE is denied to this user but memory = %d", *info.MemoryBytes)
	}
	dbs, err := kv.ListDatabases(ctx)
	if err != nil || dbs.DatabaseLimit != defaultDatabaseLimit {
		t.Errorf("databases = %+v, err = %v", dbs, err)
	}
	err = kv.WriteValue(ctx, 0, []byte("acl:denied"), engine.WriteOp{Kind: engine.WriteSetString, Value: []byte("x")})
	if engine.KindOf(err) != engine.KindServer {
		t.Fatalf("write err = %v, want a server refusal", err)
	}
	reply, err := kv.ExecuteCommand(ctx, 0, [][]byte{[]byte("SET"), []byte("acl:denied"), []byte("x")})
	if err != nil || reply.Kind != engine.ReplyError {
		t.Fatalf("SET reply = %+v, err = %v", reply, err)
	}
}
