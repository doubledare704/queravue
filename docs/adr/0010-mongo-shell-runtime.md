# ADR 0010 — Mongo shell runtime

**Status:** Accepted · 2026-11-06

## Context
Iteration 6 adds a shell tab where common `mongosh` snippets run unchanged against MongoDB, Cosmos DB (Mongo API) and DocumentDB. The PRD left open whether to embed a JS engine (goja) or delegate to an installed `mongosh`. The runtime must be cancellable, stay inside the PRD memory budgets, and be reusable by the It. 15 scheduler while the UI is closed. Related: ADR 0003 (capabilities), 0006 (cancel), 0009 (document model, EJSON, production confirmation).

## Decision

### 1. Embedded goja runtime in core
`internal/shell` runs a [goja](https://github.com/dop251/goja) runtime (pure Go, no cgo) with a mongosh-compatible API subset. It uses the driver session of the open connection, so TLS, SSH tunnels, secrets and the production flag apply unchanged. The package has no gRPC dependency; `internal/api` is a thin adapter, and the scheduler calls the same package.

**Rejected: shelling out to `mongosh`.** It must be installed, and its version drifts from the server. It opens its own connection, so credentials and TLS material would have to travel on a command line or in the environment. Its output is text that we would parse back into typed values. Cancelling means killing a process, with no way to tell what the server did. It cannot run for the scheduler on a machine without it. Cosmos DB and DocumentDB quirks could not be handled in one place.

### 2. Sessions and threading
One runtime per shell, on its own goroutine; `Eval` calls on a shell run one at a time. Top-level `var`/`let`/functions persist between calls. `OpenShell` takes a `SessionService` session id and a default database; `CloseShell` and closing the session free the runtime.

### 3. Supported subset
- **Globals:** `db`, `use(name)` and the `use name` / `show dbs` / `show collections` line forms, `print`, `printjson`, `console.log`.
- **Database:** `getSiblingDB`, `getName`, `getCollectionNames`, `runCommand`, `adminCommand`, `stats`, `createCollection`, `dropDatabase`.
- **BSON constructors:** `ObjectId`, `ISODate`, `Date`, `NumberInt`, `NumberLong`, `NumberDecimal`, `UUID`, `BinData`, `Timestamp`, `MinKey`, `MaxKey`, regex literals. Values round-trip through the EJSON code in `engine/mongo` (ADR 0009 §1), so no type is coerced.
- **Collection:** `find`, `findOne`, `countDocuments`, `estimatedDocumentCount`, `distinct`, `aggregate`, `insertOne/Many`, `updateOne/Many`, `replaceOne`, `deleteOne/Many`, `findOneAndUpdate/Replace/Delete`, `bulkWrite`, `createIndex`, `getIndexes`, `dropIndex`, `drop`, `renameCollection`.
- **Cursor:** `limit`, `skip`, `sort`, `project`/`projection`, `batchSize`, `hint`, `maxTimeMS`, `toArray`, `forEach`, `map`, `hasNext`/`next`, `count`, `pretty`, `itcount`, `explain`.
- **Collection access:** `db.users` and `db['my-coll']` through a goja dynamic object.

Anything else throws an `UNSUPPORTED` error naming the method. Differences from mongosh are listed in `docs/engines/mongodb.md`.

### 4. Sandbox and limits
No `require`, filesystem, network or `process`; `load()` and `require` throw `UNSUPPORTED`. Timers are not provided. Cancellation: the `Eval` context sets `vm.Interrupt` and cancels in-flight driver operations, so an infinite loop and a long `find` both stop. Panics are recovered at the `Eval` boundary and in every runtime goroutine and become typed errors. A wall-clock timeout is optional and off by default. Output is capped (default 16 MiB of printed text and materialised documents per `Eval`, configurable); crossing the cap ends the call with `OUTPUT_LIMIT`. `toArray()` and `itcount`-style materialisation count against the cap. Iterating with `forEach` or `next` holds one driver batch, so a 1M-document cursor keeps core memory flat.

### 5. Result mapping
`Eval` streams events: print lines, result items, an optional error, and a final `Done`. The last expression statement of the script becomes a result item:
- scalar → EJSON text;
- one document → canonical EJSON (ADR 0009);
- write operations → mongosh-shaped results (`acknowledged`, `insertedId(s)`, `matchedCount`, `modifiedCount`, `deletedCount`, `upsertedId`);
- an unconsumed cursor → a **cursor handle**, nothing is materialised.

A cursor handle is a replayable query spec (`find` with filter/sort/projection/skip/limit, or an `aggregate` pipeline), not a server-held cursor. The UI opens it in the document views and pages it by re-running the spec with `skip`/`limit` (ADR 0009 §3), through `DocumentService.Find` for `find` handles and `ShellService.FetchCursor` for `aggregate` handles. Handles live as long as the shell.

Errors carry the JS stack and a line/column in UTF-16 units (ADR 0006), so the UI can jump to the position.

### 6. Production safety
On connections flagged `production`, these fail with `CONFIRMATION_REQUIRED` and change nothing: `deleteMany({})`, `drop`, `dropDatabase`, `updateMany` with an empty filter, and `adminCommand`/`runCommand` with write commands. The error names the operation. The UI asks, then re-sends the same `Eval` with `confirmed=true` (the ADR 0009 §8 mechanism). The flag lives on the saved connection, so the check is in the shell's operation layer, not in the engine. `db.dropDatabase` asks for confirmation on every connection through the same error unless `confirmed` is set.

### 7. Capability
`CapShell = "shell"`, declared by the Mongo engines (all variants). The UI offers the shell tab from this name only.

### 8. Contract
`ShellService`: `OpenShell`, `Eval` (server stream), `FetchCursor` (server stream wrapping `DocumentBatch`), `Cancel`, `CloseShell`. `protocol_version` becomes 5 once the service is served.

## Consequences
- Works with no `mongosh` installed, is cancellable, and runs without a UI.
- We maintain a compatibility layer; behaviour that differs from mongosh is documented and covered by a snippet corpus (`core/internal/shell/testdata/corpus`).
- goja is ES5.1+ with much of ES6; modern syntax unsupported by goja fails with a syntax error, which the docs list.
- Cursor handles re-run queries, so paged results can change if data changes in between; accepted, as for ADR 0009.
- New dependency: `github.com/dop251/goja` (MIT), pure Go.
