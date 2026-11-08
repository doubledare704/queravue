# Editor

Design decisions are in [ADR 0015](adr/0015-completion-and-formatting.md); this page describes behaviour as it ships.

## Completion & formatting

Status: contract only (Iteration 8, PR 1). Core logic lands in PRs 2 and 3, UI in PR 4.

- Completion runs in core. `CompletionService.Complete` takes the current statement and a UTF-16 cursor offset, and returns items in ranked order.
- Context kinds: `sql`, `shell`, `mongo_query`.
- Ranking tiers: in-scope aliases and tables, columns of in-scope tables, other schema objects, keywords and functions.
- `WarmCatalog` streams bulk column loading progress; `Complete` never waits for it and reports `catalog_state`.
- `FormatSQL` formats a selection or statement; options are keyword case, indent width, comma style and max line width.
- The UI enables both features from the `completion` and `format` capabilities.
