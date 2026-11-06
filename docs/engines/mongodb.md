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

## Limitations
- No mongosh-style shell, aggregation builder, index manager or schema validation editor yet (see ROADMAP).
- Table view columns come from a sample of 100 documents (`$sample`, with a fallback to the first documents).
- Kerberos, LDAP and AWS IAM authentication are not exposed.

## Testing
```bash
docker compose -f dev/docker-compose.yml up -d --wait mongo
docker compose -f dev/docker-compose.yml --profile seed up mongo-seed    # users, orders, 1M events
cd core && go test -tags=integration ./internal/engine/mongo/...
```
Auth, TLS and X.509 are covered by unit tests only: the dev server runs without authentication.
