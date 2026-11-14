// Package session keeps live database connections for the UI. A session owns
// one engine.Conn; statements on it run one at a time. Idle sessions close
// themselves.
package session

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"sync"
	"time"

	"github.com/google/uuid"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

// DefaultIdleTimeout closes sessions that run nothing for this long.
const DefaultIdleTimeout = 30 * time.Minute

var (
	// ErrNotFound means no open session has the id.
	ErrNotFound = errors.New("session: not found")
	// ErrBusy means the session is already running a statement.
	ErrBusy = errors.New("session: busy")
)

// Opener connects to a saved connection. *connections.Service implements it.
type Opener interface {
	Open(ctx context.Context, connectionID string) (engine.Conn, engine.Descriptor, error)
}

// ReleasingOpener is an Opener whose connections hold more than the Conn, such
// as an SSH tunnel. The release function runs after the Conn is closed.
type ReleasingOpener interface {
	OpenReleasing(ctx context.Context, connectionID string) (engine.Conn, engine.Descriptor, func(), error)
}

// Session is one live connection.
type Session struct {
	// ID identifies the session on the wire.
	ID string
	// ConnectionID is the ID of the saved connection profile.
	ConnectionID string
	// Conn is the live connection. Use it only inside a Begin/finish pair.
	Conn engine.Conn
	// Desc is the engine descriptor.
	Desc engine.Descriptor
	// Dialect is the SQL dialect of the engine; nil if it is not a SQL engine.
	Dialect sqldialect.Dialect

	now     func() time.Time
	release func()

	runMu sync.Mutex // held while a statement runs

	mu       sync.Mutex
	cancel   context.CancelFunc
	lastUsed time.Time
	closed   bool
}

// Begin marks the session busy and returns a context to run a statement
// with; Cancel cancels it. Call finish when the statement ends. ErrBusy if a
// statement is already running.
func (s *Session) Begin(parent context.Context) (ctx context.Context, finish func(), err error) {
	if !s.runMu.TryLock() {
		return nil, nil, ErrBusy
	}
	s.mu.Lock()
	if s.closed {
		s.mu.Unlock()
		s.runMu.Unlock()
		return nil, nil, ErrNotFound
	}
	ctx, cancel := context.WithCancel(parent)
	s.cancel = cancel
	s.lastUsed = s.now()
	s.mu.Unlock()
	return ctx, func() {
		cancel()
		s.mu.Lock()
		s.cancel = nil
		s.lastUsed = s.now()
		s.mu.Unlock()
		s.runMu.Unlock()
	}, nil
}

// Cancel cancels the running statement, if any.
func (s *Session) Cancel() {
	s.mu.Lock()
	c := s.cancel
	s.mu.Unlock()
	if c != nil {
		c()
	}
}

func (s *Session) idleSince() (time.Time, bool) {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.lastUsed, s.cancel == nil
}

// shutdown cancels any statement, waits for it, and closes the connection.
func (s *Session) shutdown() error {
	s.mu.Lock()
	s.closed = true
	s.mu.Unlock()
	s.Cancel()
	s.runMu.Lock()
	defer s.runMu.Unlock()
	err := s.Conn.Close()
	if s.release != nil {
		s.release()
	}
	return err
}

// Manager owns all open sessions.
type Manager struct {
	opener  Opener
	idle    time.Duration
	log     *slog.Logger
	now     func() time.Time
	onClose func(sessionID string)
	onOpen  func(*Session)

	mu       sync.Mutex
	sessions map[string]*Session
	stop     chan struct{}
	stopped  bool
}

// Option configures a Manager.
type Option func(*Manager)

// WithIdleTimeout sets the idle timeout; <= 0 keeps the default.
func WithIdleTimeout(d time.Duration) Option {
	return func(m *Manager) {
		if d > 0 {
			m.idle = d
		}
	}
}

// WithClock sets the time source (tests).
func WithClock(now func() time.Time) Option { return func(m *Manager) { m.now = now } }

// WithLogger sets the logger.
func WithLogger(l *slog.Logger) Option { return func(m *Manager) { m.log = l } }

