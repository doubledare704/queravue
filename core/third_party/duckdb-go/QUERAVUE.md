# Queravue driver changes

Source: [duckdb-go v2.20000.0](https://github.com/duckdb/duckdb-go/tree/v2.20000.0).
This local Go module contains the buildable sources and upstream MIT license.
The native bindings and platform archives still come from the versions in
`go.mod`.

- `streaming.go` adds a callback that owns the statement's native result and
  keeps the existing context interrupter active until row fetching and cleanup
  finish.
- `statement.go` lets that callback select the streaming pending-result
  function. Existing driver entry points still use the default pending function.
- `rows.go` distinguishes fetch errors from EOF.
- `mapping/mapping.go` re-exports the pending streaming binding.

Remove this module and the corresponding `replace` in core's `go.mod` once a
tagged upstream driver provides streaming with equivalent cancellation and
fetch-error handling. The DuckDB engine tests exercise both.
