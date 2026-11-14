package redis

import (
	"cmp"
	"context"
	"fmt"
	"slices"
	"strconv"
	"strings"
	"sync"

	goredis "github.com/redis/go-redis/v9"

	"github.com/doubledare704/queravue/core/internal/engine"
)

const (
	defaultDatabaseLimit = 16
	bigKeyElements       = 10_000
	bigKeyBytes          = 10 << 20
	maxScanPage          = 10_000
)

var typeNames = map[engine.KeyType]string{
	engine.KeyTypeString: "string", engine.KeyTypeHash: "hash", engine.KeyTypeList: "list",
	engine.KeyTypeSet: "set", engine.KeyTypeZSet: "zset", engine.KeyTypeStream: "stream",
	engine.KeyTypeJSON: "ReJSON-RL",
}

func keyTypeOf(name string) engine.KeyType {
	for t, n := range typeNames {
		if n == name {
			return t
		}
	}
	return engine.KeyTypeUnknown
}

// ListDatabases implements engine.KeyValueStore.
func (c *Conn) ListDatabases(ctx context.Context) (engine.KVDatabases, error) {
	cl, err := c.client(0)
	if err != nil {
		return engine.KVDatabases{}, err
	}
	counts := map[uint32]engine.KVDatabase{}
	collect := func(ctx context.Context, node *goredis.Client) error {
		text, err := node.Info(ctx, "keyspace").Result()
		if err != nil {
			return err
		}
		for k, v := range infoFields(text) {
			idx, ok := strings.CutPrefix(k, "db")
			n, perr := strconv.ParseUint(idx, 10, 32)
			if !ok || perr != nil {
				continue
			}
			db := counts[uint32(n)]
			db.Index = uint32(n)
			for _, kv := range strings.Split(v, ",") {
				name, val, _ := strings.Cut(kv, "=")
				num, _ := strconv.ParseUint(val, 10, 64)
				switch name {
				case "keys":
					db.KeyCount += num
				case "expires":
					db.ExpiringCount += num
				}
			}
			counts[uint32(n)] = db
		}
		return nil
	}
	limit := uint32(1)
	if cc, ok := cl.(*goredis.ClusterClient); ok {
		var mu sync.Mutex
		err = cc.ForEachMaster(ctx, func(ctx context.Context, node *goredis.Client) error {
			mu.Lock()
			defer mu.Unlock()
			return collect(ctx, node)
		})
	} else {
		err = collect(ctx, cl.(*goredis.Client))
		limit = c.databaseLimit(ctx, cl)
	}
	if err != nil {
		return engine.KVDatabases{}, c.fail("list databases", err)
	}
	if _, ok := counts[0]; !ok {
		counts[0] = engine.KVDatabase{}
	}
	out := engine.KVDatabases{DatabaseLimit: limit}
	for _, db := range counts {
		out.Databases = append(out.Databases, db)
	}
	slices.SortFunc(out.Databases, func(a, b engine.KVDatabase) int { return cmp.Compare(a.Index, b.Index) })
	return out, nil
}

func (c *Conn) databaseLimit(ctx context.Context, cl goredis.UniversalClient) uint32 {
	vals, err := cl.ConfigGet(ctx, "databases").Result()
	if err != nil {
		return defaultDatabaseLimit
	}
	n, err := strconv.ParseUint(vals["databases"], 10, 32)
	if err != nil || n == 0 {
		return defaultDatabaseLimit
	}
	return uint32(n)
}

// ScanKeys implements engine.KeyValueStore.
func (c *Conn) ScanKeys(ctx context.Context, opts engine.ScanOptions, emit func(engine.ScanPage) error) error {
	cl, err := c.client(opts.Database)
	if err != nil {
		return err
	}
	pageSize := opts.PageSize
	if pageSize <= 0 {
		pageSize = engine.DefaultScanPageSize
	}
	pageSize = min(pageSize, maxScanPage)
	typeName := ""
	if opts.TypeFilter != engine.KeyTypeUnknown {
		if typeName = typeNames[opts.TypeFilter]; typeName == "" {
			return engine.Errorf(engine.KindUnsupported, c.id, "scan", "keys cannot be filtered by this type")
		}
	}
	pattern := opts.Pattern
	if pattern == "" {
		pattern = "*"
	}
	scan := scanner{pattern: pattern, typeName: typeName, pageSize: pageSize, filterType: opts.TypeFilter}
	if cc, ok := cl.(*goredis.ClusterClient); ok {
		err = scan.cluster(ctx, cc, emit)
	} else {
		err = scan.node(ctx, cl.(*goredis.Client), emit)
	}
	return c.scanFailure(ctx, err)
}

