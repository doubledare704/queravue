// Package postgres implements the PostgreSQL engine and its wire-compatible
// CockroachDB variant on top of jackc/pgx v5.
package postgres

import (
	"context"
	"fmt"
	"regexp"
	"strings"
	"sync"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/netpath"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

// Variant selects PostgreSQL or a wire-compatible server.
type Variant int

// Supported variants.
const (
	VariantPostgres Variant = iota
	VariantCockroach
)

// Engine ids.
const (
	IDPostgres  = "postgres"
	IDCockroach = "cockroachdb"
)

// Param keys.
const (
	ParamHost     = "host"
	ParamPort     = "port"
	ParamDatabase = "database"
	ParamUser     = "user"
	ParamPassword = "password"
	ParamSSLMode  = "sslmode"
)

// SSLModes are the libpq sslmode values pgx supports.
var SSLModes = []string{"disable", "allow", "prefer", "require", "verify-ca", "verify-full"}

// allowedKeys restricts what a built connection string may contain, so pgx
// never reads service or pass files named in it.
var allowedKeys = []string{"host", "port", "dbname", "user", "sslmode", "application_name", "connect_timeout"}

// Engine is the postgres engine for one variant.
type Engine struct {
	variant Variant
	desc    engine.Descriptor
}

// New returns the engine for variant v.
func New(v Variant) *Engine {
	id, name, port, db, user := IDPostgres, "PostgreSQL", "5432", "postgres", ""
	example := "postgres://user@localhost:5432/postgres?sslmode=prefer"
	if v == VariantCockroach {
		id, name, port, db, user = IDCockroach, "CockroachDB", "26257", "defaultdb", "root"
		example = "postgresql://root@localhost:26257/defaultdb?sslmode=disable"
	}
	return &Engine{
		variant: v,
		desc: engine.Descriptor{
			ID:          id,
			DisplayName: name,
			Family:      IDPostgres,
			SupportsURI: true,
			SupportsSSH: true,
			SupportsTLS: true,
			URIExample:  example,
			Fields: []engine.FieldSpec{
				{Key: ParamHost, Label: "Host", Kind: engine.FieldText, Required: true, Default: "localhost", Placeholder: "localhost"},
				{Key: ParamPort, Label: "Port", Kind: engine.FieldInteger, Required: true, Default: port, Placeholder: port},
				{Key: ParamDatabase, Label: "Database", Kind: engine.FieldText, Default: db, Placeholder: db},
				{Key: ParamUser, Label: "User", Kind: engine.FieldText, Default: user, Placeholder: "postgres"},
				{Key: ParamPassword, Label: "Password", Kind: engine.FieldPassword},
				{Key: ParamSSLMode, Label: "SSL mode", Kind: engine.FieldSelect, Default: "prefer", Options: SSLModes},
			},
			Capabilities: []engine.Capability{engine.CapConnect, engine.CapExecute, engine.CapSchemaInspector, engine.CapIndexManager, engine.CapStats, engine.CapCompletion, engine.CapFormat, engine.CapSchemaGraph},
		},
	}
}

// Descriptor implements engine.Engine.
func (e *Engine) Descriptor() engine.Descriptor { return e.desc }

// ParseURI implements engine.Engine.
func (e *Engine) ParseURI(uri string) (engine.Config, engine.Secret, error) {
	params, pw, err := parseConnString(uri)
	if err != nil {
		return engine.Config{}, engine.Secret{}, engine.Errorf(engine.KindInvalidConfig, e.desc.ID, "parse uri", "%s", err.Error())
	}
	return engine.Config{EngineID: e.desc.ID, Params: params}, engine.NewSecret(pw), nil
}

// Connect implements engine.Engine.
func (e *Engine) Connect(ctx context.Context, cfg engine.Config, secret engine.Secret) (engine.Conn, error) {
	cfg = e.desc.WithDefaults(cfg)
	if err := e.desc.Validate(cfg); err != nil {
		return nil, err
	}
	connCfg, err := e.connConfig(cfg, secret)
	if err != nil {
		return nil, err
	}
	nt := &notices{}
	connCfg.OnNotice = nt.add
	conn, err := pgx.ConnectConfig(ctx, connCfg)
	if err != nil {
		return nil, classify(e.desc.ID, "connect", err, secret)
	}
	return &Conn{id: e.desc.ID, variant: e.variant, conn: conn, secret: secret, notices: nt}, nil
}

// connConfig builds a pgx config from params only. The password is set on the
// parsed config, never put in a connection string, and it always overrides
// PGPASSWORD / .pgpass so the keychain is the single source of secrets.
func (e *Engine) connConfig(cfg engine.Config, secret engine.Secret) (*pgx.ConnConfig, error) {
	kv := []string{
		kvPair("host", cfg.Param(ParamHost, "")),
		kvPair("port", cfg.Param(ParamPort, "")),
		kvPair("sslmode", sslModeFor(cfg)),
		kvPair("application_name", "Queravue"),
	}
	if db := cfg.Param(ParamDatabase, ""); db != "" {
		kv = append(kv, kvPair("dbname", db))
	}
	if u := cfg.Param(ParamUser, ""); u != "" {
		kv = append(kv, kvPair("user", u))
	}
	connCfg, err := pgx.ParseConfigWithOptions(strings.Join(kv, " "), pgx.ParseConfigOptions{
		ParseConfigOptions: pgconn.ParseConfigOptions{ConnStringAllowedKeys: allowedKeys},
	})
	if err != nil {
		return nil, &engine.Error{
			Kind: engine.KindInvalidConfig, Engine: e.desc.ID, Op: "config",
			Msg: engine.Redact(err.Error(), secret), Err: err,
		}
	}
	connCfg.Password = secret.Reveal()
	if err := applyNetwork(connCfg, cfg.Net, e.desc.ID, secret); err != nil {
		return nil, err
	}
	// Each connection is short-lived in It. 1; skip the statement cache.
	connCfg.DefaultQueryExecMode = pgx.QueryExecModeSimpleProtocol
	// A cancelled context sends a native cancel request instead of killing
	// the socket, so the server stops the query and the session survives.
	connCfg.BuildContextWatcherHandler = buildWatcher
	return connCfg, nil
}

func kvPair(k, v string) string {
	v = strings.ReplaceAll(v, `\`, `\\`)
	v = strings.ReplaceAll(v, `'`, `\'`)
	return fmt.Sprintf("%s='%s'", k, v)
}

// Conn is a live postgres connection.
type Conn struct {
	id      string
	variant Variant
	secret  engine.Secret
	notices *notices

	mu   sync.Mutex
	conn *pgx.Conn
}

// Ping implements engine.Conn.
func (c *Conn) Ping(ctx context.Context) error {
	if err := c.conn.Ping(ctx); err != nil {
		return classify(c.id, "ping", err, c.secret)
	}
	return nil
}

// ServerInfo implements engine.Conn.
func (c *Conn) ServerInfo(ctx context.Context) (engine.ServerInfo, error) {
	var banner string
	if err := c.conn.QueryRow(ctx, "SELECT version()").Scan(&banner); err != nil {
		return engine.ServerInfo{}, classify(c.id, "server info", err, c.secret)
	}
	return parseBanner(banner, c.conn.PgConn().ParameterStatus("server_version")), nil
}

// Close implements engine.Conn.
func (c *Conn) Close() error {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.conn == nil {
		return nil
	}
	ctx, cancel := context.WithTimeout(context.Background(), closeTimeout)
	defer cancel()
	err := c.conn.Close(ctx)
	c.conn = nil
	if err != nil {
		return fmt.Errorf("%s: close: %w", c.id, err)
	}
	return nil
}

var (
	pgVersionRe = regexp.MustCompile(`^PostgreSQL (\S+)`)
	crdbRe      = regexp.MustCompile(`^CockroachDB \S+ v?(\S+)`)
)

// parseBanner extracts product and version from SELECT version() output,
// falling back to the server_version parameter.
func parseBanner(banner, serverVersion string) engine.ServerInfo {
	if m := crdbRe.FindStringSubmatch(banner); m != nil {
		return engine.ServerInfo{Product: "CockroachDB", Version: m[1], Banner: banner}
	}
	info := engine.ServerInfo{Product: "PostgreSQL", Version: serverVersion, Banner: banner}
	if m := pgVersionRe.FindStringSubmatch(banner); m != nil {
		info.Version = strings.TrimSuffix(m[1], ",")
	}
	if i := strings.IndexByte(info.Version, ' '); i > 0 {
		info.Version = info.Version[:i]
	}
	return info
}

// Dialect implements sqldialect.Provider.
func (c *Conn) Dialect() sqldialect.Dialect { return sqldialect.Postgres }

// TransactionalDDL is false on CockroachDB, which limits schema changes inside a transaction.
func (c *Conn) TransactionalDDL() bool { return c.variant != VariantCockroach }

func sslModeFor(cfg engine.Config) string {
	modes := map[netpath.TLSMode]string{
		netpath.TLSDisable: "disable", netpath.TLSPrefer: "prefer", netpath.TLSRequire: "require",
		netpath.TLSVerifyCA: "verify-ca", netpath.TLSVerifyFull: "verify-full",
	}
	if m, ok := modes[cfg.Net.TLS.Mode]; ok {
		return m
	}
	return cfg.Param(ParamSSLMode, "prefer")
}

// applyNetwork routes sockets through the session dialer and replaces pgx's
// TLS configs with the shared builder's.
func applyNetwork(connCfg *pgx.ConnConfig, n engine.NetworkPath, id string, secret engine.Secret) error {
	if n.Tunneled() {
		connCfg.DialFunc = pgconn.DialFunc(n.Dial)
		// The bastion resolves the host name; pgx must not resolve it locally.
		connCfg.LookupFunc = func(_ context.Context, host string) ([]string, error) { return []string{host}, nil }
	}
	if !n.HasTLSSettings() || !n.TLS.Enabled() {
		return nil
	}
	tlsCfg, err := n.TLS.Build(connCfg.Host)
	if err != nil {
		return &engine.Error{Kind: engine.KindInvalidConfig, Engine: id, Op: "config", Msg: engine.Redact(err.Error(), secret), Err: err}
	}
	if connCfg.TLSConfig != nil {
		connCfg.TLSConfig = tlsCfg
	}
	for _, fb := range connCfg.Fallbacks {
		if fb.TLSConfig != nil {
			fbCfg := tlsCfg.Clone()
			fbCfg.ServerName = serverNameFor(n.TLS, fb.Host)
			fb.TLSConfig = fbCfg
		}
	}
	return nil
}

func serverNameFor(t netpath.TLSSettings, host string) string {
	if t.ServerName != "" {
		return t.ServerName
	}
	return host
}
