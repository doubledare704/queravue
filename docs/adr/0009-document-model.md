# ADR 0009 — Document model (MongoDB and compatible engines)

**Status:** Accepted · 2026-11-06

## Context
Iteration 5 adds MongoDB, Azure Cosmos DB (Mongo API) and Amazon DocumentDB. Documents are nested, schemaless and typed beyond JSON (Int32 vs Int64 vs Double, Decimal128, ObjectId, Date, Binary subtypes, Timestamp, MinKey/MaxKey, Regex). The UI must show, filter and edit them without silently changing types, and stay inside the PRD memory budget (1M-document collections browsed in one batch window). Related: ADR 0003 (capabilities), 0006 (spool), 0007 (schema model).

## Decision

### 1. Wire format: canonical Extended JSON v2, one string per document
Every document, `_id`, and update payload travels as a `string` holding canonical EJSON v2 (`{"_id":{"$oid":"…"},"n":{"$numberLong":"5"},"d":{"$date":{"$numberLong":"…"}}}`). Filter, sort and projection also travel as EJSON text; they may be relaxed.

Raw BSON bytes were the alternative. They are about 1.3–2× smaller and skip a text step in core, but Dart would need a BSON decoder (a new dependency and a second type system to keep in sync), and the editor needs text anyway. EJSON is parsed with `dart:convert`, shown and edited as text, and bounded batches keep the size cost small.

**Type preservation.** The UI treats `$`-wrapper objects as typed values and never coerces them (`{"$numberLong":"5"}` stays a wrapper, not a Dart `int`). Display renders relaxed or shell-style text (`NumberLong("5")`, `ISODate(…)`, `ObjectId(…)`) from the canonical tree; saving sends canonical EJSON. Hence an Int64 never becomes a double and a Date never becomes a string. Bare JSON numbers in documents written by the editor are rejected with a parse error that names the wrappers (`$numberInt`, `$numberLong`, `$numberDouble`); filter, sort and projection accept relaxed input (bare integer → Int32 if it fits, else Int64; bare decimal → Double). Conversion BSON ↔ EJSON lives in one place in core (`engine/mongo`), with round-trip tests for every BSON type.

### 2. Batches and memory
`Find` streams `DocumentBatch`es of at most `batch_size` documents (default 500, max 5000) **and** about 2 MiB, whichever comes first. A single larger document (BSON limit 16 MiB) travels alone, so PR 2 raises the gRPC max message size to 48 MiB on both ends. Core memory during browsing is one batch window; the driver cursor is never drained with `All`.

### 3. Paging: skip/limit re-query, no spool
ADR 0006 spools SQL results because a statement runs once and cannot be replayed cheaply. Mongo cursors cannot be re-read at random and documents change underneath, so the UI pages by re-running `Find` with `skip`/`limit` (like the SQL table view). Large `skip` is O(skip) on the server; keyset paging on `_id` is a later optimisation. `max_time_ms` bounds server work; cancelling the RPC closes the cursor.

### 4. Capability
`CapDocumentStore = "document_store"` with `engine.DocumentStore` (`Find`, `Count`, `Insert`, `Replace`, `UpdateFields`, `Delete`, `SampleFields`) on `Conn`, mapped in `CapabilityInterfaces`. Document views are enabled from this name only. Mongo engines do not declare `execute`, so the SQL editor never offers "Run SQL" for them. `Find` streams into a `DocSink` (same stop semantics as `RowSink`, `ErrStopDocs`).

### 5. Tree: reuse SchemaService
`ListDatabases` → databases, `ListObjects(database, schema="")` → collections. There is no schema level (like MySQL in ADR 0007). Additive contract changes: `SchemaObjectType` gains `COLLECTION` and `TIME_SERIES` (views reuse `VIEW`), `SchemaObject` gains `capped` and `size_bytes`, and `ListObjectsRequest` gains `include_system` (hides `system.*` by default; the schema cache key must include it). Estimated document counts use `row_count_estimate`.

### 6. DocumentService
A separate service, not more `SchemaService`/`QueryService` RPCs, because document payloads, errors and paging differ from rows. RPCs: `Find` (server stream), `Count` (estimated when the filter is empty, exact otherwise, with a timeout), `InsertDocuments`, `ReplaceDocument`, `UpdateFields`, `DeleteDocuments`, `SampleFields`. All take `session_id`; sessions are those of `SessionService`.

