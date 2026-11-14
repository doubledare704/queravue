package redis

import (
	"context"
	"time"

	goredis "github.com/redis/go-redis/v9"

	"github.com/doubledare704/queravue/core/internal/engine"
)

const deleteChunk = 500

func toAny(values [][]byte) []any {
	out := make([]any, len(values))
	for i, v := range values {
		out[i] = string(v)
	}
	return out
}

// WriteValue implements engine.KeyValueStore.
func (c *Conn) WriteValue(ctx context.Context, database uint32, key []byte, op engine.WriteOp) error {
	cl, err := c.client(database)
	if err != nil {
		return err
	}
	k := string(key)
	var opErr error
	switch op.Kind {
	case engine.WriteSetString:
		opErr = cl.SetArgs(ctx, k, string(op.Value), goredis.SetArgs{KeepTTL: true}).Err()
	case engine.WriteHashSet:
		opErr = cl.HSet(ctx, k, string(op.Field), string(op.Value)).Err()
	case engine.WriteHashDelete:
		opErr = cl.HDel(ctx, k, string(op.Field)).Err()
	case engine.WriteListPush:
		if op.AtHead {
			opErr = cl.LPush(ctx, k, toAny(op.Values)...).Err()
		} else {
			opErr = cl.RPush(ctx, k, toAny(op.Values)...).Err()
		}
	case engine.WriteListSet:
		opErr = cl.LSet(ctx, k, op.Index, string(op.Value)).Err()
	case engine.WriteListRemove:
		opErr = cl.LRem(ctx, k, op.Count, string(op.Value)).Err()
	case engine.WriteSetAdd:
		opErr = cl.SAdd(ctx, k, toAny(op.Values)...).Err()
	case engine.WriteSetRemove:
		opErr = cl.SRem(ctx, k, toAny(op.Values)...).Err()
	case engine.WriteZSetAdd:
		members := make([]goredis.Z, len(op.ZSet))
		for i, e := range op.ZSet {
			members[i] = goredis.Z{Score: e.Score, Member: string(e.Member)}
		}
		opErr = cl.ZAdd(ctx, k, members...).Err()
	case engine.WriteZSetRemove:
		opErr = cl.ZRem(ctx, k, toAny(op.Values)...).Err()
	case engine.WriteStreamAdd:
		opErr = c.streamAdd(ctx, cl, k, op)
	case engine.WriteStreamDelete:
		opErr = cl.XDel(ctx, k, op.IDs...).Err()
	case engine.WriteJSONSet:
		path := op.JSONPath
		if path == "" {
			path = "$"
		}
		opErr = cl.Do(ctx, "JSON.SET", k, path, op.Value).Err()
	default:
		return engine.Errorf(engine.KindInvalidConfig, c.id, "write value", "unknown edit")
	}
	if opErr != nil {
		if engine.KindOf(opErr) != engine.KindUnknown {
			return opErr
		}
		return c.fail("write value", opErr)
	}
	return nil
}

func (c *Conn) streamAdd(ctx context.Context, cl goredis.UniversalClient, key string, op engine.WriteOp) error {
	id := op.ID
	if id == "" {
		id = "*"
	}
	if len(op.Fields) == 0 {
		return engine.Errorf(engine.KindInvalidConfig, c.id, "write value", "a stream entry needs at least one field")
	}
	args := []any{"XADD", key, id}
	for _, f := range op.Fields {
		args = append(args, string(f.Field), string(f.Value))
	}
	return cl.Do(ctx, args...).Err()
}

// RenameKey implements engine.KeyValueStore.
func (c *Conn) RenameKey(ctx context.Context, database uint32, key, newKey []byte, overwrite bool) error {
	cl, err := c.client(database)
	if err != nil {
		return err
	}
	if overwrite {
		if err := cl.Rename(ctx, string(key), string(newKey)).Err(); err != nil {
			return c.fail("rename key", err)
		}
		return nil
	}
	renamed, err := cl.RenameNX(ctx, string(key), string(newKey)).Result()
	if err != nil {
		return c.fail("rename key", err)
	}
	if !renamed {
		return engine.Errorf(engine.KindConflict, c.id, "rename key", "the new key already exists")
	}
	return nil
}

// SetExpiry implements engine.KeyValueStore.
func (c *Conn) SetExpiry(ctx context.Context, database uint32, key []byte, ttl *time.Duration) error {
	cl, err := c.client(database)
	if err != nil {
		return err
	}
	var applied bool
	if ttl == nil {
		applied, err = cl.Persist(ctx, string(key)).Result()
		if err == nil && !applied {
			if exists, eerr := cl.Exists(ctx, string(key)).Result(); eerr == nil && exists > 0 {
				return nil
			}
		}
	} else {
		if *ttl < time.Millisecond {
			return engine.Errorf(engine.KindInvalidConfig, c.id, "set expiry", "the time to live must be at least 1 ms")
		}
		applied, err = cl.PExpire(ctx, string(key), *ttl).Result()
	}
	if err != nil {
		return c.fail("set expiry", err)
	}
	if !applied {
		return engine.Errorf(engine.KindNotFound, c.id, "set expiry", "key does not exist")
	}
	return nil
}

// DeleteKeys implements engine.KeyValueStore.
func (c *Conn) DeleteKeys(ctx context.Context, database uint32, keys [][]byte) (uint64, error) {
	cl, err := c.client(database)
	if err != nil {
		return 0, err
	}
	var deleted uint64
	for start := 0; start < len(keys); start += deleteChunk {
		chunk := keys[start:min(start+deleteChunk, len(keys))]
		n, err := c.deleteChunk(ctx, cl, chunk)
		deleted += n
		if err != nil {
			return deleted, c.fail("delete keys", err)
		}
	}
	return deleted, nil
}

func (c *Conn) deleteChunk(ctx context.Context, cl goredis.UniversalClient, keys [][]byte) (uint64, error) {
	if c.topo.mode != ModeCluster {
		names := make([]string, len(keys))
		for i, k := range keys {
			names[i] = string(k)
		}
		n, err := cl.Del(ctx, names...).Result()
		return uint64(max(n, 0)), err
	}
	pipe := cl.Pipeline()
	cmds := make([]*goredis.IntCmd, len(keys))
	for i, k := range keys {
		cmds[i] = pipe.Del(ctx, string(k))
	}
	_, err := pipe.Exec(ctx)
	var n uint64
	for _, cmd := range cmds {
		n += uint64(max(cmd.Val(), 0))
	}
	return n, err
}
