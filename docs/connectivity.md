# Connectivity: SSH tunnels, TLS and host keys

Decision record: [ADR 0018](adr/0018-network-paths-ssh-tls.md). Code: `core/internal/netpath` (tunnel, host keys, TLS builder) and `core/internal/connections` (storage, test steps).

A connection reaches its database over one of three paths: direct, TLS, or SSH (with or without TLS inside the tunnel). The path is a property of the connection (`SshTunnel`, `TlsSettings`), not of the engine.

## SSH tunnels
- One `*ssh.Client` per session. Every pool the session opens shares it, and closing the session closes it. Opening takes at most the connect timeout (default 10 s) and a cancelled context returns at once without leaving goroutines.
- Auth methods: password, key file (OpenSSH or PEM, passphrase from the keychain) and agent. The agent is `SSH_AUTH_SOCK` on macOS and Linux and the `\\.\pipe\openssh-ssh-agent` pipe on Windows. Pageant is not supported yet.
- One optional jump host. The jump host has its own credentials.
- Keep-alive (default 30 s) probes the bastion. When it fails, or the SSH connection closes, the tunnel is marked lost: in-flight reads and writes fail with `ERROR_KIND_TUNNEL_LOST`, and so does every later dial. The session has to be reopened.
- The driver dials the database from the bastion, so the host name is resolved there. `postgres` or `10.0.3.7` are the bastion's view of the network, not the laptop's.
- SSH channels have no deadlines. The core adds read deadlines and checks write deadlines before each write; a write that blocks on a stalled bastion is only stopped by closing the session.

### Secrets
The SSH password, key passphrase and client key passphrase go in `SshSecrets` and `TlsSecrets` and are stored in the OS keychain under `conn/<id>/ssh-password`, `.../ssh-key-passphrase`, `.../ssh-jump-password`, `.../ssh-jump-key-passphrase` and `.../tls-key-passphrase`. They never come back; the connection only exposes `has_*` flags. Removing the tunnel or jump host from a connection deletes the matching secrets. Keys, passphrases, passwords and DSNs are never logged or put in error messages.

## Host keys
Keys are checked against `~/.ssh/known_hosts` (read only) and `known_hosts` in the Queravue config directory (written by Queravue). There is no `InsecureIgnoreHostKey` anywhere.

| State | Result |
|---|---|
| Key matches either file | Connects. |
| Host in neither file | `ERROR_KIND_SSH_HOST_KEY_UNKNOWN` with `ssh_host` and the SHA256 fingerprint. The UI shows it and, if the user accepts, calls `TrustHostKey` with that fingerprint. |
| Host known with a different key | `ERROR_KIND_SSH_HOST_KEY_CHANGED` with the presented and the trusted fingerprint. A hard failure: there is no trust call for it. Remove the old line from the known_hosts file yourself if the change is legitimate. |

`TrustHostKey` only accepts the fingerprint of the key the last failed connect presented for that host and port. The core keeps that key in memory, so trusting needs a failed connect first, and a fingerprint typed by hand is refused.

## TLS
One `TlsSettings` for every network engine:

| Mode | Behaviour |
|---|---|
| `disable` | No TLS. |
| `prefer` | TLS if the server offers it, no verification. |
| `require` | TLS, certificate not verified. |
| `verify-ca` | TLS, the chain is verified against the CA file (or system roots), the host name is not. |
| `verify-full` | Chain and host name verified. `server_name` replaces the connect host in the check. |

