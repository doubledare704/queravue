# ADR 0025 — Mock data generator

**Status:** Proposed · 2026-11-27

## Context
Iteration 13's exit criterion is generating 1M realistic rows into Postgres and Mongo in reasonable time: 1M rows with a foreign key into Postgres in ≤ 20 s, and 1M documents into Mongo in ≤ 35 s, with core RSS peak ≤ baseline + 60 MiB. The generator must respect foreign keys and insert through the loaders of ADR 0024 §8. Related: ADR 0003 (capabilities), ADR 0007 (schema model), ADR 0009 (documents), ADR 0017 (schema graph).

## Decision

### 1. Generation lives in core
A new package `core/internal/mockdata` generates rows. It is deterministic for a seed, so a preview equals the first rows of the run.

### 2. Per-column rules
A rule is one of:
- a faker kind (name, email, phone, address parts, company, lorem, URL, UUID, IP, ...)
- a sequence
- an int, float or decimal range
- a date or timestamp range
- a weighted list of values
- a constant
- a pattern (`#` digit, `?` letter)
- a foreign-key reference
- skip, to leave the column to the server default or identity

Each rule can also set a null ratio and require unique values. Faker kinds travel as strings, and core lists the supported ones, so new kinds need no contract change.

Default rules come from name and type heuristics (`email` → email, `*_at` → a timestamp in the last two years, identity columns → skip), so a table generates with one click. For Mongo, rules attach to field paths from `SampleFieldPaths`, including nested documents and arrays with a length range.

### 3. Faker library
`github.com/brianvoe/gofakeit/v7` (MIT, no transitive dependencies), seeded per run, `en` locale only in v1. A kind that cannot be made deterministic is written in-house.

### 4. Foreign keys
- Tables are ordered topologically from the FK graph (`engine.RelationLister`, capability `schema_graph`).
- A child's FK values are drawn from the parent's keys:
  - keys generated in this run, kept as a compact set (1M int64 keys ≈ 8 MiB);
  - or a capped sample of existing parent keys, read with a streaming `SELECT`.
- A cycle is reported before anything runs, with its edges. The user breaks it by setting a nullable FK to null or leaving a table out.
- Unique columns use sequences or retry a bounded number of times, then fail with the column name. Composite unique constraints are best effort.
- Without `schema_graph`, tables run in the order the user picks, and FK columns get no default rule.

### 5. Run
The generator is the source of a `RowLoader` or `DocumentLoader` (ADR 0024 §8). Each table streams progress (rows, rows per second) and the run can be cancelled. Finished tables stay committed and are reported. A production connection needs `confirmed=true`.

### 6. Contract and gating
`MockDataService` in `mockdata.proto`:
- `SuggestMockSpec` returns default rules, the table order, cycles and the faker kinds.
- `PreviewMock` returns sample rows or documents without writing.
- `RunMock` streams progress per table and a summary.

Failures are in-band `MockError`: PARSE, CYCLE, UNIQUE_EXHAUSTED, CONSTRAINT, CONFIRMATION_REQUIRED, AUTH, NETWORK, TIMEOUT, CANCELED, UNSUPPORTED, SERVER. The UI offers the generator when the connection has `bulk_load` and `schema_inspector`, or `document_load`.

## Consequences
- New `MockDataService`; protocol version 13 (shared with ADR 0024).
- One new dependency (`gofakeit`), justified in the PR that adds it.
- Throughput depends on each engine's loader; only Postgres and Mongo are gated.
