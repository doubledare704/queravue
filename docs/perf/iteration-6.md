# Iteration 6 perf results (Mongo shell)

Core side, in-process tests against the dev Mongo 8 replica set seeded with `mongo-seed` (Apple M4 Pro, 2026-11-07). Run with:

```bash
cd core && go test -tags=integration -v -run 'TestIdleMemoryWithShellsOpen|TestForEachMillionDocumentsKeepsMemoryFlat' ./internal/shell/
```

| | Result | Budget |
|---|---|---|
| Heap added by one open shell (runtime + prelude, after one `Eval`) | +1.3 MiB | < 15 MiB |
| Heap added by ten open shells | +7.4 MiB (about 0.7 MiB each) | < 150 MiB |
| Process RSS: no shell, one shell, ten shells | 20.7, 25.8, 33.8 MiB | — |
| Ten shells left idle for 2 s | no change | — |
| `db.events.find().forEach(...)` over 1M documents | 10.5 s | — |
| Heap peak above its start during that run | +63 MiB (heap 5.6 → 68.7 MiB) | < 100 MiB (PRD allows +200 MB) |
| Heap after the run, once collected | 6.2 MiB (+0.6 MiB) | no retention (< 10 MiB) |
| RSS before and after the run | 34.5 → 100.1 MiB | — |

## Reading the numbers
- An open shell is cheap: the idle core stays far below the 150 MB budget with ten shells open.
- `forEach` retains nothing, but it is not flat: the heap peaks about 63 MiB above its start while documents are decoded in batches of 500, then falls back to where it began. That is garbage between collections, not growth with the collection size. It fits the 1M-row budget (+200 MB) with room to spare.
- Where the peak comes from has not been profiled. If it matters, candidates are the per-batch EJSON text, the goja objects built for each batch, and the driver's own batch buffers; a smaller default batch size or a memory limit for the shell runtime would lower it.

## Not measured
- UI idle memory with a shell tab open. The Flutter runtime alone idles above the 150 MB target (182 MB in the profile build, see `iteration-2.md`), so the combined idle budget is not met independently of the shell; the shell tab adds one editor widget and a short output list.
- The 1M-document run through the UI: the output pane shows cursors one page at a time (20 to 500 documents), so the UI cost is the page, as in the collection tab.
