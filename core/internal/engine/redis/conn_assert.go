package redis

import "github.com/doubledare704/queravue/core/internal/engine"

var _ engine.KeyValueStore = (*Conn)(nil)
