# ADR 0018 — Network paths: SSH tunnels and TLS

**Status:** Proposed · 2026-11-14 (changes the security model; needs owner sign-off before PR 0 merges)

## Context
Iteration 10 makes every network engine reachable over three paths: direct, TLS and SSH. Today TLS is an engine-specific param (`sslmode` for Postgres, `tls` for MySQL) and there is no tunnel. Core owns all I/O, so core must also own the tunnel.

Related: ADR 0003 (engine interface, `KindTLS`), AGENTS.md security rules.

## Decision

### 1. Typed connection-level settings
`Connection` gets `SshTunnel` and `TlsSettings` (proto `connections.proto`, fields 11 and 12). They replace the per-engine params. Existing `sslmode` and `tls` values are migrated to `TlsSettings` when a stored connection is read; the old keys are dropped on the next save.
- `SshTunnel`: host, port, user, auth method (password, key file, agent), keep-alive, connect timeout, optional single jump host.
- `TlsSettings`: mode (disable, prefer, require, verify-ca, verify-full), CA file, client certificate and key, server name override.
- `EngineInfo.supports_ssh` and `supports_tls` tell the UI which sections to render. File-based engines report neither.
- Secrets (SSH password, key passphrase, client key passphrase) travel only in `SshSecrets` and `TlsSecrets` on create, update and test, are stored in the OS keychain, and never come back; the messages expose `has_*` flags.

### 2. Dialing
One `*ssh.Client` is opened per session and shared by all pools of that connection. Engines receive a dialer that opens channels on it:

| Engine | Hook |
|---|---|
| PostgreSQL family | pgx `DialFunc` |
| MySQL family | `mysql.RegisterDialContext` |
| SQL Server | go-mssqldb `Dialer` |
| MongoDB family | `SetDialer` |
| Redis, Valkey | go-redis `Dialer` |
| ClickHouse | clickhouse-go `DialContext` |
| Oracle | to be verified; if go-ora has no hook, a local forward on `127.0.0.1:<random>` that lives as long as the session |

Lane A records the Oracle outcome here. The target host is resolved on the bastion side.

### 3. Host keys
Keys are checked against `~/.ssh/known_hosts` and a Queravue-owned known_hosts file.
- Unknown host: the connect fails with `ERROR_KIND_SSH_HOST_KEY_UNKNOWN` carrying the SHA256 fingerprint. The UI asks the user and calls `TrustHostKey`, which only accepts the fingerprint the failure carried.
- Changed key: hard failure, `ERROR_KIND_SSH_HOST_KEY_CHANGED`, with both fingerprints. There is no ignore option and no trust RPC path for it.
- `InsecureIgnoreHostKey` is never used.

### 4. Agent
`SSH_AUTH_SOCK` on macOS and Linux. On Windows, the OpenSSH agent named pipe, with Pageant as an optional fallback.

### 5. Topology-aware engines
Mongo replica sets and Redis Cluster/Sentinel route every discovered member through the tunnel dialer. Advertised member names (for example `localhost:27017`) must be reachable from the bastion. If they are not, `directConnection=true` (Mongo) is the documented escape hatch; `docs/connectivity.md` explains it.

### 6. Lifecycle
The tunnel opens at session open. Keep-alives detect a dead tunnel; in-flight calls fail with `ERROR_KIND_TUNNEL_LOST` and the UI offers "tunnel lost — reconnect". Closing the session closes the tunnel, and a cancelled dial leaves no goroutine behind (verified with `goleak`).

### 7. Test connection
`TestConnectionResponse.steps` reports SSH, TLS, auth and ping separately and stops at the first failure.

### 8. Logging
Keys, passphrases, passwords and full DSNs are never logged or put in error messages.

## Consequences
- `golang.org/x/crypto` (BSD-3-Clause) becomes a direct dependency, for `ssh` and `ssh/agent`.
- One TLS config builder replaces per-engine TLS code; engines map it to their driver options.
- Two engines of the same family behave identically on every path, which is what the CI matrix tests.
- Not chosen: forwarding every connection through a local port. It works for all drivers, but opens listening sockets, breaks topology discovery and leaks past session close. It remains only the Oracle fallback.
- Follow-up, out of scope: HTTP and SOCKS proxies.
