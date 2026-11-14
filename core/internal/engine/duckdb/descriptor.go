// Package duckdb implements the DuckDB engine. The driver wraps the C++
// library through cgo, so the code that touches it builds only with
// -tags duckdb (docs/adr/0019-duckdb-cgo.md). The files without the tag hold
// what needs no driver: the descriptor, URI parsing, error and type mapping.
package duckdb

import "github.com/doubledare704/queravue/core/internal/engine"

// ID is the engine id.
const ID = "duckdb"

// Parameter keys.
const (
	ParamPath            = "path"
	ParamReadOnly        = "read_only"
	ParamCreateIfMissing = "create_if_missing"
	ParamMemoryLimit     = "memory_limit"
)

// MemoryPath opens a private in-memory database.
const MemoryPath = ":memory:"

func descriptor() engine.Descriptor {
	return engine.Descriptor{
		ID:          ID,
		DisplayName: "DuckDB",
		Family:      ID,
		SupportsURI: true,
		URIExample:  "duckdb:///Users/me/analytics.duckdb",
		Fields: []engine.FieldSpec{
			{Key: ParamPath, Label: "Database file", Kind: engine.FieldFile, Required: true, Default: MemoryPath, Placeholder: "/path/to/analytics.duckdb or :memory:"},
			{Key: ParamReadOnly, Label: "Read-only", Kind: engine.FieldBoolean, Default: "false"},
			{Key: ParamCreateIfMissing, Label: "Create file if missing", Kind: engine.FieldBoolean, Default: "false"},
			{Key: ParamMemoryLimit, Label: "Memory limit", Kind: engine.FieldText, Placeholder: "e.g. 4GB (default: 80% of RAM)"},
		},
		Capabilities: []engine.Capability{engine.CapConnect, engine.CapExecute, engine.CapSchemaInspector, engine.CapCompletion, engine.CapFormat, engine.CapSchemaGraph},
	}
}
