package redis

import (
	"context"
	"errors"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
)

// Subscribe implements engine.KeyValueStore.
func (c *Conn) Subscribe(ctx context.Context, channels, patterns []string, emit func(engine.PubSubMessage) error) error {
	if len(channels)+len(patterns) == 0 {
		return engine.Errorf(engine.KindInvalidConfig, c.id, "subscribe", "name at least one channel or pattern")
	}
	cl, err := c.client(0)
	if err != nil {
		return err
	}
	ps := cl.Subscribe(ctx, channels...)
	defer func() { _ = ps.Close() }()
	if len(patterns) > 0 {
		if err := ps.PSubscribe(ctx, patterns...); err != nil {
			return c.fail("subscribe", err)
		}
	}
	for {
		msg, err := ps.ReceiveMessage(ctx)
		switch {
		case err == nil:
		case ctx.Err() != nil:
			return nil
		case errors.Is(err, context.Canceled):
			return nil
		default:
			return c.fail("subscribe", err)
		}
		m := engine.PubSubMessage{Channel: msg.Channel, Pattern: msg.Pattern, Payload: []byte(msg.Payload), ReceivedAt: time.Now()}
		if err := emit(m); err != nil {
			return err
		}
	}
}

// Publish implements engine.KeyValueStore.
func (c *Conn) Publish(ctx context.Context, channel string, payload []byte) (uint64, error) {
	cl, err := c.client(0)
	if err != nil {
		return 0, err
	}
	n, err := cl.Publish(ctx, channel, string(payload)).Result()
	if err != nil {
		return 0, c.fail("publish", err)
	}
	return uint64(max(n, 0)), nil
}
