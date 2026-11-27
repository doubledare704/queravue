# ADR 0023 — GridFS

**Status:** Proposed · 2026-11-19

## Context
Iteration 12 adds a GridFS viewer: browse buckets, preview images, text and PDF, upload and download. Files can be gigabytes, so neither core nor app may hold a whole file. Related: ADR 0003 (capabilities), ADR 0009 (EJSON, paging, production confirmation), ADR 0018 (network paths).

## Decision

### 1. Capability
`CapGridFS = "gridfs"` with `engine.GridFS` on the Mongo `Conn` (`ListBuckets`, `ListFiles`, `Download`, `Upload`, `Delete`, `Rename`), mapped in `CapabilityInterfaces` and declared by all Mongo variants once implemented. It uses the driver's GridFS bucket API for bucket operations and spec-compatible collection access for transfers. The UI shows GridFS from this name only.

### 2. Buckets
A bucket is a pair of collections `<name>.files` and `<name>.chunks`. The tree shows buckets under a "GridFS" node per database and hides the two collections behind it, with a toggle to show them as ordinary collections.

### 3. Bytes travel over gRPC; the app owns the filesystem
- `Download` is a server stream: a header with the file, then chunks of at most 1 MiB. It takes an optional `offset` and `length`, which preview uses. Full and ranged reads use the same validated chunks cursor with a target of 4 MiB of chunk data per batch; a single larger GridFS chunk still requires its full size.
- `Upload` is a client stream: a header (filename, content type, metadata, optional file to replace), then chunks. Core writes GridFS chunk documents in bounded batches and inserts the file document last; this avoids the driver's fixed 16 MiB upload buffer and the larger encoding buffers it induces.
- The app reads and writes local files through its open and save dialogs. Back-pressure comes from the streams, and neither side buffers a whole file.

Rejected: core reading or writing paths sent by the UI. It widens what core can touch on disk, and it does not fit a scheduled or remote core.

### 4. Listing
`ListFiles` pages `<bucket>.files` with a relaxed EJSON filter and sort, `skip` and `limit` (ADR 0009 §3), streamed in batches. Each file reports `_id` (canonical EJSON), filename, length, chunk size, upload date, content type and metadata. Content type is `metadata.contentType`, falling back to the deprecated top-level `contentType`.

### 5. Preview
The app downloads at most a capped number of bytes with `length`: text 1 MiB (UTF-8, otherwise a hex view), images 32 MiB (PNG, JPEG, GIF, WebP, BMP), PDF 32 MiB. The type comes from the content type, then from magic bytes in the first 512 bytes. Larger files show their metadata and a Download button.

### 6. PDF
**Decision: System viewer** (write the downloaded preview bytes to a private temporary file and open it with the OS default handler: `open` on macOS, `cmd /c start ""` on Windows, `xdg-open` detached on Linux; zero new dependencies since `url_launcher` is not in `app/pubspec.yaml`). Do not add `pdfrx` to `app/`.

The half-day macOS release spike (`spikes/pdf/README.md`, Apple M4 Pro, Flutter 3.47.9, `pdfrx` 3.0.0 / PDFium `chromium/8125`) measured:
- **App bundle size:** `36.68 MiB` (`38.46 MB`) baseline → `67.29 MiB` (`70.55 MB`) with `pdfrx` (**`+30.61 MiB` / `+32.09 MB`**, including `14.54 MiB` `PDFium.framework` and a `11.87 MiB` duplicate `pdfium_dart.framework` retained on macOS for `flutter test`).
- **Idle RSS delta (30 s, median of 3 runs):** `144.67 MiB` baseline → `162.30 MiB` with `pdfrx` linked but unused (**`+17.62 MiB` / `+18.48 MB`** because `PDFium.framework` is dynamically linked at launch; `+19.80 MiB` / `+20.76 MB` with eager `pdfrxFlutterInitialize()`). Against Queravue's `139.4 MiB` (`146.2 MB`) combined UI + sidecar baseline (`docs/perf/iteration-10.md`), adding `pdfrx` pushes idle memory to **~157.0 MiB (~164.7 MB)** — over the **150 MB** idle budget before any PDF is opened.
- **In-app render, scroll, and close RSS (`PdfViewer.data` from `Uint8List`, medians of 3):**
  - 1-page (`1.1 KiB`): first page in `313 ms`, peak `201.20 MiB`, `187.08 MiB` 10 s after close (`+53.05 MiB` retained).
  - 300-page text (`0.30 MiB`, scrolled): first page in `160 ms`, peak `318.14 MiB`, `284.89 MiB` 10 s after close (`+141.06 MiB` retained).
  - 30 MiB image-heavy (`29.76 MiB`, 15 pages scrolled): first page in `165 ms`, peak `398.08 MiB`, `372.33 MiB` 10 s after close (`+228.38 MiB` retained).
- **System viewer baseline:** `4–10 ms` temp write + `64–91 ms` `/usr/bin/open` launch, `0 B` bundle delta, `0 MiB` idle RSS delta, and PDF rendering memory stays outside Queravue.
- **Licensing & cross-platform caveats:** `pdfrx` is MIT, while bundled PDFium binaries are BSD-3-Clause + Apache-2.0 with ~20 embedded C/C++ libraries (e.g., FreeType FTL attribution, libjpeg-turbo, OpenJPEG, ICU) not auto-registered in `LicenseRegistry`; Windows builds also require Developer Mode symlinks, and clean Windows/Linux builds download PDFium over HTTPS and compile `pdfrx_pdfium_gate` with a C toolchain.

Implementation note for the GridFS viewer: stream `≤ 1 MiB` download chunks straight to a sanitized filename inside a private `0700` temp directory (`0600` file on POSIX) and remove tracked temp files when the session or app exits. Iteration 12 implements this for previews: image and PDF previews stream into a private temp directory instead of a `Uint8List` in state; the image file is deleted when the selection changes and PDF files when the bucket tab closes or the app exits. When macOS App Sandbox is re-enabled in Iteration 19, verify `NSWorkspace` / temp-file open permissions.

### 7. Safety
`DeleteFile`, and `Upload` that replaces a file, need `confirmed=true` on connections flagged production, otherwise `CONFIRMATION_REQUIRED` and nothing changes (ADR 0009 §8). Renaming needs no confirmation. A cancelled upload deletes the chunks it wrote.

### 8. Errors
Failures the user can act on are in-band `GridFsError` with the kinds of `DocumentErrorKind` plus `CORRUPT` (missing or short chunks). Unknown sessions are gRPC `NOT_FOUND`; a session without the capability is `FAILED_PRECONDITION`.

## Consequences
- New `GridFsService` in `gridfs.proto`; protocol version 12 (shared with ADR 0022).
- Memory stays flat for any file size; the cost is a copy through gRPC instead of a direct file write in core.
- Cosmos DB for MongoDB stays unverified; DocumentDB Local is tested.
