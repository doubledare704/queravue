// Package engine defines the database engine abstraction: a small base
// interface every engine implements, plus optional capability interfaces
// discovered at runtime. See docs/adr/0003-engine-interface.md.
package engine

import (
	"context"
	"fmt"

	"github.com/doubledare704/queravue/core/internal/netpath"
)

// Engine is a stateless driver for one database product (or wire-compatible
// variant). Implementations must be safe for concurrent use.
type Engine interface {
	// Descriptor describes the engine: id, display name, form fields and
	// declared capabilities.
	Descriptor() Descriptor
	// ParseURI splits a connection URI or DSN into params and a secret.
	// The secret never ends up in Config.Params.
	ParseURI(uri string) (Config, Secret, error)
	// Connect opens one live connection. It must honour ctx for the whole
	// dial + handshake and return an *Error with a classified Kind on failure.
	Connect(ctx context.Context, cfg Config, secret Secret) (Conn, error)
}

// Conn is one live connection. Optional capabilities (Executor in It. 2,
// SchemaInspector, Explainer, ...) are separate interfaces a Conn may also
// implement; callers discover them with As.
type Conn interface {
	// Ping checks the connection is alive with a server round-trip.
	Ping(ctx context.Context) error
	// ServerInfo reports the server product and version.
	ServerInfo(ctx context.Context) (ServerInfo, error)
	// Close releases the connection. It is safe to call more than once.
	Close() error
}

// As returns c as capability interface T if it implements it.
//
//	if ex, ok := engine.As[engine.Executor](conn); ok { ... }
func As[T any](c Conn) (T, bool) {
	t, ok := c.(T)
	return t, ok
}

// Config is the non-secret connection configuration for one engine.
type Config struct {
	// EngineID selects the engine, e.g. "postgres".
	EngineID string
	// Params holds values keyed by FieldSpec.Key. Never secrets.
	Params map[string]string
	// Net is how to reach the server. Its zero value means a direct connection
	// with the TLS params in Params.
	Net NetworkPath
}

// NetworkPath is the connection-level routing every network engine honours.
type NetworkPath struct {
	// Dial opens every socket the engine needs; nil dials directly. Engines
	// must route all connections through it, including replica set members.
	Dial netpath.DialFunc
	// TLS overrides the engine's own TLS params when its Mode is set.
	TLS netpath.TLSSettings
}

// Tunneled reports whether sockets go through a dialer other than the default.
func (n NetworkPath) Tunneled() bool { return n.Dial != nil }

// HasTLSSettings reports whether TLS comes from TLSSettings, not engine params.
func (n NetworkPath) HasTLSSettings() bool { return n.TLS.Mode != netpath.TLSUnset }

// Param returns Params[key], or def if missing or empty.
func (c Config) Param(key, def string) string {
	if v, ok := c.Params[key]; ok && v != "" {
		return v
	}
	return def
}

// Secret holds a password or token. It refuses to print itself so it cannot
// leak through logs, %v formatting or JSON.
type Secret struct{ value string }

// NewSecret wraps s.
func NewSecret(s string) Secret { return Secret{value: s} }

// Reveal returns the plaintext. Call it only at the driver boundary.
func (s Secret) Reveal() string { return s.value }

// IsZero reports whether the secret is empty.
func (s Secret) IsZero() bool { return s.value == "" }

// String implements fmt.Stringer with a redacted value.
func (s Secret) String() string { return redacted(s) }

// GoString implements fmt.GoStringer with a redacted value.
func (s Secret) GoString() string { return redacted(s) }

// Format implements fmt.Formatter so every verb is redacted.
func (s Secret) Format(f fmt.State, _ rune) { _, _ = f.Write([]byte(redacted(s))) }

// MarshalJSON implements json.Marshaler with a redacted value.
func (s Secret) MarshalJSON() ([]byte, error) { return []byte(`"` + redacted(s) + `"`), nil }

// MarshalText implements encoding.TextMarshaler with a redacted value.
func (s Secret) MarshalText() ([]byte, error) { return []byte(redacted(s)), nil }

func redacted(s Secret) string {
	if s.IsZero() {
		return ""
	}
	return "[REDACTED]"
}

// ServerInfo is what a connection learned about the server.
type ServerInfo struct {
	// Product, e.g. "PostgreSQL", "CockroachDB", "SQLite".
	Product string
	// Version, e.g. "17.11".
	Version string
	// Banner is the full version string if the server provides one.
	Banner string
}
