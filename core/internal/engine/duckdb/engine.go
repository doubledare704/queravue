//go:build duckdb

package duckdb

import (
	"context"
	"database/sql"
	"database/sql/driver"
	"errors"
	"fmt"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"sync"

	duckdbdriver "github.com/duckdb/duckdb-go/v2"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

const (
	workConns = 1
	metaConns = 2
)

// Engine is the DuckDB engine.
type Engine struct{ desc engine.Descriptor }

// New returns the DuckDB engine.
func New() *Engine { return &Engine{desc: descriptor()} }

// Descriptor implements engine.Engine.
func (e *Engine) Descriptor() engine.Descriptor { return e.desc }

// ParseURI implements engine.Engine. DuckDB has no password, so the secret is
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
	path, err := expandPath(cfg.Param(ParamPath, MemoryPath))
	if err != nil {
		return nil, engine.Errorf(engine.KindInvalidConfig, ID, "connect", "%s", err.Error())
	}
	readOnly := cfg.Param(ParamReadOnly, "false") == "true"
	create := cfg.Param(ParamCreateIfMissing, "false") == "true" && !readOnly
	if path != MemoryPath && !create {
		if _, err := os.Stat(path); err != nil {
			return nil, &engine.Error{Kind: classifyStat(err), Engine: ID, Op: "connect", Msg: statMsg(path, err), Err: err}
		}
	}
	connector, err := duckdbdriver.NewConnector(dsn(path, readOnly, cfg.Param(ParamMemoryLimit, "")), nil)
	if err != nil {
		return nil, classify("open", err)
	}
	shared := sharedConnector{connector}
	c := &Conn{connector: connector, path: path, work: sql.OpenDB(shared), meta: sql.OpenDB(shared)}
	c.work.SetMaxOpenConns(workConns)
	c.meta.SetMaxOpenConns(metaConns)
	if err := c.Ping(ctx); err != nil {
		_ = c.Close()
		return nil, err
	}
	return c, nil
}

func expandPath(p string) (string, error) {
	if p == "" || p == MemoryPath {
		return MemoryPath, nil
	}
	if strings.ContainsRune(p, '?') {
		return "", errors.New("the file path must not contain '?'")
	}
	if p == "~" || strings.HasPrefix(p, "~/") {
		home, err := os.UserHomeDir()
		if err != nil {
			return "", fmt.Errorf("resolve ~: %w", err)
		}
		p = filepath.Join(home, strings.TrimPrefix(p, "~"))
	}
	abs, err := filepath.Abs(p)
	if err != nil {
		return "", fmt.Errorf("resolve path: %w", err)
	}
	return abs, nil
}

func dsn(path string, readOnly bool, memoryLimit string) string {
	q := url.Values{}
	if readOnly {
		q.Set("access_mode", "read_only")
	}
	if memoryLimit != "" {
		q.Set("memory_limit", memoryLimit)
	}
	if len(q) == 0 {
		return path
	}
	return path + "?" + q.Encode()
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
		return fmt.Sprintf("file %s does not exist (tick \"Create file if missing\" to make it)", path)
	case errors.Is(err, os.ErrPermission):
		return fmt.Sprintf("permission denied for %s", path)
	default:
		return err.Error()
	}
}

// sharedConnector hides Close so the two pools can share one database and
// Conn.Close releases it once, after both pools are closed.
type sharedConnector struct{ *duckdbdriver.Connector }

func (sharedConnector) Close() error { return nil }

var _ driver.Connector = sharedConnector{}

// Conn is a live DuckDB database. Statements run on a one-connection pool, so
// transactions and session settings span Execute calls; schema listings use a
// second pool and stay available while a long statement runs.
type Conn struct {
	path      string
	connector *duckdbdriver.Connector

	mu   sync.Mutex
	work *sql.DB
	meta *sql.DB
}

func (c *Conn) pools(op string) (work, meta *sql.DB, err error) {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.work == nil {
		return nil, nil, &engine.Error{Kind: engine.KindConnectionLost, Engine: ID, Op: op, Msg: "connection is closed"}
	}
	return c.work, c.meta, nil
}

func (c *Conn) metaPool(op string) (*sql.DB, error) {
	_, meta, err := c.pools(op)
	return meta, err
}

// Ping implements engine.Conn.
func (c *Conn) Ping(ctx context.Context) error {
	meta, err := c.metaPool("ping")
	if err != nil {
		return err
	}
	var one int
	if err := meta.QueryRowContext(ctx, "SELECT 1").Scan(&one); err != nil {
		return classify("ping", err)
	}
	return nil
}

// ServerInfo implements engine.Conn.
func (c *Conn) ServerInfo(ctx context.Context) (engine.ServerInfo, error) {
	meta, err := c.metaPool("server info")
	if err != nil {
		return engine.ServerInfo{}, err
	}
	var version string
	if err := meta.QueryRowContext(ctx, "SELECT version()").Scan(&version); err != nil {
		return engine.ServerInfo{}, classify("server info", err)
	}
	return engine.ServerInfo{Product: "DuckDB", Version: strings.TrimPrefix(version, "v"), Banner: "DuckDB " + version}, nil
}

// Close implements engine.Conn.
func (c *Conn) Close() error {
	c.mu.Lock()
	work, meta := c.work, c.meta
	c.work, c.meta = nil, nil
	c.mu.Unlock()
	if work == nil {
		return nil
	}
	err := errors.Join(work.Close(), meta.Close(), c.connector.Close())
	if err != nil {
		return fmt.Errorf("duckdb: close: %w", err)
	}
	return nil
}

// Dialect implements sqldialect.Provider.
func (c *Conn) Dialect() sqldialect.Dialect { return sqldialect.DuckDB }
