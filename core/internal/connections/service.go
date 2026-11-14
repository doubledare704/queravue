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
	"github.com/doubledare704/queravue/core/internal/netpath"
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
	hostKeys *netpath.HostKeys
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

// WithKnownHosts sets the known_hosts files SSH host keys are checked against:
// the user's own (read only) and the one Queravue appends accepted keys to.
func WithKnownHosts(userFile, ownFile string) Option {
	return func(s *Service) { s.hostKeys = netpath.NewHostKeys(userFile, ownFile) }
}

// NewService returns a Service.
func NewService(reg *engine.Registry, store Persister, sec secrets.Store, opts ...Option) *Service {
	s := &Service{
		registry: reg, store: store, secrets: sec,
		log: slog.Default(), now: time.Now, newID: uuid.NewString,
		hostKeys: netpath.NewHostKeys("", ""),
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
	for i := range conns {
		s.migrateLegacyTLS(&conns[i])
	}
	s.conns, s.loaded = conns, true
	return nil
}

// migrateLegacyTLS moves engine-specific TLS params into TLSSettings.
func (s *Service) migrateLegacyTLS(c *Connection) {
	e, ok := s.registry.Get(c.EngineID)
	if !ok {
		return
	}
	family := e.Descriptor().Family
	if c.TLS != nil {
		if rest, dropped := dropKeys(c.Params, netpath.LegacyTLSKeys(family)); dropped {
			c.Params = rest
		}
		return
	}
	if t, rest, ok := netpath.MigrateLegacyTLS(family, c.Params); ok {
		c.TLS, c.Params = fromNetpath(t), rest
	}
}

func dropKeys(params map[string]string, keys []string) (map[string]string, bool) {
	var found bool
	for _, k := range keys {
		if _, ok := params[k]; ok {
			found = true
		}
	}
	if !found {
		return params, false
	}
	out := make(map[string]string, len(params))
	for k, v := range params {
		out[k] = v
	}
	for _, k := range keys {
		delete(out, k)
	}
	return out, true
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
	s.migrateLegacyTLS(&c)
	if err := validateNetwork(c, d); err != nil {
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
func (s *Service) Create(ctx context.Context, c Connection, password *string) (Connection, error) {
	return s.CreateWith(ctx, c, Secrets{Password: password})
}

// CreateWith is Create with tunnel and TLS secrets.
func (s *Service) CreateWith(_ context.Context, c Connection, sec Secrets) (Connection, error) {
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
	clearStoredFlags(&c)
	if sec.Password != nil && *sec.Password != "" {
		ref := secretRef(c.ID)
		if err := s.secrets.Set(ref, *sec.Password); err != nil {
			return Connection{}, fmt.Errorf("connections: store password: %w", err)
		}
		c.SecretRef = ref
	}
	written, _, err := s.applyNetworkSecrets(&c, nil, sec)
	if err != nil {
		s.deleteSecrets(c.SecretRef, written)
		return Connection{}, err
	}
	next := append(slices.Clone(s.conns), c)
	if err := s.store.Save(next); err != nil {
		s.deleteSecrets(c.SecretRef, written)
		return Connection{}, err
	}
	s.conns = next
	return c, nil
}

// Update replaces a connection's settings. password nil keeps the stored
// secret; clearPassword removes it (ignored when password is set).
func (s *Service) Update(ctx context.Context, c Connection, password *string, clearPassword bool) (Connection, error) {
	return s.UpdateWith(ctx, c, Secrets{Password: password, ClearPassword: clearPassword})
}

// UpdateWith is Update with tunnel and TLS secrets.
func (s *Service) UpdateWith(_ context.Context, c Connection, sec Secrets) (Connection, error) {
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

	deleteAfter := []string{}
	switch {
	case sec.Password != nil && *sec.Password != "":
		ref := secretRef(c.ID)
		if err := s.secrets.Set(ref, *sec.Password); err != nil {
			return Connection{}, fmt.Errorf("connections: store password: %w", err)
		}
		c.SecretRef = ref
	case sec.ClearPassword || (sec.Password != nil && *sec.Password == ""):
		if old.SecretRef != "" {
			deleteAfter = append(deleteAfter, old.SecretRef)
		}
		c.SecretRef = ""
	}
	_, stale, err := s.applyNetworkSecrets(&c, &old, sec)
	if err != nil {
		return Connection{}, err
	}
	deleteAfter = append(deleteAfter, stale...)

	next := slices.Clone(s.conns)
	next[i] = c
	if err := s.store.Save(next); err != nil {
		return Connection{}, err
	}
	s.conns = next
	for _, ref := range deleteAfter {
		if err := s.secrets.Delete(ref); err != nil {
			s.log.Warn("delete stale secret", "connection", c.ID, "err", err)
		}
	}
	return c, nil
}

func clearStoredFlags(c *Connection) {
	for _, slot := range allSlots {
		if f := c.flag(slot); f != nil {
			*f = false
		}
	}
}

// applyNetworkSecrets writes the tunnel and TLS secrets sec carries and sets
// the Has flags on c. It returns the refs it wrote and the refs of stored
// secrets that no longer apply, for the caller to delete after saving.
func (s *Service) applyNetworkSecrets(c, old *Connection, sec Secrets) (written, stale []string, err error) {
	for _, slot := range allSlots {
		ref := slotRef(c.ID, slot)
		flag := c.flag(slot)
		oldHad := false
		if old != nil {
			if f := old.flag(slot); f != nil {
				oldHad = *f
			}
		}
		if flag == nil {
			if oldHad {
				stale = append(stale, ref)
			}
			continue
		}
		v := sec.value(slot)
		switch {
		case v != nil && *v != "":
			if err := s.secrets.Set(ref, *v); err != nil {
				s.deleteSecrets("", written)
				return nil, nil, fmt.Errorf("connections: store %s: %w", slot, err)
			}
			written = append(written, ref)
			*flag = true
		case (v != nil && *v == "") || sec.clears(slot):
			*flag = false
			if oldHad {
				stale = append(stale, ref)
			}
		default:
			*flag = oldHad
		}
	}
	return written, stale, nil
}

func (s *Service) deleteSecrets(ref string, refs []string) {
	if ref != "" {
		refs = append(refs, ref)
	}
	for _, r := range refs {
		_ = s.secrets.Delete(r)
	}
}

// Delete removes a connection, then its keychain secrets.
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
	refs := []string{}
	if old.SecretRef != "" {
		refs = append(refs, old.SecretRef)
	}
	for _, slot := range allSlots {
		if f := old.flag(slot); f != nil && *f {
			refs = append(refs, slotRef(id, slot))
		}
	}
	for _, ref := range refs {
		if err := s.secrets.Delete(ref); err != nil {
			s.log.Warn("delete secret", "connection", id, "err", err)
		}
	}
	return nil
}

// TrustHostKey records the host key a failed connect presented.
func (s *Service) TrustHostKey(host string, port int, fingerprint string) error {
	if err := s.hostKeys.Trust(host, port, fingerprint); err != nil {
		var cfg *netpath.ConfigError
		if errors.As(err, &cfg) {
			return engine.Errorf(engine.KindInvalidConfig, "", "trust host key", "%s", cfg.Msg)
		}
		return err
	}
	return nil
}

// TestRequest selects what to test. With both ID and Draft, the draft's
// settings are used and unset secrets fall back to the ones stored for ID.
type TestRequest struct {
	ID       string
	Draft    *Connection
	Password *string
	Secrets  Secrets
	Timeout  time.Duration
}

// Stage is one step of a connection test. Values mirror queravue.v1.TestStage.
type Stage int

// Test stages.
const (
	StageSSH Stage = iota + 1
	StageTLS
	StageAuth
	StagePing
)

// Step is the outcome of one stage.
type Step struct {
	Stage   Stage
	OK      bool
	Elapsed time.Duration
	Err     *engine.Error
}

// TestResult is the outcome of a test. Err is nil on success and an
// *engine.Error otherwise. Steps stop at the first failure.
type TestResult struct {
	Server  engine.ServerInfo
	Connect time.Duration
	Latency time.Duration
	Steps   []Step
	Err     *engine.Error
}

// ClampTimeout applies the default and bounds to a requested test timeout.
func ClampTimeout(d time.Duration) time.Duration {
	if d <= 0 {
		return DefaultTestTimeout
	}
	return min(max(d, MinTestTimeout), MaxTestTimeout)
}

// credentials are the secrets one connect needs, read from the keychain or the request.
type credentials struct {
	db                           engine.Secret
	sshPassword, sshPassphrase   string
	jumpPassword, jumpPassphrase string
	tlsPassphrase                string
}

func (c credentials) redactable() []engine.Secret {
	var out []engine.Secret
	for _, v := range []string{c.sshPassword, c.sshPassphrase, c.jumpPassword, c.jumpPassphrase, c.tlsPassphrase} {
		if v != "" {
			out = append(out, engine.NewSecret(v))
		}
	}
	return append(out, c.db)
}

// loadCredentials reads what target needs. Values in sec win; otherwise the
// keychain entries of saved (if any) are used.
func (s *Service) loadCredentials(target Connection, saved *Connection, password *string, sec Secrets) (credentials, error) {
	var creds credentials
	switch {
	case password != nil:
		creds.db = engine.NewSecret(*password)
	case saved != nil && saved.SecretRef != "":
		v, err := s.read(saved.SecretRef)
		if err != nil {
			return creds, err
		}
		creds.db = engine.NewSecret(v)
	}
	dests := map[secretSlot]*string{
		slotSSHPassword: &creds.sshPassword, slotSSHPassphrase: &creds.sshPassphrase,
		slotJumpPassword: &creds.jumpPassword, slotJumpPassphrase: &creds.jumpPassphrase,
		slotTLSKeyPassphrase: &creds.tlsPassphrase,
	}
	for slot, dst := range dests {
		if target.flag(slot) == nil {
			continue
		}
		if v := sec.value(slot); v != nil {
			*dst = *v
			continue
		}
		if saved == nil || saved.flag(slot) == nil || !*saved.flag(slot) {
			continue
		}
		v, err := s.read(slotRef(saved.ID, slot))
		if err != nil {
			return creds, err
		}
		*dst = v
	}
	return creds, nil
}

func (s *Service) read(ref string) (string, error) {
	v, err := s.secrets.Get(ref)
	switch {
	case errors.Is(err, secrets.ErrNotFound):
		return "", nil
	case err != nil:
		s.log.Warn("read secret", "ref", ref, "err", err)
		return "", errors.New("could not read a secret from the keychain")
	}
	return v, nil
}

// establish opens the tunnel (if configured) and the engine connection. It
// returns the steps it completed or failed, and a tunnel the caller must close
// together with the connection.
func (s *Service) establish(ctx context.Context, eng engine.Engine, target Connection, creds credentials) (engine.Conn, *netpath.Tunnel, []Step, error) {
	var steps []Step
	cfg := engine.Config{EngineID: target.EngineID, Params: target.Params}
	cfg.Net.TLS = target.TLS.netpathSettings(creds.tlsPassphrase)
	var tunnel *netpath.Tunnel
	if target.SSH != nil {
		start := time.Now()
		t, err := netpath.OpenTunnel(ctx, target.SSH.netpathConfig(creds, false), s.hostKeys)
		if err != nil {
			steps = append(steps, failedStep(StageSSH, start, target.EngineID, err, creds))
			return nil, nil, steps, err
		}
		steps = append(steps, Step{Stage: StageSSH, OK: true, Elapsed: time.Since(start)})
		tunnel, cfg.Net.Dial = t, t.DialContext
	}
	start := time.Now()
	conn, err := eng.Connect(ctx, cfg, creds.db)
	if err != nil {
		if tunnel != nil {
			_ = tunnel.Close()
		}
		steps = append(steps, connectFailure(target, start, err, creds)...)
		return nil, nil, steps, err
	}
	elapsed := time.Since(start)
	if target.TLS != nil && target.TLS.Mode > netpath.TLSDisable {
		steps = append(steps, Step{Stage: StageTLS, OK: true, Elapsed: elapsed})
	}
	steps = append(steps, Step{Stage: StageAuth, OK: true, Elapsed: elapsed})
	return conn, tunnel, steps, nil
}

// connectFailure attributes a failed connect to a stage. The engine connects
// and authenticates in one call, so a TLS error is the TLS step, any other
// failure is the step it most likely happened in.
func connectFailure(target Connection, start time.Time, err error, creds credentials) []Step {
	tlsOn := target.TLS != nil && target.TLS.Mode > netpath.TLSDisable
	kind := engine.ClassifyCommon(err)
	var ee *engine.Error
	if errors.As(err, &ee) {
		kind = ee.Kind
	}
	var steps []Step
	failedStage := StageAuth
	switch {
	case kind == engine.KindTLS:
		failedStage = StageTLS
	case tlsOn && kind != engine.KindAuth:
		failedStage = StageTLS
	case tlsOn:
		steps = append(steps, Step{Stage: StageTLS, OK: true, Elapsed: time.Since(start)})
	}
	return append(steps, failedStep(failedStage, start, target.EngineID, err, creds))
}

func failedStep(stage Stage, start time.Time, engineID string, err error, creds credentials) Step {
	return Step{Stage: stage, Elapsed: time.Since(start), Err: asEngineError(engineID, err, creds.redactable()...)}
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
		s.migrateLegacyTLS(&target)
	case saved != nil:
		target = *saved
	default:
		return TestResult{Err: engine.Errorf(engine.KindInvalidConfig, "", "test", "nothing to test")}, nil
	}
	eng, ok := s.registry.Get(target.EngineID)
	if !ok {
		return TestResult{Err: engine.Errorf(engine.KindInvalidConfig, target.EngineID, "test", "unknown engine %q", target.EngineID)}, nil
	}
	if err := validateNetwork(target, eng.Descriptor()); err != nil {
		return TestResult{Err: asEngineError(target.EngineID, err)}, nil
	}
	creds, err := s.loadCredentials(target, saved, req.Password, req.Secrets)
	if err != nil {
		return TestResult{Err: engine.Errorf(engine.KindUnknown, target.EngineID, "test", "%s", err.Error())}, nil
	}

	timeout := ClampTimeout(req.Timeout)
	tctx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()
	res, err := s.runTest(tctx, eng, target, creds)
	if err != nil {
		if ctx.Err() != nil {
			return TestResult{}, fmt.Errorf("connections: test: %w", ctx.Err())
		}
		e := asEngineError(target.EngineID, err, creds.redactable()...)
		if errors.Is(tctx.Err(), context.DeadlineExceeded) {
			e = &engine.Error{Kind: engine.KindTimeout, Engine: e.Engine, Op: e.Op,
				Msg: fmt.Sprintf("timed out after %s", timeout), Err: e}
		}
		res.Err = e
		if n := len(res.Steps); n > 0 && res.Steps[n-1].Err != nil {
			res.Steps[n-1].Err = e
		}
	}
	return res, nil
}

// Release frees what an opened connection holds besides the engine
// connection itself: its SSH tunnel.
type Release func()

// Open connects to a saved connection. A connection that needs an SSH tunnel
// cannot be opened this way, because nothing would close the tunnel: use
// OpenReleasing.
func (s *Service) Open(ctx context.Context, id string) (engine.Conn, engine.Descriptor, error) {
	conn, desc, release, err := s.OpenReleasing(ctx, id)
	if err != nil {
		return nil, engine.Descriptor{}, err
	}
	if release != nil {
		release()
		_ = conn.Close()
		return nil, engine.Descriptor{}, engine.Errorf(engine.KindInvalidConfig, desc.ID, "open", "this connection uses an SSH tunnel; open it through a session")
	}
	return conn, desc, nil
}

// OpenReleasing connects to a saved connection and returns the live Conn, its
// engine's descriptor, and a Release that closes the tunnel (nil without
// one). The caller owns the Conn and must close it, then call Release. ctx
// bounds only the connect; failures are *engine.Error (or ErrNotFound).
func (s *Service) OpenReleasing(ctx context.Context, id string) (engine.Conn, engine.Descriptor, func(), error) {
	c, err := s.Get(ctx, id)
	if err != nil {
		return nil, engine.Descriptor{}, nil, err
	}
	eng, ok := s.registry.Get(c.EngineID)
	if !ok {
		return nil, engine.Descriptor{}, nil, engine.Errorf(engine.KindInvalidConfig, c.EngineID, "open", "unknown engine %q", c.EngineID)
	}
	creds, err := s.loadCredentials(c, &c, nil, Secrets{})
	if err != nil {
		return nil, engine.Descriptor{}, nil, engine.Errorf(engine.KindUnknown, c.EngineID, "open", "%s", err.Error())
	}
	cctx, cancel := context.WithTimeout(ctx, DefaultTestTimeout)
	defer cancel()
	conn, tunnel, _, err := s.establish(cctx, eng, c, creds)
	if err != nil {
		if ctx.Err() != nil {
			return nil, engine.Descriptor{}, nil, fmt.Errorf("connections: open: %w", ctx.Err())
		}
		e := asEngineError(c.EngineID, err, creds.redactable()...)
		if errors.Is(cctx.Err(), context.DeadlineExceeded) {
			e = &engine.Error{Kind: engine.KindTimeout, Engine: e.Engine, Op: e.Op,
				Msg: fmt.Sprintf("timed out after %s", DefaultTestTimeout), Err: e}
		}
		return nil, engine.Descriptor{}, nil, e
	}
	var release func()
	if tunnel != nil {
		release = func() { _ = tunnel.Close() }
	}
	return conn, eng.Descriptor(), release, nil
}

func (s *Service) runTest(ctx context.Context, eng engine.Engine, target Connection, creds credentials) (TestResult, error) {
	var res TestResult
	start := time.Now()
	conn, tunnel, steps, err := s.establish(ctx, eng, target, creds)
	res.Steps = steps
	if err != nil {
		return res, err
	}
	defer func() {
		_ = conn.Close()
		if tunnel != nil {
			_ = tunnel.Close()
		}
	}()
	res.Connect = time.Since(start)

	start = time.Now()
	if err := conn.Ping(ctx); err != nil {
		res.Steps = append(res.Steps, failedStep(StagePing, start, target.EngineID, err, creds))
		return res, err
	}
	res.Latency = time.Since(start)
	res.Steps = append(res.Steps, Step{Stage: StagePing, OK: true, Elapsed: res.Latency})

	info, err := conn.ServerInfo(ctx)
	if err != nil {
		return res, err
	}
	res.Server = info
	return res, nil
}

// asEngineError guarantees a typed, redacted error.
func asEngineError(engineID string, err error, secret ...engine.Secret) *engine.Error {
	var e *engine.Error
	if errors.As(err, &e) {
		cp := *e
		cp.Msg = engine.Redact(cp.Msg, secret...)
		return &cp
	}
	return &engine.Error{
		Kind: engine.ClassifyCommon(err), Engine: engineID, Op: "test",
		Msg: engine.Redact(err.Error(), secret...), Err: err,
	}
}

func validateNetwork(c Connection, d engine.Descriptor) error {
	if c.SSH != nil {
		if !d.SupportsSSH {
			return engine.Errorf(engine.KindInvalidConfig, d.ID, "validate", "%s cannot be reached through an SSH tunnel", d.DisplayName)
		}
		if err := validateTunnel(c.SSH, d.ID, false); err != nil {
			return err
		}
	}
	if c.TLS != nil {
		if !d.SupportsTLS {
			return engine.Errorf(engine.KindInvalidConfig, d.ID, "validate", "%s does not support TLS settings", d.DisplayName)
		}
		if c.TLS.Mode < netpath.TLSUnset || c.TLS.Mode > netpath.TLSVerifyFull {
			return engine.Errorf(engine.KindInvalidConfig, d.ID, "validate", "unknown TLS mode")
		}
	}
	return nil
}

func validateTunnel(t *SSHTunnel, engineID string, jump bool) error {
	who := "SSH tunnel"
	if jump {
		who = "SSH jump host"
	}
	switch {
	case strings.TrimSpace(t.Host) == "":
		return engine.Errorf(engine.KindInvalidConfig, engineID, "validate", "%s: host is required", who)
	case strings.TrimSpace(t.User) == "":
		return engine.Errorf(engine.KindInvalidConfig, engineID, "validate", "%s: user is required", who)
	case t.Port < 0 || t.Port > 65535:
		return engine.Errorf(engine.KindInvalidConfig, engineID, "validate", "%s: port is out of range", who)
	case t.Auth == netpath.SSHAuthKeyFile && t.KeyFile == "":
		return engine.Errorf(engine.KindInvalidConfig, engineID, "validate", "%s: key file is required", who)
	}
	if t.Jump != nil {
		if jump {
			return engine.Errorf(engine.KindInvalidConfig, engineID, "validate", "only one jump host is supported")
		}
		return validateTunnel(t.Jump, engineID, true)
	}
	return nil
}
