package redis

import (
	"context"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"unicode/utf8"

	goredis "github.com/redis/go-redis/v9"

	"github.com/doubledare704/queravue/core/internal/engine"
)

const maxJSONMemoryBytes = 16 << 20

// ReadValue implements engine.KeyValueStore.
func (c *Conn) ReadValue(ctx context.Context, opts engine.ReadOptions) (engine.ValuePage, error) {
	cl, err := c.client(opts.Database)
	if err != nil {
		return engine.ValuePage{}, err
	}
	if opts.PageSize <= 0 {
		opts.PageSize = engine.DefaultValuePageSize
	}
	if opts.MaxBytes <= 0 {
		opts.MaxBytes = engine.DefaultStringMaxBytes
	}
	k := string(opts.Key)
	typeName, err := cl.Type(ctx, k).Result()
	if err != nil {
		return engine.ValuePage{}, c.fail("read value", err)
	}
	var page engine.ValuePage
	switch typeName {
	case "none":
		return engine.ValuePage{}, engine.Errorf(engine.KindNotFound, c.id, "read value", "key does not exist")
	case "string":
		page, err = c.readString(ctx, cl, k, opts)
	case "hash":
		page, err = readHash(ctx, cl, k, opts)
	case "list":
		page, err = readList(ctx, cl, k, opts)
	case "set":
		page, err = readSet(ctx, cl, k, opts)
	case "zset":
		page, err = readZSet(ctx, cl, k, opts)
	case "stream":
		page, err = readStream(ctx, cl, k, opts)
	case "ReJSON-RL":
		page, err = readJSON(ctx, cl, k)
	default:
		return engine.ValuePage{}, engine.Errorf(engine.KindUnsupported, c.id, "read value", "values of type %q cannot be browsed; use the command line", typeName)
	}
	if err != nil {
		var ee *engine.Error
		if errors.As(err, &ee) {
			ee.Engine = c.id
			return engine.ValuePage{}, ee
		}
		return engine.ValuePage{}, c.fail("read value", err)
	}
	return page, nil
}

func (c *Conn) readString(ctx context.Context, cl goredis.UniversalClient, k string, o engine.ReadOptions) (engine.ValuePage, error) {
	offset, err := parseOffset(o.Cursor)
	if err != nil {
		return engine.ValuePage{}, badCursor(err)
	}
	head, err := cl.GetRange(ctx, k, 0, 3).Result()
	if err != nil {
		return engine.ValuePage{}, err
	}
	if head == "HYLL" {
		n, err := cl.PFCount(ctx, k).Result()
		if err != nil {
			return engine.ValuePage{}, err
		}
		return engine.ValuePage{Type: engine.KeyTypeHyperLogLog, Cardinality: uint64(n)}, nil
	}
	total, err := cl.StrLen(ctx, k).Result()
	if err != nil {
		return engine.ValuePage{}, err
	}
	data := ""
	if offset < total {
		data, err = cl.GetRange(ctx, k, offset, offset+int64(o.MaxBytes)-1).Result()
		if err != nil {
			return engine.ValuePage{}, err
		}
	}
	chunk := []byte(data)
	if offset+int64(len(chunk)) < total {
		chunk = chunk[:len(chunk)-incompleteRuneTail(chunk)]
	}
	page := engine.ValuePage{Type: engine.KeyTypeString, String: chunk, TotalBytes: uint64(total), Binary: !utf8.Valid(chunk)}
	if next := offset + int64(len(chunk)); next < total && len(chunk) > 0 {
		page.NextCursor = strconv.FormatInt(next, 10)
	}
	return page, nil
}

// incompleteRuneTail returns how many trailing bytes start a UTF-8 sequence
// that the chunk ends in the middle of.
func incompleteRuneTail(b []byte) int {
	for n := 1; n <= min(utf8.UTFMax-1, len(b)); n++ {
		r := b[len(b)-n:]
		if utf8.RuneStart(r[0]) {
			if !utf8.FullRune(r) {
				return n
			}
			return 0
		}
	}
	return 0
}

