package engine

import "context"

// ColumnRef is one column of a table or view, as listed in bulk.
type ColumnRef struct {
	Table    string
	Name     string
	TypeName string
}

// ColumnLister is implemented by Conns with CapCompletion. It lists every
// column of a schema in one query, ordered by table then ordinal position.
type ColumnLister interface {
	// ListColumns returns the columns of all tables and views in the schema.
	ListColumns(ctx context.Context, database, schema string) ([]ColumnRef, error)
}
