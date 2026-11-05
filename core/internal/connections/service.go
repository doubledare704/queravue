package connections

import (
	"cmp"
	"context"
	"errors"
	"fmt"
	"log/slog"
	"slices"
	"strings"
	"sync"
	"time"

	"github.com/google/uuid"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/secrets"
)

// ErrNotFound means no connection has the requested id.
var ErrNotFound = errors.New("connections: not found")

// Test timeouts.
const (
	DefaultTestTimeout = 10 * time.Second
	MinTestTimeout     = time.Second
	MaxTestTimeout     = 60 * time.Second
)

// Persister loads and saves the full connection list.
type Persister interface {
	Load() ([]Connection, error)
	Save([]Connection) error
}

// Service is the connection manager. It is safe for concurrent use.
type Service struct {
	registry *engine.Registry
	store    Persister
	secrets  secrets.Store
	log      *slog.Logger
	now      func() time.Time
	newID    func() string

	mu     sync.Mutex
	conns  []Connection
	loaded bool
}

// Option configures a Service.
type Option func(*Service)

// WithClock sets the time source (tests).
func WithClock(now func() time.Time) Option { return func(s *Service) { s.now = now } }

// WithIDs sets the id generator (tests).
func WithIDs(f func() string) Option { return func(s *Service) { s.newID = f } }

// WithLogger sets the logger.
func WithLogger(l *slog.Logger) Option { return func(s *Service) { s.log = l } }

// NewService returns a Service.
func NewService(reg *engine.Registry, store Persister, sec secrets.Store, opts ...Option) *Service {
	s := &Service{
		registry: reg, store: store, secrets: sec,
		log: slog.Default(), now: time.Now, newID: uuid.NewString,
	}
	for _, o := range opts {
		o(s)
	}
	return s
}

// Engines returns the registered engine descriptors.
func (s *Service) Engines() []engine.Descriptor {
	es := s.registry.List()
	out := make([]engine.Descriptor, len(es))
	for i, e := range es {
		out[i] = e.Descriptor()
	}
	return out
}

// ParseURI parses a connection string for engineID.
func (s *Service) ParseURI(engineID, uri string) (map[string]string, engine.Secret, error) {
	e, ok := s.registry.Get(engineID)
	if !ok {
		return nil, engine.Secret{}, engine.Errorf(engine.KindInvalidConfig, engineID, "parse uri", "unknown engine %q", engineID)
	}
	if !e.Descriptor().SupportsURI {
		return nil, engine.Secret{}, engine.Errorf(engine.KindInvalidConfig, engineID, "parse uri", "%s does not support connection strings", e.Descriptor().DisplayName)
	}
	cfg, sec, err := e.ParseURI(uri)
	if err != nil {
		return nil, engine.Secret{}, err
	}
	return cfg.Params, sec, nil
}

// load must be called with s.mu held.
func (s *Service) load() error {
	if s.loaded {
		return nil
	}
	conns, err := s.store.Load()
	if err != nil {
		return err
	}
	s.conns, s.loaded = conns, true
	return nil
}

// List returns all connections sorted by folder, then name.
func (s *Service) List(_ context.Context) ([]Connection, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if err := s.load(); err != nil {
		return nil, err
	}
	out := slices.Clone(s.conns)
	slices.SortStableFunc(out, func(a, b Connection) int {
		return cmp.Or(
			cmp.Compare(strings.ToLower(a.Folder), strings.ToLower(b.Folder)),
			cmp.Compare(strings.ToLower(a.Name), strings.ToLower(b.Name)),
		)
	})
	return out, nil
}

// Get returns the connection with id.
func (s *Service) Get(_ context.Context, id string) (Connection, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	if err := s.load(); err != nil {
		return Connection{}, err
	}
	i := s.index(id)
	if i < 0 {
		return Connection{}, ErrNotFound
	}
	return s.conns[i], nil
}

func (s *Service) index(id string) int {
	return slices.IndexFunc(s.conns, func(c Connection) bool { return c.ID == id })
}

// sanitize validates c against its engine and strips params the engine does
// not know, including any password-kind key, so secrets can never reach disk.
func (s *Service) sanitize(c Connection) (Connection, error) {
	c.Name = strings.TrimSpace(c.Name)
	if c.Name == "" {
		return c, engine.Errorf(engine.KindInvalidConfig, c.EngineID, "validate", "Name is required")
	}
	e, ok := s.registry.Get(c.EngineID)
	if !ok {
		return c, engine.Errorf(engine.KindInvalidConfig, c.EngineID, "validate", "unknown engine %q", c.EngineID)
	}
	d := e.Descriptor()
	params := map[string]string{}
	for k, v := range c.Params {
		if d.KnownKey(k) && v != "" {
			params[k] = strings.TrimSpace(v)
		}
	}
	c.Params = params
	if err := d.Validate(engine.Config{EngineID: c.EngineID, Params: params}); err != nil {
		return c, err
	}
	c.Folder = NormalizeFolder(c.Folder)
	if c.Color < ColorNone || c.Color > ColorGray {
		c.Color = ColorNone
	}
	return c, nil
}

