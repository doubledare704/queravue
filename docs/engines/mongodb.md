# MongoDB

One package, `core/internal/engine/mongo`, built on the official `go.mongodb.org/mongo-driver/v2`. It serves three engine ids that share all code and differ only in form defaults and connection options:

| id | Server | Page |
|---|---|---|
| `mongodb` | MongoDB 6/7/8, Atlas, self-hosted | this page |
| `cosmosdb-mongo` | Azure Cosmos DB for MongoDB | [cosmosdb.md](cosmosdb.md) |
| `documentdb` | DocumentDB (documentdb.io, Amazon DocumentDB) | [documentdb.md](documentdb.md) |

Design: [ADR 0009](../adr/0009-document-model.md). The engine declares `connect`, `schema_inspector` and `document_store`, not `execute`: a Mongo connection never offers "Run SQL".

## Connecting
Fields: hosts (comma list), SRV, replica set, default database, user, password (keychain only), auth source, auth mechanism (`default`, `SCRAM-SHA-256`, `SCRAM-SHA-1`, `MONGODB-X509`), TLS, CA file, client certificate + key, allow invalid certificates, direct connection, read preference.

Or paste a URI (`mongodb://`, `mongodb+srv://`): it is split into the fields above and the password goes to the keychain. `mongodb+srv` is not resolved while parsing, only on connect.

```text
mongodb://app@localhost:27017/?replicaSet=rs0
mongodb+srv://app@cluster0.example.mongodb.net/?authSource=admin
mongodb://x509user@host:27017/?tls=true&authMechanism=MONGODB-X509&tlsCertificateKeyFile=/path/client.pem
```

## Behaviour
- **Tree:** databases → collections and views. Time-series and capped collections are marked. `system.*` collections are hidden. Counts are estimates from collection metadata.
- **Documents** travel as canonical Extended JSON v2, so every BSON type survives a round trip (`Int32` stays `Int32`, `Date` stays `Date`). Filter, sort and projection also accept relaxed EJSON. Documents from the editor must be canonical: a bare number is rejected with a message naming `$numberInt`, `$numberLong` and `$numberDouble`.
- **Query bar:** filter, sort, projection, skip, limit; parse errors point at the failing character. Results stream in batches of at most 500 documents and about 2 MiB; paging re-queries with skip/limit. 1M documents stream in about 4 s with the core heap growing by about 3 MB.
- **Editing:** insert, replace and field update. Edits send the document as loaded; if the stored document changed meanwhile the write is refused with a conflict that carries the current document (reload, or overwrite). The check is compare-then-guarded-write, not a single atomic operation, so two writers racing inside the same few milliseconds can still lose an update.
- **Production connections** require a confirmation for deletes (enforced in the core).
- **Cancel:** every find is cancellable; the server cursor is closed.

## Shell
The shell runs mongosh-style JavaScript on an embedded goja runtime in the core (ADR 0010). It works on MongoDB, DocumentDB and Cosmos DB connections and needs no `mongosh` install. Variables, functions and `let`/`const` persist between runs of one shell. Write one command per line or several statements per run; the value of the last expression becomes the result.

**Supported**
- Globals: `db`, `use name` / `use("name")`, `show dbs`, `show collections`, `print`, `printjson`, `tojson`, `console.log/info/warn/error`, `sleep(ms)`.
- Database: `getSiblingDB`, `getName`, `getCollection`, `getCollectionNames`, `runCommand`, `adminCommand`, `stats`, `version`, `serverStatus`, `createCollection`, `dropDatabase`.
- Collections: `db.users`, `db['my-coll']`, `db.a.b`, with `find`, `findOne`, `countDocuments`, `estimatedDocumentCount`, `distinct`, `aggregate`, `insertOne/Many`, `updateOne/Many`, `replaceOne`, `deleteOne/Many`, `findOneAndUpdate/Replace/Delete`, `bulkWrite`, `createIndex`, `getIndexes`, `dropIndex`, `drop`, `renameCollection`, `stats`.
- Cursors: `limit`, `skip`, `sort`, `project`/`projection`, `batchSize`, `hint`, `maxTimeMS`, `toArray`, `forEach`, `map`, `hasNext`, `next`, `tryNext`, `count`, `size`, `itcount`, `pretty`, `explain`, `close`.
- BSON: `ObjectId`, `ISODate`, `Date`, `NumberInt`, `NumberLong`, `NumberDecimal`, `UUID`, `BinData`, `Timestamp`, `MinKey`, `MaxKey`, `Double`, regex literals. All round-trip exactly through canonical EJSON.

**Results.** A scalar or a document is returned as EJSON. A write returns the mongosh-shaped object (`acknowledged`, `insertedId`, `matchedCount`, ...). If the last expression is an unconsumed cursor (`db.users.find(...)`, `db.users.aggregate(...)`), nothing is read by the shell: the UI gets a cursor handle and pages it. `toArray()` is capped by the output limit (8 MiB per run by default) and fails with `OUTPUT_LIMIT` beyond it; `forEach` and `next` hold one batch, so memory stays flat on huge collections.

**Differences from mongosh**
- Synchronous API: no `await`, `Promise`-returning driver methods or callbacks. goja runs ES5.1 plus most of ES6; newer syntax is a syntax error.
- No `require`, `load`, `process`, file system, network or timers; they fail with `UNSUPPORTED`. `sleep` is cancellable.
- Integral doubles that fit an Int32 are written back as Int32 (as in the Node driver); `Double(2)` forces a double. `NumberLong` has no arithmetic beyond `toNumber()`.
- `print` and `printjson` use the legacy shell style (`ObjectId("…")`, `NumberLong("…")`, `ISODate("…")`), not Node's `util.inspect`.
- `insertOne`/`insertMany` do not modify the document you pass in. `cursor.map` returns the same cursor with the mapper attached.
- A cursor result is a replayable query: paging re-runs it with `skip`/`limit`. A `$out`/`$merge` pipeline runs once, when `aggregate` is called.
- Not implemented: sessions and transactions, change streams, `getMongo`, user and role helpers, `db.collection.help()`, `Symbol`, `DBRef`, `Code`.

**Safety.** The shell stops with `CONFIRMATION_REQUIRED` (nothing changes) before `deleteMany({})`, `drop`, `updateMany` with an empty filter, `$out`/`$merge`, and `runCommand`/`adminCommand` with a write command on connections flagged production. `dropDatabase` asks on every connection. The UI re-runs the script with `confirmed` after the user agrees. A gated call cannot be caught with `try/catch`.

**Limits and cancel.** Cancelling interrupts the running script, including a tight loop, and the server operation in flight. A timeout per run is optional and off by default.

## Limitations
- No aggregation builder, index manager or schema validation editor yet (see ROADMAP). The shell has no autocomplete yet.
- Table view columns come from a sample of 100 documents (`$sample`, with a fallback to the first documents).
- Kerberos, LDAP and AWS IAM authentication are not exposed.

## Testing
```bash
docker compose -f dev/docker-compose.yml up -d --wait mongo
docker compose -f dev/docker-compose.yml --profile seed up mongo-seed    # users, orders, 1M events
cd core && go test -tags=integration ./internal/engine/mongo/... ./internal/shell/...
```
The shell's snippet corpus lives in `core/internal/shell/testdata/corpus`: each `name.js` has a `name.out` transcript produced by a real server. After changing shell behaviour on purpose, regenerate with `go test -tags=integration ./internal/shell -run TestSnippetCorpus -update` and review the diff. `make test-docdb` also runs a shell smoke test on the DocumentDB service.
Auth, TLS and X.509 are covered by unit tests only: the dev server runs without authentication.
