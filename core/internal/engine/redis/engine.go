// Package redis implements the Redis engine and Valkey on top of
// github.com/redis/go-redis/v9: standalone, Sentinel and Cluster. See
// docs/engines/redis.md and ADR 0020.
package redis

import (
	"context"
	"fmt"
	"net/url"
	"strconv"
	"strings"
	"sync"
	"time"

	goredis "github.com/redis/go-redis/v9"

	"github.com/doubledare704/queravue/core/internal/engine"
)

// Engine ids.
const (
	ID       = "redis"
	IDValkey = "valkey"
)

// Param keys.
const (
	ParamMode        = "mode"
	ParamHosts       = "hosts"
	ParamMasterName  = "master_name"
	ParamUsername    = "username"
	ParamPassword    = "password"
	ParamDatabase    = "database"
	ParamTLS         = "tls"
	ParamTLSCAFile   = "tls_ca_file"
	ParamTLSInsecure = "tls_insecure"
)

// Connection modes.
const (
	ModeStandalone = "standalone"
	ModeSentinel   = "sentinel"
	ModeCluster    = "cluster"
)

// Modes are the supported values of ParamMode.
var Modes = []string{ModeStandalone, ModeSentinel, ModeCluster}

// Variant selects a Redis-compatible server family.
type Variant int

// Variants.
const (
	VariantRedis Variant = iota
	VariantValkey
)

const (
	dialTimeout = 10 * time.Second
	ioTimeout   = 30 * time.Second
	poolSize    = 4
	appName     = "Queravue"
)

// Engine is a Redis-family engine.
type Engine struct {
	variant Variant
	desc    engine.Descriptor
}

// New returns the engine for variant v.
func New(v Variant) *Engine {
	id, name := ID, "Redis"
	if v == VariantValkey {
		id, name = IDValkey, "Valkey"
	}
	return &Engine{variant: v, desc: engine.Descriptor{
		ID: id, DisplayName: name, Family: ID, SupportsURI: true,
		SupportsSSH: true, SupportsTLS: true,
		URIExample: "redis://user@localhost:6379/0",
		Fields: []engine.FieldSpec{
			{Key: ParamMode, Label: "Mode", Kind: engine.FieldSelect, Default: ModeStandalone, Options: Modes},
			{Key: ParamHosts, Label: "Hosts", Kind: engine.FieldText, Required: true, Default: "localhost:6379", Placeholder: "host:port, comma-separated for Sentinel and Cluster"},
			{Key: ParamMasterName, Label: "Sentinel master name", Kind: engine.FieldText, Placeholder: "mymaster"},
			{Key: ParamUsername, Label: "User", Kind: engine.FieldText, Placeholder: "default"},
			{Key: ParamPassword, Label: "Password", Kind: engine.FieldPassword},
			{Key: ParamDatabase, Label: "Database", Kind: engine.FieldInteger, Default: "0"},
			{Key: ParamTLS, Label: "TLS", Kind: engine.FieldBoolean, Default: "false"},
			{Key: ParamTLSCAFile, Label: "CA file", Kind: engine.FieldFile, Placeholder: "/path/to/ca.pem"},
			{Key: ParamTLSInsecure, Label: "Allow invalid certificates", Kind: engine.FieldBoolean, Default: "false"},
		},
		Capabilities: []engine.Capability{engine.CapConnect, engine.CapKeyValueStore},
	}}
}

// Descriptor implements engine.Engine.
func (e *Engine) Descriptor() engine.Descriptor { return e.desc }

// ParseURI implements engine.Engine.
func (e *Engine) ParseURI(uri string) (engine.Config, engine.Secret, error) {
	params, pw, err := parseURI(uri)
	if err != nil {
		return engine.Config{}, engine.Secret{}, engine.Errorf(engine.KindInvalidConfig, e.desc.ID, "parse uri", "%s", err.Error())
	}
	return engine.Config{EngineID: e.desc.ID, Params: params}, engine.NewSecret(pw), nil
}

func parseURI(s string) (map[string]string, string, error) {
	u, err := url.Parse(strings.TrimSpace(s))
	if err != nil {
		return nil, "", fmt.Errorf("malformed URI")
	}
	if u.Scheme != "redis" && u.Scheme != "rediss" && u.Scheme != "valkey" && u.Scheme != "valkeys" {
		return nil, "", fmt.Errorf("unsupported scheme %q; use redis:// or rediss://", u.Scheme)
	}
	params := map[string]string{ParamMode: ModeStandalone}
	if strings.HasSuffix(u.Scheme, "s") {
		params[ParamTLS] = "true"
	}
	if u.Host != "" {
		params[ParamHosts] = u.Host
	}
	var password string
	if u.User != nil {
		params[ParamUsername] = u.User.Username()
		password, _ = u.User.Password()
	}
	if db := strings.Trim(u.Path, "/"); db != "" {
		if _, err := strconv.ParseUint(db, 10, 32); err != nil {
			return nil, "", fmt.Errorf("database %q is not a number", db)
		}
		params[ParamDatabase] = db
	}
	return params, password, nil
}

