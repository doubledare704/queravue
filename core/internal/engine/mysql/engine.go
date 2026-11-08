// Package mysql implements the MySQL engine and its wire-compatible MariaDB
// and TiDB variants on top of go-sql-driver/mysql.
package mysql

import (
	"context"
	"database/sql"
	"fmt"
	"net"
	"regexp"
	"strings"
	"sync"
	"time"

	drv "github.com/go-sql-driver/mysql"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

// Variant selects MySQL or a wire-compatible server.
type Variant int

// Supported variants.
const (
	VariantMySQL Variant = iota
	VariantMariaDB
	VariantTiDB
)

// Engine ids.
const (
	IDMySQL   = "mysql"
	IDMariaDB = "mariadb"
	IDTiDB    = "tidb"
)

// Param keys.
const (
	ParamHost     = "host"
	ParamPort     = "port"
	ParamDatabase = "database"
	ParamUser     = "user"
	ParamPassword = "password"
	ParamTLS      = "tls"
)

// TLSModes are the TLS options. "preferred" uses TLS when the server offers
// it without verifying the certificate; "verify" requires a valid one.
var TLSModes = []string{"disable", "preferred", "skip-verify", "verify"}

// driverTLS maps a TLS mode to the driver's tls= value.
var driverTLS = map[string]string{
	"disable": "false", "preferred": "preferred", "skip-verify": "skip-verify", "verify": "true",
}

// Engine is the mysql engine for one variant.
type Engine struct {
	variant Variant
	desc    engine.Descriptor
}

// New returns the engine for variant v.
func New(v Variant) *Engine {
	id, name, port, user := IDMySQL, "MySQL", "3306", "root"
	example := "mysql://user@localhost:3306/mydb"
	switch v {
	case VariantMariaDB:
		id, name = IDMariaDB, "MariaDB"
		example = "mariadb://user@localhost:3306/mydb"
	case VariantTiDB:
		id, name, port = IDTiDB, "TiDB", "4000"
		example = "tidb://root@localhost:4000/test"
	}
	return &Engine{
		variant: v,
		desc: engine.Descriptor{
			ID:          id,
			DisplayName: name,
			Family:      IDMySQL,
			SupportsURI: true,
			URIExample:  example,
			Fields: []engine.FieldSpec{
				{Key: ParamHost, Label: "Host", Kind: engine.FieldText, Required: true, Default: "localhost", Placeholder: "localhost"},
				{Key: ParamPort, Label: "Port", Kind: engine.FieldInteger, Required: true, Default: port, Placeholder: port},
				{Key: ParamDatabase, Label: "Database", Kind: engine.FieldText},
				{Key: ParamUser, Label: "User", Kind: engine.FieldText, Default: user, Placeholder: user},
				{Key: ParamPassword, Label: "Password", Kind: engine.FieldPassword},
				{Key: ParamTLS, Label: "TLS", Kind: engine.FieldSelect, Default: "preferred", Options: TLSModes},
			},
			Capabilities: []engine.Capability{engine.CapConnect, engine.CapExecute, engine.CapSchemaInspector, engine.CapIndexManager, engine.CapStats, engine.CapCompletion},
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
	dc := drv.NewConfig()
	dc.User = cfg.Param(ParamUser, "")
	dc.Passwd = secret.Reveal()
	dc.Net = "tcp"
	dc.Addr = net.JoinHostPort(cfg.Param(ParamHost, "localhost"), cfg.Param(ParamPort, "3306"))
	dc.DBName = cfg.Param(ParamDatabase, "")
	dc.Timeout = 10 * time.Second
	dc.TLSConfig = driverTLS[cfg.Param(ParamTLS, "preferred")]
	dc.ConnectionAttributes = "program_name:Queravue"
	// TIMESTAMP values come back as UTC; DATETIME is shown as stored.
	dc.Params = map[string]string{"time_zone": "'+00:00'"}
	// Values are converted from text by column type, not by the driver.
	dc.ParseTime = false

	connector, err := drv.NewConnector(dc)
	if err != nil {
		return nil, &engine.Error{Kind: engine.KindInvalidConfig, Engine: e.desc.ID, Op: "config",
			Msg: engine.Redact(err.Error(), secret), Err: err}
	}
	db := sql.OpenDB(connector)
	// One connection runs statements; a second one is for KILL QUERY.
	db.SetMaxOpenConns(2)
	db.SetConnMaxLifetime(0)
	conn, err := db.Conn(ctx)
	if err != nil {
		_ = db.Close()
		return nil, classify(e.desc.ID, "connect", err, secret)
	}
	var connID uint64
	if err := conn.QueryRowContext(ctx, "SELECT CONNECTION_ID()").Scan(&connID); err != nil {
		_ = conn.Close()
		_ = db.Close()
		return nil, classify(e.desc.ID, "connect", err, secret)
	}
	return &Conn{id: e.desc.ID, variant: e.variant, secret: secret, db: db, conn: conn, connID: connID}, nil
}

// Conn is a live MySQL-family connection.
type Conn struct {
	id      string
	variant Variant
	secret  engine.Secret
	connID  uint64 // server-side connection id, target of KILL QUERY

	mu   sync.Mutex
	db   *sql.DB
	conn *sql.Conn
}

// live returns the statement connection, or a connection-lost error.
func (c *Conn) live(op string) (*sql.Conn, error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.conn == nil {
		return nil, &engine.Error{Kind: engine.KindConnectionLost, Engine: c.id, Op: op, Msg: "connection is closed"}
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
		return classify(c.id, "ping", err, c.secret)
	}
	return nil
}

// ServerInfo implements engine.Conn.
func (c *Conn) ServerInfo(ctx context.Context) (engine.ServerInfo, error) {
	conn, err := c.live("server info")
	if err != nil {
		return engine.ServerInfo{}, err
	}
	var banner string
	if err := conn.QueryRowContext(ctx, "SELECT VERSION()").Scan(&banner); err != nil {
		return engine.ServerInfo{}, classify(c.id, "server info", err, c.secret)
	}
	return parseBanner(banner), nil
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
		return fmt.Errorf("%s: close: %w", c.id, err)
	}
	return nil
}

// Dialect implements sqldialect.Provider.
func (c *Conn) Dialect() sqldialect.Dialect { return sqldialect.MySQL }

var tidbRe = regexp.MustCompile(`TiDB-v?(\S+)`)

// parseBanner extracts product and version from SELECT VERSION() output:
// "8.4.13", "11.4.2-MariaDB-ubu2404", "8.0.11-TiDB-v8.1.0".
func parseBanner(banner string) engine.ServerInfo {
	switch {
	case strings.Contains(banner, "TiDB"):
		v := banner
		if m := tidbRe.FindStringSubmatch(banner); m != nil {
			v = m[1]
		}
		return engine.ServerInfo{Product: "TiDB", Version: v, Banner: banner}
	case strings.Contains(banner, "MariaDB"):
		v := strings.TrimPrefix(banner, "5.5.5-") // replication-compat prefix
		if i := strings.Index(v, "-"); i > 0 {
			v = v[:i]
		}
		return engine.ServerInfo{Product: "MariaDB", Version: v, Banner: banner}
	}
	v := banner
	if i := strings.IndexAny(v, "-+ "); i > 0 {
		v = v[:i]
	}
	return engine.ServerInfo{Product: "MySQL", Version: v, Banner: banner}
}
