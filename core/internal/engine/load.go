package engine

import "context"

// LoadTarget is the table a RowLoader writes to.
type LoadTarget struct {
	Database, Schema, Table string
}

// LoadStats counts what a loader committed. It is returned with an error too,
// so a partial load is reported.
type LoadStats struct {
	Rows, Batches uint64
}

// RowBatchSource yields row batches until it returns io.EOF. Values line up
// with the columns passed to LoadRows.
type RowBatchSource interface {
	Next(ctx context.Context) ([][]Value, error)
}

// DocumentBatchSource yields document batches until it returns io.EOF.
type DocumentBatchSource interface {
	Next(ctx context.Context) ([]Document, error)
}

// RowLoader is implemented by Conns with CapBulkLoad (ADR 0024 §8). Each
// engine uses its native fast path; batches already committed stay committed
// when ctx is cancelled or src fails.
type RowLoader interface {
	LoadRows(ctx context.Context, t LoadTarget, columns []string, src RowBatchSource) (LoadStats, error)
}

// DocumentLoader is implemented by Conns with CapDocumentLoad (ADR 0024 §8).
type DocumentLoader interface {
	LoadDocuments(ctx context.Context, database, collection string, src DocumentBatchSource) (LoadStats, error)
}
