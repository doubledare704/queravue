package enginetest

import (
	"context"
	"fmt"
	"strconv"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
)

// KVTarget describes one key-value server under test. It must hold the seed
// from dev/seed/redis.
type KVTarget struct {
	Engine  engine.Engine
	Config  engine.Config
	Secret  engine.Secret
	Product string
}

func (tg KVTarget) connect(t *testing.T) (engine.KeyValueStore, engine.Conn) {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	c, err := tg.Engine.Connect(ctx, tg.Config, tg.Secret)
	if err != nil {
		t.Fatalf("connect: %v (are the dev databases up and seeded? see dev/seed/redis)", err)
	}
	t.Cleanup(func() { _ = c.Close() })
	kv, ok := engine.As[engine.KeyValueStore](c)
	if !ok {
		t.Fatal("connection does not implement KeyValueStore")
	}
	return kv, c
}

// RunKeyValue executes the key-value suite.
func RunKeyValue(t *testing.T, tg KVTarget) {
	t.Run("ConnectPingInfo", func(t *testing.T) { kvConnectPing(t, tg) })
	t.Run("ListDatabases", func(t *testing.T) { kvListDatabases(t, tg) })
	t.Run("ScanKeys", func(t *testing.T) { kvScan(t, tg) })
	t.Run("ScanCancel", func(t *testing.T) { kvScanCancel(t, tg) })
	t.Run("KeyInfo", func(t *testing.T) { kvKeyInfo(t, tg) })
	t.Run("ReadStrings", func(t *testing.T) { kvReadStrings(t, tg) })
	t.Run("ReadCollections", func(t *testing.T) { kvReadCollections(t, tg) })
	t.Run("Writes", func(t *testing.T) { kvWrites(t, tg) })
	t.Run("ExpiryRenameDelete", func(t *testing.T) { kvExpiryRenameDelete(t, tg) })
	t.Run("Commands", func(t *testing.T) { kvCommands(t, tg) })
	t.Run("PubSub", func(t *testing.T) { kvPubSub(t, tg) })
}

func kvConnectPing(t *testing.T, tg KVTarget) {
	_, c := tg.connect(t)
	ctx := context.Background()
	if err := c.Ping(ctx); err != nil {
		t.Fatal(err)
	}
	info, err := c.ServerInfo(ctx)
	if err != nil || info.Product != tg.Product || info.Version == "" {
		t.Fatalf("info = %+v, err = %v", info, err)
	}
}

