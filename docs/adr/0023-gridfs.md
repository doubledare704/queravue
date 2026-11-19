# ADR 0023 — GridFS

**Status:** Proposed · 2026-11-19

## Context
Iteration 12 adds a GridFS viewer: browse buckets, preview images, text and PDF, upload and download. Files can be gigabytes, so neither core nor app may hold a whole file. Related: ADR 0003 (capabilities), ADR 0009 (EJSON, paging, production confirmation), ADR 0018 (network paths).

## Decision

### 1. Capability
`CapGridFS = "gridfs"` with `engine.GridFS` on the Mongo `Conn` (`ListBuckets`, `ListFiles`, `Download`, `Upload`, `Delete`, `Rename`), mapped in `CapabilityInterfaces` and declared by all Mongo variants once implemented. It is built on the driver's `gridfs` bucket API. The UI shows GridFS from this name only.

### 2. Buckets
A bucket is a pair of collections `<name>.files` and `<name>.chunks`. The tree shows buckets under a "GridFS" node per database and hides the two collections behind it, with a toggle to show them as ordinary collections.

### 3. Bytes travel over gRPC; the app owns the filesystem
- `Download` is a server stream: a header with the file, then chunks of at most 1 MiB. It takes an optional `offset` and `length`, which preview uses.
- `Upload` is a client stream: a header (filename, content type, metadata, optional file to replace), then chunks.
- The app reads and writes local files through its open and save dialogs. Back-pressure comes from the streams, and neither side buffers a whole file.

Rejected: core reading or writing paths sent by the UI. It widens what core can touch on disk, and it does not fit a scheduled or remote core.

### 4. Listing
`ListFiles` pages `<bucket>.files` with a relaxed EJSON filter and sort, `skip` and `limit` (ADR 0009 §3), streamed in batches. Each file reports `_id` (canonical EJSON), filename, length, chunk size, upload date, content type and metadata. Content type is `metadata.contentType`, falling back to the deprecated top-level `contentType`.

### 5. Preview
The app downloads at most a capped number of bytes with `length`: text 1 MiB (UTF-8, otherwise a hex view), images 32 MiB (PNG, JPEG, GIF, WebP, BMP), PDF 32 MiB. The type comes from the content type, then from magic bytes in the first 512 bytes. Larger files show their metadata and a Download button.

### 6. PDF
A half-day spike decides: render in the app with `pdfrx` (MIT, bundles PDFium) if it stays within the app-size and idle-memory budgets, otherwise write a temporary file and open it in the system viewer. The default is the system viewer. The spike's result is added here.

### 7. Safety
`DeleteFile`, and `Upload` that replaces a file, need `confirmed=true` on connections flagged production, otherwise `CONFIRMATION_REQUIRED` and nothing changes (ADR 0009 §8). Renaming needs no confirmation. A cancelled upload deletes the chunks it wrote.

### 8. Errors
Failures the user can act on are in-band `GridFsError` with the kinds of `DocumentErrorKind` plus `CORRUPT` (missing or short chunks). Unknown sessions are gRPC `NOT_FOUND`; a session without the capability is `FAILED_PRECONDITION`.

## Consequences
- New `GridFsService` in `gridfs.proto`; protocol version 12 (shared with ADR 0022).
- Memory stays flat for any file size; the cost is a copy through gRPC instead of a direct file write in core.
- Cosmos DB for MongoDB stays unverified; DocumentDB Local is tested.
