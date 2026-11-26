# Iteration 12 — batch 3 (finish the iteration)

**Date:** 2026-11-26 · Base: `main` at `819637c` (PRs #71–#74 merged)

## State of `main`
Every planned feature PR is merged: contract (#66), capped preview (#67), FIND translation (#68), GridFS core (#69), aggregate translation (#71), GridFS viewer (#72), SQL mode tab (#73), PDF spike (#74, decision: system viewer).

Checked on `origin/main`: `go build`, `go vet`, `go test ./...`, `golangci-lint` clean; `flutter analyze` clean, `flutter test` 732 passed.

Exit criteria:
- Translator corpus: 356 cases, 261 supported (target 100+). Differential test: 139 comparable cases. Semantics test covers every ADR 0022 §6 difference. ✅
- GridFS 1 GiB round-trip with flat live heap and cancel: core ✅ (`docs/perf/iteration-12.md`, Lane G). ❌ **Memory budget:** PR #72 measured 480.8 MiB combined idle RSS after a GridFS session and disconnect (app 222.6 MiB, core 258.3 MiB). The budget is 150 MB. Core live heap stays at about 17 MiB while RSS rises to about 194 MiB during a transfer and does not come back down. Core never calls `debug.FreeOSMemory` or sets a memory limit. The app measurement used a profile build that already idled at about 193 MiB, so it is not comparable with the 139.4 MiB release baseline (`docs/perf/iteration-10.md`, Lane G verification).
- Filter builder preview gap closed. ✅

## Jobs
| Job | Area | Can start now |
|---|---|---|
| F1 — Core memory after large transfers | `core/` (GridFS engine + service, process memory settings) | yes |
| F2 — App memory on a release build | `app/` (measurement, image cache, retention after closing tabs) | yes |
| G — Review of the GridFS upload transport | `app/lib/core_client/gridfs_upload.dart` and its callers | yes |
| E — Close-out | `ROADMAP.md`, ADRs, plan, perf | after F1, F2, G merge |

F1, F2 and G touch separate files. F2 and G both touch `app/`, but G stays inside `app/lib/core_client/` and the GridFS repository, while F2 touches the image preview and measurement code; if both need `app/lib/features/gridfs/`, keep edits small and rebase the second.

---

## Prompt F1 — Core memory after large GridFS transfers

```text
Repository: Queravue (Flutter desktop UI in app/, Go core sidecar in core/, gRPC contract in proto/). Read AGENTS.md and CLAUDE.md first and follow them: names over comments, ctx first, wrapped errors, slog without secrets or row data, integration tests behind //go:build integration, no new dependencies without a reason. Do NOT change proto/. Ask (in the PR description) before changing the security model.

Problem: the PRD idle budget is ≤ 150 MB combined (UI + core). After a GridFS session the core sidecar idles at 258.3 MiB RSS even after disconnect (docs/perf/iteration-12.md, "Lane G: app"). The core engine test shows live heap flat at ~17 MiB during a 1 GiB round-trip, but process RSS rises from 17.9 to ~194 MiB and stays there (docs/perf/iteration-12.md, "Lane G: Core GridFS": upload raw pre-GC heap peaks at 129–151 MiB from per-16 MiB InsertMany encoding and wire compression buffers). Nothing in core calls debug.FreeOSMemory or sets a soft memory limit.

Read: docs/adr/0023-gridfs.md, core/internal/engine/mongo/gridfs.go (OpenUploadStream at ~line 614, ranged download path), core/internal/api/gridfs_service.go (Upload at ~line 298, Download), core/cmd/queravued (process start-up), and the existing memory tests: core/internal/engine/mongo (TestIntegrationGridFS1GiBRoundTripMemory), core/internal/netcells (TestIdleMemoryWithTunnelOpen), core/internal/engine/redis/perf_integration_test.go.

Task, on a new branch `iteration-12-core-memory` from the latest origin/main:
1. Find out where the retained RSS comes from. Use runtime/metrics (heap released vs. idle vs. in-use, stacks, mspan), pprof heap/alloc profiles and RSS. Confirm or rule out each candidate: Go not returning freed pages to the OS, the driver upload buffer (16 MiB) and InsertMany batch encoding, wire compression buffers, gRPC receive buffers sized to the 48 MiB max message limit (core/internal/server/server.go), per-session driver connection pools, goroutines or buffers left after disconnect.
2. Fix the causes in order of impact. Options to evaluate, keeping the 1 GiB throughput within ~20% of today's numbers:
   - Smaller upload batching (driver upload buffer / chunk batch size) so a transfer never allocates more than a few MiB at once.
   - Reusing buffers for download chunks (≤ 1 MiB) instead of allocating per message.
   - A soft memory limit (debug.SetMemoryLimit, configurable by env, default chosen from measurements) and/or returning memory to the OS after a large transfer finishes or a session closes (debug.FreeOSMemory, rate-limited, off the request path). Explain the trade-off in the PR.
   - Releasing driver resources when the last session for a connection closes.
3. Add or extend an integration test that runs the 1 GiB upload + download, closes the session, waits, and asserts process RSS returns to within a set margin (e.g. ≤ 60 MiB) of the pre-transfer baseline, plus the existing flat-live-heap assertion. Keep it opt-in with an env flag like the other perf tests if it is slow.
4. Record before/after numbers (RSS during and after, live heap, throughput) in docs/perf/iteration-12.md under a new "Core memory after transfers" heading, with the reproduction command. If you add a setting (e.g. a memory-limit env var), document it in docs/SETUP.md.

Done when: `cd core && go build ./... && go vet ./... && go test ./... && golangci-lint run` are green, the integration memory test is green against `docker compose -f dev/docker-compose.yml up -d --wait mongo`, the core idles at or below ~60 MiB RSS 20 s after a 1 GiB round-trip and disconnect (or the PR explains exactly what remains and why), and a PR titled "Iteration 12: release core memory after GridFS transfers" is open against main.
```

## Prompt F2 — App memory on a release build

```text
Repository: Queravue (Flutter desktop UI in app/, Go core sidecar in core/, gRPC contract in proto/). Read AGENTS.md and CLAUDE.md first and follow them: Riverpod plain Notifiers (ADR 0002), no business logic in widgets, virtualized lists only, names over comments, flutter analyze/test green. Do NOT change proto/ or core/ (a parallel job fixes core memory).

Problem: the PRD idle budget is ≤ 150 MB combined (UI + core); a loaded 1M-row result may add ≤ 200 MB. PR #72 measured the app at 193.2 MiB with only a GridFS bucket open, 288.5 MiB with a 32 MiB BMP preview open, and 222.6 MiB 20 s after closing the GridFS tab and disconnecting (docs/perf/iteration-12.md, "Lane G: app"). Those were profile-build numbers. The last release-build baseline was 139.4 MiB combined, 30 s after launch with an empty config dir (docs/perf/iteration-10.md, "Lane G verification"), so the regression may be partly the build mode.

Read: docs/perf/iteration-10.md and iteration-12.md (methods), app/integration_test/gridfs_test.dart and app/test_driver/perf_driver.dart (the GRIDFS_PERF profile run), the GridFS feature in app/lib/features/gridfs/ (preview panel, image decoding, PDF temp files), app/lib/features/documents/ (SQL mode results and document views), the Makefile app targets, and docs/testing.md.

Task, on a new branch `iteration-12-app-memory` from the latest origin/main:
1. Measure on a macOS release build with the real sidecar (same method as iteration 10: temporary empty config dir, RSS of the app and the sidecar separately, 30 s after launch). Checkpoints: idle after launch; idle with a Mongo connection open; after opening and closing a GridFS bucket tab; with a 32 MiB image preview open and 10 s after clearing it; after a 1 GiB upload and download; after closing everything and disconnecting; after opening and closing a SQL mode tab with results. Put a reproducible script or `make` target in the repo (e.g. `make perf-idle-release`) so E and later iterations can rerun it.
2. Find what the app retains: use DevTools memory snapshots or the VM service (Dart heap vs. external vs. raster cache vs. image cache), and check that closing a GridFS or SQL mode tab disposes its providers (autoDispose), stream subscriptions and preview byte buffers.
3. Fix what you find. Likely areas: decode images at display size (cacheWidth/cacheHeight, already partly done) and evict them from PaintingBinding.imageCache when the preview changes or the tab closes; set an image cache byte limit appropriate for a desktop DB tool; drop preview Uint8List references on selection change; make sure upload/download progress state does not keep chunks; delete tracked PDF temp files on tab close (ADR 0023 §6 note).
4. Update docs/perf/iteration-12.md with a "Lane G: app (release build)" table of before/after numbers and the command. Keep the old profile-build table but label it as profile.

Done when: `cd app && flutter analyze && flutter test` are green, the release-build numbers are recorded, the app returns to within ~10 MiB of its post-launch idle after closing GridFS and SQL mode tabs (or the PR explains what remains and why), and a PR titled "Iteration 12: app memory on release builds" is open against main.
```

## Prompt G — Review of the GridFS upload transport

```text
Repository: Queravue (Flutter desktop UI in app/, Go core sidecar in core/). Read AGENTS.md (Security section: the core listens on a Unix socket on macOS/Linux, loopback TCP + random token on Windows; requests without the token are rejected) and CLAUDE.md. Do NOT change proto/ or core/ unless a core-side bug is the only fix, and then say so in the PR.

Context: PR #72 added app/lib/core_client/gridfs_upload.dart. It does not use the generated grpc-dart client for GridFsService.Upload because that client queues outgoing messages ahead of HTTP/2 flow control. Instead it opens its own socket to the sidecar, speaks HTTP/2 via package:http2 (declared as a direct dependency, BSD), frames gRPC by hand (GrpcHttpEncoder/Decoder), and sends `authorization: Bearer <token>`. Read that file, its callers (grep for uploadGridFs in app/lib), app/lib/core_client/core_connection.dart (how the normal channel is created for Unix socket vs. Windows loopback), core/internal/server/server.go (auth interceptors, message size limits) and core/internal/api/gridfs_service.go (Upload).

Task, on a new branch `iteration-12-upload-transport-review` from the latest origin/main: review this transport and fix what is wrong.
Check at least:
1. Addressing: it connects to the same endpoint as the main channel on every platform (Unix socket path on macOS/Linux, loopback + token on Windows), never a non-loopback address, and fails clearly if the address type is unexpected.
2. Auth: the token is always sent, never logged or included in error messages, and an auth failure surfaces as a typed error.
3. Protocol correctness: gRPC status and message come from trailers (and from headers in the trailers-only case), grpc-message percent-decoding is safe on malformed input, HTTP status other than 200 is handled, a response without a message is an error, and the response is not accepted before the server's trailers.
4. Back-pressure: memory stays bounded for a 1 GiB upload (no unbounded buffering in the encoder or the file reader); compare against what the generated client would do.
5. Cancellation and cleanup: cancelling before connect, during send and while awaiting the response closes the stream with RST_STREAM/terminate, destroys the socket, and lets the core remove written chunks (ADR 0023 §7); no leaked sockets or subscriptions on any error path; timeouts for connect and for a stalled server.
6. Errors: send failures and the response future cannot both throw unhandled; Future.any does not leave an unobserved error.
7. Whether a smaller change to the generated client (e.g. awaiting flow control via a custom ClientTransportConnector, or chunking with acks) would remove the need for hand framing. If yes, propose it in the PR description; do not rewrite unless it is clearly simpler and safer.
Add unit tests for every bug you fix, using an in-process HTTP/2 server (package:http2 server side) to simulate trailers-only errors, bad statuses, stalls and mid-stream resets.

Done when: `cd app && flutter analyze && flutter test` are green, the existing GridFS integration test still passes if you can run it (`flutter test integration_test/gridfs_test.dart -d macos` with the env from docs/perf/iteration-12.md), and a PR titled "Iteration 12: harden the GridFS upload transport" is open against main. The PR lists each finding as fixed, not a problem, or deferred with a reason.
```

## Prompt E — Close-out (run after F1, F2 and G are merged)

```text
Repository: Queravue. Read AGENTS.md, ROADMAP.md (the It. 10 and It. 11 sections show the status and known-gaps format), docs/plans/iteration-12.md, docs/plans/iteration-12-batch-2.md, docs/plans/iteration-12-batch-3.md, docs/adr/0022-mongo-sql-mode.md, docs/adr/0023-gridfs.md and docs/perf/iteration-12.md. Look at merged PRs #66–#74 and the batch-3 PRs (core memory, app memory, upload transport) with `gh pr view <n>`.

Task: close iteration 12 on a branch `iteration-12-pr7-closeout` from the latest origin/main. No feature code; only fixes needed to make checks pass.
1. Verify on main: `cd proto && buf lint`; `cd core && go build ./... && go vet ./... && go test ./... && golangci-lint run`; `cd app && flutter analyze && flutter test`; with `docker compose -f dev/docker-compose.yml up -d --wait mongo`, `cd core && go test -count=1 -tags=integration ./internal/mongosql/... ./internal/engine/mongo/...`. Report anything red in the PR instead of hiding it.
2. Measure the one missing number: app-side SQL mode latency from a keystroke in the SQL editor to the updated MQL pane (p50/p95 over the corpus queries or a representative set), on a profile build like the completion perf test (app/integration_test/completion_perf_test.dart). Add it to docs/perf/iteration-12.md and remove it from "Not measured yet".
3. ROADMAP.md, It. 12: mark ✅ done with a Status paragraph (PR numbers, protocol version 12, ADRs 0022/0023, corpus 356 cases / 261 supported / 139 differential, key GridFS and memory numbers after batch 3). Add "Known gaps (carry forward)" from the PRs, at least: Cosmos DB for MongoDB unverified for SQL mode and GridFS; compound-ON `$lookup` pipelines unsupported on older DocumentDB/Cosmos DB; PDF opens in the system viewer (no in-app render, per ADR 0023 §6); the memory budget status after F1/F2 (met, or what remains); anything listed as deferred in the upload-transport review.
4. ADRs 0022 and 0023: Status → Accepted · <date>, and add a short "Implementation notes" list for deviations that shipped (e.g. ADR 0022: `$sort` before the final `$project`; the extra warnings PR #71 added; ADR 0023: `DeleteFile`/`RenameFile` method names, the custom HTTP/2 upload transport and why).
5. docs/plans/iteration-12.md: Status → Done, and link each PR row to its PR.
6. Open a PR titled "Iteration 12 PR 7: close-out (roadmap, ADR status, perf)" against main.
```