### 7. Optimistic concurrency
`ReplaceDocument` and `UpdateFields` accept `expected_document`, the document as the editor loaded it. The core re-reads the stored document and compares its BSON with the expected one byte for byte (field order and types count, so an Int32 turned Int64 by another writer is a conflict). On mismatch, or if the document was deleted, it writes nothing and returns `CONFLICT` with `current_document` (unset if deleted). The write itself is a `findOneAndReplace`/`findOneAndUpdate` whose filter is `_id` plus equality on the expected document's plain top-level fields, which narrows the window between check and write; if that write matches nothing the core reports a conflict as well. A fully atomic check (`$expr` on `$$ROOT`) is not used because it is unevenly supported on Cosmos DB and DocumentDB and ignores numeric type differences. The remaining window is a concurrent change that touches only fields the filter cannot express (dotted or `$`-prefixed names); accepted for an interactive editor. The UI offers "reload" (take `current_document`) or "overwrite" (resend without `expected_document`).

### 8. Errors
Per-request failures are in-band `DocumentError{kind, message, input, position, document_index, current_document}` with kinds PARSE, CONFLICT, NOT_FOUND, CONFIRMATION_REQUIRED, AUTH, NETWORK, TIMEOUT, CANCELED, UNSUPPORTED, SERVER. PARSE errors name the input (filter / sort / projection / document) and a UTF-16 offset. Unknown sessions are gRPC `NOT_FOUND`; a session without the capability is `FAILED_PRECONDITION`. Connections flagged `production` need `confirmed=true` on `DeleteDocuments` (the UI always confirms there) or the API layer returns CONFIRMATION_REQUIRED without changing anything; the flag lives on the saved connection, so the check sits in `DocumentService`, not the engine.

### 9. Sampling for table view
`SampleFields` returns top-level field names, `$type` aliases with counts and frequencies from `$sample` (default 100 documents). Views and servers without `$sample` fall back to reading the first documents and set `used_fallback`. The table view uses `_id` first, then the fields by frequency; unseen fields stay reachable in the tree and JSON views.

### 10. Connection parameters
No change to the `Connection` message. The engine descriptor declares fields stored in `params`: `hosts`, `srv`, `replica_set`, `database`, `username`, `auth_source`, `auth_mechanism` (`default`, `SCRAM-SHA-256`, `SCRAM-SHA-1`, `MONGODB-X509`), `tls`, `tls_ca_file`, `tls_cert_key_file`, `tls_insecure`, `direct_connection`, `read_preference`. Passwords and credentials embedded in URIs are split off by `ParseConnectionString` and live only in the keychain. Logs never contain the URI. Variants (`mongodb`, `cosmosdb-mongo`, `documentdb`) set defaults in their descriptors (ADR 0003 pattern).

### 11. UI (PR 3)
- **Capability gating, no engine ids in Dart.** The tree treats a session with `document_store` as "databases hold collections directly" (`ListObjects(db, "")`) and opens collections in document tabs. SQL entry points (new query tab, ⌘T, the `+` button) are hidden when the engine has `document_store` and not `execute`. The connection form is built from the descriptor, including select, boolean and file fields; "paste URI" goes through `ParseConnectionString`.
- **One page, three views.** A collection tab holds one page of documents (20/50/100/500; one extra document is requested to know whether a next page exists) and shows it as Table (the virtualized `FixedGridView` of ADR 0004), Tree (flattened to the expanded rows and built lazily) or JSON (one lazily built entry per document). Table columns come from `SampleFields`, `_id` first; nested values show as compact shell-style text and open in a value dialog.
- **Display vs. wire.** Views show shell-style text (`NumberLong("5")`, `ISODate(…)`, `UUID(…)`) derived from the canonical tree, with a type badge in the tree. Edits always start from the canonical text received from the core.
- **Editing.** The editor shows pretty-printed canonical EJSON, a "Changes" tab with a line diff of canonical text (so Int32 → Int64 is visible), and saves with `expected_document` set to the text as loaded. A conflict offers reload or overwrite (overwrite is not offered if the document was deleted). Deletes always confirm; production connections say so in the dialog and button.
- **Cancel.** Find and Count run as cancellable gRPC calls; a Cancel button replaces Run after 300 ms. The core records document operations in the query history as shell-style text.

## Consequences
- Dart needs no BSON library; the editor and diff work on text, and exact types survive because the canonical form is the single stored representation.
- EJSON is bulkier on the wire than BSON; mitigated by batch caps, and revisitable by adding a `bytes` field alongside later (additive).
- `skip` paging degrades on very deep pages; acceptable for browsing, to be revisited with keyset paging.
- `protocol_version` is 4 from PR 2, when `DocumentService` is first served; the gRPC message limit is 48 MiB on the core.
