package engine

import "context"

// KeyValueStore is implemented by Conns with CapKeyValueStore (ADR 0020). The
// operations arrive with the Redis engine; this interface only reserves the
// capability.
type KeyValueStore interface {
	// ScanKeys pages through keys with SCAN, never KEYS, until ctx is cancelled
	// or the scan ends.
	ScanKeys(ctx context.Context, database uint32, pattern string, pageSize int, emit func(keys [][]byte) error) error
}
