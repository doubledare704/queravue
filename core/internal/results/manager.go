package results

import (
	"errors"
	"fmt"
	"log/slog"
	"os"
	"path/filepath"
	"strconv"
	"sync"

	"github.com/google/uuid"
)

// ErrNotFound means no open result has the id.
var ErrNotFound = errors.New("results: not found")

// Manager owns the spools of all open results.
type Manager struct {
	dir string // per-process spool directory
	cap int64
	log *slog.Logger

	mu     sync.Mutex
	byID   map[string]*entry
	closed bool
}

type entry struct {
	spool   *Spool
	session string
}

// DefaultBaseDir is where spool directories live: <tmp>/queravue-<uid>/spool.
func DefaultBaseDir() string {
	return filepath.Join(os.TempDir(), fmt.Sprintf("queravue-%d", os.Getuid()), "spool")
}

// NewManager creates the process's spool directory under base and sweeps
// directories left by dead processes. capBytes <= 0 means DefaultCap.
func NewManager(base string, capBytes int64, log *slog.Logger) (*Manager, error) {
	if log == nil {
		log = slog.Default()
	}
	if err := os.MkdirAll(base, 0o700); err != nil {
		return nil, fmt.Errorf("results: create spool base: %w", err)
	}
	Sweep(base, os.Getpid(), log)
	dir := filepath.Join(base, strconv.Itoa(os.Getpid()))
	if err := os.MkdirAll(dir, 0o700); err != nil {
		return nil, fmt.Errorf("results: create spool dir: %w", err)
	}
	return &Manager{dir: dir, cap: capBytes, log: log, byID: map[string]*entry{}}, nil
}

// Sweep removes spool directories in base that belong to processes that are
// no longer running. self is never removed.
func Sweep(base string, self int, log *slog.Logger) {
	ents, err := os.ReadDir(base)
	if err != nil {
		return
	}
	for _, e := range ents {
		pid, err := strconv.Atoi(e.Name())
		if !e.IsDir() || err != nil || pid == self || pidAlive(pid) {
			continue
		}
		if err := os.RemoveAll(filepath.Join(base, e.Name())); err != nil {
			log.Warn("sweep spool dir", "dir", e.Name(), "err", err)
			continue
		}
		log.Info("swept stale spool dir", "pid", pid)
	}
}

// Create opens a new spool for a statement of the session and returns its
// result id.
func (m *Manager) Create(sessionID string) (string, *Spool, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	if m.closed {
		return "", nil, ErrClosed
	}
	id := uuid.NewString()
	s, err := newSpool(filepath.Join(m.dir, id+".spool"), m.cap)
	if err != nil {
		return "", nil, err
	}
	m.byID[id] = &entry{spool: s, session: sessionID}
	return id, s, nil
}

// Get returns the spool of a result.
func (m *Manager) Get(id string) (*Spool, error) {
	m.mu.Lock()
	defer m.mu.Unlock()
	e, ok := m.byID[id]
	if !ok {
		return nil, ErrNotFound
	}
	return e.spool, nil
}

// Close discards one result. Unknown ids are ignored.
func (m *Manager) Close(id string) {
	m.mu.Lock()
	e, ok := m.byID[id]
	delete(m.byID, id)
	m.mu.Unlock()
	if ok {
		if err := e.spool.Close(); err != nil {
			m.log.Warn("close spool", "err", err)
		}
	}
}

// CloseSession discards all results of a session.
func (m *Manager) CloseSession(sessionID string) {
	m.mu.Lock()
	var spools []*Spool
	for id, e := range m.byID {
		if e.session == sessionID {
			spools = append(spools, e.spool)
			delete(m.byID, id)
		}
	}
	m.mu.Unlock()
	for _, s := range spools {
		if err := s.Close(); err != nil {
			m.log.Warn("close spool", "err", err)
		}
	}
}

// Len returns the number of open results.
func (m *Manager) Len() int {
	m.mu.Lock()
	defer m.mu.Unlock()
	return len(m.byID)
}

// Shutdown closes every result and removes the process's spool directory.
func (m *Manager) Shutdown() {
	m.mu.Lock()
	m.closed = true
	entries := m.byID
	m.byID = map[string]*entry{}
	m.mu.Unlock()
	for _, e := range entries {
		_ = e.spool.Close()
	}
	_ = os.Remove(m.dir)
}
