package engine

import "context"

// KeyedColumn is one column of a table or view with what a diagram shows.
type KeyedColumn struct {
	Table    string
	Name     string
	TypeName string
	Nullable bool
	// PrimaryKeyOrder is the 1-based position in the primary key, 0 if none.
	PrimaryKeyOrder int
}

// TableRelation is a foreign key together with the table that owns it.
type TableRelation struct {
	Table string
	ForeignKeyDef
}

// RelationLister is implemented by Conns with CapSchemaGraph. Each method is
// one query for the whole schema (ADR 0017).
type RelationLister interface {
	// ListKeyedColumns returns all columns ordered by table, then position.
	ListKeyedColumns(ctx context.Context, database, schema string) ([]KeyedColumn, error)
	// ListRelations returns all foreign keys ordered by table, then name.
	ListRelations(ctx context.Context, database, schema string) ([]TableRelation, error)
}

// RelationRows folds one-row-per-column foreign key listings, ordered by
// table, constraint and column position, into relations.
type RelationRows struct {
	relations []TableRelation
}

// Add appends one column pair to the relation named name on table, starting
// that relation if the previous row belonged to another one.
func (r *RelationRows) Add(table, name string, start ForeignKeyDef, column, referencedColumn string) {
	n := len(r.relations)
	if n == 0 || r.relations[n-1].Table != table || r.relations[n-1].Name != name {
		start.Name = name
		r.relations = append(r.relations, TableRelation{Table: table, ForeignKeyDef: start})
		n++
	}
	last := &r.relations[n-1]
	last.Columns = append(last.Columns, column)
	last.ReferencedColumns = append(last.ReferencedColumns, referencedColumn)
}

// Relations returns what was folded so far.
func (r *RelationRows) Relations() []TableRelation { return r.relations }
