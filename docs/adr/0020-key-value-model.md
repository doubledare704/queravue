# ADR 0020 — Key-value model (Redis)

**Status:** Accepted · 2026-11-14

## Context
Redis is neither SQL nor documents. It needs a key browser, a value view per data type, TTLs, a command line and pub/sub. Related: ADR 0003 (capabilities), ADR 0013 (confirmation).

## Decision

### 1. Capability and service
New capability `key_value_store`, backed by the `engine.KeyValueStore` interface, and a `KeyValueService` in `keyvalue.proto`. The UI enables the key browser from the capability, never from engine ids. Valkey and Redis Cluster use the same service.

### 2. Keys are bytes, reads are paged
Keys and values are `bytes`; binary is detected by the core. Nothing reads a whole collection:
- `ScanKeys` is a server stream over `SCAN` (never `KEYS`); on a cluster it scans every master. The UI builds the `:`-delimited tree lazily from the pages.
- `ReadValue` pages per type with an opaque cursor: strings with a size cap, hashes `HSCAN`, lists `LRANGE`, sets `SSCAN`, sorted sets `ZRANGE … WITHSCORES` or `ZSCAN`, streams `XRANGE`/`XREVRANGE`, ReJSON `JSON.GET` when the module is present, HyperLogLog count only.
- `GetKeyInfo` returns type, TTL, encoding, length and `MEMORY USAGE` where allowed, and flags big keys.

### 3. Typed writes
`WriteValue` takes a typed `WriteOp` per data type (set, hset/hdel, l/rpush, lset, lrem, sadd/srem, zadd/zrem, xadd/xdel, JSON.SET). `RenameKey`, `SetExpiry` (unset TTL means PERSIST) and `DeleteKeys` are separate RPCs.

### 4. Commands
`ExecuteCommand` takes pre-split arguments and returns a typed RESP3 reply tree (`RespValue`: string, integer, double, boolean, nil, array, map, set, verbatim, error). The CLI splits quoted input as `redis-cli` does. Blocking commands (`BLPOP`, `SUBSCRIBE`, `MONITOR`) are refused with `BLOCKING_REFUSED` and a hint to use the pub/sub viewer.

### 5. Pub/sub
`Subscribe` streams messages for channels and patterns until cancelled; `Publish` returns the receiver count. Keyspace notifications may follow later.

### 6. Safety
The mechanism of ADR 0013: a refused call returns `CONFIRMATION_REQUIRED` with an `operation` text, and the UI repeats it with `confirmed=true`. On production connections these always need confirmation: `FLUSHALL`, `FLUSHDB`, `DEL` of more than one key, `CONFIG SET`, `SHUTDOWN`, `DEBUG`. `KEYS` is refused with `KEYS_REFUSED` and a "use SCAN" hint.

## Consequences
- The proto change is additive; protocol version 10.
- Field numbers are fixed once released; new data types add `KeyType` and `WriteOp` entries.
- Cluster topology views are out of scope (Iteration 14).
