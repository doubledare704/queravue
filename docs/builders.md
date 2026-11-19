# Visual query builders

ADR 0021 defines the builders. This file documents what ships.

## Aggregation pipeline builder

Opens from the schema tree (right-click a collection, "Build aggregation pipeline") and from the command palette ("Open aggregation pipeline builder", ⌘⇧A, collection tab active). Available when the connection has the `document_store` capability.

Code: `app/lib/features/documents/pipeline_builder/` (`domain`, `application`, `presentation`). No proto change and no new RPC.

- **Model:** ordered stages, each with an operator, an EJSON body and an enabled flag.
- **Cards:** typed forms for `$match`, `$group`, `$project`, `$sort`, `$limit`, `$skip`, `$unwind`, `$lookup`, `$addFields`, `$count`. Every other operator, and a typed stage whose body the form cannot express (for example `$match` with `$or`, `$lookup` with a sub-pipeline), is edited as EJSON text.
- **Import:** accepts an array of stages or `db.<collection>.aggregate([...])` in relaxed shell syntax (unquoted keys, single quotes, comments, `ObjectId`, `ISODate`, `NumberLong`, regex literals, `UUID`, ...). A stage that does not parse, or is not a one-key `$operator` document, becomes a raw text card and the import still succeeds. Options after the array are ignored and reported.
- **Export:** shell code or JSON. Only enabled stages are exported. Comments are not preserved.
- **Preview:** runs the enabled stages up to the selected card, plus `$limit` (default 20), as `db.<collection>.aggregate([...])` on a shell (ADR 0010), then fetches a capped page with `FetchCursor`. The preview uses the shared document pane and offers Cancel after 300 ms. A preview never runs a pipeline that contains `$out` or `$merge`, and it refuses to run through a raw text card.
- **Suggestions:** field names come from `SampleFields`, the `$lookup` collection from the schema listing.
- **Tests:** the round-trip corpus is `app/test/features/documents/pipeline_builder/fixtures/pipeline_corpus.dart`. Add a pipeline there when a new shape needs to survive import and export.

## Mongo filter builder

Open **Visual filter builder** in a MongoDB collection tab. **Run** in the preview pane runs the current filter, projection and sort, honoring Skip and any smaller collection Limit. The preview requests at most 20 documents via `DocumentService.Find` with `max_time_ms` set to 5000. After 300 ms, **Cancel** replaces **Run** and cancels the Find stream.

Both builders use the shared preview controller and show results in the read-only Table, Tree and JSON views.
