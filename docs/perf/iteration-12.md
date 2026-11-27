# Iteration 12 perf results

## Lane G: Core GridFS

Apple M4 Pro laptop (arm64, macOS), 2026-11-19, `mongo:8.0.34` single-node replica set (`rs0`) from `dev/docker-compose.yml`, core and container on the same machine, `go.mongodb.org/mongo-driver/v2` v2.9.3.

```bash
docker compose -f dev/docker-compose.yml up -d --wait mongo
cd core && GRIDFS_MEMORY_PERF=1 go test -count=1 -tags=integration -v -run '^TestIntegrationGridFS1GiBRoundTripMemory$' ./internal/engine/mongo/
```

### 1 GiB round-trip (`TestIntegrationGridFS1GiBRoundTripMemory`)

Deterministic 1 GiB (`1,073,741,824` bytes) stream hashed on the fly with SHA-256 on both upload and download; `HeapAlloc` and process RSS (`ps -o rss=`) are sampled every 128 MiB (`128..1024 MiB`), running two `runtime.GC()` cycles per checkpoint so live heap reflects retained objects rather than `sync.Pool` victim buffers.

| Direction | Time | Throughput | Base heap | Live heap checkpoints (every 128 MiB) | Live heap peak | Raw heap peak (pre-GC) | Post-run heap | RSS (base → peak → post) |
|---|---|---:|---:|---|---:|---:|---:|---|
| Upload (1 GiB) | 1.699 s | 602.8 MiB/s | 0.7 MiB | `[17.4, 17.5, 17.5, 17.5, 17.5, 17.5, 17.5, 17.5]` MiB | 17.5 MiB | 129.6 MiB | 0.6 MiB | 17.9 → 193.6 → 194.0 MiB |
| Download (1 GiB) | 877 ms | 1167.9 MiB/s | 0.6 MiB | `[17.1, 17.1, 17.1, 17.1, 17.1, 17.1, 17.1, 5.2]` MiB | 17.1 MiB | 49.0 MiB | 0.7 MiB | 194.0 → 194.3 → 194.3 MiB |

A second run inside the full `./internal/engine/mongo/` GridFS integration run measured `1.786 s` (`573.3 MiB/s`) upload and `898 ms` (`1140.0 MiB/s`) download with the same flat checkpoints (`17.5 MiB` upload, `17.2 MiB` download, `0.7 MiB` post-run).

### Reading the numbers
- **Flat live heap:** Every 128 MiB checkpoint across the 1 GiB stream stays at `17.5 MiB` on upload (`uploadBufferSize = 16 MiB` inside `mongo.GridFSUploadStream`) and `17.1 MiB` on download (one driver cursor batch buffer), returning to `0.6–0.7 MiB` after completion.
- **Transient batch churn:** Pre-GC `rawPeak` during upload (`129.6–151.2 MiB`) reflects temporary per-16 MiB `InsertMany` BSON encoding and wire-message copy buffers before GC collects them; this stays within the PRD's `+200 MB` large-result budget and does not grow with file size.

## Core memory after transfers

Apple M4 Pro, macOS 27.2.1, Go 1.27.4, MongoDB 8.0.34. The direct-engine test transfers 1 GiB in each direction, hashes the bytes and forces two GCs at each 128 MiB checkpoint to measure live heap. RSS is sampled with `ps` approximately every 25 ms during the transfer, so short peaks between samples may be missed. It checks that the sampled peak is at most 60 MiB above the pre-transfer baseline; it logs but does not gate RSS after disconnect. The test runs without a memory limit or explicit OS memory release.

| Implementation | Upload MiB/s | Download MiB/s | RSS peak | RSS 20 s after disconnect | Upload / download peak live heap |
|---|---:|---:|---:|---:|---:|
| Stock upload, bounded download (before) | 547.5 | 918.4 | 194.7 MiB (upload checkpoints) | 195.2 MiB | 17.5 / 5.2 MiB |
| Bounded writer, run 1 | 206.9 | 949.3 | 49.5 MiB | 49.5 MiB | 3.3 / 5.3 MiB |
| Bounded writer, run 2 | 202.2 | 848.0 | 54.7 MiB | 54.7 MiB | 3.4 / 5.3 MiB |
| Bounded writer, run 3 | 208.5 | 793.8 | 49.7 MiB | 49.7 MiB | 3.3 / 5.3 MiB |

