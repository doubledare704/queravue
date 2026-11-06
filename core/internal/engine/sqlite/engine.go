// Package sqlite implements the SQLite engine on top of modernc.org/sqlite
// (pure Go, no cgo).
package sqlite

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"sync"

	sqlite "modernc.org/sqlite"
	sqlite3 "modernc.org/sqlite/lib"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

// ID is the engine id.
const ID = "sqlite"

// Param keys.
const (
	ParamPath            = "path"
	ParamReadOnly        = "read_only"
	ParamCreateIfMissing = "create_if_missing"
)

// Engine is the SQLite engine.
type Engine struct{ desc engine.Descriptor }

// New returns the SQLite engine.
func New() *Engine {
	return &Engine{desc: engine.Descriptor{
		ID:          ID,
		DisplayName: "SQLite",
		Family:      ID,
		SupportsURI: true,
		URIExample:  "sqlite:///Users/me/data.db",
		Fields: []engine.FieldSpec{
			{Key: ParamPath, Label: "Database file", Kind: engine.FieldFile, Required: true, Placeholder: "/path/to/database.db"},
			{Key: ParamReadOnly, Label: "Read-only", Kind: engine.FieldBoolean, Default: "false"},
			{Key: ParamCreateIfMissing, Label: "Create file if missing", Kind: engine.FieldBoolean, Default: "false"},
		},
		Capabilities: []engine.Capability{engine.CapConnect, engine.CapExecute, engine.CapSchemaInspector},
	}}
}

// Descriptor implements engine.Engine.
func (e *Engine) Descriptor() engine.Descriptor { return e.desc }

// ParseURI implements engine.Engine. SQLite has no password, so the secret is
// always empty.
func (e *Engine) ParseURI(uri string) (engine.Config, engine.Secret, error) {
	params, err := parseURI(uri)
	if err != nil {
		return engine.Config{}, engine.Secret{}, engine.Errorf(engine.KindInvalidConfig, ID, "parse uri", "%s", err.Error())
	}
	return engine.Config{EngineID: ID, Params: params}, engine.Secret{}, nil
}

// Connect implements engine.Engine.
func (e *Engine) Connect(ctx context.Context, cfg engine.Config, _ engine.Secret) (engine.Conn, error) {
	cfg = e.desc.WithDefaults(cfg)
	if err := e.desc.Validate(cfg); err != nil {
		return nil, err
	}
	path, err := expandPath(cfg.Param(ParamPath, ""))
	if err != nil {
		return nil, engine.Errorf(engine.KindInvalidConfig, ID, "connect", "%s", err.Error())
	}
	readOnly := cfg.Param(ParamReadOnly, "false") == "true"
	create := cfg.Param(ParamCreateIfMissing, "false") == "true" && !readOnly
	if !create {
		if _, err := os.Stat(path); err != nil {
			return nil, &engine.Error{Kind: classifyStat(err), Engine: ID, Op: "connect", Msg: statMsg(path, err), Err: err}
		}
	}

	db, err := sql.Open("sqlite", dsn(path, readOnly, create))
	if err != nil {
		return nil, classify("open", err)
	}
	// One file handle per connection: SQLite serialises writers anyway.
	db.SetMaxOpenConns(1)
	c := &Conn{db: db, path: path}
	if err := c.Ping(ctx); err != nil {
		_ = db.Close()
		return nil, err
	}
	return c, nil
}

func expandPath(p string) (string, error) {
	if p == "~" || strings.HasPrefix(p, "~/") {
		home, err := os.UserHomeDir()
		if err != nil {
			return "", fmt.Errorf("resolve ~: %w", err)
		}
		p = filepath.Join(home, strings.TrimPrefix(p, "~"))
	}
	if p == "" || p == ":memory:" {
		return p, nil
	}
	abs, err := filepath.Abs(p)
	if err != nil {
		return "", fmt.Errorf("resolve path: %w", err)
	}
	return abs, nil
}

func dsn(path string, readOnly, create bool) string {
	mode := "rw"
	switch {
	case readOnly:
		mode = "ro"
	case create:
		mode = "rwc"
	}
	q := url.Values{}
	q.Set("mode", mode)
	q.Add("_pragma", "busy_timeout(5000)")
	return "file:" + (&url.URL{Path: path}).EscapedPath() + "?" + q.Encode()
}

func classifyStat(err error) engine.Kind {
	switch {
	case errors.Is(err, os.ErrNotExist):
		return engine.KindNotFound
	case errors.Is(err, os.ErrPermission):
		return engine.KindAuth
	default:
		return engine.KindUnknown
	}
}

func statMsg(path string, err error) string {
	switch {
	case errors.Is(err, os.ErrNotExist):
		return fmt.Sprintf("file %s does not exist", path)
	case errors.Is(err, os.ErrPermission):
		return fmt.Sprintf("permission denied for %s", path)
	default:
		return err.Error()
	}
}

// classify maps SQLite result codes to error kinds.
func classify(op string, err error) error {
	kind := engine.ClassifyCommon(err)
	msg := err.Error()
	var se *sqlite.Error
	if errors.As(err, &se) {
		switch se.Code() & 0xff {
		case sqlite3.SQLITE_CANTOPEN:
			kind = engine.KindNotFound
		case sqlite3.SQLITE_PERM, sqlite3.SQLITE_AUTH, sqlite3.SQLITE_READONLY:
			kind = engine.KindAuth
		case sqlite3.SQLITE_NOTADB:
			kind, msg = engine.KindInvalidConfig, "file is not a SQLite database"
		case sqlite3.SQLITE_BUSY, sqlite3.SQLITE_LOCKED:
			kind = engine.KindTimeout
		}
	}
	return &engine.Error{Kind: kind, Engine: ID, Op: op, Msg: msg, Err: err}
}

// Conn is a live SQLite connection.
type Conn struct {
	path string

	mu sync.Mutex
	db *sql.DB
}

// Ping implements engine.Conn. It reads the schema table, because SQLite only
// notices a non-database file on the first read.
func (c *Conn) Ping(ctx context.Context) error {
	var n int
	if err := c.db.QueryRowContext(ctx, "SELECT count(*) FROM sqlite_master").Scan(&n); err != nil {
		return classify("ping", err)
	}
	return nil
}

// ServerInfo implements engine.Conn.
func (c *Conn) ServerInfo(ctx context.Context) (engine.ServerInfo, error) {
	var v string
	if err := c.db.QueryRowContext(ctx, "SELECT sqlite_version()").Scan(&v); err != nil {
		return engine.ServerInfo{}, classify("server info", err)
	}
	return engine.ServerInfo{Product: "SQLite", Version: v, Banner: "SQLite " + v}, nil
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
		return fmt.Errorf("sqlite: close: %w", err)
	}
	return nil
}

// Dialect implements sqldialect.Provider.
func (c *Conn) Dialect() sqldialect.Dialect { return sqldialect.SQLite }