// WithOnClose registers a hook called after a session closes, for example to
// drop its spooled results.
func WithOnClose(f func(sessionID string)) Option { return func(m *Manager) { m.onClose = f } }

// WithOnOpen registers a hook called after a session opens, for example to
// warm its schema catalog in the background. It must not block.
func WithOnOpen(f func(*Session)) Option { return func(m *Manager) { m.onOpen = f } }

// NewManager returns a Manager and starts its idle sweeper. Call Shutdown to
// stop it and close all sessions.
func NewManager(opener Opener, opts ...Option) *Manager {
	m := &Manager{
		opener: opener, idle: DefaultIdleTimeout, log: slog.Default(), now: time.Now,
		sessions: map[string]*Session{}, stop: make(chan struct{}),
	}
	for _, o := range opts {
		o(m)
	}
	go m.janitor()
	return m
}

// Open connects and registers a session.
func (m *Manager) Open(ctx context.Context, connectionID string) (*Session, error) {
	var (
		conn    engine.Conn
		desc    engine.Descriptor
		release func()
		err     error
	)
	if ro, ok := m.opener.(ReleasingOpener); ok {
		conn, desc, release, err = ro.OpenReleasing(ctx, connectionID)
	} else {
		conn, desc, err = m.opener.Open(ctx, connectionID)
	}
	if err != nil {
		return nil, err
	}
	s := &Session{ID: uuid.NewString(), ConnectionID: connectionID, Conn: conn, Desc: desc, now: m.now, lastUsed: m.now(), release: release}
	s.Dialect, _ = sqldialect.Of(conn)
	m.mu.Lock()
	if m.stopped {
		m.mu.Unlock()
		_ = conn.Close()
		if release != nil {
			release()
		}
		return nil, fmt.Errorf("session: manager is shut down")
	}
	m.sessions[s.ID] = s
	m.mu.Unlock()
	if m.onOpen != nil {
		m.onOpen(s)
	}
	return s, nil
}

// Get returns an open session.
func (m *Manager) Get(id string) (*Session, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	s, ok := m.sessions[id]
	if !ok {
		return nil, ErrNotFound
	}
	return s, nil
}

// Close ends a session. Unknown ids are ignored.
func (m *Manager) Close(id string) {
	m.mu.Lock()
	s, ok := m.sessions[id]
	delete(m.sessions, id)
	m.mu.Unlock()
	if ok {
		m.finish(s)
	}
}

func (m *Manager) finish(s *Session) {
	if err := s.shutdown(); err != nil {
		m.log.Warn("close session connection", "session", s.ID, "err", err)
	}
	if m.onClose != nil {
		m.onClose(s.ID)
	}
}

// Len returns the number of open sessions.
func (m *Manager) Len() int {
	m.mu.Lock()
	defer m.mu.Unlock()
	return len(m.sessions)
}

// Sweep closes sessions idle for longer than the timeout and returns how many.
func (m *Manager) Sweep() int {
	now := m.now()
	var victims []*Session
	m.mu.Lock()
	for id, s := range m.sessions {
		if last, idle := s.idleSince(); idle && now.Sub(last) > m.idle {
			victims = append(victims, s)
			delete(m.sessions, id)
		}
	}
	m.mu.Unlock()
	for _, s := range victims {
		m.log.Info("closing idle session", "session", s.ID)
		m.finish(s)
	}
	return len(victims)
}

func (m *Manager) janitor() {
	every := min(max(m.idle/4, time.Second), time.Minute)
	t := time.NewTicker(every)
	defer t.Stop()
	for {
		select {
		case <-t.C:
			m.Sweep()
		case <-m.stop:
			return
		}
	}
}

// Shutdown stops the sweeper and closes every session.
func (m *Manager) Shutdown() {
	m.mu.Lock()
	if m.stopped {
		m.mu.Unlock()
		return
	}
	m.stopped = true
	close(m.stop)
	all := m.sessions
	m.sessions = map[string]*Session{}
	m.mu.Unlock()
	for _, s := range all {
		m.finish(s)
	}
}
