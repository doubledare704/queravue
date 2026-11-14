// Package oracle implements the Oracle Database engine on top of the
// pure-Go sijms/go-ora driver. See docs/engines/oracle.md.
package oracle

import (
	"context"
	"database/sql"
	"fmt"
	"strconv"
	"strings"
	"sync"

	goora "github.com/sijms/go-ora/v2"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/netpath"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

// ID is the engine id.
const ID = "oracle"

// Param keys.
const (
	ParamHost             = "host"
	ParamPort             = "port"
	ParamService          = "service_name"
	ParamSID              = "sid"
	ParamDescriptor       = "tns_descriptor"
	ParamUser             = "user"
	ParamPassword         = "password"
	ParamRole             = "role"
	ParamSSL              = "ssl"
	ParamSSLVerify        = "ssl_verify"
	ParamWallet           = "wallet"
	ParamShowSystemSchema = "show_system_schemas"
)

// Roles a session can connect with.
const (
	RoleNormal = "normal"
	RoleSysDBA = "sysdba"
)

const prefetchRows = engine.MaxBatchRows

// Inline LOB fetch is 80 times faster than streaming for small LOBs with the same live heap; see docs/perf/iteration-10.md.
var lobFetchMode = "PRE"

// Engine is the Oracle engine.
type Engine struct{ desc engine.Descriptor }

// New returns the Oracle engine.
func New() *Engine {
	return &Engine{desc: engine.Descriptor{
		ID:          ID,
		DisplayName: "Oracle",
		Family:      ID,
		SupportsURI: true,
		SupportsSSH: true,
		SupportsTLS: true,
		URIExample:  "oracle://system@localhost:1521/FREEPDB1",
		Fields: []engine.FieldSpec{
			{Key: ParamHost, Label: "Host", Kind: engine.FieldText, Required: true, Default: "localhost", Placeholder: "localhost"},
			{Key: ParamPort, Label: "Port", Kind: engine.FieldInteger, Required: true, Default: "1521", Placeholder: "1521"},
			{Key: ParamService, Label: "Service name", Kind: engine.FieldText, Placeholder: "FREEPDB1"},
			{Key: ParamSID, Label: "SID", Kind: engine.FieldText, Placeholder: "used when there is no service name"},
			{Key: ParamDescriptor, Label: "TNS descriptor", Kind: engine.FieldText, Placeholder: "(DESCRIPTION=(ADDRESS=...)(CONNECT_DATA=...))"},
			{Key: ParamUser, Label: "User", Kind: engine.FieldText, Required: true, Placeholder: "system"},
			{Key: ParamPassword, Label: "Password", Kind: engine.FieldPassword},
			{Key: ParamRole, Label: "Role", Kind: engine.FieldSelect, Default: RoleNormal, Options: []string{RoleNormal, RoleSysDBA}},
			{Key: ParamSSL, Label: "TCPS (TLS)", Kind: engine.FieldBoolean, Default: "false"},
			{Key: ParamSSLVerify, Label: "Verify server certificate", Kind: engine.FieldBoolean, Default: "true"},
			{Key: ParamWallet, Label: "Wallet directory", Kind: engine.FieldFile},
			{Key: ParamShowSystemSchema, Label: "Show Oracle-maintained schemas", Kind: engine.FieldBoolean, Default: "false"},
		},
		Capabilities: []engine.Capability{engine.CapConnect, engine.CapExecute, engine.CapSchemaInspector, engine.CapIndexManager, engine.CapStats, engine.CapCompletion, engine.CapFormat, engine.CapSchemaGraph},
	}}
}

// Descriptor implements engine.Engine.
func (e *Engine) Descriptor() engine.Descriptor { return e.desc }

// ParseURI implements engine.Engine.
func (e *Engine) ParseURI(uri string) (engine.Config, engine.Secret, error) {
	params, pw, err := parseConnString(uri)
	if err != nil {
		return engine.Config{}, engine.Secret{}, engine.Errorf(engine.KindInvalidConfig, ID, "parse uri", "%s", err.Error())
	}
	return engine.Config{EngineID: ID, Params: params}, engine.NewSecret(pw), nil
}

// Connect implements engine.Engine.
func (e *Engine) Connect(ctx context.Context, cfg engine.Config, secret engine.Secret) (engine.Conn, error) {
	cfg = e.desc.WithDefaults(cfg)
	if err := e.desc.Validate(cfg); err != nil {
		return nil, err
	}
	dsn, err := dataSourceName(cfg, secret)
	if err != nil {
		return nil, err
	}
	connector, ok := goora.NewConnector(dsn).(*goora.OracleConnector)
	if !ok {
		return nil, engine.Errorf(engine.KindUnknown, ID, "config", "unexpected go-ora connector type")
	}
	if err := applyNetwork(connector, cfg, secret); err != nil {
		return nil, err
	}
	db := sql.OpenDB(connector)
	db.SetMaxOpenConns(1) // one pinned session; cancel sends a break to it
	conn, err := db.Conn(ctx)
	if err != nil {
		_ = db.Close()
		return nil, classify("connect", err, secret)
	}
	if err := conn.PingContext(ctx); err != nil {
		_ = conn.Close()
		_ = db.Close()
		return nil, classify("connect", err, secret)
	}
	return &Conn{secret: secret, db: db, conn: conn, showSystem: cfg.Param(ParamShowSystemSchema, "false") == "true"}, nil
}

func dataSourceName(cfg engine.Config, secret engine.Secret) (string, error) {
	user := cfg.Param(ParamUser, "")
	options := map[string]string{
		"CONNECT TIMEOUT": "10",
		"PREFETCH_ROWS":   strconv.Itoa(prefetchRows),
		"LOB FETCH":       lobFetchMode,
	}
	if cfg.Param(ParamRole, RoleNormal) == RoleSysDBA {
		options["DBA PRIVILEGE"] = "SYSDBA"
	}
	switch {
	case cfg.Net.HasTLSSettings():
		if cfg.Net.TLS.Enabled() {
			options["SSL"] = "true"
			options["SSL VERIFY"] = strconv.FormatBool(cfg.Net.TLS.Mode >= netpath.TLSVerifyCA)
		}
	case cfg.Param(ParamSSL, "false") == "true":
		options["SSL"] = "true"
		options["SSL VERIFY"] = cfg.Param(ParamSSLVerify, "true")
	}
	if wallet := cfg.Param(ParamWallet, ""); wallet != "" {
		options["WALLET"] = wallet
	}
	if descriptor := cfg.Param(ParamDescriptor, ""); descriptor != "" {
		return goora.BuildJDBC(user, secret.Reveal(), descriptor, options), nil
	}
	port, err := strconv.Atoi(cfg.Param(ParamPort, "1521"))
	if err != nil {
		return "", engine.Errorf(engine.KindInvalidConfig, ID, "config", "port must be a number")
	}
	service, sid := cfg.Param(ParamService, ""), cfg.Param(ParamSID, "")
	switch {
	case service == "" && sid == "":
		return "", engine.Errorf(engine.KindInvalidConfig, ID, "config", "give a service name, a SID or a TNS descriptor")
	case service == "":
		options["SID"] = sid
	}
	return goora.BuildUrl(cfg.Param(ParamHost, "localhost"), port, service, user, secret.Reveal(), options), nil
}

// Conn is a live Oracle session.
type Conn struct {
	secret     engine.Secret
	showSystem bool

	mu   sync.Mutex
	db   *sql.DB
	conn *sql.Conn
	tx   *sql.Tx
}

func (c *Conn) live(op string) (*sql.Conn, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.conn == nil {
		return nil, &engine.Error{Kind: engine.KindConnectionLost, Engine: ID, Op: op, Msg: "connection is closed"}
	}
	return c.conn, nil
}

// Ping implements engine.Conn.
func (c *Conn) Ping(ctx context.Context) error {
	conn, err := c.live("ping")
	if err != nil {
		return err
	}
	if err := conn.PingContext(ctx); err != nil {
		return classify("ping", err, c.secret)
	}
	return nil
}

// ServerInfo implements engine.Conn.
func (c *Conn) ServerInfo(ctx context.Context) (engine.ServerInfo, error) {
	conn, err := c.live("server info")
	if err != nil {
		return engine.ServerInfo{}, err
	}
	var version string
	if err := conn.QueryRowContext(ctx, "SELECT version FROM product_component_version WHERE ROWNUM = 1").Scan(&version); err != nil {
		return engine.ServerInfo{}, classify("server info", err, c.secret)
	}
	info := engine.ServerInfo{Product: "Oracle Database", Version: version}
	var banner string
	if conn.QueryRowContext(ctx, "SELECT banner FROM v$version WHERE ROWNUM = 1").Scan(&banner) == nil {
		info.Banner = strings.TrimSpace(banner)
	}
	return info, nil
}

// Close implements engine.Conn.
func (c *Conn) Close() error {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.conn == nil {
		return nil
	}
	if c.tx != nil {
		_ = c.tx.Rollback()
		c.tx = nil
	}
	_ = c.conn.Close()
	err := c.db.Close()
	c.conn, c.db = nil, nil
	if err != nil {
		return fmt.Errorf("%s: close: %w", ID, err)
	}
	return nil
}

// Dialect implements sqldialect.Provider.
func (c *Conn) Dialect() sqldialect.Dialect { return sqldialect.Oracle }

// applyNetwork sets the dialer and, for TLSSettings, the TLS config. go-ora
// has no "prefer" mode, so prefer behaves as require.
func applyNetwork(c *goora.OracleConnector, cfg engine.Config, secret engine.Secret) error {
	if cfg.Net.Tunneled() {
		c.Dialer(cfg.Net.Dial)
	}
	if !cfg.Net.HasTLSSettings() || !cfg.Net.TLS.Enabled() {
		return nil
	}
	tlsCfg, err := cfg.Net.TLS.Build(cfg.Param(ParamHost, "localhost"))
	if err != nil {
		return &engine.Error{Kind: engine.KindInvalidConfig, Engine: ID, Op: "config", Msg: engine.Redact(err.Error(), secret), Err: err}
	}
	c.WithTLSConfig(tlsCfg)
	return nil
}
