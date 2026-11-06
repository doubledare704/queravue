// Package mssql implements the SQL Server engine on top of
// microsoft/go-mssqldb. Authentication is SQL login only.
package mssql

import (
	"context"
	"database/sql"
	"fmt"
	"net"
	"net/url"
	"strings"
	"sync"

	mssqldb "github.com/microsoft/go-mssqldb"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

// ID is the engine id.
const ID = "mssql"

// Param keys.
const (
	ParamHost     = "host"
	ParamPort     = "port"
	ParamDatabase = "database"
	ParamUser     = "user"
	ParamPassword = "password"
	ParamEncrypt  = "encrypt"
	ParamTrust    = "trust_server_certificate"
)

// EncryptModes control TLS. "optional" encrypts only the login packet;
// "required" encrypts everything; "strict" is TDS 8 (TLS before the
// handshake).
var EncryptModes = []string{"disable", "optional", "required", "strict"}

// driverEncrypt maps an encrypt mode to the driver's encrypt= value.
var driverEncrypt = map[string]string{
	"disable": "disable", "optional": "false", "required": "true", "strict": "strict",
}

// Engine is the SQL Server engine.
type Engine struct{ desc engine.Descriptor }

// New returns the SQL Server engine.
func New() *Engine {
	return &Engine{desc: engine.Descriptor{
		ID:          ID,
		DisplayName: "SQL Server",
		Family:      ID,
		SupportsURI: true,
		URIExample:  "sqlserver://sa@localhost:1433?database=master&encrypt=required",
		Fields: []engine.FieldSpec{
			{Key: ParamHost, Label: "Host", Kind: engine.FieldText, Required: true, Default: "localhost", Placeholder: "localhost"},
			{Key: ParamPort, Label: "Port", Kind: engine.FieldInteger, Required: true, Default: "1433", Placeholder: "1433"},
			{Key: ParamDatabase, Label: "Database", Kind: engine.FieldText, Placeholder: "master"},
			{Key: ParamUser, Label: "User", Kind: engine.FieldText, Default: "sa", Placeholder: "sa"},
			{Key: ParamPassword, Label: "Password", Kind: engine.FieldPassword},
			{Key: ParamEncrypt, Label: "Encryption", Kind: engine.FieldSelect, Default: "required", Options: EncryptModes},
			{Key: ParamTrust, Label: "Trust server certificate", Kind: engine.FieldBoolean, Default: "false"},
		},
		Capabilities: []engine.Capability{engine.CapConnect, engine.CapExecute, engine.CapSchemaInspector},
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
	q := url.Values{}
	q.Set("app name", "Queravue")
	q.Set("encrypt", driverEncrypt[cfg.Param(ParamEncrypt, "required")])
	q.Set("TrustServerCertificate", cfg.Param(ParamTrust, "false"))
	q.Set("connection timeout", "10")
	if db := cfg.Param(ParamDatabase, ""); db != "" {
		q.Set("database", db)
	}
	u := url.URL{
		Scheme:   "sqlserver",
		User:     url.UserPassword(cfg.Param(ParamUser, "sa"), secret.Reveal()),
		Host:     net.JoinHostPort(cfg.Param(ParamHost, "localhost"), cfg.Param(ParamPort, "1433")),
		RawQuery: q.Encode(),
	}
	connector, err := mssqldb.NewConnector(u.String())
	if err != nil {
		return nil, &engine.Error{Kind: engine.KindInvalidConfig, Engine: ID, Op: "config",
			Msg: engine.Redact(err.Error(), secret), Err: err}
	}
	db := sql.OpenDB(connector)
	db.SetMaxOpenConns(1) // one pinned connection; cancel uses the TDS attention signal
	conn, err := db.Conn(ctx)
	if err != nil {
		_ = db.Close()
		return nil, classify(ID, "connect", err, secret)
	}
	if err := conn.PingContext(ctx); err != nil {
		_ = conn.Close()
		_ = db.Close()
		return nil, classify(ID, "connect", err, secret)
	}
	return &Conn{secret: secret, db: db, conn: conn}, nil
}

// Conn is a live SQL Server connection.
type Conn struct {
	secret engine.Secret

	mu   sync.Mutex
	db   *sql.DB
	conn *sql.Conn
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
		return classify(ID, "ping", err, c.secret)
	}
	return nil
}

// ServerInfo implements engine.Conn.
func (c *Conn) ServerInfo(ctx context.Context) (engine.ServerInfo, error) {
	conn, err := c.live("server info")
	if err != nil {
		return engine.ServerInfo{}, err
	}
	var version, banner string
	if err := conn.QueryRowContext(ctx, "SELECT CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(64)), @@VERSION").Scan(&version, &banner); err != nil {
		return engine.ServerInfo{}, classify(ID, "server info", err, c.secret)
	}
	if i := strings.IndexByte(banner, '\n'); i > 0 {
		banner = banner[:i]
	}
	return engine.ServerInfo{Product: "SQL Server", Version: version, Banner: strings.TrimSpace(banner)}, nil
}

// Close implements engine.Conn.
func (c *Conn) Close() error {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.conn == nil {
		return nil
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
func (c *Conn) Dialect() sqldialect.Dialect { return sqldialect.MSSQL }