func readHash(ctx context.Context, cl goredis.UniversalClient, k string, o engine.ReadOptions) (engine.ValuePage, error) {
	cursor, err := parseOffsetU(o.Cursor)
	if err != nil {
		return engine.ValuePage{}, badCursor(err)
	}
	flat, next, err := cl.HScan(ctx, k, cursor, "", int64(o.PageSize)).Result()
	if err != nil {
		return engine.ValuePage{}, err
	}
	page := engine.ValuePage{Type: engine.KeyTypeHash, NextCursor: nextScanCursor(next)}
	for i := 0; i+1 < len(flat); i += 2 {
		page.Hash = append(page.Hash, engine.HashEntry{Field: []byte(flat[i]), Value: []byte(flat[i+1])})
	}
	return page, nil
}

func readSet(ctx context.Context, cl goredis.UniversalClient, k string, o engine.ReadOptions) (engine.ValuePage, error) {
	cursor, err := parseOffsetU(o.Cursor)
	if err != nil {
		return engine.ValuePage{}, badCursor(err)
	}
	members, next, err := cl.SScan(ctx, k, cursor, "", int64(o.PageSize)).Result()
	if err != nil {
		return engine.ValuePage{}, err
	}
	page := engine.ValuePage{Type: engine.KeyTypeSet, NextCursor: nextScanCursor(next)}
	for _, m := range members {
		page.Set = append(page.Set, []byte(m))
	}
	return page, nil
}

func readList(ctx context.Context, cl goredis.UniversalClient, k string, o engine.ReadOptions) (engine.ValuePage, error) {
	offset, err := parseOffset(o.Cursor)
	if err != nil {
		return engine.ValuePage{}, badCursor(err)
	}
	length, err := cl.LLen(ctx, k).Result()
	if err != nil {
		return engine.ValuePage{}, err
	}
	size := int64(o.PageSize)
	lo, hi := offset, offset+size-1
	if o.Reverse {
		hi = length - 1 - offset
		lo = max(0, hi-size+1)
	}
	page := engine.ValuePage{Type: engine.KeyTypeList, ListStart: uint64(max(lo, 0))}
	if offset >= length {
		return page, nil
	}
	items, err := cl.LRange(ctx, k, lo, hi).Result()
	if err != nil {
		return engine.ValuePage{}, err
	}
	for _, it := range items {
		page.List = append(page.List, []byte(it))
	}
	if o.Reverse {
		for i, j := 0, len(page.List)-1; i < j; i, j = i+1, j-1 {
			page.List[i], page.List[j] = page.List[j], page.List[i]
		}
		page.ListStart = uint64(max(hi, 0))
	}
	if next := offset + int64(len(items)); next < length && len(items) > 0 {
		page.NextCursor = strconv.FormatInt(next, 10)
	}
	return page, nil
}

func readZSet(ctx context.Context, cl goredis.UniversalClient, k string, o engine.ReadOptions) (engine.ValuePage, error) {
	page := engine.ValuePage{Type: engine.KeyTypeZSet}
	if !o.OrderByScore {
		cursor, err := parseOffsetU(o.Cursor)
		if err != nil {
			return page, badCursor(err)
		}
		flat, next, err := cl.ZScan(ctx, k, cursor, "", int64(o.PageSize)).Result()
		if err != nil {
			return page, err
		}
		for i := 0; i+1 < len(flat); i += 2 {
			score, err := strconv.ParseFloat(flat[i+1], 64)
			if err != nil {
				return page, fmt.Errorf("zset score %q: %w", flat[i+1], err)
			}
			page.ZSet = append(page.ZSet, engine.ZSetEntry{Member: []byte(flat[i]), Score: score})
		}
		page.NextCursor = nextScanCursor(next)
		return page, nil
	}
	offset, err := parseOffset(o.Cursor)
	if err != nil {
		return page, badCursor(err)
	}
	stop := offset + int64(o.PageSize) - 1
	var entries []goredis.Z
	if o.Reverse {
		entries, err = cl.ZRevRangeWithScores(ctx, k, offset, stop).Result()
	} else {
		entries, err = cl.ZRangeWithScores(ctx, k, offset, stop).Result()
	}
	if err != nil {
		return page, err
	}
	for _, z := range entries {
		member, _ := z.Member.(string)
		page.ZSet = append(page.ZSet, engine.ZSetEntry{Member: []byte(member), Score: z.Score})
	}
	if len(entries) == o.PageSize {
		page.NextCursor = strconv.FormatInt(offset+int64(len(entries)), 10)
	}
	return page, nil
}