func kvListDatabases(t *testing.T, tg KVTarget) {
	kv, _ := tg.connect(t)
	dbs, err := kv.ListDatabases(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if len(dbs.Databases) == 0 || dbs.Databases[0].Index != 0 || dbs.Databases[0].KeyCount < 30 || dbs.DatabaseLimit == 0 {
		t.Fatalf("databases = %+v", dbs)
	}
	if dbs.Databases[0].ExpiringCount < 2 {
		t.Fatalf("expiring = %d, want the seeded TTL keys", dbs.Databases[0].ExpiringCount)
	}
}

func scanAll(t *testing.T, kv engine.KeyValueStore, opts engine.ScanOptions) (keys []string, scanned uint64) {
	t.Helper()
	err := kv.ScanKeys(context.Background(), opts, func(p engine.ScanPage) error {
		for _, k := range p.Keys {
			keys = append(keys, string(k.Key))
		}
		scanned = p.Scanned
		return nil
	})
	if err != nil {
		t.Fatalf("scan %+v: %v", opts, err)
	}
	return keys, scanned
}

func kvScan(t *testing.T, tg KVTarget) {
	kv, _ := tg.connect(t)
	keys, scanned := scanAll(t, kv, engine.ScanOptions{Pattern: "app:*", PageSize: 5000})
	want := map[string]bool{"app:users:1": true, "app:cache:session:42": true, "app:leaderboard": true}
	for _, k := range keys {
		delete(want, k)
	}
	if len(want) != 0 || scanned < uint64(len(keys)) {
		t.Fatalf("missing %v; scanned %d, got %d keys", want, scanned, len(keys))
	}
	hashes, _ := scanAll(t, kv, engine.ScanOptions{Pattern: "hash:*", TypeFilter: engine.KeyTypeHash})
	if len(hashes) != 1 || hashes[0] != "hash:user:1" {
		t.Fatalf("hash filter = %v", hashes)
	}
	none, _ := scanAll(t, kv, engine.ScanOptions{Pattern: "hash:*", TypeFilter: engine.KeyTypeList})
	if len(none) != 0 {
		t.Fatalf("list filter on a hash key = %v", none)
	}
	binary, _ := scanAll(t, kv, engine.ScanOptions{Pattern: "bin:key:*"})
	if len(binary) != 1 || binary[0] != "bin:key:\x00\xff" {
		t.Fatalf("binary key = %q", binary)
	}
}

func kvScanCancel(t *testing.T, tg KVTarget) {
	kv, _ := tg.connect(t)
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	pages := 0
	err := kv.ScanKeys(ctx, engine.ScanOptions{Pattern: "*", PageSize: 100}, func(engine.ScanPage) error {
		if pages++; pages == 3 {
			cancel()
		}
		return nil
	})
	if engine.KindOf(err) != engine.KindCanceled {
		t.Fatalf("err = %v, want canceled", err)
	}
}

func kvKeyInfo(t *testing.T, tg KVTarget) {
	kv, _ := tg.connect(t)
	ctx := context.Background()
	tests := []struct {
		key    string
		typ    engine.KeyType
		length uint64
	}{
		{"str:plain", engine.KeyTypeString, 11},
		{"hash:user:1", engine.KeyTypeHash, 4},
		{"list:queue", engine.KeyTypeList, 5},
		{"set:tags", engine.KeyTypeSet, 3},
		{"zset:scores", engine.KeyTypeZSet, 4},
		{"stream:events", engine.KeyTypeStream, 3},
		{"hll:visitors", engine.KeyTypeHyperLogLog, 0},
	}
	for _, tt := range tests {
		info, err := kv.KeyInfo(ctx, 0, []byte(tt.key))
		if err != nil || info.Type != tt.typ || tt.length != 0 && info.Length != tt.length || info.Encoding == "" {
			t.Errorf("%s: %+v, err = %v", tt.key, info, err)
		}
	}
	short, _ := kv.KeyInfo(ctx, 0, []byte("ttl:short"))
	if short.TTLMs <= 0 || short.TTLMs > 3_600_000 {
		t.Errorf("ttl:short = %d ms", short.TTLMs)
	}
	forever, _ := kv.KeyInfo(ctx, 0, []byte("ttl:persistent"))
	if forever.TTLMs != engine.NoTTL {
		t.Errorf("ttl:persistent = %d ms", forever.TTLMs)
	}
	big, _ := kv.KeyInfo(ctx, 0, []byte("big:hash"))
	if !big.BigKey || big.Length != 100_000 || big.MemoryBytes == nil {
		t.Errorf("big:hash = %+v", big)
	}
	if _, err := kv.KeyInfo(ctx, 0, []byte("no:such:key")); engine.KindOf(err) != engine.KindNotFound {
		t.Errorf("missing key err = %v", err)
	}
}

func read(t *testing.T, kv engine.KeyValueStore, o engine.ReadOptions) engine.ValuePage {
	t.Helper()
	p, err := kv.ReadValue(context.Background(), o)
	if err != nil {
		t.Fatalf("read %q %+v: %v", o.Key, o, err)
	}
	return p
}

func kvReadStrings(t *testing.T, tg KVTarget) {
	kv, _ := tg.connect(t)
	plain := read(t, kv, engine.ReadOptions{Key: []byte("str:plain")})
	if string(plain.String) != "hello world" || plain.Binary || plain.NextCursor != "" {
		t.Fatalf("plain = %+v", plain)
	}
	if utf := read(t, kv, engine.ReadOptions{Key: []byte("str:utf8")}); utf.Binary || string(utf.String) != "héllo €uro 日本語" {
		t.Fatalf("utf8 = %+v", utf)
	}
	if bin := read(t, kv, engine.ReadOptions{Key: []byte("bin:blob")}); !bin.Binary || len(bin.String) != 12 {
		t.Fatalf("binary = %+v", bin)
	}
	var got, pages int
	cursor := ""
	for {
		p := read(t, kv, engine.ReadOptions{Key: []byte("str:large"), Cursor: cursor, MaxBytes: 1 << 20})
		got += len(p.String)
		pages++
		if p.TotalBytes != 2_400_000 || len(p.String) > 1<<20 {
			t.Fatalf("page %d: total %d, len %d", pages, p.TotalBytes, len(p.String))
		}
		if cursor = p.NextCursor; cursor == "" {
			break
		}
	}
	if got != 2_400_000 || pages != 3 {
		t.Fatalf("read %d bytes in %d pages", got, pages)
	}
	if hll := read(t, kv, engine.ReadOptions{Key: []byte("hll:visitors")}); hll.Type != engine.KeyTypeHyperLogLog || hll.Cardinality != 5 {
		t.Fatalf("hll = %+v", hll)
	}
	if _, err := kv.ReadValue(context.Background(), engine.ReadOptions{Key: []byte("no:such:key")}); engine.KindOf(err) != engine.KindNotFound {
		t.Fatalf("missing key err = %v", err)
	}
	if _, err := kv.ReadValue(context.Background(), engine.ReadOptions{Key: []byte("hash:user:1"), Cursor: "junk"}); engine.KindOf(err) != engine.KindInvalidConfig {
		t.Fatalf("bad cursor err = %v", err)
	}
}

func kvReadCollections(t *testing.T, tg KVTarget) {
	kv, _ := tg.connect(t)
	count := func(key string, o engine.ReadOptions, n func(engine.ValuePage) int) int {
		total := 0
		for pages := 0; ; pages++ {
			o.Key = []byte(key)
			p := read(t, kv, o)
			if got := n(p); got > o.PageSize+o.PageSize/2+16 {
				t.Fatalf("%s: page of %d for page size %d", key, got, o.PageSize)
			}
			total += n(p)
			if o.Cursor = p.NextCursor; o.Cursor == "" || pages > 1000 {
				return total
			}
		}
	}
	if n := count("big:hash", engine.ReadOptions{PageSize: 1000}, func(p engine.ValuePage) int { return len(p.Hash) }); n != 100_000 {
		t.Errorf("hash entries = %d", n)
	}
	if n := count("big:list", engine.ReadOptions{PageSize: 5000}, func(p engine.ValuePage) int { return len(p.List) }); n != 100_000 {
		t.Errorf("list items = %d", n)
	}
	if n := count("big:zset", engine.ReadOptions{PageSize: 1000}, func(p engine.ValuePage) int { return len(p.ZSet) }); n != 100_000 {
		t.Errorf("zset scan entries = %d", n)
	}
	if n := count("big:zset", engine.ReadOptions{PageSize: 10_000, OrderByScore: true}, func(p engine.ValuePage) int { return len(p.ZSet) }); n != 100_000 {
		t.Errorf("zset range entries = %d", n)
	}
	small := read(t, kv, engine.ReadOptions{Key: []byte("hash:user:1")})
	if len(small.Hash) != 4 || small.NextCursor != "" {
		t.Errorf("small hash = %+v", small)
	}
	forward := read(t, kv, engine.ReadOptions{Key: []byte("big:list"), PageSize: 3})
	if len(forward.List) != 3 || string(forward.List[0]) != "item1" || forward.ListStart != 0 || forward.NextCursor != "3" {
		t.Errorf("list forward = %+v", forward)
	}
	backward := read(t, kv, engine.ReadOptions{Key: []byte("big:list"), PageSize: 3, Reverse: true})
	if len(backward.List) != 3 || string(backward.List[0]) != "item100000" || string(backward.List[2]) != "item99998" || backward.ListStart != 99_999 {
		t.Errorf("list reverse = %+v", backward)
	}
	byScore := read(t, kv, engine.ReadOptions{Key: []byte("zset:scores"), OrderByScore: true})
	if len(byScore.ZSet) != 4 || string(byScore.ZSet[0].Member) != "alice" || byScore.ZSet[1].Score != 15.5 {
		t.Errorf("zset by score = %+v", byScore.ZSet)
	}
	desc := read(t, kv, engine.ReadOptions{Key: []byte("zset:scores"), OrderByScore: true, Reverse: true})
	if string(desc.ZSet[0].Member) != "carol" {
		t.Errorf("zset reverse = %+v", desc.ZSet)
	}
	if set := read(t, kv, engine.ReadOptions{Key: []byte("set:tags")}); len(set.Set) != 3 {
		t.Errorf("set = %+v", set)
	}
	stream := read(t, kv, engine.ReadOptions{Key: []byte("stream:events"), PageSize: 2})
	if len(stream.Stream) != 2 || stream.Stream[0].ID != "1700000000000-0" || stream.NextCursor != "1700000000001-1" ||
		string(stream.Stream[0].Fields[0].Field) != "type" || string(stream.Stream[0].Fields[1].Value) != "ada" {
		t.Errorf("stream page 1 = %+v", stream)
	}
	rest := read(t, kv, engine.ReadOptions{Key: []byte("stream:events"), PageSize: 2, Cursor: stream.NextCursor})
	if len(rest.Stream) != 1 || rest.Stream[0].ID != "1700000000002-0" || rest.NextCursor != "" {
		t.Errorf("stream page 2 = %+v", rest)
	}
	newest := read(t, kv, engine.ReadOptions{Key: []byte("stream:events"), PageSize: 1, Reverse: true})
	if len(newest.Stream) != 1 || newest.Stream[0].ID != "1700000000002-0" || newest.NextCursor != "1700000000001-18446744073709551615" {
		t.Errorf("stream reverse = %+v", newest)
	}
}

var scratchCounter atomic.Int64

func scratchKey(t *testing.T, kv engine.KeyValueStore, name string) []byte {
	t.Helper()
	key := []byte(fmt.Sprintf("test:%d:%d:%s", time.Now().UnixNano(), scratchCounter.Add(1), name))
	t.Cleanup(func() { _, _ = kv.DeleteKeys(context.Background(), 0, [][]byte{key}) })
	return key
}

func write(t *testing.T, kv engine.KeyValueStore, key []byte, op engine.WriteOp) {
	t.Helper()
	if err := kv.WriteValue(context.Background(), 0, key, op); err != nil {
		t.Fatalf("write kind %d on %q: %v", op.Kind, key, err)
	}
}

func b(values ...string) [][]byte {
	out := make([][]byte, len(values))
	for i, v := range values {
		out[i] = []byte(v)
	}
	return out
}

func kvWrites(t *testing.T, tg KVTarget) {
	kv, _ := tg.connect(t)
	ctx := context.Background()

	str := scratchKey(t, kv, "string")
	write(t, kv, str, engine.WriteOp{Kind: engine.WriteSetString, Value: []byte("one")})
	if p := read(t, kv, engine.ReadOptions{Key: str}); string(p.String) != "one" {
		t.Errorf("string = %+v", p)
	}
	if err := kv.SetExpiry(ctx, 0, str, ptr(time.Hour)); err != nil {
		t.Fatal(err)
	}
	write(t, kv, str, engine.WriteOp{Kind: engine.WriteSetString, Value: []byte("two")})
	if info, _ := kv.KeyInfo(ctx, 0, str); info.TTLMs <= 0 {
		t.Errorf("editing a string dropped its TTL: %d", info.TTLMs)
	}

	hash := scratchKey(t, kv, "hash")
	write(t, kv, hash, engine.WriteOp{Kind: engine.WriteHashSet, Field: []byte("f1"), Value: []byte("v1")})
	write(t, kv, hash, engine.WriteOp{Kind: engine.WriteHashSet, Field: []byte("f2"), Value: []byte("v2")})
	write(t, kv, hash, engine.WriteOp{Kind: engine.WriteHashDelete, Field: []byte("f1")})
	if p := read(t, kv, engine.ReadOptions{Key: hash}); len(p.Hash) != 1 || string(p.Hash[0].Field) != "f2" {
		t.Errorf("hash = %+v", p.Hash)
	}

	list := scratchKey(t, kv, "list")
	write(t, kv, list, engine.WriteOp{Kind: engine.WriteListPush, Values: b("b", "c")})
	write(t, kv, list, engine.WriteOp{Kind: engine.WriteListPush, Values: b("a"), AtHead: true})
	write(t, kv, list, engine.WriteOp{Kind: engine.WriteListSet, Index: 1, Value: []byte("B")})
	write(t, kv, list, engine.WriteOp{Kind: engine.WriteListPush, Values: b("c")})
	write(t, kv, list, engine.WriteOp{Kind: engine.WriteListRemove, Value: []byte("c"), Count: 1})
	if p := read(t, kv, engine.ReadOptions{Key: list}); fmt.Sprint(p.List) != fmt.Sprint(b("a", "B", "c")) {
		t.Errorf("list = %q", p.List)
	}

	set := scratchKey(t, kv, "set")
	write(t, kv, set, engine.WriteOp{Kind: engine.WriteSetAdd, Values: b("x", "y", "z")})
	write(t, kv, set, engine.WriteOp{Kind: engine.WriteSetRemove, Values: b("y")})
	if p := read(t, kv, engine.ReadOptions{Key: set}); len(p.Set) != 2 {
		t.Errorf("set = %q", p.Set)
	}

	zset := scratchKey(t, kv, "zset")
	write(t, kv, zset, engine.WriteOp{Kind: engine.WriteZSetAdd, ZSet: []engine.ZSetEntry{{Member: []byte("m1"), Score: 2.5}, {Member: []byte("m2"), Score: 1}}})
	write(t, kv, zset, engine.WriteOp{Kind: engine.WriteZSetRemove, Values: b("m2")})
	if p := read(t, kv, engine.ReadOptions{Key: zset, OrderByScore: true}); len(p.ZSet) != 1 || p.ZSet[0].Score != 2.5 {
		t.Errorf("zset = %+v", p.ZSet)
	}

	stream := scratchKey(t, kv, "stream")
	write(t, kv, stream, engine.WriteOp{Kind: engine.WriteStreamAdd, ID: "5-1", Fields: []engine.HashEntry{{Field: []byte("k"), Value: []byte("v")}}})
	write(t, kv, stream, engine.WriteOp{Kind: engine.WriteStreamAdd, Fields: []engine.HashEntry{{Field: []byte("k"), Value: []byte("auto")}}})
	write(t, kv, stream, engine.WriteOp{Kind: engine.WriteStreamDelete, IDs: []string{"5-1"}})
	if p := read(t, kv, engine.ReadOptions{Key: stream}); len(p.Stream) != 1 || string(p.Stream[0].Fields[0].Value) != "auto" {
		t.Errorf("stream = %+v", p.Stream)
	}

	if err := kv.WriteValue(ctx, 0, str, engine.WriteOp{Kind: engine.WriteHashSet, Field: []byte("f"), Value: []byte("v")}); engine.KindOf(err) != engine.KindServer {
		t.Errorf("wrong type err = %v", err)
	}
	if err := kv.WriteValue(ctx, 0, str, engine.WriteOp{Kind: engine.WriteStreamAdd}); engine.KindOf(err) != engine.KindInvalidConfig {
		t.Errorf("empty stream entry err = %v", err)
	}
}

func ptr[T any](v T) *T { return &v }

func kvExpiryRenameDelete(t *testing.T, tg KVTarget) {
	kv, _ := tg.connect(t)
	ctx := context.Background()
	k := scratchKey(t, kv, "expiry")
	write(t, kv, k, engine.WriteOp{Kind: engine.WriteSetString, Value: []byte("v")})
	if err := kv.SetExpiry(ctx, 0, k, ptr(90*time.Second)); err != nil {
		t.Fatal(err)
	}
	if info, _ := kv.KeyInfo(ctx, 0, k); info.TTLMs <= 0 || info.TTLMs > 90_000 {
		t.Errorf("ttl = %d", info.TTLMs)
	}
	if err := kv.SetExpiry(ctx, 0, k, nil); err != nil {
		t.Fatal(err)
	}
	if err := kv.SetExpiry(ctx, 0, k, nil); err != nil {
		t.Errorf("persisting a key without TTL: %v", err)
	}
	if info, _ := kv.KeyInfo(ctx, 0, k); info.TTLMs != engine.NoTTL {
		t.Errorf("ttl after persist = %d", info.TTLMs)
	}
	if err := kv.SetExpiry(ctx, 0, k, ptr(time.Duration(0))); engine.KindOf(err) != engine.KindInvalidConfig {
		t.Errorf("zero ttl err = %v", err)
	}
	if err := kv.SetExpiry(ctx, 0, []byte("no:such:key"), ptr(time.Minute)); engine.KindOf(err) != engine.KindNotFound {
		t.Errorf("missing key err = %v", err)
	}

	hashTag := "{" + strconv.FormatInt(scratchCounter.Add(1), 10) + "}"
	from := scratchKey(t, kv, hashTag+"from")
	to := scratchKey(t, kv, hashTag+"to")
	write(t, kv, from, engine.WriteOp{Kind: engine.WriteSetString, Value: []byte("moved")})
	write(t, kv, to, engine.WriteOp{Kind: engine.WriteSetString, Value: []byte("existing")})
	if err := kv.RenameKey(ctx, 0, from, to, false); engine.KindOf(err) != engine.KindConflict {
		t.Errorf("rename onto existing err = %v", err)
	}
	if err := kv.RenameKey(ctx, 0, from, to, true); err != nil {
		t.Fatal(err)
	}
	if p := read(t, kv, engine.ReadOptions{Key: to}); string(p.String) != "moved" {
		t.Errorf("renamed value = %q", p.String)
	}
	if err := kv.RenameKey(ctx, 0, from, to, true); engine.KindOf(err) != engine.KindNotFound {
		t.Errorf("rename missing err = %v", err)
	}

	many := make([][]byte, 1200)
	for i := range many {
		many[i] = []byte(fmt.Sprintf("test:bulk:%d:%d", scratchCounter.Add(1), i))
		write(t, kv, many[i], engine.WriteOp{Kind: engine.WriteSetString, Value: []byte("x")})
	}
	if n, err := kv.DeleteKeys(ctx, 0, append(many, []byte("no:such:key"))); err != nil || n != 1200 {
		t.Errorf("deleted %d, err = %v", n, err)
	}
}

func kvCommands(t *testing.T, tg KVTarget) {
	kv, _ := tg.connect(t)
	ctx := context.Background()
	run := func(args ...string) engine.Reply {
		t.Helper()
		r, err := kv.ExecuteCommand(ctx, 0, b(args...))
		if err != nil {
			t.Fatalf("%v: %v", args, err)
		}
		return r
	}
	if r := run("PING"); r.Kind != engine.ReplyString || string(r.Bytes) != "PONG" {
		t.Errorf("PING = %+v", r)
	}
	counter := scratchKey(t, kv, "counter")
	if r := run("INCR", string(counter)); r.Kind != engine.ReplyInteger || r.Int != 1 {
		t.Errorf("INCR = %+v", r)
	}
	if r := run("GET", "no:such:key"); r.Kind != engine.ReplyNil {
		t.Errorf("GET missing = %+v", r)
	}
	if r := run("HGETALL", "hash:user:1"); r.Kind != engine.ReplyMap && r.Kind != engine.ReplyArray || len(r.Entries)+len(r.Items) == 0 {
		t.Errorf("HGETALL = %+v", r)
	}
	if r := run("SMEMBERS", "set:tags"); r.Kind != engine.ReplySet || len(r.Items) != 3 {
		t.Errorf("SMEMBERS = %+v", r)
	}
	if r := run("LRANGE", "list:queue", "0", "1"); r.Kind != engine.ReplyArray || len(r.Items) != 2 {
		t.Errorf("LRANGE = %+v", r)
	}
	if r := run("ZSCORE", "zset:scores", "dave"); r.Kind != engine.ReplyDouble && r.Kind != engine.ReplyString {
		t.Errorf("ZSCORE = %+v", r)
	}
	if r := run("NOSUCHCOMMAND"); r.Kind != engine.ReplyError || r.Text == "" {
		t.Errorf("unknown command = %+v", r)
	}
	if r := run("INCR", "str:plain"); r.Kind != engine.ReplyError {
		t.Errorf("INCR on text = %+v", r)
	}
	for args, want := range map[string]engine.Kind{
		"KEYS *": engine.KindKeysRefused, "keys app:*": engine.KindKeysRefused,
		"BLPOP list:queue 0": engine.KindBlockingRefused, "SUBSCRIBE c": engine.KindBlockingRefused, "MONITOR": engine.KindBlockingRefused,
		"SELECT 1": engine.KindInvalidConfig, "MULTI": engine.KindInvalidConfig,
	} {
		fields := strings.Fields(args)
		if _, err := kv.ExecuteCommand(ctx, 0, b(fields...)); engine.KindOf(err) != want {
			t.Errorf("%s: err = %v, want %v", args, err, want)
		}
	}
	if _, err := kv.ExecuteCommand(ctx, 0, b("LRANGE", "big:list", "0", "-1")); engine.KindOf(err) != engine.KindUnsupported {
		t.Errorf("a 100k element reply err = %v, want unsupported", err)
	}
}

func kvPubSub(t *testing.T, tg KVTarget) {
	kv, _ := tg.connect(t)
	channel := fmt.Sprintf("test:chan:%d", time.Now().UnixNano())
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	got := make(chan engine.PubSubMessage, 8)
	done := make(chan error, 1)
	go func() {
		done <- kv.Subscribe(ctx, []string{channel}, []string{"test:pattern:*"}, func(m engine.PubSubMessage) error {
			got <- m
			return nil
		})
	}()
	deadline := time.After(10 * time.Second)
	publishUntil := func(ch, payload string, accept func(engine.PubSubMessage) bool) engine.PubSubMessage {
		t.Helper()
		tick := time.NewTicker(100 * time.Millisecond)
		defer tick.Stop()
		for {
			if _, err := kv.Publish(context.Background(), ch, []byte(payload)); err != nil {
				t.Fatal(err)
			}
			select {
			case m := <-got:
				if accept(m) {
					return m
				}
			case <-tick.C:
			case <-deadline:
				t.Fatalf("no message on %q", ch)
			}
		}
	}
	m := publishUntil(channel, "hello", func(m engine.PubSubMessage) bool { return m.Channel == channel })
	if string(m.Payload) != "hello" || m.Pattern != "" || m.ReceivedAt.IsZero() {
		t.Errorf("message = %+v", m)
	}
	pm := publishUntil("test:pattern:x", "via pattern", func(m engine.PubSubMessage) bool { return m.Pattern != "" })
	if pm.Pattern != "test:pattern:*" || pm.Channel != "test:pattern:x" {
		t.Errorf("pattern message = %+v", pm)
	}
	cancel()
	select {
	case err := <-done:
		if err != nil {
			t.Errorf("subscribe after cancel: %v", err)
		}
	case <-time.After(5 * time.Second):
		t.Fatal("subscribe did not stop after cancel")
	}
	if err := kv.Subscribe(context.Background(), nil, nil, func(engine.PubSubMessage) error { return nil }); engine.KindOf(err) != engine.KindInvalidConfig {
		t.Errorf("empty subscription err = %v", err)
	}
}
