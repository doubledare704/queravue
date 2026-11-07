# DocumentDB

Engine id `documentdb` (display name "Amazon DocumentDB"), the same package as [MongoDB](mongodb.md) with these defaults: TLS on, `retryWrites=false`, host placeholder `<cluster>.docdb.amazonaws.com:27017`.

Two servers matter:

- **DocumentDB** from [documentdb.io](https://documentdb.io): open-source, PostgreSQL plus a MongoDB wire gateway. Runs locally in Docker. Azure Cosmos DB for MongoDB vCore is built on it.
- **Amazon DocumentDB**: the AWS service. Same wire protocol, different implementation.

## Connection examples
Local container (see Testing):
```text
mongodb://queravue@127.0.0.1:10260/?tls=true&tlsAllowInvalidCertificates=true&directConnection=true
```
Amazon DocumentDB cluster, from a host that can reach the VPC (or through the SSH tunnel):
```text
mongodb://admin@mycluster.cluster-xxxx.eu-west-1.docdb.amazonaws.com:27017/?tls=true&tlsCAFile=global-bundle.pem&retryWrites=false&replicaSet=rs0&readPreference=secondaryPreferred
```
The password is entered in the form (or stripped from the pasted URI) and stored in the keychain.

## TLS and CA notes
- DocumentDB Local generates a **self-signed** certificate valid for 365 days. Either tick "Allow invalid certificates" (local only) or copy the certificate out and use it as the CA file:
  ```bash
  docker cp queravue-dev-documentdb-1:/home/documentdb/.local/state/documentdb-gateway/tls/cert.pem ./documentdb-cert.pem
  ```
- Amazon DocumentDB requires TLS by default. Download the Amazon RDS `global-bundle.pem` and set it as the CA file; clusters are reachable only from inside their VPC.
- `direct_connection` is needed for the local container (single node, no replica-set name). Amazon DocumentDB clusters use `replicaSet=rs0` and the cluster endpoint.

## Limitations
Taken from vendor documentation and experience with the protocol, **not verified by our tests** except where "Verified against" says so.

- **Retryable writes** are not supported by Amazon DocumentDB; Queravue always sets `retryWrites=false` for this engine.
- Amazon DocumentDB supports a subset of the MongoDB API (no `$expr`-heavy aggregation pipelines in older engine versions, no client-side field-level encryption, capped collections only in some versions). Queravue's own operations avoid `$expr`, but a filter you type can hit an unsupported operator: the server's error is shown as an `UNSUPPORTED`/`SERVER` message next to the query bar.
- `$sample` support differs between servers and versions. When it fails, table columns are built from the first documents instead (`used_fallback`); the table still works.
- Estimated counts and "databases visible" depend on the user's privileges; if listing databases is denied, the tree falls back to the connection's default database.

## Verified against
Run manually on 2026-11-06 with `make test-docdb` (smoke test `TestSmokeDocumentDB`):

| Server | `buildInfo` version | Result |
|---|---|---|
| DocumentDB Local `ghcr.io/documentdb/documentdb/documentdb-local:pg17-1.0.0`, arm64, username/password auth, TLS self-signed | 7.0.0 | pass |

Verified: connect and ping with TLS and SCRAM credentials; `buildInfo`; insert of `Int32`, `Int64`, `Double` and `Date` values and find returning them type for type; filter, sort and projection; exact count; collection listing; replace with `expected_document`; field update with set and unset; conflict on a stale replace with the current document attached; delete; `$sample` (no fallback needed); index create, list and drop, with `$indexStats` usage and per-index sizes, `collStats`, and a `collMod` `$jsonSchema` validator set, read back and removed (DocumentDB Local 7.0.0).

**Not verified:** Amazon DocumentDB (no AWS account used), `listDatabases` as a user without that privilege, large result streaming, retryable writes.

## Testing
The container is behind a compose profile, so a plain `up` does not start it:
```bash
make test-docdb                  # starts only the documentdb service, runs the smoke test
make db-only DB=documentdb       # stop every other test database first, then start this one
QV_DOCDB_URI='mongodb://user:pass@host:27017/?tls=true&tlsCAFile=global-bundle.pem&retryWrites=false' \
  go test -tags=integration -run TestSmokeDocumentDB -v ./internal/engine/mongo/   # from core/
```
The test is skipped when `QV_DOCDB_URI` is unset. `QV_DOCDB_DB` overrides the scratch database (`queravue_smoke`); the test creates and drops its own collection.
