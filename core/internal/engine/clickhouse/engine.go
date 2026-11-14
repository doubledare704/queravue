// Package clickhouse implements the ClickHouse engine over the native protocol.
package clickhouse

import (
	"context"
	"crypto/tls"
	"database/sql"
	"fmt"
	"net"
	"sync"
	"time"

	chdriver "github.com/ClickHouse/clickhouse-go/v2"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

// ID is the engine id.
const ID = "clickhouse"

// Connection parameter keys.
const (
	ParamHost     = "host"
	ParamPort     = "port"
	ParamDatabase = "database"
	ParamUser     = "user"
	ParamPassword = "password"
	ParamTLS      = "tls"
)

// TLSModes are the TLS options for the native connection.
var TLSModes = []string{"disable", "skip-verify", "verify"}

const (
	blockSize       = 8192
	dialTimeout     = 10 * time.Second
	maxOpenConns    = 4
	connMaxLifetime = time.Hour
)

// Engine is the ClickHouse engine over the native protocol.
type Engine struct{ desc engine.Descriptor }

// New returns the ClickHouse engine.
func New() *Engine {
	return &Engine{desc: engine.Descriptor{
		ID:          ID,
		DisplayName: "ClickHouse",
		Family:      ID,
		SupportsURI: true,
		URIExample:  "clickhouse://default@localhost:9000/default",
		Fields: []engine.FieldSpec{
			{Key: ParamHost, Label: "Host", Kind: engine.FieldText, Required: true, Default: "localhost", Placeholder: "localhost"},
			{Key: ParamPort, Label: "Native port", Kind: engine.FieldInteger, Required: true, Default: "9000", Placeholder: "9000 (9440 with TLS)"},
			{Key: ParamDatabase, Label: "Database", Kind: engine.FieldText, Default: "default", Placeholder: "default"},
			{Key: ParamUser, Label: "User", Kind: engine.FieldText, Default: "default", Placeholder: "default"},
			{Key: ParamPassword, Label: "Password", Kind: engine.FieldPassword},
			{Key: ParamTLS, Label: "TLS", Kind: engine.FieldSelect, Default: "disable", Options: TLSModes},
		},
		Capabilities: []engine.Capability{engine.CapConnect, engine.CapExecute, engine.CapSchemaInspector, engine.CapCompletion, engine.CapFormat, engine.CapSchemaGraph},
	}}
}

// Descriptor implements engine.Engine.
func (e *Engine) Descriptor() engine.Descriptor { return e.desc }

// ParseURI implements engine.Engine.
func (e *Engine) ParseURI(uri string) (engine.Config, engine.Secret, error) {
	params, password, err := parseURI(uri)
	if err != nil {
		return engine.Config{}, engine.Secret{}, engine.Errorf(engine.KindInvalidConfig, ID, "parse uri", "%s", err.Error())
	}
	return engine.Config{EngineID: ID, Params: params}, engine.NewSecret(password), nil
}

// Connect implements engine.Engine.
func (e *Engine) Connect(ctx context.Context, cfg engine.Config, secret engine.Secret) (engine.Conn, error) {
	cfg = e.desc.WithDefaults(cfg)
	if err := e.desc.Validate(cfg); err != nil {
		return nil, err
	}
	tlsConfig, err := tlsConfigFor(cfg)
	if err != nil {
		return nil, err
	}
	db := sql.OpenDB(chdriver.Connector(&chdriver.Options{
		Addr: []string{net.JoinHostPort(cfg.Param(ParamHost, "localhost"), cfg.Param(ParamPort, "9000"))},
		Auth: chdriver.Auth{
			Database: cfg.Param(ParamDatabase, "default"),
			Username: cfg.Param(ParamUser, "default"),
			Password: secret.Reveal(),
		},
		TLS:         tlsConfig,
		DialTimeout: dialTimeout,
		Settings:    chdriver.Settings{"max_block_size": blockSize},
		ClientInfo:  chdriver.ClientInfo{Products: []struct{ Name, Version string }{{Name: "Queravue"}}},
	}))
	db.SetMaxOpenConns(maxOpenConns)
	db.SetConnMaxLifetime(connMaxLifetime)
	if err := db.PingContext(ctx); err != nil {
		_ = db.Close()
		return nil, classify(ID, "connect", err, secret)
	}
	return &Conn{secret: secret, db: db, database: cfg.Param(ParamDatabase, "default")}, nil
}

func tlsConfigFor(cfg engine.Config) (*tls.Config, error) {
	switch cfg.Param(ParamTLS, "disable") {
	case "disable":
		return nil, nil
	case "skip-verify":
		return &tls.Config{InsecureSkipVerify: true, MinVersion: tls.VersionTLS12}, nil //nolint:gosec // the user chose skip-verify explicitly
	default:
		return &tls.Config{ServerName: cfg.Param(ParamHost, "localhost"), MinVersion: tls.VersionTLS12}, nil
	}
}

// Conn is a pooled ClickHouse session.
type Conn struct {
	secret   engine.Secret
	database string

	mu sync.Mutex
	db *sql.DB
}

func (c *Conn) live(op string) (*sql.DB, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.db == nil {
		return nil, &engine.Error{Kind: engine.KindConnectionLost, Engine: ID, Op: op, Msg: "connection is closed"}
	}
	return c.db, nil
}

// Ping implements engine.Conn.
func (c *Conn) Ping(ctx context.Context) error {
	db, err := c.live("ping")
	if err != nil {
		return err
	}
	if err := db.PingContext(ctx); err != nil {
		return classify(ID, "ping", err, c.secret)
	}
	return nil
}

// ServerInfo implements engine.Conn.
func (c *Conn) ServerInfo(ctx context.Context) (engine.ServerInfo, error) {
	db, err := c.live("server info")
	if err != nil {
		return engine.ServerInfo{}, err
	}
	var version string
	if err := db.QueryRowContext(ctx, "SELECT version()").Scan(&version); err != nil {
		return engine.ServerInfo{}, classify(ID, "server info", err, c.secret)
	}
	return engine.ServerInfo{Product: "ClickHouse", Version: version, Banner: "ClickHouse " + version}, nil
}

// Close implements engine.Conn.
func (c *Conn) Close() error {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.db == nil {
		return nil
	}
	err := c.db.Close()
	c.db = nil
	if err != nil {
		return fmt.Errorf("%s: close: %w", ID, err)
	}
	return nil
}

// Dialect implements sqldialect.Provider.
func (c *Conn) Dialect() sqldialect.Dialect { return sqldialect.ClickHouse }
