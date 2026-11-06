# Azure Cosmos DB for MongoDB

Engine id `cosmosdb-mongo`, the same package as [MongoDB](mongodb.md) with these defaults: TLS on, `retryWrites=false`, host placeholder `<account>.mongo.cosmos.azure.com:10255`.

Cosmos DB has two Mongo offerings: **RU-based** accounts (port 10255) and **vCore** clusters (built on [DocumentDB](documentdb.md), port 10260). Both speak the MongoDB wire protocol.

## Connection examples
RU-based account (copy the connection string from the portal; the password becomes the keychain entry):
```text
mongodb://myaccount@myaccount.mongo.cosmos.azure.com:10255/?ssl=true&replicaSet=globaldb&retrywrites=false&maxIdleTimeMS=120000&appName=@myaccount@
```
vCore cluster:
```text
mongodb+srv://admin@mycluster.mongocluster.cosmos.azure.com/?tls=true&authMechanism=SCRAM-SHA-256&retrywrites=false
```
Both use the public Microsoft CA chain, so no CA file is needed.

## Limitations
All of this comes from Microsoft's documentation and is **not verified by our tests** (see "Verified against").

- **Retryable writes** are not supported (RU accounts): Queravue sets `retryWrites=false`.
- **Rate limiting (RU accounts):** requests over the provisioned throughput fail with error 16500 ("TooManyRequests"). The message is shown as a server error; retry later or raise RU/s. Large sorts and scans cost many RUs.
- Sorting needs an index on the sort field in RU accounts; otherwise the server rejects the query.
- Only a subset of MongoDB operators and aggregation stages is implemented, depending on the account's server version (3.6 to 7.0). Operators you type that are missing come back as server errors next to the query bar.
- Time-series collections, views and capped collections may be unavailable.
- Estimated counts are cheap, exact counts and `$sample` consume RUs.

## Testing
**There is no Docker image that serves the MongoDB API on Apple Silicon.** The vNext Linux emulator (`mcr.microsoft.com/cosmosdb/linux/azure-cosmos-emulator:vnext-latest`) supports the **NoSQL API only**, in HTTP/HTTPS gateway mode without authentication, so it cannot test this engine. The older Windows emulator and the legacy Linux emulator image (x64 only) expose a Mongo endpoint but are not part of our dev stack. For vCore behaviour use [DocumentDB Local](documentdb.md), which is the same engine family.

The smoke test (`TestSmokeCosmosDB`) therefore runs against a real account, by hand:
```bash
export QV_COSMOS_URI='mongodb://account:KEY@account.mongo.cosmos.azure.com:10255/?ssl=true&replicaSet=globaldb&retrywrites=false'
make test-cosmos
```
It is skipped when the variable is unset. It creates and drops its own collection in `queravue_smoke` (override with `QV_COSMOS_DB`) and uses a few hundred RUs.

## Verified against
**Nothing yet.** The Cosmos smoke test has not been run against a real account or emulator by us. Everything on this page about Cosmos behaviour comes from Microsoft's documentation and is unverified; the shared code path is verified against MongoDB 8 and DocumentDB Local. Record the server version and the results of `make test-cosmos` here when someone with an account runs it.
