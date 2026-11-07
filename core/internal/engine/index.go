package engine

import (
	"context"
	"time"
)

// IndexKeyKind says how one index key part is ordered or hashed.
type IndexKeyKind int

// Index key kinds; the last three exist only in document engines.
const (
	IndexKeyAscending IndexKeyKind = iota
	IndexKeyDescending
	IndexKeyHashed
	IndexKeyText
	IndexKeyGeo2DSphere
)

// IndexKey is one part of an index key: a column, field path or expression.
type IndexKey struct {
	Name         string
	Kind         IndexKeyKind
	IsExpression bool
}

// IndexSpec defines an index for display and creation; Options holds engine-specific settings as EJSON text.
type IndexSpec struct {
	Name             string
	Keys             []IndexKey
	Unique           bool
	Method           string
	PartialPredicate string
	IncludeColumns   []string
	Options          map[string]string
}

// IndexUsage reports use since the server's counters began; Available is false when the server keeps none.
type IndexUsage struct {
	Available     bool
	Scans         *uint64
	LastUsed      *time.Time
	TrackingSince *time.Time
}

// IndexInfo is an existing index with its size and usage.
type IndexInfo struct {
	Spec      IndexSpec
	IsPrimary bool
	SizeBytes *uint64
	Usage     IndexUsage
}

// IndexManager is implemented by Conns with CapIndexManager.
type IndexManager interface {
	ListIndexes(ctx context.Context, database, schema, table string) ([]IndexInfo, error)
}

// IndexWriter is implemented by Conns that create and drop indexes natively
// instead of through SQL DDL. With dryRun it only builds the statement.
type IndexWriter interface {
	CreateIndex(ctx context.Context, database, schema, table string, spec IndexSpec, dryRun bool) (statement, name string, err error)
	DropIndex(ctx context.Context, database, schema, table, name string, dryRun bool) (statement string, err error)
}

// StatEntry is an engine-specific figure already formatted for display.
type StatEntry struct {
	Key, Label, Value string
}

// TableStats holds figures read from server metadata; nil means unknown.
type TableStats struct {
	EstimatedRows *int64
	DataBytes     *uint64
	IndexBytes    *uint64
	TotalBytes    *uint64
	Extras        []StatEntry
}

// StatsProvider is implemented by Conns with CapStats.
type StatsProvider interface {
	TableStats(ctx context.Context, database, schema, table string) (TableStats, error)
}
