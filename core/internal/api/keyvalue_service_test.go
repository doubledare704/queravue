package api_test

import (
	"context"
	"testing"
	"time"

	"google.golang.org/grpc"

	"github.com/doubledare704/queravue/core/internal/api"
	"github.com/doubledare704/queravue/core/internal/connections"
	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/redis"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/secrets"
	"github.com/doubledare704/queravue/core/internal/session"
)

type fakeKVConn struct {
	fakeDocConn
	executed [][][]byte
	deleted  int
	execErr  error
}

func (*fakeKVConn) ListDatabases(context.Context) (engine.KVDatabases, error) {
	return engine.KVDatabases{DatabaseLimit: 16, Databases: []engine.KVDatabase{{Index: 0, KeyCount: 3, ExpiringCount: 1}}}, nil
}

func (*fakeKVConn) ScanKeys(_ context.Context, _ engine.ScanOptions, emit func(engine.ScanPage) error) error {
	return emit(engine.ScanPage{Keys: []engine.KeySummary{{Key: []byte("a:b"), TTLMs: engine.UnknownTTL}}, Scanned: 1})
}

func (*fakeKVConn) KeyInfo(context.Context, uint32, []byte) (engine.KeyInfo, error) {
	return engine.KeyInfo{Type: engine.KeyTypeHash, TTLMs: engine.NoTTL, Length: 2}, nil
}

func (*fakeKVConn) ReadValue(context.Context, engine.ReadOptions) (engine.ValuePage, error) {
	return engine.ValuePage{Type: engine.KeyTypeList, List: [][]byte{[]byte("x")}, NextCursor: "1"}, nil
}

func (*fakeKVConn) WriteValue(context.Context, uint32, []byte, engine.WriteOp) error { return nil }

func (*fakeKVConn) RenameKey(context.Context, uint32, []byte, []byte, bool) error { return nil }

func (*fakeKVConn) SetExpiry(context.Context, uint32, []byte, *time.Duration) error { return nil }

func (f *fakeKVConn) DeleteKeys(_ context.Context, _ uint32, keys [][]byte) (uint64, error) {
	f.deleted += len(keys)
	return uint64(len(keys)), nil
}

func (f *fakeKVConn) ExecuteCommand(_ context.Context, _ uint32, args [][]byte) (engine.Reply, error) {
	if f.execErr != nil {
		return engine.Reply{}, f.execErr
	}
	f.executed = append(f.executed, args)
	return engine.Reply{Kind: engine.ReplyMap, Entries: []engine.ReplyEntry{{
		Key: engine.Reply{Kind: engine.ReplyString, Bytes: []byte("n")}, Value: engine.Reply{Kind: engine.ReplyInteger, Int: 7},
	}}}, nil
}

func (*fakeKVConn) Subscribe(ctx context.Context, _, _ []string, emit func(engine.PubSubMessage) error) error {
	if err := emit(engine.PubSubMessage{Channel: "c", Payload: []byte("hi")}); err != nil {
		return err
	}
	<-ctx.Done()
	return nil
}

func (*fakeKVConn) Publish(context.Context, string, []byte) (uint64, error) { return 2, nil }

type kvOpener struct{ conn engine.Conn }

func (o kvOpener) Open(context.Context, string) (engine.Conn, engine.Descriptor, error) {
	return o.conn, engine.Descriptor{ID: "redis", Capabilities: []engine.Capability{engine.CapConnect, engine.CapKeyValueStore}}, nil
}

func newKVService(t *testing.T, conn *fakeKVConn, production bool) (*api.KeyValueService, string) {
	t.Helper()
	mgr := session.NewManager(kvOpener{conn: conn})
	t.Cleanup(mgr.Shutdown)
	sess, err := mgr.Open(context.Background(), "c")
	if err != nil {
		t.Fatal(err)
	}
	reg, err := engine.NewRegistry(redis.New(redis.VariantRedis))
	if err != nil {
		t.Fatal(err)
	}
	store := connections.NewFileStore(t.TempDir())
	if err := store.Save([]connections.Connection{{ID: sess.ConnectionID, Name: "R", EngineID: "redis", Production: production}}); err != nil {
		t.Fatal(err)
	}
	return api.NewKeyValueService(mgr, connections.NewService(reg, store, secrets.NewMemory()), nil), sess.ID
}

func args(parts ...string) [][]byte {
	out := make([][]byte, len(parts))
	for i, p := range parts {
		out[i] = []byte(p)
	}
	return out
}