// Create saves a new connection. A non-empty password is stored in the
// keychain before the config is written.
func (s *Service) Create(_ context.Context, c Connection, password *string) (Connection, error) {
	c, err := s.sanitize(c)
	if err != nil {
		return Connection{}, err
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if err := s.load(); err != nil {
		return Connection{}, err
	}
	now := s.now().UTC()
	c.ID, c.CreatedAt, c.UpdatedAt, c.SecretRef = s.newID(), now, now, ""
	if password != nil && *password != "" {
		ref := secretRef(c.ID)
		if err := s.secrets.Set(ref, *password); err != nil {
			return Connection{}, fmt.Errorf("connections: store password: %w", err)
		}
		c.SecretRef = ref
	}
	next := append(slices.Clone(s.conns), c)
	if err := s.store.Save(next); err != nil {
		if c.SecretRef != "" {
			_ = s.secrets.Delete(c.SecretRef)
		}
		return Connection{}, err
	}
	s.conns = next
	return c, nil
}

// Update replaces a connection's settings. password nil keeps the stored
// secret; clearPassword removes it (ignored when password is set).
func (s *Service) Update(_ context.Context, c Connection, password *string, clearPassword bool) (Connection, error) {
	c, err := s.sanitize(c)
	if err != nil {
		return Connection{}, err
	}
	s.mu.Lock()
	defer s.mu.Unlock()
	if err := s.load(); err != nil {
		return Connection{}, err
	}
	i := s.index(c.ID)
	if i < 0 {
		return Connection{}, ErrNotFound
	}
	old := s.conns[i]
	c.CreatedAt, c.UpdatedAt, c.SecretRef = old.CreatedAt, s.now().UTC(), old.SecretRef

	deleteAfter := ""
	switch {
	case password != nil && *password != "":
		ref := secretRef(c.ID)
		if err := s.secrets.Set(ref, *password); err != nil {
			return Connection{}, fmt.Errorf("connections: store password: %w", err)
		}
		c.SecretRef = ref
	case clearPassword || (password != nil && *password == ""):
		deleteAfter, c.SecretRef = old.SecretRef, ""
	}

	next := slices.Clone(s.conns)
	next[i] = c
	if err := s.store.Save(next); err != nil {
		return Connection{}, err
	}
	s.conns = next
	if deleteAfter != "" {
		if err := s.secrets.Delete(deleteAfter); err != nil {
			s.log.Warn("delete stale secret", "connection", c.ID, "err", err)
		}
	}
	return c, nil
}

// Delete removes a connection, then its keychain secret.
func (s *Service) Delete(_ context.Context, id string) error {
	s.mu.Lock()
	defer s.mu.Unlock()
	if err := s.load(); err != nil {
		return err
	}
	i := s.index(id)
	if i < 0 {
		return ErrNotFound
	}
	old := s.conns[i]
	next := slices.Delete(slices.Clone(s.conns), i, i+1)
	if err := s.store.Save(next); err != nil {
		return err
	}
	s.conns = next
	if old.SecretRef != "" {
		if err := s.secrets.Delete(old.SecretRef); err != nil {
			s.log.Warn("delete secret", "connection", id, "err", err)
		}
	}
	return nil
}

// TestRequest selects what to test. With both ID and Draft, the draft's
// settings are used and the password falls back to the one stored for ID.
type TestRequest struct {
	ID       string
	Draft    *Connection
	Password *string
	Timeout  time.Duration
}

// TestResult is the outcome of a test. Err is nil on success and an
// *engine.Error otherwise.
type TestResult struct {
	Server  engine.ServerInfo
	Connect time.Duration
	Latency time.Duration
	Err     *engine.Error
}

// ClampTimeout applies the default and bounds to a requested test timeout.
func ClampTimeout(d time.Duration) time.Duration {
	if d <= 0 {
		return DefaultTestTimeout
	}
	return min(max(d, MinTestTimeout), MaxTestTimeout)
}

// Test connects, pings, reads server info and disconnects. Failures are
// returned in TestResult.Err; the error return is only for ErrNotFound and
// cancellation by the caller.
func (s *Service) Test(ctx context.Context, req TestRequest) (TestResult, error) {
	var saved *Connection
	if req.ID != "" {
		c, err := s.Get(ctx, req.ID)
		if err != nil {
			return TestResult{}, err
		}
		saved = &c
	}
	var target Connection
	switch {
	case req.Draft != nil:
		target = *req.Draft
	case saved != nil:
		target = *saved
	default:
		return TestResult{Err: engine.Errorf(engine.KindInvalidConfig, "", "test", "nothing to test")}, nil
	}
	eng, ok := s.registry.Get(target.EngineID)
	if !ok {
		return TestResult{Err: engine.Errorf(engine.KindInvalidConfig, target.EngineID, "test", "unknown engine %q", target.EngineID)}, nil
	}

	var secret engine.Secret
	switch {
	case req.Password != nil:
		secret = engine.NewSecret(*req.Password)
	case saved != nil && saved.SecretRef != "":
		pw, err := s.secrets.Get(saved.SecretRef)
		switch {
		case errors.Is(err, secrets.ErrNotFound):
		case err != nil:
			s.log.Warn("read secret", "connection", saved.ID, "err", err)
			return TestResult{Err: engine.Errorf(engine.KindUnknown, target.EngineID, "test", "could not read the password from the keychain")}, nil
		default:
			secret = engine.NewSecret(pw)
		}
	}

	timeout := ClampTimeout(req.Timeout)
	tctx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()
	res, err := runTest(tctx, eng, engine.Config{EngineID: target.EngineID, Params: target.Params}, secret)
	if err != nil {
		if ctx.Err() != nil {
			return TestResult{}, fmt.Errorf("connections: test: %w", ctx.Err())
		}
		e := asEngineError(target.EngineID, err, secret)
		if errors.Is(tctx.Err(), context.DeadlineExceeded) {
			e = &engine.Error{Kind: engine.KindTimeout, Engine: e.Engine, Op: e.Op,
				Msg: fmt.Sprintf("timed out after %s", timeout), Err: e}
		}
		res.Err = e
	}
	return res, nil
}

// Open connects to a saved connection and returns the live Conn together with
// its engine's descriptor. The caller owns the Conn and must Close it. ctx
// bounds only the connect; failures are *engine.Error (or ErrNotFound).
func (s *Service) Open(ctx context.Context, id string) (engine.Conn, engine.Descriptor, error) {
	c, err := s.Get(ctx, id)
	if err != nil {
		return nil, engine.Descriptor{}, err
	}
	eng, ok := s.registry.Get(c.EngineID)
	if !ok {
		return nil, engine.Descriptor{}, engine.Errorf(engine.KindInvalidConfig, c.EngineID, "open", "unknown engine %q", c.EngineID)
	}
	var secret engine.Secret
	if c.SecretRef != "" {
		pw, err := s.secrets.Get(c.SecretRef)
		switch {
		case errors.Is(err, secrets.ErrNotFound):
		case err != nil:
			s.log.Warn("read secret", "connection", c.ID, "err", err)
			return nil, engine.Descriptor{}, engine.Errorf(engine.KindUnknown, c.EngineID, "open", "could not read the password from the keychain")
		default:
			secret = engine.NewSecret(pw)
		}
	}
	cctx, cancel := context.WithTimeout(ctx, DefaultTestTimeout)
	defer cancel()
	conn, err := eng.Connect(cctx, engine.Config{EngineID: c.EngineID, Params: c.Params}, secret)
	if err != nil {
		if ctx.Err() != nil {
			return nil, engine.Descriptor{}, fmt.Errorf("connections: open: %w", ctx.Err())
		}
		e := asEngineError(c.EngineID, err, secret)
		if errors.Is(cctx.Err(), context.DeadlineExceeded) {
			e = &engine.Error{Kind: engine.KindTimeout, Engine: e.Engine, Op: e.Op,
				Msg: fmt.Sprintf("timed out after %s", DefaultTestTimeout), Err: e}
		}
		return nil, engine.Descriptor{}, e
	}
	return conn, eng.Descriptor(), nil
}

func runTest(ctx context.Context, eng engine.Engine, cfg engine.Config, secret engine.Secret) (TestResult, error) {
	var res TestResult
	start := time.Now()
	conn, err := eng.Connect(ctx, cfg, secret)
	if err != nil {
		return res, err
	}
	defer func() { _ = conn.Close() }()
	res.Connect = time.Since(start)

	start = time.Now()
	if err := conn.Ping(ctx); err != nil {
		return res, err
	}
	res.Latency = time.Since(start)

	info, err := conn.ServerInfo(ctx)
	if err != nil {
		return res, err
	}
	res.Server = info
	return res, nil
}

// asEngineError guarantees a typed, redacted error.
func asEngineError(engineID string, err error, secret engine.Secret) *engine.Error {
	var e *engine.Error
	if errors.As(err, &e) {
		cp := *e
		cp.Msg = engine.Redact(cp.Msg, secret)
		return &cp
	}
	return &engine.Error{
		Kind: engine.ClassifyCommon(err), Engine: engineID, Op: "test",
		Msg: engine.Redact(err.Error(), secret), Err: err,
	}
}
