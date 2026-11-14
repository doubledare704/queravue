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

## Testing it
```bash
dev/tls/gen.sh                                                    # CA, server and client certs, SSH keys (gitignored)
docker compose -f dev/docker-compose.yml up -d --wait postgres mysql mongo clickhouse
docker compose -f dev/docker-compose.yml --profile tls --profile ssh up -d --wait
cd core && go test -tags=integration ./internal/netcells/
```
`gen.sh` keeps existing files, so reruns and CI get the same material; `--force` regenerates it. The `tls` profile adds `postgres-tls`, `mysql-tls`, `mongo-tls` and `clickhouse-tls` (ports 5443, 3316, 27018, 9441). The `ssh-bastion` service (port 2222, user `queravue`) accepts the password `queravue`, the key `dev/tls/out/ssh/id_ed25519` and the encrypted key `id_ed25519_encrypted` (passphrase `dev-passphrase`). It reaches the databases by service name on the compose network, so `postgres:5432` only resolves through the tunnel. Cells skip themselves when their database is not running.

Not covered by compose yet: SQL Server and Oracle TLS (no server certificate setup), and mutual TLS against a real database. Mutual TLS and the encrypted client key are covered by unit tests against a Go TLS server.

The bastion runs with `PerSourcePenalties no`: OpenSSH 9.8 penalises addresses that disconnect before authenticating, which is what the host key prompt does.
