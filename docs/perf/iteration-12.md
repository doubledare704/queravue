# Iteration 12 perf results

## Lane G: Core GridFS

Apple M4 Pro laptop (arm64, macOS), 2026-11-19, `mongo:8.0.34` single-node replica set (`rs0`) from `dev/docker-compose.yml`, core and container on the same machine, `go.mongodb.org/mongo-driver/v2` v2.9.3.

```bash
docker compose -f dev/docker-compose.yml up -d --wait mongo
cd core && go test -count=1 -tags=integration -v -run '^TestIntegrationGridFS1GiBRoundTripMemory$' ./internal/engine/mongo/
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
- **Transient batch churn:** Pre-GC `rawPeak` during upload (`129.6–151.2 MiB`) reflects temporary per-16 MiB `InsertMany` BSON encoding and wire compression buffers before GC collects them; this stays within the PRD's `+200 MB` large-result budget and does not grow with file size.

## Lane G: app

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