func TestKeyValueProductionConfirmation(t *testing.T) {
	needs := [][]string{
		{"FLUSHALL"}, {"flushdb"}, {"DEL", "a", "b"}, {"CONFIG", "SET", "maxmemory", "1"}, {"SHUTDOWN"}, {"DEBUG", "sleep", "0"},
	}
	for _, cmd := range needs {
		t.Run(cmd[0], func(t *testing.T) {
			conn := &fakeKVConn{}
			svc, sid := newKVService(t, conn, true)
			resp, err := svc.ExecuteCommand(context.Background(), &queravuev1.ExecuteCommandRequest{SessionId: sid, Args: args(cmd...)})
			if err != nil {
				t.Fatal(err)
			}
			e := resp.GetError()
			if e.GetKind() != queravuev1.KeyValueErrorKind_KEY_VALUE_ERROR_KIND_CONFIRMATION_REQUIRED || e.GetOperation() == "" || len(conn.executed) != 0 {
				t.Fatalf("error = %v, executed = %d", e, len(conn.executed))
			}
			resp, err = svc.ExecuteCommand(context.Background(), &queravuev1.ExecuteCommandRequest{SessionId: sid, Args: args(cmd...), Confirmed: true})
			if err != nil || resp.GetError() != nil || len(conn.executed) != 1 {
				t.Fatalf("confirmed: err = %v, resp = %v", err, resp)
			}
		})
	}
}

func TestKeyValueNonProductionAndSafeCommandsSkipConfirmation(t *testing.T) {
	conn := &fakeKVConn{}
	svc, sid := newKVService(t, conn, false)
	resp, _ := svc.ExecuteCommand(context.Background(), &queravuev1.ExecuteCommandRequest{SessionId: sid, Args: args("FLUSHALL")})
	if resp.GetError() != nil {
		t.Fatalf("non-production: %v", resp.GetError())
	}
	prod, psid := newKVService(t, &fakeKVConn{}, true)
	for _, cmd := range [][]string{{"GET", "k"}, {"DEL", "k"}, {"CONFIG", "GET", "maxmemory"}} {
		resp, _ := prod.ExecuteCommand(context.Background(), &queravuev1.ExecuteCommandRequest{SessionId: psid, Args: args(cmd...)})
		if resp.GetError() != nil {
			t.Fatalf("%v: %v", cmd, resp.GetError())
		}
	}
}

func TestKeyValueDeleteKeysConfirmation(t *testing.T) {
	conn := &fakeKVConn{}
	svc, sid := newKVService(t, conn, true)
	ctx := context.Background()
	resp, _ := svc.DeleteKeys(ctx, &queravuev1.DeleteKeysRequest{SessionId: sid, Keys: args("a")})
	if resp.GetError() != nil || resp.GetDeleted() != 1 {
		t.Fatalf("one key: %v", resp)
	}
	resp, _ = svc.DeleteKeys(ctx, &queravuev1.DeleteKeysRequest{SessionId: sid, Keys: args("a", "b", "c")})
	if resp.GetError().GetKind() != queravuev1.KeyValueErrorKind_KEY_VALUE_ERROR_KIND_CONFIRMATION_REQUIRED || resp.GetError().GetOperation() != "delete 3 keys" || conn.deleted != 1 {
		t.Fatalf("many keys: %v deleted=%d", resp, conn.deleted)
	}
	resp, _ = svc.DeleteKeys(ctx, &queravuev1.DeleteKeysRequest{SessionId: sid, Keys: args("a", "b", "c"), Confirmed: true})
	if resp.GetError() != nil || resp.GetDeleted() != 3 {
		t.Fatalf("confirmed: %v", resp)
	}
}

func TestKeyValueEngineRefusalsAreInBand(t *testing.T) {
	tests := []struct {
		kind engine.Kind
		want queravuev1.KeyValueErrorKind
	}{
		{engine.KindKeysRefused, queravuev1.KeyValueErrorKind_KEY_VALUE_ERROR_KIND_KEYS_REFUSED},
		{engine.KindBlockingRefused, queravuev1.KeyValueErrorKind_KEY_VALUE_ERROR_KIND_BLOCKING_REFUSED},
		{engine.KindUnsupported, queravuev1.KeyValueErrorKind_KEY_VALUE_ERROR_KIND_UNSUPPORTED},
		{engine.KindNotFound, queravuev1.KeyValueErrorKind_KEY_VALUE_ERROR_KIND_NOT_FOUND},
		{engine.KindInvalidConfig, queravuev1.KeyValueErrorKind_KEY_VALUE_ERROR_KIND_INVALID},
		{engine.KindServer, queravuev1.KeyValueErrorKind_KEY_VALUE_ERROR_KIND_SERVER},
	}
	for _, tt := range tests {
		svc, sid := newKVService(t, &fakeKVConn{execErr: engine.Errorf(tt.kind, "redis", "command", "no")}, false)
		resp, err := svc.ExecuteCommand(context.Background(), &queravuev1.ExecuteCommandRequest{SessionId: sid, Args: args("X")})
		if err != nil || resp.GetError().GetKind() != tt.want {
			t.Errorf("%v: err = %v, resp = %v", tt.kind, err, resp)
		}
	}
}

