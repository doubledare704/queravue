package engine

import "context"

// CursorKind says how a CursorSpec is replayed.
type CursorKind int

// Cursor kinds.
const (
	CursorFind CursorKind = iota + 1
	CursorAggregate
)

// CursorSpec describes a find or aggregate. All documents are canonical
// Extended JSON text; empty means unset.
type CursorSpec struct {
	Kind                 CursorKind
	Database, Collection string
	Filter               string
	Sort                 string
	Projection           string
	Hint                 string
	Pipeline             string
	Skip, Limit          uint64
	BatchSize            int
	MaxTimeMS            uint32
}

// DocCursor yields documents one at a time.
type DocCursor interface {
	// Next returns the next canonical EJSON document; ok is false at the end.
	Next(ctx context.Context) (doc Document, ok bool, err error)
	// Close releases the server-side cursor. Safe to call more than once.
	Close() error
}

// ShellBackend is implemented by Conns with CapShell. It gives the shell
// runtime raw access to a server without engine-specific knowledge.
type ShellBackend interface {
	// RunCommand runs a database command given as canonical EJSON and returns
	// the reply as canonical EJSON. Failures are *Error; server errors carry
	// Code.
	RunCommand(ctx context.Context, database string, command Document) (Document, error)
	// OpenCursor starts a find or aggregate.
	OpenCursor(ctx context.Context, spec CursorSpec) (DocCursor, error)
}