// Connect implements engine.Engine.
func (e *Engine) Connect(ctx context.Context, cfg engine.Config, secret engine.Secret) (engine.Conn, error) {
	cfg = e.desc.WithDefaults(cfg)
	if err := e.desc.Validate(cfg); err != nil {
		return nil, err
	}
	topo, err := newTopology(cfg, e.desc.ID)
	if err != nil {
		return nil, err
	}
	dial, err := newDialer(cfg)
	if err != nil {
		return nil, &engine.Error{Kind: engine.KindInvalidConfig, Engine: e.desc.ID, Op: "config", Msg: engine.Redact(err.Error(), secret), Err: err}
	}
	c := &Conn{id: e.desc.ID, variant: e.variant, secret: secret, topo: topo, dial: dial, clients: map[uint32]goredis.UniversalClient{}}
	if _, err := c.client(topo.defaultDB); err != nil {
		return nil, err
	}
	if err := c.Ping(ctx); err != nil {
		_ = c.Close()
		return nil, err
	}
	return c, nil
}

// Conn is a live Redis connection. Standalone and Sentinel connections keep
// one small pool per logical database; the driver is safe for concurrent use.
type Conn struct {
	id      string
	variant Variant
	secret  engine.Secret
	topo    topology
	dial    dialFunc

	mu      sync.Mutex
	closed  bool
	clients map[uint32]goredis.UniversalClient
}

func (c *Conn) client(db uint32) (goredis.UniversalClient, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.closed {
		return nil, &engine.Error{Kind: engine.KindConnectionLost, Engine: c.id, Op: "connect", Msg: "connection is closed"}
	}
	if c.topo.mode == ModeCluster {
		if db != 0 {
			return nil, engine.Errorf(engine.KindUnsupported, c.id, "select database", "Redis Cluster has database 0 only")
		}
	}
	if cl, ok := c.clients[db]; ok {
		return cl, nil
	}
	cl := c.topo.newClient(db, c.secret.Reveal(), c.dial)
	c.clients[db] = cl
	return cl, nil
}

func (c *Conn) fail(op string, err error) error {
	return classify(c.id, op, err, c.secret)
}

// Ping implements engine.Conn.
func (c *Conn) Ping(ctx context.Context) error {
	cl, err := c.client(c.topo.defaultDB)
	if err != nil {
		return err
	}
	if err := cl.Ping(ctx).Err(); err != nil {
		return c.fail("ping", err)
	}
	return nil
}

// ServerInfo implements engine.Conn.
func (c *Conn) ServerInfo(ctx context.Context) (engine.ServerInfo, error) {
	cl, err := c.client(c.topo.defaultDB)
	if err != nil {
		return engine.ServerInfo{}, err
	}
	text, err := cl.Info(ctx, "server").Result()
	if err != nil {
		return engine.ServerInfo{}, c.fail("server info", err)
	}
	return parseServerInfo(text, c.variant), nil
}

func parseServerInfo(text string, v Variant) engine.ServerInfo {
	fields := infoFields(text)
	product, version := "Redis", fields["redis_version"]
	if fields["server_name"] == "valkey" || fields["valkey_version"] != "" || v == VariantValkey {
		product = "Valkey"
		if vv := fields["valkey_version"]; vv != "" {
			version = vv
		}
	}
	return engine.ServerInfo{Product: product, Version: version, Banner: strings.TrimSpace(product + " " + version)}
}

func infoFields(text string) map[string]string {
	out := map[string]string{}
	for _, line := range strings.Split(text, "\n") {
		line = strings.TrimSpace(line)
		if line == "" || strings.HasPrefix(line, "#") {
			continue
		}
		if k, v, ok := strings.Cut(line, ":"); ok {
			out[k] = v
		}
	}
	return out
}

// Close implements engine.Conn.
func (c *Conn) Close() error {
	c.mu.Lock()
	clients := c.clients
	c.clients, c.closed = map[uint32]goredis.UniversalClient{}, true
	c.mu.Unlock()
	var first error
	for _, cl := range clients {
		if err := cl.Close(); err != nil && first == nil {
			first = fmt.Errorf("%s: close: %w", c.id, err)
		}
	}
	return first
}