func TestKeyValueReplyTree(t *testing.T) {
	svc, sid := newKVService(t, &fakeKVConn{}, false)
	resp, _ := svc.ExecuteCommand(context.Background(), &queravuev1.ExecuteCommandRequest{SessionId: sid, Args: args("HGETALL", "h")})
	entries := resp.GetReply().GetMap().GetEntries()
	if len(entries) != 1 || string(entries[0].GetKey().GetStringValue()) != "n" || entries[0].GetValue().GetInteger() != 7 {
		t.Fatalf("reply = %v", resp.GetReply())
	}
}

func TestKeyValueReadsAndWrites(t *testing.T) {
	svc, sid := newKVService(t, &fakeKVConn{}, true)
	ctx := context.Background()
	if r, _ := svc.ListKvDatabases(ctx, &queravuev1.ListKvDatabasesRequest{SessionId: sid}); r.GetDatabaseLimit() != 16 || len(r.GetDatabases()) != 1 {
		t.Fatalf("databases = %v", r)
	}
	if r, _ := svc.GetKeyInfo(ctx, &queravuev1.GetKeyInfoRequest{SessionId: sid, Key: []byte("k")}); r.GetType() != queravuev1.KeyType_KEY_TYPE_HASH || r.GetLength() != 2 {
		t.Fatalf("info = %v", r)
	}
	r, _ := svc.ReadValue(ctx, &queravuev1.ReadValueRequest{SessionId: sid, Key: []byte("k")})
	if string(r.GetList().GetItems()[0]) != "x" || r.GetNextCursor() != "1" {
		t.Fatalf("value = %v", r)
	}
	w, _ := svc.WriteValue(ctx, &queravuev1.WriteValueRequest{SessionId: sid, Key: []byte("k"), Op: &queravuev1.WriteOp{}})
	if w.GetError().GetKind() != queravuev1.KeyValueErrorKind_KEY_VALUE_ERROR_KIND_INVALID {
		t.Fatalf("empty op = %v", w)
	}
	w, _ = svc.WriteValue(ctx, &queravuev1.WriteValueRequest{SessionId: sid, Key: []byte("k"), Op: &queravuev1.WriteOp{
		Op: &queravuev1.WriteOp_SetString_{SetString: &queravuev1.WriteOp_SetString{Value: []byte("v")}},
	}})
	if w.GetError() != nil {
		t.Fatalf("write = %v", w)
	}
	if p, _ := svc.Publish(ctx, &queravuev1.PublishRequest{SessionId: sid, Channel: "c"}); p.GetReceivers() != 2 {
		t.Fatalf("publish = %v", p)
	}
}

type scanStream struct {
	grpc.ServerStream
	ctx  context.Context
	msgs []*queravuev1.ScanKeysResponse
}

func (s *scanStream) Context() context.Context { return s.ctx }
func (s *scanStream) Send(m *queravuev1.ScanKeysResponse) error {
	s.msgs = append(s.msgs, m)
	return nil
}

func TestKeyValueScanKeysEndsWithDone(t *testing.T) {
	svc, sid := newKVService(t, &fakeKVConn{}, false)
	st := &scanStream{ctx: context.Background()}
	if err := svc.ScanKeys(&queravuev1.ScanKeysRequest{SessionId: sid}, st); err != nil {
		t.Fatal(err)
	}
	if len(st.msgs) != 2 || string(st.msgs[0].GetKeys()[0].GetKey()) != "a:b" || !st.msgs[1].GetDone() {
		t.Fatalf("messages = %v", st.msgs)
	}
}

type subStream struct {
	grpc.ServerStream
	ctx  context.Context
	msgs chan *queravuev1.SubscribeResponse
}

func (s *subStream) Context() context.Context { return s.ctx }
func (s *subStream) Send(m *queravuev1.SubscribeResponse) error {
	s.msgs <- m
	return nil
}

func TestKeyValueSubscribeStopsOnCancel(t *testing.T) {
	svc, sid := newKVService(t, &fakeKVConn{}, false)
	ctx, cancel := context.WithCancel(context.Background())
	st := &subStream{ctx: ctx, msgs: make(chan *queravuev1.SubscribeResponse, 4)}
	done := make(chan error, 1)
	go func() { done <- svc.Subscribe(&queravuev1.SubscribeRequest{SessionId: sid, Channels: []string{"c"}}, st) }()
	if m := <-st.msgs; string(m.GetPayload()) != "hi" {
		t.Fatalf("message = %v", m)
	}
	cancel()
	if err := <-done; err != nil {
		t.Fatalf("subscribe returned %v after cancel", err)
	}
}

func TestKeyValueRequiresCapability(t *testing.T) {
	svc, _ := newKVService(t, &fakeKVConn{}, false)
	if _, err := svc.GetKeyInfo(context.Background(), &queravuev1.GetKeyInfoRequest{SessionId: "nope"}); err == nil {
		t.Fatal("unknown session should fail")
	}
}
