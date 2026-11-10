package completion

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"sync"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/session"
)

// Progress counts what a warm-up has loaded.
type Progress struct {
	SchemasTotal  int
	SchemasDone   int
	TablesLoaded  int
	ColumnsLoaded int
	Done          bool
	Err           error
}

// ErrNotSupported means the connection cannot list schemas and columns.
var ErrNotSupported = errors.New("completion: connection cannot list schemas and columns")

type entryKey struct{ session, database string }

type entry struct {
	mu         sync.Mutex
	snapshot   *Snapshot
	progress   Progress
	changed    chan struct{}
	done       chan struct{}
	cancel     context.CancelFunc
	watchers   int
	started    bool
	background bool
	failedAt   time.Time
}

const retryAfterFailure = 5 * time.Second

func newEntry() *entry {
	return &entry{changed: make(chan struct{}), done: make(chan struct{})}
}

func (e *entry) publish(snapshot *Snapshot, p Progress) {
	e.mu.Lock()
	if snapshot != nil {
		e.snapshot = snapshot
	}
	e.progress = p
	close(e.changed)
	e.changed = make(chan struct{})
	e.mu.Unlock()
}

// Manager keeps one catalog per session and database and warms them in the
// background.
type Manager struct {
	root context.Context
	stop context.CancelFunc

	mu      sync.Mutex
	entries map[entryKey]*entry
	recent  map[string]*Recency

	mongo *MongoCatalog
}

// Mongo returns the catalog that backs Mongo completion.
func (m *Manager) Mongo() *MongoCatalog { return m.mongo }

// NewManager returns a Manager. Call Shutdown to cancel running warm-ups.
func NewManager() *Manager {
	root, stop := context.WithCancel(context.Background())
	return &Manager{root: root, stop: stop, entries: map[entryKey]*entry{}, recent: map[string]*Recency{}, mongo: NewMongoCatalog()}
}

// Shutdown cancels every warm-up.
func (m *Manager) Shutdown() { m.stop() }

func (m *Manager) entryFor(sessionID, database string) *entry {
	m.mu.Lock()
	defer m.mu.Unlock()
	k := entryKey{sessionID, database}
	e, ok := m.entries[k]
	if !ok {
		e = newEntry()
		m.entries[k] = e
	}
	return e
}

// Snapshot returns what is cached for the session and database, never nil.
func (m *Manager) Snapshot(sessionID, database string) *Snapshot {
	m.mu.Lock()
	e, ok := m.entries[entryKey{sessionID, database}]
	m.mu.Unlock()
	if !ok {
		return newSnapshot(StateCold, nil, nil)
	}
	e.mu.Lock()
	defer e.mu.Unlock()
	if e.snapshot == nil {
		return newSnapshot(StateCold, nil, nil)
	}
	return e.snapshot
}

// Recency returns the session's recently used names.
func (m *Manager) Recency(sessionID string) *Recency {
	m.mu.Lock()
	defer m.mu.Unlock()
	r, ok := m.recent[sessionID]
	if !ok {
		r = NewRecency()
		m.recent[sessionID] = r
	}
	return r
}

// Start begins warming in the background if nothing has loaded or is loading.
func (m *Manager) Start(sess *session.Session, database string) {
	e := m.entryFor(sess.ID, database)
	e.mu.Lock()
	running := e.started
	e.mu.Unlock()
	if !running {
		m.begin(sess, database, e)
	}
}

// Watch makes sure a warm-up runs and reports its progress until it ends or
// ctx is cancelled. Callers share one load; when the last watcher leaves
// before the load ends, the load is cancelled unless Start began it.
func (m *Manager) Watch(ctx context.Context, sess *session.Session, database string, report func(Progress) error) error {
	e := m.entryFor(sess.ID, database)
	e.mu.Lock()
	started := e.started
	e.watchers++
	e.mu.Unlock()
	if !started {
		m.begin(sess, database, e)
	}
	defer m.leave(e)
	for {
		e.mu.Lock()
		p, changed, done := e.progress, e.changed, e.done
		e.mu.Unlock()
		if err := report(p); err != nil {
			return err
		}
		if p.Done {
			return nil
		}
		select {
		case <-changed:
		case <-done:
		case <-ctx.Done():
			return fmt.Errorf("completion: watch: %w", ctx.Err())
		}
	}
}

func (m *Manager) leave(e *entry) {
	e.mu.Lock()
	e.watchers--
	cancel := e.cancel
	stopLoad := e.watchers == 0 && !e.progress.Done && !e.background
	e.mu.Unlock()
	if stopLoad && cancel != nil {
		cancel()
	}
}