The bounded runs started at 17.5–18.1 MiB RSS. The before peak was measured at 128 MiB checkpoints, rather than by the new periodic sampler; it is a lower bound on the actual peak. The writer reuses a buffer sized for a target of 2 MiB of chunk payload per batch, writes the file document last, and preserves larger configured chunk sizes by using at least one chunk per batch. Full and ranged downloads use a validated cursor targeting 4 MiB per batch. Document encoding and MongoDB's wire buffers add overhead to these payload sizes.

On this macOS version Go can mark pages reusable with `madvise` without an immediate fall in `ps` RSS or footprint. In the earlier stock-driver run, the runtime reported 175.9 MiB released and 1.4 MiB live heap after disconnect while RSS remained about 195 MiB. RSS after a transfer therefore does not measure live Go heap alone. Allocation profiles showed the driver's fixed 16 MiB upload buffer, batch encoding and wire-message copies; compression is not enabled on this connection. The driver pool closes with the connection, and the 48 MiB gRPC message limit does not by itself allocate a 48 MiB buffer. No driver fork, `GOMEMLIMIT`, `debug.SetMemoryLimit`, or `debug.FreeOSMemory` is used.

Reproduction:

```bash
docker compose -f dev/docker-compose.yml up -d --wait mongo
cd core
GRIDFS_MEMORY_PERF=1 go test -count=1 -tags=integration -v -run '^TestIntegrationGridFS1GiBRoundTripMemory$' ./internal/engine/mongo/
```

Set `GRIDFS_PROFILE_DIR` to a writable directory to save heap and allocation profiles. For the release application and real sidecar:

```bash
QUERAVUE_PERF_OUT=/tmp/queravue-core-memory-release.md make perf-idle-release
```

The release-app run measured sidecar RSS at 33.3 MiB after launch, 37.6 MiB with the GridFS bucket open, 77.0 MiB after the 32 MiB preview scenarios, and a sampled peak of 87.5 MiB during both 1 GiB upload and download (100 ms sampling). It was 87.7 MiB 20 seconds after closing GridFS and disconnecting, compared with 258.1 MiB in the earlier release run. Upload took 10 s and download 9 s. The app and sidecar together were 188.9 MiB at idle before any transfer, above the PRD's 150 MB combined idle budget; after disconnect they were 316.9 MiB. These values include the preview scenarios and are not directly comparable to the isolated engine test.

## Lane G: app (profile build)

Apple M4 Pro (arm64, macOS 27.2.1), 2026-11-20. The Flutter macOS profile build used the real sidecar and the Docker Mongo replica set. The test sampled app RSS with `ps` approximately every 50 ms and included the first sample after each operation in its peak. The 1 GiB fixture was a sparse file filled with zeros. The image was a 32 MiB BMP at 4096 × 2700 pixels, decoded to 2048 × 1350 for preview.

| Operation | App RSS before | App RSS peak | App RSS after | Time |
|---|---:|---:|---:|---:|
| Upload 1 GiB | 196.2 MiB | 223.1 MiB | 173.3 MiB | 10.0 s |
| Download 1 GiB | 173.3 MiB | 184.9 MiB | 172.5 MiB | 5.7 s |
| Preview 32 MiB BMP | 177.4 MiB | 288.5 MiB | 288.5 MiB with preview open | 0.4 s |

App RSS fell to 223.9 MiB 10 seconds after clearing the preview. Flutter's image cache returned to its pre-preview size.

| Idle checkpoint | App RSS | Core RSS | Combined RSS |
|---|---:|---:|---:|
| Bucket open before the round trip | 193.2 MiB | 37.2 MiB | 230.4 MiB |
| 20 seconds after closing the GridFS tab and disconnecting | 222.6 MiB | 258.3 MiB | 480.8 MiB |

The measured session exceeded the 150 MB combined idle RSS budget. The profile build was already above budget before the transfers, and the sidecar alone was above budget at the post-session checkpoint.

