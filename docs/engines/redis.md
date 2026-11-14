# Redis and Valkey

Package `core/internal/engine/redis`, built on `redis/go-redis/v9` (BSD-2-Clause). One engine, two descriptors: `redis` and `valkey` (same code; Valkey differs only in the product name taken from `INFO server`). The engine reports `connect` and `key_value_store` and implements `engine.KeyValueStore` behind `KeyValueService` (ADR 0020). It has no SQL, schema or document capabilities.

## Connection
Form fields: mode (`standalone`, `sentinel`, `cluster`), hosts (comma-separated `host:port`, default port 6379), Sentinel master name, user (ACL), password (keychain), database, TLS, CA file and "allow invalid certificates". URI: `redis://user:password@host:6379/3`; `rediss://` turns TLS on; `valkey://` and `valkeys://` are accepted.

- **Standalone:** one client per logical database, created on first use (4 connections each). Choosing a database never runs `SELECT` on a shared connection.
- **Sentinel:** `FailoverClient` with the master name; the Sentinel nodes use the same user and password as the master.
- **Cluster:** `ClusterClient`; database 0 only (other indexes return `UNSUPPORTED`).
- **RESP3** is requested; a server that rejects `HELLO 3` falls back to RESP2 on its own.
- **TLS and SSH:** every socket (standalone, Sentinel and Cluster members, discovered nodes) is dialed by one function that uses the session dialer (`internal/netpath`, the SSH tunnel) and then wraps TLS with `netpath.TLSSettings.Build(host)`. go-redis applies `TLSConfig` only to its own dialer, so TLS is done here, per target host. The older `tls`, `tls_ca_file` and `tls_insecure` params still work when no `TLSSettings` are set.

## Behaviour
- **Keys are bytes.** Scanning never uses `KEYS`; it is `SCAN` with `COUNT` (default 500, at most 10,000) and an optional server-side `TYPE` filter. On a cluster every master is scanned and pages are sent as they arrive. Type and TTL are not fetched per key during a scan (`ttl_ms = -2`); `GetKeyInfo` has them.
- **GetKeyInfo:** `TYPE`, `PTTL`, `OBJECT ENCODING`, `MEMORY USAGE` (left unset when the ACL forbids it), and the length per type. A string that starts with `HYLL` is reported as HyperLogLog. A key is "big" at 10,000 elements, 10 MiB of memory, or a 10 MiB string.
- **ReadValue** pages by type; the cursor is opaque to the UI:

| Type | Read | Cursor |
|---|---|---|
| string | `GETRANGE` up to `max_bytes` (default 1 MiB), cut on a UTF-8 boundary; `binary` when not valid UTF-8 | byte offset |
| hash, set | `HSCAN`, `SSCAN` | server cursor |
| list | `LRANGE` windows; `reverse` reads from the tail (the page is returned newest first) | element offset |
| sorted set | `ZSCAN`, or `ZRANGE … WITHSCORES` / reversed with `order_by_score` | server cursor, element offset |
| stream | `XRANGE` / `XREVRANGE` with `COUNT` | next id (computed, so Redis 6.2 exclusive ranges are not needed) |
| ReJSON | `JSON.GET key $`, refused above 16 MiB | none |
| HyperLogLog | `PFCOUNT` | none |

- **Writes** are the typed ops of ADR 0020. `SET` keeps an existing TTL. `RENAME` without `overwrite` uses `RENAMENX` and reports `Conflict` when the target exists. `SetExpiry` with no value is `PERSIST`; a TTL below 1 ms is rejected. `DeleteKeys` deletes in chunks of 500; on a cluster it deletes key by key so keys in different slots work.
- **ExecuteCommand:** pre-split arguments, typed reply tree. Refused before they reach the server: `KEYS` (`KEYS_REFUSED`), blocking commands (`BLOCKING_REFUSED`: `BLPOP` family, `SUBSCRIBE` family, `MONITOR`, `WAIT`, `SYNC`, `XREAD`/`XREADGROUP` with `BLOCK`), and commands that change connection state (`SELECT`, `HELLO`, `AUTH`, `MULTI`, `EXEC`, `DISCARD`, `WATCH`, `UNWATCH`, `RESET`; reported as `INVALID`). A server error reply is a normal reply of kind `error`. A reply with more than 100,000 elements is refused (`UNSUPPORTED`) with a hint to page.
- **Production connections** need `confirmed=true` for `FLUSHALL`, `FLUSHDB`, `DEL`/`UNLINK` of more than one key, `CONFIG SET`, `SHUTDOWN` and `DEBUG`, and for `DeleteKeys` with more than one key. The rule lives in `internal/rediscli` (`Inspect`) and runs in `KeyValueService`, before the engine.
- **Pub/sub:** `Subscribe` streams until the RPC is cancelled; the session is held so it does not idle out meanwhile. `Publish` returns the receiver count.
- **Command-line parsing:** `internal/rediscli.Split` splits a line like `redis-cli` (double quotes with `\n \r \t \b \a \xHH \\ \"`, single quotes with `\'`). The UI splits input itself before `ExecuteCommand`; this package is the reference and is tested for the same cases.

## Limitations
- **Map order and sets in command replies.** go-redis returns RESP3 maps unordered and sets as lists, and drops the verbatim format. Core sorts map entries by key and labels the top-level reply of `SMEMBERS`, `SINTER`, `SUNION` and `SDIFF` as a set. Nested sets and verbatim strings show as arrays and strings. `Reply` has a `verbatim` kind that the engine never produces.
- **Stream fields keep their order** (read from the raw reply); only command replies lose map order.
- **Sentinel** is implemented with go-redis `FailoverClient` and covered by configuration tests only; there is no Sentinel service in `dev/docker-compose.yml`.
- **Cluster:** database 0 only; `Subscribe` uses one node (the one owning the first channel's slot, or any node for pattern-only subscriptions), so patterns see messages published to that node's shard. Cluster topology views are Iteration 14.
- **Unbounded server commands** typed in the command line (`SMEMBERS` of a huge set) still run on the server; core refuses the oversized reply but cannot stop the read.
- **Modules:** only ReJSON is read and written; the dev images have no modules, so JSON is not covered by integration tests. `JSON.SET` reports `UNSUPPORTED` where the module is missing.
- **Keyspace notifications, `MONITOR` and client tracking** are not supported.
- **The key-value engine has no history.** Commands and values are not written to the query history, as they can hold data.

## Testing
```bash
docker compose -f dev/docker-compose.yml up -d --wait redis valkey
docker compose -f dev/docker-compose.yml --profile seed up redis-seed
cd core && go test -tags=integration ./internal/engine/redis/ ./internal/api/
```
`redis-seed` runs `dev/seed/redis/seed.sh`: one of every type, nested `:` names, binary values and a binary key, keys with TTLs, the read-only ACL user `viewer`/`viewer`, 1M small keys (`scan:*`), a 2.4 MB string (`str:large`) and a 100k-element hash, list and sorted set (`big:*`). It starts with `FLUSHALL`.

The Cluster test needs three masters (an amd64 image, emulated on Apple Silicon) and skips when none answer:
```bash
docker compose -f dev/docker-compose.yml --profile redis-cluster up -d --wait redis-cluster
```
`REDIS_PERF=1` adds the memory measurement used in `docs/perf/iteration-10.md`. Ports and the password come from `REDIS_PORT`, `VALKEY_PORT` and `REDIS_PASSWORD`.