// Invalidate drops the catalogs of a session and warms them again on the next
// Start or Complete.
func (m *Manager) Invalidate(sessionID string) {
	m.mongo.Invalidate(sessionID)
	m.mu.Lock()
	var victims []*entry
	for k, e := range m.entries {
		if k.session == sessionID {
			victims = append(victims, e)
			delete(m.entries, k)
		}
	}
	m.mu.Unlock()
	for _, e := range victims {
		e.mu.Lock()
		cancel := e.cancel
		e.mu.Unlock()
		if cancel != nil {
			cancel()
		}
	}
}

// CloseSession cancels warm-ups and forgets everything about a session.
func (m *Manager) CloseSession(sessionID string) {
	m.Invalidate(sessionID)
	m.mu.Lock()
	delete(m.recent, sessionID)
	m.mu.Unlock()
}

func (m *Manager) begin(sess *session.Session, database string, e *entry) {
	e.mu.Lock()
	if e.started || !e.failedAt.IsZero() && time.Since(e.failedAt) < retryAfterFailure {
		e.mu.Unlock()
		return
	}
	e.started = true
	select {
	case <-e.done:
		e.done = make(chan struct{})
		e.progress = Progress{}
	default:
	}
	ctx, cancel := context.WithCancel(m.root)
	e.cancel = cancel
	e.background = e.watchers == 0
	e.mu.Unlock()
	go func() {
		defer cancel()
		err := warm(ctx, sess, database, e)
		failed := err != nil && ctx.Err() == nil
		if failed {
			slog.Warn("completion: catalog warm-up failed", "error", err)
		}
		e.mu.Lock()
		p := e.progress
		p.Done, p.Err = true, err
		done := e.done
		e.mu.Unlock()
		e.publish(nil, p)
		e.mu.Lock()
		if failed {
			e.started, e.failedAt = false, time.Now()
		}
		e.mu.Unlock()
		close(done)
	}()
}

func warm(ctx context.Context, sess *session.Session, database string, e *entry) error {
	inspector, ok := engine.As[engine.SchemaInspector](sess.Conn)
	if !ok {
		return ErrNotSupported
	}
	lister, ok := engine.As[engine.ColumnLister](sess.Conn)
	if !ok {
		return ErrNotSupported
	}
	var schemas []string
	if err := withConn(ctx, sess, func(ctx context.Context) (err error) {
		schemas, err = inspector.ListSchemas(ctx, database)
		return err
	}); err != nil {
		return err
	}
	w := warmer{entry: e, schemas: schemas, byKey: map[string][]*Table{}}
	w.progress.SchemasTotal = len(schemas)
	e.publish(newSnapshot(StateWarming, schemas, nil), w.progress)

	for _, schema := range schemas {
		var objects []engine.SchemaObject
		if err := withConn(ctx, sess, func(ctx context.Context) (err error) {
			objects, err = inspector.ListObjects(ctx, database, schema)
			return err
		}); err != nil {
			return err
		}
		tables := make([]*Table, 0, len(objects))
		for _, o := range objects {
			tables = append(tables, &Table{Schema: schema, Name: o.Name, View: o.Type == engine.ObjectTypeView || o.Type == engine.ObjectTypeMaterializedView})
		}
		w.byKey[schema] = tables
		w.progress.TablesLoaded += len(tables)
		w.publish(StateWarming)

		var refs []engine.ColumnRef
		if err := withConn(ctx, sess, func(ctx context.Context) (err error) {
			refs, err = lister.ListColumns(ctx, database, schema)
			return err
		}); err != nil {
			return err
		}
		tables = withColumns(tables, refs)
		w.byKey[schema] = tables
		w.progress.ColumnsLoaded += len(refs)
		w.progress.SchemasDone++
		w.publish(StateWarming)
	}
	w.publish(StateReady)
	return nil
}

type warmer struct {
	entry    *entry
	schemas  []string
	byKey    map[string][]*Table
	progress Progress
}

func (w *warmer) publish(state State) {
	var all []*Table
	for _, schema := range w.schemas {
		all = append(all, w.byKey[schema]...)
	}
	w.entry.publish(newSnapshot(state, w.schemas, all), w.progress)
}

// withColumns returns copies of tables holding refs' columns, so snapshots
// already handed out are never modified.
func withColumns(tables []*Table, refs []engine.ColumnRef) []*Table {
	out := make([]*Table, len(tables))
	byName := make(map[string]*Table, len(tables))
	for i, t := range tables {
		c := *t
		out[i] = &c
		byName[t.Name] = &c
	}
	for _, r := range refs {
		if t, ok := byName[r.Table]; ok {
			t.Columns = append(t.Columns, Column{Name: r.Name, Type: r.TypeName})
		}
	}
	return out
}

func withConn(ctx context.Context, sess *session.Session, f func(context.Context) error) error {
	return sess.RunWhenFree(ctx, f)
}
