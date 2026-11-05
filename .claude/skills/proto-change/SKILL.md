---
name: proto-change
description: Safely change the Queravue gRPC/protobuf contract between the Flutter UI and Go core. Use whenever editing files under proto/ or adding/changing an RPC or message.
---
# Change the UI↔core contract

The contract in `proto/queravue/v1/` is the only interface between `app/` and `core/`. Use plan mode first.

## Rules
- **Never** reuse or renumber field numbers. Removing a field → `reserved <n>; reserved "<name>";`.
- Renaming is a breaking change for JSON only; avoid it anyway.
- New fields must have safe zero-value defaults (old UI + new core must still work, and the reverse).
- Large or unbounded data → **server streaming** RPC with batches (never a repeated field holding a whole result set).
- Long-running RPCs must honour cancellation (context in Go, `ResponseFuture.cancel()` in Dart).
- Breaking changes need a new RPC or `v2` package plus user approval.

## Steps
1. Edit `.proto`, with doc comments on every RPC, message and field.
2. `cd proto && buf format -w && buf lint && buf breaking --against '.git#branch=main'`.
3. `buf generate`: regenerates Go (`core/internal/gen/`) and Dart (`app/lib/core_client/gen/`). Commit generated code in the same change.
4. Implement in core: `core/internal/api/` (keep handlers thin, logic in `internal/engine` or services). Add a handler test.
5. Update the Dart client wrapper in `app/lib/core_client/` and the providers that use it.
6. Run `cd core && go test ./...` and `cd app && flutter analyze && flutter test`.

## Done when
- `buf lint` and `buf breaking` are clean (or the break is approved and versioned).
- Both sides compile against the regenerated code, and tests pass.
