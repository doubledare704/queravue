package session

import (
	"context"
	"errors"
	"log/slog"
	"sync"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

type fakeConn struct {
	mu     sync.Mutex
	closed int
}

func (c *fakeConn) Ping(context.Context) error { return nil }
func (c *fakeConn) ServerInfo(context.Context) (engine.ServerInfo, error) {
	return engine.ServerInfo{}, nil
}
func (c *fakeConn) Close() error { c.mu.Lock(); c.closed++; c.mu.Unlock(); return nil }

type fakeOpener struct {
	conns []*fakeConn
	err   error
}

func (o *fakeOpener) Open(_ context.Context, id string) (engine.Conn, engine.Descriptor, error) {
	if o.err != nil {
		return nil, engine.Descriptor{}, o.err
	}
	c := &fakeConn{}
	o.conns = append(o.conns, c)
	return c, engine.Descriptor{ID: id, Family: "postgres"}, nil
}

func newMgr(t *testing.T, o Opener, opts ...Option) *Manager {
	t.Helper()
	opts = append([]Option{WithLogger(slog.New(slog.DiscardHandler))}, opts...)
	m := NewManager(o, opts...)
	t.Cleanup(m.Shutdown)
	return m
}

func TestOpenGetClose(t *testing.T) {
	var closedHook []string
	o := &fakeOpener{}
	m := newMgr(t, o, WithOnClose(func(id string) { closedHook = append(closedHook, id) }))
	s, err := m.Open(context.Background(), "pg")
	if err != nil {
		t.Fatal(err)
	}
	if s.Dialect != sqlsplit.Postgres {
		t.Errorf("dialect = %v", s.Dialect)
	}
	if got, err := m.Get(s.ID); err != nil || got != s {
		t.Fatalf("Get: %v", err)
	}
	m.Close(s.ID)
	m.Close(s.ID) // idempotent
	if _, err := m.Get(s.ID); !errors.Is(err, ErrNotFound) {
		t.Errorf("Get after close: %v", err)
	}
	if o.conns[0].closed != 1 || len(closedHook) != 1 || closedHook[0] != s.ID {
		t.Errorf("closed=%d hook=%v", o.conns[0].closed, closedHook)
	}
}

func TestOpenError(t *testing.T) {
	want := errors.New("boom")
	m := newMgr(t, &fakeOpener{err: want})
	if _, err := m.Open(context.Background(), "x"); !errors.Is(err, want) {
		t.Errorf("err = %v", err)
	}
	if m.Len() != 0 {
		t.Error("session registered after failed open")
	}
}

func TestSequentialPerSession(t *testing.T) {
	m := newMgr(t, &fakeOpener{})
	s, _ := m.Open(context.Background(), "pg")
	ctx, finish, err := s.Begin(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	if _, _, err := s.Begin(context.Background()); !errors.Is(err, ErrBusy) {
		t.Errorf("second Begin: %v", err)
	}
	s.Cancel()
	if ctx.Err() == nil {
		t.Error("Cancel did not cancel the run context")
	}
	finish()
	if _, f2, err := s.Begin(context.Background()); err != nil {
		t.Errorf("Begin after finish: %v", err)
	} else {
		f2()
	}
	s.Cancel() // nothing running: no-op
}

func TestIdleTimeout(t *testing.T) {
	var mu sync.Mutex
	now := time.Unix(1000, 0)
	clock := func() time.Time { mu.Lock(); defer mu.Unlock(); return now }
	advance := func(d time.Duration) { mu.Lock(); now = now.Add(d); mu.Unlock() }

	o := &fakeOpener{}
	m := newMgr(t, o, WithIdleTimeout(time.Minute), WithClock(clock))
	idle, _ := m.Open(context.Background(), "a")
	busy, _ := m.Open(context.Background(), "b")
	_, finish, _ := busy.Begin(context.Background())

	advance(30 * time.Second)
	if n := m.Sweep(); n != 0 {
		t.Fatalf("swept %d too early", n)
	}
	advance(2 * time.Minute)
	if n := m.Sweep(); n != 1 {
		t.Fatalf("swept %d, want 1 (a running session must survive)", n)
	}
	if _, err := m.Get(idle.ID); !errors.Is(err, ErrNotFound) {
		t.Error("idle session still open")
	}
	if _, err := m.Get(busy.ID); err != nil {
		t.Error("busy session was closed")
	}
	finish()
	advance(30 * time.Second) // finishing refreshes lastUsed
	if n := m.Sweep(); n != 0 {
		t.Errorf("swept %d right after activity", n)
	}
}

func TestCloseCancelsRunningStatement(t *testing.T) {
	m := newMgr(t, &fakeOpener{})
	s, _ := m.Open(context.Background(), "pg")
	ctx, finish, _ := s.Begin(context.Background())
	done := make(chan struct{})
	go func() { <-ctx.Done(); finish(); close(done) }()
	m.Close(s.ID) // must cancel, wait for finish, then close the conn
	select {
	case <-done:
	case <-time.After(2 * time.Second):
		t.Fatal("running statement was not cancelled")
	}
}
