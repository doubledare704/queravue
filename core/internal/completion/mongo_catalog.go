package completion

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/session"
)

const (
	pathsTTL       = 5 * time.Minute
	collectionsTTL = 30 * time.Second

	defaultSampleSize = 100
	maxSampleSize     = 1000
	defaultMaxDepth   = 6
	maxMaxDepth       = 12
)

type flight[V any] struct {
	done chan struct{}
	val  V
	err  error
	at   time.Time
}

type ttlCache[K comparable, V any] struct {
	mu        sync.Mutex
	ttl       time.Duration
	now       func() time.Time
	bySession map[string]map[K]*flight[V]
}

func newTTLCache[K comparable, V any](ttl time.Duration) *ttlCache[K, V] {
	return &ttlCache[K, V]{ttl: ttl, now: time.Now, bySession: map[string]map[K]*flight[V]{}}
}

func (c *ttlCache[K, V]) get(ctx context.Context, sessionID string, key K, refresh bool, compute func(context.Context) (V, error)) (V, error) {
	c.mu.Lock()
	entries := c.bySession[sessionID]
	if entries == nil {
		entries = map[K]*flight[V]{}
		c.bySession[sessionID] = entries
	}
	if f := entries[key]; f != nil && !refresh {
		select {
		case <-f.done:
			if f.err == nil && c.now().Sub(f.at) < c.ttl {
				c.mu.Unlock()
				return f.val, nil
			}
		default:
			c.mu.Unlock()
			return waitFor(ctx, f)
		}
	}
	f := &flight[V]{done: make(chan struct{})}
	entries[key] = f
	c.mu.Unlock()

	go func() {
		val, err := compute(context.WithoutCancel(ctx))
		f.val, f.err, f.at = val, err, c.now()
		close(f.done)
		if err != nil {
			c.mu.Lock()
			if entries[key] == f {
				delete(entries, key)
			}
			c.mu.Unlock()
		}
	}()
	return waitFor(ctx, f)
}

func waitFor[V any](ctx context.Context, f *flight[V]) (V, error) {
	select {
	case <-f.done:
		return f.val, f.err
	case <-ctx.Done():
		var zero V
		return zero, fmt.Errorf("completion: waiting for the server: %w", context.Cause(ctx))
	}
}

func (c *ttlCache[K, V]) invalidate(sessionID string) {
	c.mu.Lock()
	delete(c.bySession, sessionID)
	c.mu.Unlock()
}

type pathsKey struct {
	database, collection string
	sampleSize           uint32
	maxDepth             int
}

type collectionsKey struct{ database string }

// MongoCatalog caches what Mongo completion needs from the server: sampled
// field paths per collection and collection names per database.
type MongoCatalog struct {
	paths       *ttlCache[pathsKey, engine.FieldPathSample]
	collections *ttlCache[collectionsKey, []string]
}

// NewMongoCatalog returns an empty catalog.
func NewMongoCatalog() *MongoCatalog {
	return &MongoCatalog{
		paths:       newTTLCache[pathsKey, engine.FieldPathSample](pathsTTL),
		collections: newTTLCache[collectionsKey, []string](collectionsTTL),
	}
}

// PathsRequest selects the collection to sample.
type PathsRequest struct {
	Database, Collection string
	Options              engine.PathSampleOptions
	Refresh              bool
}

// FieldPaths returns sampled field paths, from the cache while fresh.
func (m *MongoCatalog) FieldPaths(ctx context.Context, sess *session.Session, req PathsRequest) (engine.FieldPathSample, error) {
	ds, ok := engine.As[engine.DocumentStore](sess.Conn)
	if !ok {
		return engine.FieldPathSample{}, ErrNotSupported
	}
	opts := req.Options
	if opts.SampleSize == 0 {
		opts.SampleSize = defaultSampleSize
	}
	opts.SampleSize = min(opts.SampleSize, maxSampleSize)
	if opts.MaxDepth <= 0 {
		opts.MaxDepth = defaultMaxDepth
	}
	opts.MaxDepth = min(opts.MaxDepth, maxMaxDepth)
	key := pathsKey{req.Database, req.Collection, opts.SampleSize, opts.MaxDepth}
	return m.paths.get(ctx, sess.ID, key, req.Refresh, func(ctx context.Context) (engine.FieldPathSample, error) {
		return ds.SampleFieldPaths(ctx, req.Database, req.Collection, opts)
	})
}

// Collections returns the collection and view names of a database.
func (m *MongoCatalog) Collections(ctx context.Context, sess *session.Session, database string) ([]string, error) {
	inspector, ok := engine.As[engine.SchemaInspector](sess.Conn)
	if !ok || database == "" {
		return nil, ErrNotSupported
	}
	return m.collections.get(ctx, sess.ID, collectionsKey{database}, false, func(ctx context.Context) ([]string, error) {
		objects, err := inspector.ListObjects(ctx, database, "")
		if err != nil {
			return nil, fmt.Errorf("completion: list collections: %w", err)
		}
		names := make([]string, 0, len(objects))
		for _, o := range objects {
			names = append(names, o.Name)
		}
		return names, nil
	})
}

// Invalidate drops everything cached for a session.
func (m *MongoCatalog) Invalidate(sessionID string) {
	m.paths.invalidate(sessionID)
	m.collections.invalidate(sessionID)
}
