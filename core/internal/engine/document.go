package engine

import (
	"context"
	"errors"
)

// MaxDocBatch is the default number of documents per DocSink.Batch call.
const MaxDocBatch = 500

// MaxDocBatchBytes is the soft byte cap of one document batch. A single
// document larger than the cap travels alone.
const MaxDocBatchBytes = 2 << 20

// ErrStopDocs returned from a DocSink ends a Find cleanly: the engine closes
// the cursor and Find returns a nil error.
var ErrStopDocs = errors.New("engine: stop reading documents")

// Document is a canonical Extended JSON v2 document or value (ADR 0009).
type Document = string

// FindOptions selects documents. Filter, Sort and Projection are Extended
// JSON text; empty means unset.
type FindOptions struct {
	Database, Collection string
	Filter               string
	Sort                 string
	Projection           string
	Skip, Limit          uint64 // Limit 0 = no limit
	BatchSize            int    // 0 = MaxDocBatch
	MaxTimeMS            uint32
}

// DocSink receives the documents of a Find. Implementations must not retain
// the slice after returning. Returning an error stops the Find; ErrStopDocs
// stops it without failing.
type DocSink interface {
	// Batch delivers 1..BatchSize documents as canonical EJSON.
	Batch(docs []Document) error
}

// Count is a document count.
type Count struct {
	N     uint64
	Exact bool
}

// WriteOptions carries the concurrency guard of a write. Production
// confirmation is enforced by the API layer, which knows the connection flag.
type WriteOptions struct {
	// Expected, if non-nil, makes a replace or update fail with
	// KindConflict when the stored document differs.
	Expected *Document
}

// FieldType is a BSON type seen in a sample.
type FieldType struct {
	Type  string // $type alias, e.g. "int", "long", "date"
	Count uint32
}

// FieldStat describes one sampled top-level field.
type FieldStat struct {
	Name      string
	Types     []FieldType
	Frequency float64 // 0..1
}

// FieldPathStat describes one sampled field path. Array elements use the
// segment "[]", so "items.[].sku" is the sku of every element of items.
type FieldPathStat struct {
	Path      string
	Types     []FieldType
	Frequency float64 // share of sampled documents that have the path, 0..1
	Depth     int
}

// PathSampleOptions bound SampleFieldPaths. Zero values pick the defaults.
type PathSampleOptions struct {
	SampleSize uint32
	MaxDepth   int
	MaxPaths   int
}

// FieldPathSample is the result of SampleFieldPaths.
type FieldPathSample struct {
	Paths        []FieldPathStat
	Sampled      uint32
	UsedFallback bool
	Truncated    bool
}

// FieldSample is the result of SampleFields.
type FieldSample struct {
	Fields       []FieldStat
	Sampled      uint32
	UsedFallback bool
}

// DocumentStore is implemented by Conns with CapDocumentStore. Parse
// problems are *Error with KindParse and a Position; write conflicts are
// KindConflict and carry the stored document in Error.Current.
type DocumentStore interface {
	// Find streams matching documents into sink in batches. Cancelling ctx
	// closes the cursor.
	Find(ctx context.Context, opt FindOptions, sink DocSink) error
	// Count returns an estimate for an empty filter, an exact count otherwise.
	Count(ctx context.Context, database, collection, filter string, maxTimeMS uint32) (Count, error)
	// Insert inserts documents and returns their canonical EJSON _id values.
	Insert(ctx context.Context, database, collection string, docs []Document, w WriteOptions) ([]Document, error)
	// Replace replaces the document with the given _id and returns it as stored.
	Replace(ctx context.Context, database, collection string, id, doc Document, w WriteOptions) (Document, error)
	// UpdateFields $sets and $unsets fields of one document and returns it.
	UpdateFields(ctx context.Context, database, collection string, id, set Document, unset []string, w WriteOptions) (Document, error)
	// Delete deletes documents by _id and returns how many were removed.
	Delete(ctx context.Context, database, collection string, ids []Document, w WriteOptions) (uint64, error)
	// SampleFields reports top-level field names, types and frequencies.
	SampleFields(ctx context.Context, database, collection string, n uint32) (FieldSample, error)
	// SampleFieldPaths reports nested field paths with types and frequencies.
	SampleFieldPaths(ctx context.Context, database, collection string, opts PathSampleOptions) (FieldPathSample, error)
}