func readStream(ctx context.Context, cl goredis.UniversalClient, k string, o engine.ReadOptions) (engine.ValuePage, error) {
	start, end, name := "-", "+", "XRANGE"
	if o.Reverse {
		start, end, name = "+", "-", "XREVRANGE"
	}
	if o.Cursor != "" {
		start = o.Cursor
	}
	reply, err := cl.Do(ctx, name, k, start, end, "COUNT", o.PageSize).Slice()
	if err != nil {
		return engine.ValuePage{}, err
	}
	page := engine.ValuePage{Type: engine.KeyTypeStream}
	for _, raw := range reply {
		entry, ok := parseStreamEntry(raw)
		if !ok {
			return page, fmt.Errorf("unexpected stream entry reply %T", raw)
		}
		page.Stream = append(page.Stream, entry)
	}
	if len(page.Stream) == o.PageSize {
		if next, ok := adjacentStreamID(page.Stream[len(page.Stream)-1].ID, o.Reverse); ok {
			page.NextCursor = next
		}
	}
	return page, nil
}

func parseStreamEntry(raw any) (engine.StreamEntry, bool) {
	pair, ok := raw.([]any)
	if !ok || len(pair) != 2 {
		return engine.StreamEntry{}, false
	}
	id, _ := pair[0].(string)
	entry := engine.StreamEntry{ID: id}
	switch fields := pair[1].(type) {
	case []any:
		for i := 0; i+1 < len(fields); i += 2 {
			f, _ := fields[i].(string)
			v, _ := fields[i+1].(string)
			entry.Fields = append(entry.Fields, engine.HashEntry{Field: []byte(f), Value: []byte(v)})
		}
	case map[any]any:
		for f, v := range fields {
			fs, _ := f.(string)
			vs, _ := v.(string)
			entry.Fields = append(entry.Fields, engine.HashEntry{Field: []byte(fs), Value: []byte(vs)})
		}
	}
	return entry, true
}

// adjacentStreamID returns the id just after (or, reversed, before) id, so a
// paged read can continue without the exclusive "(" range form (Redis 6.2+).
func adjacentStreamID(id string, reverse bool) (string, bool) {
	msText, seqText, ok := strings.Cut(id, "-")
	ms, err1 := strconv.ParseUint(msText, 10, 64)
	seq, err2 := strconv.ParseUint(seqText, 10, 64)
	if !ok || err1 != nil || err2 != nil {
		return "", false
	}
	switch {
	case !reverse && seq < ^uint64(0):
		return fmt.Sprintf("%d-%d", ms, seq+1), true
	case !reverse && ms < ^uint64(0):
		return fmt.Sprintf("%d-0", ms+1), true
	case reverse && seq > 0:
		return fmt.Sprintf("%d-%d", ms, seq-1), true
	case reverse && ms > 0:
		return fmt.Sprintf("%d-%d", ms-1, ^uint64(0)), true
	}
	return "", false
}

func readJSON(ctx context.Context, cl goredis.UniversalClient, k string) (engine.ValuePage, error) {
	if m, err := cl.MemoryUsage(ctx, k).Result(); err == nil && m > maxJSONMemoryBytes {
		return engine.ValuePage{}, engine.Errorf(engine.KindUnsupported, "redis", "read value",
			"document uses %d MiB; read parts of it with JSON.GET <key> <path> on the command line", m>>20)
	}
	text, err := cl.Do(ctx, "JSON.GET", k, "$").Text()
	if err != nil {
		return engine.ValuePage{}, err
	}
	return engine.ValuePage{Type: engine.KeyTypeJSON, JSON: text}, nil
}

func nextScanCursor(next uint64) string {
	if next == 0 {
		return ""
	}
	return strconv.FormatUint(next, 10)
}

func parseOffset(cursor string) (int64, error) {
	if cursor == "" {
		return 0, nil
	}
	n, err := strconv.ParseInt(cursor, 10, 64)
	if err != nil || n < 0 {
		return 0, fmt.Errorf("cursor %q", cursor)
	}
	return n, nil
}

func parseOffsetU(cursor string) (uint64, error) {
	if cursor == "" {
		return 0, nil
	}
	return strconv.ParseUint(cursor, 10, 64)
}

func badCursor(err error) error {
	return &engine.Error{Kind: engine.KindInvalidConfig, Engine: ID, Op: "read value", Msg: "the cursor is not valid for this key", Err: err}
}