func (c *Conn) scanFailure(ctx context.Context, err error) error {
	switch {
	case err == nil:
		return nil
	case ctx.Err() != nil:
		return &engine.Error{Kind: engine.KindCanceled, Engine: c.id, Op: "scan", Msg: "scan cancelled", Err: ctx.Err()}
	case engine.KindOf(err) != engine.KindUnknown:
		return err
	}
	return c.fail("scan", err)
}

type scanner struct {
	pattern, typeName string
	pageSize          int
	filterType        engine.KeyType

	mu      sync.Mutex
	scanned uint64
}

func (s *scanner) node(ctx context.Context, node *goredis.Client, emit func(engine.ScanPage) error) error {
	var cursor uint64
	for {
		var keys []string
		var next uint64
		var err error
		if s.typeName != "" {
			keys, next, err = node.ScanType(ctx, cursor, s.pattern, int64(s.pageSize), s.typeName).Result()
		} else {
			keys, next, err = node.Scan(ctx, cursor, s.pattern, int64(s.pageSize)).Result()
		}
		if err != nil {
			return err
		}
		if err := s.emitPage(keys, emit); err != nil {
			return err
		}
		if cursor = next; cursor == 0 {
			return nil
		}
		if err := ctx.Err(); err != nil {
			return fmt.Errorf("redis: scan: %w", err)
		}
	}
}

func (s *scanner) emitPage(keys []string, emit func(engine.ScanPage) error) error {
	page := engine.ScanPage{Keys: make([]engine.KeySummary, len(keys))}
	for i, k := range keys {
		page.Keys[i] = engine.KeySummary{Key: []byte(k), Type: s.filterType, TTLMs: engine.UnknownTTL}
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	s.scanned += uint64(len(keys))
	page.Scanned = s.scanned
	return emit(page)
}

func (s *scanner) cluster(ctx context.Context, cc *goredis.ClusterClient, emit func(engine.ScanPage) error) error {
	ctx, cancel := context.WithCancel(ctx)
	defer cancel()
	return cc.ForEachMaster(ctx, func(ctx context.Context, node *goredis.Client) error {
		err := s.node(ctx, node, emit)
		if err != nil {
			cancel()
		}
		return err
	})
}

// KeyInfo implements engine.KeyValueStore.
func (c *Conn) KeyInfo(ctx context.Context, database uint32, key []byte) (engine.KeyInfo, error) {
	cl, err := c.client(database)
	if err != nil {
		return engine.KeyInfo{}, err
	}
	k := string(key)
	typeName, err := cl.Type(ctx, k).Result()
	if err != nil {
		return engine.KeyInfo{}, c.fail("key info", err)
	}
	t := keyTypeOf(typeName)
	if typeName == "none" {
		return engine.KeyInfo{}, engine.Errorf(engine.KindNotFound, c.id, "key info", "key does not exist")
	}
	pipe := cl.Pipeline()
	ttl := pipe.PTTL(ctx, k)
	enc := pipe.ObjectEncoding(ctx, k)
	mem := pipe.MemoryUsage(ctx, k)
	length := lengthCmd(ctx, pipe, t, k)
	head := pipe.GetRange(ctx, k, 0, 3)
	_, _ = pipe.Exec(ctx)
	if err := ctx.Err(); err != nil {
		return engine.KeyInfo{}, c.fail("key info", err)
	}
	info := engine.KeyInfo{Type: t, TTLMs: engine.NoTTL, Encoding: enc.Val()}
	if v, err := ttl.Result(); err == nil && v >= 0 {
		info.TTLMs = v.Milliseconds()
	}
	if length != nil {
		if n, err := length.Result(); err == nil && n > 0 {
			info.Length = uint64(n)
		}
	}
	if t == engine.KeyTypeString && head.Val() == "HYLL" {
		info.Type = engine.KeyTypeHyperLogLog
	}
	if m, err := mem.Result(); err == nil && m >= 0 {
		u := uint64(m)
		info.MemoryBytes = &u
		info.BigKey = u >= bigKeyBytes
	}
	info.BigKey = info.BigKey || info.Length >= bigKeyElements && t != engine.KeyTypeString || t == engine.KeyTypeString && info.Length >= bigKeyBytes
	return info, nil
}

func lengthCmd(ctx context.Context, pipe goredis.Pipeliner, t engine.KeyType, k string) *goredis.IntCmd {
	switch t {
	case engine.KeyTypeString:
		return pipe.StrLen(ctx, k)
	case engine.KeyTypeHash:
		return pipe.HLen(ctx, k)
	case engine.KeyTypeList:
		return pipe.LLen(ctx, k)
	case engine.KeyTypeSet:
		return pipe.SCard(ctx, k)
	case engine.KeyTypeZSet:
		return pipe.ZCard(ctx, k)
	case engine.KeyTypeStream:
		return pipe.XLen(ctx, k)
	}
	return nil
}
