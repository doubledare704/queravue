//go:build integration

package api_test

import (
	"context"
	"net"
	"os"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/api"
	"github.com/doubledare704/queravue/core/internal/connections"
	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/redis"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/secrets"
	"github.com/doubledare704/queravue/core/internal/session"
)

type redisOpener struct{}

func (redisOpener) Open(ctx context.Context, _ string) (engine.Conn, engine.Descriptor, error) {
	e := redis.New(redis.VariantRedis)
	host := os.Getenv("REDIS_HOST")
	if host == "" {
		host = "127.0.0.1"
	}
	port := os.Getenv("REDIS_PORT")
	if port == "" {
		port = "6379"
	}
	pw := os.Getenv("REDIS_PASSWORD")
	if pw == "" {
		pw = "queravue"
	}
	c, err := e.Connect(ctx, engine.Config{EngineID: redis.ID, Params: map[string]string{redis.ParamHosts: net.JoinHostPort(host, port)}}, engine.NewSecret(pw))
	return c, e.Descriptor(), err
}

func newRedisKV(t *testing.T, production bool) (*api.KeyValueService, string) {
	t.Helper()
	mgr := session.NewManager(redisOpener{})
	t.Cleanup(mgr.Shutdown)
	sess, err := mgr.Open(context.Background(), "c")
	if err != nil {
		t.Fatalf("open: %v (docker compose -f dev/docker-compose.yml up -d --wait redis)", err)
	}
	reg, _ := engine.NewRegistry(redis.New(redis.VariantRedis))
	store := connections.NewFileStore(t.TempDir())
	_ = store.Save([]connections.Connection{{ID: sess.ConnectionID, Name: "R", EngineID: "redis", Production: production}})
	return api.NewKeyValueService(mgr, connections.NewService(reg, store, secrets.NewMemory()), nil), sess.ID
}

func TestIntegrationKeyValueProductionRules(t *testing.T) {
	svc, sid := newRedisKV(t, true)
	ctx := context.Background()
	run := func(confirmed bool, parts ...string) *queravuev1.ExecuteCommandResponse {
		t.Helper()
		resp, err := svc.ExecuteCommand(ctx, &queravuev1.ExecuteCommandRequest{SessionId: sid, Args: args(parts...), Confirmed: confirmed})
		if err != nil {
			t.Fatal(err)
		}
		return resp
	}
	confirm := queravuev1.KeyValueErrorKind_KEY_VALUE_ERROR_KIND_CONFIRMATION_REQUIRED
	for _, cmd := range [][]string{{"FLUSHALL"}, {"FLUSHDB"}, {"DEL", "test:a", "test:b"}, {"CONFIG", "SET", "maxmemory-policy", "noeviction"}, {"SHUTDOWN", "NOSAVE"}, {"DEBUG", "OBJECT", "str:plain"}} {
		if k := run(false, cmd...).GetError().GetKind(); k != confirm {
			t.Errorf("%v: kind = %v, want confirmation required", cmd, k)
		}
	}
	if resp := run(true, "CONFIG", "SET", "maxmemory-policy", "noeviction"); resp.GetError() != nil || string(resp.GetReply().GetStringValue()) != "OK" {
		t.Errorf("confirmed CONFIG SET = %v", resp)
	}
	if resp := run(true, "DEL", "test:a", "test:b"); resp.GetError() != nil || resp.GetReply().GetInteger() != 0 {
		t.Errorf("confirmed DEL = %v", resp)
	}
	if resp := run(false, "GET", "str:plain"); resp.GetError() != nil || string(resp.GetReply().GetStringValue()) != "hello world" {
		t.Errorf("GET = %v", resp)
	}
	if k := run(true, "KEYS", "*").GetError().GetKind(); k != queravuev1.KeyValueErrorKind_KEY_VALUE_ERROR_KIND_KEYS_REFUSED {
		t.Errorf("KEYS kind = %v", k)
	}
	if k := run(true, "BRPOP", "list:queue", "0").GetError().GetKind(); k != queravuev1.KeyValueErrorKind_KEY_VALUE_ERROR_KIND_BLOCKING_REFUSED {
		t.Errorf("BRPOP kind = %v", k)
	}
	if resp, _ := svc.DeleteKeys(ctx, &queravuev1.DeleteKeysRequest{SessionId: sid, Keys: args("test:a", "test:b")}); resp.GetError().GetKind() != confirm {
		t.Errorf("DeleteKeys of two keys = %v", resp)
	}
	if resp, _ := svc.DeleteKeys(ctx, &queravuev1.DeleteKeysRequest{SessionId: sid, Keys: args("test:a", "test:b"), Confirmed: true}); resp.GetError() != nil {
		t.Errorf("confirmed DeleteKeys = %v", resp)
	}
	if resp := run(false, "DBSIZE"); resp.GetReply().GetInteger() < 1_000_000 {
		t.Errorf("the seed is gone after the refused flushes: DBSIZE = %v", resp)
	}
}

func TestIntegrationKeyValueSubscribePublish(t *testing.T) {
	svc, sid := newRedisKV(t, false)
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	st := &subStream{ctx: ctx, msgs: make(chan *queravuev1.SubscribeResponse, 8)}
	done := make(chan error, 1)
	go func() {
		done <- svc.Subscribe(&queravuev1.SubscribeRequest{SessionId: sid, Channels: []string{"api:chan"}}, st)
	}()
	deadline := time.After(10 * time.Second)
	for got := false; !got; {
		resp, err := svc.Publish(context.Background(), &queravuev1.PublishRequest{SessionId: sid, Channel: "api:chan", Payload: []byte("ping")})
		if err != nil || resp.GetError() != nil {
			t.Fatalf("publish = %v, err = %v", resp, err)
		}
		select {
		case m := <-st.msgs:
			got = string(m.GetPayload()) == "ping" && m.GetChannel() == "api:chan"
		case <-time.After(100 * time.Millisecond):
		case <-deadline:
			t.Fatal("no message delivered")
		}
	}
	cancel()
	select {
	case err := <-done:
		if err != nil {
			t.Errorf("subscribe returned %v", err)
		}
	case <-time.After(5 * time.Second):
		t.Fatal("subscribe did not end after cancel")
	}
}

func TestIntegrationKeyValueScanStream(t *testing.T) {
	svc, sid := newRedisKV(t, false)
	st := &scanStream{ctx: context.Background()}
	if err := svc.ScanKeys(&queravuev1.ScanKeysRequest{SessionId: sid, Pattern: "app:users:*", PageSize: 5000}, st); err != nil {
		t.Fatal(err)
	}
	last := st.msgs[len(st.msgs)-1]
	if !last.GetDone() || last.GetError() != nil {
		t.Fatalf("last message = %v", last)
	}
	var keys int
	for _, m := range st.msgs {
		keys += len(m.GetKeys())
	}
	if keys != 4 {
		t.Fatalf("found %d keys, want 4", keys)
	}
}
