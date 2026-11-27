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

Apple M4 Pro, macOS, Go 1.27.4, MongoDB 8.0.34. The same direct-engine test, with SHA-256 and two forced GCs at each 128 MiB checkpoint, measured:

| Implementation | Upload MiB/s | Download MiB/s | Upload RSS peak | RSS 20 s after disconnect | Upload / download peak live heap |
|---|---:|---:|---:|---:|---:|
| Before | 504.5 | 1084.0 | 192.8 MiB | 193.8 MiB | 17.5 / 17.1 MiB |
| Delayed release, run 1 | 528.3 | 1036.9 | 220.8 MiB | 110.7 MiB | 17.5 / 17.1 MiB |
| Delayed release, run 2 | 507.1 | 925.7 | 226.1 MiB | 19.5 MiB | 17.5 / 17.1 MiB |
| Delayed release, strict run 3 | 503.8 | 1073.8 | 198.7 MiB | 199.2 MiB | 17.5 / 17.1 MiB |
| Delayed release + `GOMEMLIMIT=64MiB` | 457.2 | 1109.5 | 108.9 MiB | 109.3 MiB | 17.5 / 17.1 MiB |

Baseline RSS was 17.7–17.8 MiB. macOS RSS remained highly variable: two runs still exceeded the 60 MiB target after release. These runs excluded the application-side 1 GiB gRPC round trip and other platforms; the later rebased release-mode run is recorded below. The test measures the Mongo connection directly, not the sidecar process or gRPC buffers, and may fail the 60 MiB margin on macOS even when Go reports that it released the pages.

The runtime reported 173.5 MiB released and 7.7 MiB free immediately after the original download, with 0.7 MiB heap objects; after disconnect it reported 175.9 MiB released, 4.5 MiB free, 1.4 MiB objects, 0.8 MiB heap stacks, 0.2 MiB mspan in use, and 22 goroutines (29 while connected). Go marks unused macOS pages reusable using `MADV_FREE_REUSABLE`; this is not equivalent to an immediate fall in `ps` RSS. The driver closes its pool on connection close. These measurements do not establish whether any small buffers or goroutines remain, but they rule out live Go heap, stacks and mspan accounting for the observed hundreds of MiB.

Sampled allocation profiles show the driver's 16 MiB upload stream, BSON/InsertMany batch construction, the wire-message copy and download cursor reads. The URI builder does not enable compression: the driver's `CompressWireMessage` no-op branch still copies the uncompressed message. Thus the earlier attribution to compression is incorrect for this connection. The 48 MiB gRPC setting is a message limit, not evidence of a preallocated 48 MiB buffer; the direct-engine measurement excludes gRPC entirely. Its isolated contribution to the app measurement remains unmeasured. The gRPC download currently copies each chunk; reusing it safely would require verifying gRPC message lifetime, so it was not changed.

The delayed `debug.FreeOSMemory` prototype was removed after the inconsistent runs above: it imposes a process-wide GC and scavenging without consistently reducing macOS RSS, potentially affecting unrelated work and later transfers. A trial with `GOMEMLIMIT=64MiB` reduced upload raw heap peak from 129.6 to 67.3 MiB and upload throughput by about 9% against the original run, but RSS still failed the 60 MiB margin at 109.3 MiB after disconnect. No global memory limit is imposed. Changing the driver's hard-coded buffer would require a driver change or a replacement GridFS implementation with interoperability and cancellation testing.

### Rebased investigation (2026-11-27)

Full and ranged downloads now use the existing validated chunks cursor, with a target of 4 MiB of chunk payloads per batch (one chunk minimum). This is a target, not a hard memory limit: MongoDB document overhead and explicitly larger GridFS chunks add to it. In a direct-engine round-trip with the stock driver and the earlier delayed release still enabled, download peak live heap fell from 17.1 to 5.2 MiB; download throughput was 978.7 MiB/s versus 1084.0 MiB/s before. Upload RSS dominated: 193.8 MiB peak and 194.3 MiB 20 seconds after disconnect. The final implementation removes delayed release: the strict run measured 17.6 MiB baseline, 194.7 MiB upload peak, and 195.2 MiB RSS 20 seconds after disconnect, with 547.5 MiB/s upload and 918.4 MiB/s download. The 60 MiB RSS delta assertion failed.

A temporary local copy of mongo-driver v2.9.3 was used only to explore a smaller upload buffer. It dynamically sized the buffer to the greater of the batch target or the requested GridFS chunk size and used the buffer length for flush bookkeeping. No fork or memory limit is included in the branch. These are individual direct-engine runs, not a validated default or sidecar benchmark:

| Upload batch | Download batch target | `GOMEMLIMIT` | Upload / download MiB/s | RSS 20 s after close | Outcome |
|---|---:|---:|---:|---:|---|
| 2 MiB | Driver default | unset | 247.8 / 1111.6 | 100.4 MiB | Failed RSS margin; upload ~51% below baseline |
| 8 MiB | 2 MiB | unset | 488.2 / 759.1 | 123.0 MiB | Failed RSS margin; download ~30% below baseline |
| 4 MiB | 2 MiB | unset | 364.0 / 857.6 | 78.9 MiB | Failed RSS margin; upload ~28% below baseline |
| 8 MiB | 4 MiB | 48 MiB | 441.8 / 968.5 | 86.8 MiB | Failed RSS margin |
| 8 MiB | 4 MiB | 40 MiB | 407.0 / 929.4 | 66.6 MiB | Passed 60 MiB *delta*, but exceeded 60 MiB absolute RSS |
| 8 MiB | 4 MiB | 32 MiB | 381.8 / 1127.1 | 66.1 MiB | Passed delta; upload ~24% below baseline |
| Stock 16 MiB | 4 MiB | 40 MiB | 426.5 / 913.3 | 106.8 MiB | Failed RSS margin |

The merged release-mode harness was also run against the rebased branch (`QUERAVUE_PERF_OUT=/tmp/queravue-core-memory-release.md make perf-idle-release`). It completed its GridFS and SQL-mode scenarios. Before transfers, app RSS was 154.6 MiB and core RSS 33.6 MiB; with the GridFS bucket open, core RSS was 37.7 MiB. After the 1 GiB upload and download, core RSS was 258.0 MiB; 20 seconds after closing GridFS and disconnecting, it was 258.1 MiB, with 227.2 MiB app RSS (485.3 MiB combined). The sidecar was already at 152.5 MiB during the 32 MiB image-preview scenario. The app-side transfers took approximately 9 seconds each. This confirms the direct-engine failure also occurs in the real sidecar, while the app alone remains above budget after the session.

The 40 MiB prototype result needs repeatability, concurrency and application-level validation before a process-wide limit or a maintained driver fork can be justified. A soft limit is not a hard cap and can cause significant garbage-collection overhead when other workloads have larger live heaps. The upload driver still uses its 16 MiB buffer in the actual branch, so the post-transfer RSS target remains unresolved.

```bash
docker compose -f dev/docker-compose.yml up -d --wait mongo
cd core
GRIDFS_MEMORY_PERF=1 GRIDFS_PROFILE_DIR=/tmp go test -count=1 -tags=integration -v -run '^TestIntegrationGridFS1GiBRoundTripMemory$' ./internal/engine/mongo/
```

The optional profile directory receives human-readable `heap.txt` and `allocs.txt` pprof snapshots. The RSS assertion is intentionally strict; inconsistent macOS resident-page accounting remains a blocker to claiming the memory target.

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