From the repository root, build the sidecar and run the profile test against Docker Mongo.

```bash
docker compose -f dev/docker-compose.yml up -d --wait mongo
make core
cd app
QUERAVUE_E2E=1 QUERAVUE_CONFIG_DIR="$(mktemp -d)" \
  QUERAVUE_CORE_BIN="$PWD/../core/bin/queravued" \
  flutter drive --profile -d macos --dart-define=GRIDFS_PERF=true \
  --driver=test_driver/perf_driver.dart --target=integration_test/gridfs_test.dart
```

Run the short end-to-end test with the same environment using `flutter test integration_test/gridfs_test.dart -d macos`.

## Lane G: app (release build)

Apple M4 Pro (arm64, macOS 27.2.1), 2026-11-26, Flutter 3.47.9. A release build of `app/perf/release_memory_main.dart` (the real app and `QueravueApp`, plus a scripted scenario that drives the same providers the UI uses) with the real sidecar, the Docker Mongo replica set seeded by `mongo-seed`, a temporary empty config dir, and `QUERAVUE_E2E=1` so the window is drawn. Integration tests cannot run in release mode, so the scenario is the release-mode driver.

```bash
make perf-idle-release
```

The script (`dev/perf-release-app.sh`) builds the sidecar and the release app, runs the scenario, and prints a Markdown table; it also writes `app/build/perf/release-memory.md.categories.txt` with the `footprint` category breakdown of every checkpoint. Each checkpoint waits as stated (30 s after launch, 10 s after closing or clearing, 20 s after disconnecting) and samples `ps -o rss=` and `footprint -p` for the app and `ps` for the sidecar.

### Which number to read
`footprint` (physical footprint, what Activity Monitor shows) is the stable measure. RSS on macOS swings by tens of MiB between identical runs because the OS compresses idle pages (the `origin/main` run below reads 132.6 MiB RSS with a 184.1 MiB footprint). The footprint tool also returned a transient wrong value twice (marked †; RSS in the same row was normal).

### Before and after
Before is `origin/main` (496b154) run through the same scenario; after is this change. App values in MiB.

| Checkpoint | Footprint before | Footprint after | RSS before | RSS after | Core RSS after |
|---|---:|---:|---:|---:|---:|
| Idle 30 s after launch | 177.8 | 341.7 † | 182.6 | 185.1 | 33.2 |
| Mongo connection open | 184.4 | 177.1 | 186.9 | 188.9 | 36.1 |
| GridFS bucket open | 187.5 | 195.9 | 190.6 | 193.0 | 37.9 |
| GridFS tab closed | 184.1 | 189.9 | 132.6 | 194.1 | 38.0 |
| 32 MiB image preview open | 271.4 | 273.0 | 208.8 | 263.1 | 195.1 |
| Preview cleared, 10 s | 261.8 | 262.8 | 214.3 | 267.7 | 195.1 |
| Same, after a forced Dart GC | 231.1 | 231.3 | 183.6 | 236.3 | 195.1 |
| Second 32 MiB preview open | | 273.0 | | 263.2 | 195.1 |
| Second preview cleared, 10 s | | 262.3 | | 267.3 | 195.1 |
| After 1 GiB upload and download | 239.1 | 237.4 | 172.1 | 201.4 | 217.1 |
| GridFS closed and disconnected, 20 s | 227.1 | 414.5 † | 165.8 | 212.7 | 217.8 |
| SQL mode tab with results open | 249.6 | 250.9 | 180.1 | 213.1 | 221.4 |
| SQL mode tab closed, 10 s | 243.9 | 245.3 | 181.4 | 214.5 | 221.4 |
| SQL mode closed and disconnected | 237.6 | 238.7 | 182.1 | 214.9 | 221.4 |

| Transfer (app RSS) | Before → peak → after | After → peak → after |
|---|---|---|
| Upload 1 GiB | 183.6 → 204.4 → 189.2 | 237.0 → 261.0 → 207.0 |
| Download 1 GiB | 189.4 → 203.4 → 170.2 | 207.2 → 218.5 → 198.4 |