A client certificate and key give mutual TLS. The key may be encrypted (PKCS#8 or legacy PEM); its passphrase comes from the keychain. A combined certificate-and-key PEM goes in both fields.

Engine mapping and limits:

| Engine | Notes |
|---|---|
| PostgreSQL family | `sslmode` for the mode, then the shared config replaces pgx's. |
| MySQL family | `Config.TLS`; `prefer` also allows plaintext. |
| SQL Server | The driver builds its own TLS from DSN options: mode, CA file and server name map; client certificates are rejected, and `verify-ca` checks the host name too. `encrypt=strict` (TDS 8) cannot be expressed and stays an engine param. |
| MongoDB family | `SetTLSConfig`; the driver verifies each replica set member against its own name unless `server_name` is set. |
| ClickHouse | `prefer` behaves as `require`. |
| Oracle | `prefer` behaves as `require`; wallets stay an engine param. |

Connections saved before this change keep working: `sslmode` (PostgreSQL), `tls` (MySQL, ClickHouse), `encrypt` and `trust_server_certificate` (SQL Server), `tls*` (MongoDB) and `ssl*` (Oracle) are converted to `TlsSettings` when the connection is read, and the old keys are dropped on the next save. `allow` becomes `prefer`.

## Topology caveats
- **MongoDB replica sets.** The driver connects to every member the server advertises, and each connection goes through the tunnel. The advertised names must resolve from the bastion. A dev replica set that advertises `localhost:27017` points at the bastion itself. Set `direct_connection=true` to talk only to the host you typed. That is the escape hatch for a replica set whose advertised names the bastion cannot reach, at the price of no failover and no primary discovery.
- **Redis Cluster and Sentinel.** The same rule applies; the Redis engine takes the dialer from `engine.Config.Net.Dial`.
- **SQL Server named instances and availability groups.** The host name is resolved on the bastion; `MultiSubnetFailover` is untouched.

## Connection form
The engine descriptor controls which sections appear. Under **SSH**, choose password, private key, or SSH agent authentication. Jump-host credentials are independent of bastion credentials. Under **TLS**, choose a mode and provide the CA and client key files when required. SQL Server `encrypt=strict` can still be imported from a URI or DSN and is retained while TLS mode is **Engine default**.

**Test** shows SSH, TLS, authentication and ping outcomes as reported by the core. Steps that do not apply are omitted. Some drivers negotiate TLS and authenticate in one call, so those two steps may share a timing. Accepting an unknown fingerprint retries the test. A changed fingerprint shows the presented and trusted keys and blocks the connection.

The status bar reflects the selected saved SSH connection. When SQL execution reports a lost tunnel, **Reconnect** reopens the browsing session. The next editor run opens a fresh tab session. Idle loss and loss observed only by document or key-value operations are not surfaced by the current gRPC contract.

## Connectivity matrix

| Engine or variant | Direct | TLS | SSH |
|---|:---:|:---:|:---:|
| PostgreSQL, CockroachDB, MySQL, MariaDB, TiDB, SQL Server, Oracle, ClickHouse | ✓ | ✓ | ✓ |
| MongoDB replica set, DocumentDB Local, Redis standalone, Redis Cluster, Valkey | ✓ | ✓ | ✓ |
| SQLite, DuckDB | ✓ | n/a | n/a |
| Cosmos DB for MongoDB | Env-gated smoke test | Env-gated smoke test | Outside the container matrix |

A check mark identifies a configured CI cell. Each applicable cell tests then opens the connection, pings, streams 10,000 rows/documents/keys, and cancels a second stream after its first batch. It checks that the endpoint can serve a ping after cancellation, reconnecting when the driver discards the original connection. The test uses a temporary database file for file engines and disposable Compose projects for network engines. SSH cells remove the database's published ports and assert that Docker published none of them. The test connects through the bastion's published port.

Run a cell locally from the repository root with Docker Compose and Go installed.

```bash
dev/run-connectivity-cell.sh postgres ssh
dev/run-connectivity-cell.sh mongo tls
dev/run-connectivity-cell.sh duckdb direct
```

Use the port variables in `dev/.env.example` to avoid local Compose port conflicts. For the direct MongoDB replica set, set `QV_MATRIX_MONGO_PORT` so its published and advertised ports match. The TLS fixtures use the CA generated by `dev/tls/gen.sh`. CockroachDB also uses a root client certificate. SQL Server can encrypt the login exchange even on its direct or SSH path. The Redis Cluster fixture advertises **localhost** for host-side cells and **redis-cluster** for SSH, so all masters resolve from the client doing the dialing.

Direct and SSH DocumentDB Local use its plaintext-capable gateway mode. The TLS cell uses the generated certificate and requires TLS. Oracle's TCPS fixture generates a development auto-login wallet using Oracle's pinned, checksum-verified PKI tool in a separate Java container. The tool is distributed under Oracle's Free Use Terms and is used only for the test fixture. See [Oracle's TLS guide](https://docs.oracle.com/en/database/oracle/oracle-database/26/dbseg/configuring-transport-layer-security-encryption.html).

The PostgreSQL SSH cell also checks agent authentication and private keys with and without a passphrase. The original integration tests in `core/internal/netcells` cover jump-host routing and TLS failures. See [Cosmos DB notes](engines/cosmosdb.md) for the optional account fixture using `QV_COSMOS_URI`. CI takes that URI from a repository secret on manual runs.
