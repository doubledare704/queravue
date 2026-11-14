package redis

import (
	"context"
	"errors"
	"fmt"
	"math/big"
	"slices"
	"strconv"
	"strings"

	goredis "github.com/redis/go-redis/v9"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/rediscli"
)

const maxReplyNodes = 100_000

// Commands that change per-connection state would leak into the pool.
var statefulCommands = map[string]bool{
	"SELECT": true, "HELLO": true, "AUTH": true, "MULTI": true, "EXEC": true,
	"DISCARD": true, "WATCH": true, "UNWATCH": true, "RESET": true,
}

// Commands whose top-level RESP3 reply is a set; go-redis returns it as a list.
var setReplyCommands = map[string]bool{"SMEMBERS": true, "SINTER": true, "SUNION": true, "SDIFF": true}

// ExecuteCommand implements engine.KeyValueStore.
func (c *Conn) ExecuteCommand(ctx context.Context, database uint32, args [][]byte) (engine.Reply, error) {
	if len(args) == 0 {
		return engine.Reply{}, engine.Errorf(engine.KindInvalidConfig, c.id, "command", "the command is empty")
	}
	name := strings.ToUpper(string(args[0]))
	verdict := rediscli.Inspect(args)
	switch {
	case verdict.Keys:
		return engine.Reply{}, engine.Errorf(engine.KindKeysRefused, c.id, "command", "KEYS walks the whole keyspace and blocks the server; use the key browser (SCAN) instead")
	case verdict.Blocking:
		return engine.Reply{}, engine.Errorf(engine.KindBlockingRefused, c.id, "command", "%s would hold the connection open; use the pub/sub viewer (Subscribe) for subscriptions", name)
	case statefulCommands[name]:
		return engine.Reply{}, engine.Errorf(engine.KindInvalidConfig, c.id, "command", "%s changes connection state and is not supported here; choose the database in the toolbar", name)
	}
	cl, err := c.client(database)
	if err != nil {
		return engine.Reply{}, err
	}
	cmd := goredis.NewCmd(ctx, toAny(args)...)
	err = cl.Process(ctx, cmd)
	switch {
	case err == nil:
	case errors.Is(err, goredis.Nil):
		return engine.Reply{Kind: engine.ReplyNil}, nil
	case isServerReply(err):
		return engine.Reply{Kind: engine.ReplyError, Text: err.Error()}, nil
	default:
		return engine.Reply{}, c.fail("command", err)
	}
	budget := maxReplyNodes
	reply, err := convertReply(cmd.Val(), setReplyCommands[name], &budget)
	if err != nil {
		return engine.Reply{}, engine.Errorf(engine.KindUnsupported, c.id, "command", "the reply has more than %d elements; page through it with SCAN, LRANGE or similar", maxReplyNodes)
	}
	return reply, nil
}

var errReplyTooLarge = fmt.Errorf("reply too large")

func convertReply(v any, asSet bool, budget *int) (engine.Reply, error) {
	if *budget--; *budget < 0 {
		return engine.Reply{}, errReplyTooLarge
	}
	switch x := v.(type) {
	case nil:
		return engine.Reply{Kind: engine.ReplyNil}, nil
	case string:
		return engine.Reply{Kind: engine.ReplyString, Bytes: []byte(x)}, nil
	case int64:
		return engine.Reply{Kind: engine.ReplyInteger, Int: x}, nil
	case float64:
		return engine.Reply{Kind: engine.ReplyDouble, Float: x}, nil
	case bool:
		return engine.Reply{Kind: engine.ReplyBoolean, Bool: x}, nil
	case *big.Int:
		return engine.Reply{Kind: engine.ReplyString, Bytes: []byte(x.String())}, nil
	case goredis.Error:
		return engine.Reply{Kind: engine.ReplyError, Text: x.Error()}, nil
	case []any:
		kind := engine.ReplyArray
		if asSet {
			kind = engine.ReplySet
		}
		out := engine.Reply{Kind: kind, Items: make([]engine.Reply, 0, len(x))}
		for _, item := range x {
			r, err := convertReply(item, false, budget)
			if err != nil {
				return engine.Reply{}, err
			}
			out.Items = append(out.Items, r)
		}
		return out, nil
	case map[any]any:
		return convertMap(x, budget)
	}
	return engine.Reply{Kind: engine.ReplyString, Bytes: []byte(fmt.Sprint(v))}, nil
}

// convertMap sorts entries by key: go-redis hands maps over unordered.
func convertMap(m map[any]any, budget *int) (engine.Reply, error) {
	out := engine.Reply{Kind: engine.ReplyMap, Entries: make([]engine.ReplyEntry, 0, len(m))}
	for k, v := range m {
		key, err := convertReply(k, false, budget)
		if err != nil {
			return engine.Reply{}, err
		}
		val, err := convertReply(v, false, budget)
		if err != nil {
			return engine.Reply{}, err
		}
		out.Entries = append(out.Entries, engine.ReplyEntry{Key: key, Value: val})
	}
	slices.SortFunc(out.Entries, func(a, b engine.ReplyEntry) int {
		return strings.Compare(sortKey(a.Key), sortKey(b.Key))
	})
	return out, nil
}

func sortKey(r engine.Reply) string {
	if r.Kind == engine.ReplyInteger {
		return strconv.FormatInt(r.Int, 10)
	}
	return string(r.Bytes)
}
