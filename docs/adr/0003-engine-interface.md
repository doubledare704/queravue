# ADR 0003 — Engine interface and capability model

**Status:** Accepted · 2026-11-05

## Context
AGENTS.md rule 3: engines implement capabilities, not one fat interface. Iteration 1 needs connect/ping/version for Postgres (and CockroachDB) and SQLite. Iteration 2 adds streaming `Execute`, and later iterations add schema browsing, explain, documents, key-value and monitoring. The UI must enable features from reported capabilities, never from engine ids. Adding a capability must not force changes to engines that don't support it.

## Decision
Code lives in `core/internal/engine`.

```go
type Engine interface {                  // stateless driver, one per engine id
    Descriptor() Descriptor               // id, name, family, form fields, capabilities
    ParseURI(uri string) (Config, Secret, error)
    Connect(ctx context.Context, cfg Config, s Secret) (Conn, error)
}
type Conn interface {                    // one live connection
    Ping(ctx context.Context) error
    ServerInfo(ctx context.Context) (ServerInfo, error)
    Close() error
}
```

- **Engine vs Conn split.** `Engine` is a stateless factory and descriptor registered once in a `Registry`. `Conn` holds live state. The ask was "Connect, Ping, Close, ServerInfo": `Connect` sits on the factory and the other three on the connection, so no method ever runs against a half-built engine.
- **Capabilities are optional interfaces on `Conn`**, discovered with `engine.As[T](conn)`. Each descriptor also declares `[]Capability` names. The core uses those names to answer `ListEngines` without connecting, and the UI gates features on them. `CapConnect` is mandatory. A test checks that every declared capability has an interface mapping in `CapabilityInterfaces`.
- **Variants share a package.** CockroachDB is a second descriptor (`cockroachdb`, family `postgres`) built by `postgres.New(VariantCockroach)`.
- **Data-driven forms.** `Descriptor.Fields` (`FieldSpec`: key, label, kind, required, default, options) drives the UI's connection dialog. Password-kind fields never appear in `Config.Params`; they travel as an `engine.Secret`. `Secret` redacts itself under `fmt`, `slog` and JSON.
- **Typed errors.** Engines return `*engine.Error{Kind, Engine, Op, Msg, Err}`. Kinds are auth, network, tls, not_found, timeout, invalid_config and unknown. `Msg` is built for users and passed through `Redact`. `Err` keeps the cause for `errors.Is/As`, but its text is never shown. `ClassifyCommon` handles shared net, TLS and deadline cases.
- **Context everywhere.** Every method doing I/O takes `ctx`. `Connect` must honour the deadline for dial and handshake.

### How Iteration 2 adds Execute without breaking this
```go
// Executor is implemented by Conns with CapExecute.
type Executor interface {
    Execute(ctx context.Context, stmt Statement, sink RowSink) error
}
type RowSink interface {
    Columns(cols []Column) error
    Batch(rows [][]Value) error   // ≤ 500 rows per call; returning an error stops the query
}
```
- Add `CapExecute → reflect.TypeFor[Executor]()` to `CapabilityInterfaces`, and add `CapExecute` to the descriptors of engines that implement it.
- The gRPC handler drives a `RowSink` that forwards each batch to the server stream. Back-pressure comes from `stream.Send` blocking, and cancellation from the stream context. Nothing collects a full result set.
- `Conn` and `Engine` keep their current methods. The `Conn` returned by `Connect` simply gains a method. Session pooling (one long-lived `Conn` per open connection) is added in the API layer, not in this interface.

## Consequences
- Adding an engine means adding a package and registering it in `engine/engines`. No central switch statements.
- The capability names in the descriptor and the interfaces the Conn implements can drift apart. The registry test guards the mapping, and integration tests per engine assert each declared capability works.
- Type assertions are a runtime check. That is acceptable because the set of interfaces is small and covered by tests.