The "GC probe" rows come from the harness allocating and dropping 400 MiB of `Uint8List`s, which makes the Dart VM collect; the app itself never does this.

### What the app retains
The `footprint` categories at idle, with the 32 MiB preview open, after clearing it, and at the end:

| Category (MiB) | Idle | Preview open | Cleared | Cleared, GC probe | End |
|---|---:|---:|---:|---:|---:|
| IOSurface (window drawables) | 53 | 53 | 53 | 53 | 53 |
| Malloc Large | 48 | 80 | 80 | 80 | 80 |
| Malloc Small | 22 | 31 | 32 | 32 | 44 |
| Untagged (Dart heap) | 15 | 47 | 52 | 20 | 26 |

- **Closing tabs does dispose their state.** `GridFsController`, `MongoSqlController`, `shellTabProvider` (invalidated when its tab closes), `documentPreviewProvider` and `cursorPageProvider` are all disposed or invalidated; the SQL mode tab adds about 13 MiB of footprint while open and gives it back on close. The image cache is empty 10 s after the preview clears (`Image cache` column in the raw report).
- **Dart garbage lags the GC.** The 32 MiB preview streams through 1 MiB gRPC chunks, and the Dart heap keeps about 31 MiB of it until a collection; the probe row shows it is garbage, not a reference. Decoding images from a temp file instead of an in-memory `Uint8List` did not change this, because the chunks still pass through Dart.
- **`Malloc Large` keeps the 32 MiB it used for decoding.** macOS keeps freed large malloc blocks counted in the footprint. A standalone probe (allocate and free 96 MiB, call `malloc_zone_pressure_relief`, wait 15 s) stayed at the high-water mark, so it cannot be returned from Dart. It is a reusable cache, not a leak: a second 32 MiB preview adds nothing (263.2 vs 263.1 MiB RSS).
- **`Malloc Small` grows by about 20 MiB** over the session (gRPC, protobuf, widgets) and does not shrink.
- **Idle itself is about 165 to 180 MiB of footprint here** (53 MiB of window surfaces, 48 MiB of large malloc), against 139.4 MiB combined in the iteration 10 empty-profile run. `origin/main` measures the same, so this is not from this change; a smaller default window or surface count is the lever and is not part of this PR.

So after closing the GridFS and SQL mode tabs the app is about 60 MiB above its post-launch idle, not within 10 MiB: roughly 32 MiB is the allocator's large-block cache, 20 MiB small-malloc growth and 10 MiB one-time UI warm-up (first bucket open adds 5 to 10 MiB). The same session reaches a combined RSS above the 150 MB idle budget before any preview, and the sidecar alone holds 195 to 220 MiB after the 1 GiB transfers (the core job covers that).

### Changes in this PR
- Image and PDF previews stream into a private temp file (`GridFsPreviewFiles`) instead of a `Uint8List` held in state; images decode from the file at display size and the file is deleted when the selection changes, PDFs when the tab closes (ADR 0023 §6).
- `PaintingBinding.imageCache` is capped at 32 MiB and 20 images (`limitImageCache`).
- The harness above, so later iterations can rerun it.

## Lane T: SQL → MQL translator

Apple M4 Pro laptop (arm64, macOS), 2026-11-20, pure translation (no I/O) of every `core/internal/mongosql/testdata/corpus` query, `BenchmarkTranslate` with 3000 passes over each group. The percentiles are per `Translate` call, from timing each call separately.

```bash
cd core && go test ./internal/mongosql -run '^$' -bench Translate -benchtime 3000x -count=1
```

| Group | Queries | p50 | p95 |
|---|---:|---:|---:|
| `find` (no pipeline) | 86 | 1.9 µs | 4.5 µs |
| `aggregate` (group, aggregates, join, computed, DISTINCT) | 175 | 4.6 µs | 9.5 µs |
| rejected (parse error or unsupported, offset reported) | 95 | 0.8 µs | 2.5 µs |

Even the p95 of the pipeline group is under 10 µs, so translation is negligible next to the RPC round trip.

## Not measured yet

- App-side SQL mode latency (editor to MQL pane, PR 4); the translator itself is in Lane T.
