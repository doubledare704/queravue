package engine

import (
	"context"
	"strings"
)

// ObjectType classifies a database object.
type ObjectType string

const (
	// ObjectTypeTable represents a regular relational table.
	ObjectTypeTable ObjectType = "table"
	// ObjectTypeView represents a standard SQL view.
	ObjectTypeView ObjectType = "view"
	// ObjectTypeMaterializedView represents a materialized view.
	ObjectTypeMaterializedView ObjectType = "materialized_view"
	// ObjectTypeCollection represents a document collection.
	ObjectTypeCollection ObjectType = "collection"
	// ObjectTypeTimeSeries represents a time series collection.
	ObjectTypeTimeSeries ObjectType = "time_series"
)

// SchemaObject represents a table or view in a schema list.
type SchemaObject struct {
	Name          string
	Type          ObjectType
	EstimatedRows int64 // -1 if unknown or unsupported
	Capped        bool  // capped collection
	SizeBytes     uint64
}

// ColumnDef describes a single table column.
type ColumnDef struct {
	Name            string
	TypeName        string
	Kind            ValueKind
	Nullable        bool
	DefaultValue    *string
	IsPrimaryKey    bool
	PrimaryKeyOrder int // 1-based position in composite primary key; 0 if not PK
	Identity        bool
	Collation       *string
}

// ReferentialAction is what a foreign key does when the referenced row changes.
type ReferentialAction int

// Referential actions; ReferentialDefault means unknown or the engine default.
const (
	ReferentialDefault ReferentialAction = iota
	ReferentialNoAction
	ReferentialRestrict
	ReferentialCascade
	ReferentialSetNull
	ReferentialSetDefault
)

// IndexDef describes an index on a table.
type IndexDef struct {
	Name      string
	Columns   []string
	IsUnique  bool
	IsPrimary bool
}

// ForeignKeyDef describes a foreign key constraint.
type ForeignKeyDef struct {
	Name              string
	Columns           []string
	ReferencedSchema  string
	ReferencedTable   string
	ReferencedColumns []string
	OnDelete          ReferentialAction
	OnUpdate          ReferentialAction
}

// TableRebuild holds what rebuilding a table (copy into a new table, swap)
// needs. Only SQLite reports it.
type TableRebuild struct {
	// CreateSQL is the table's own CREATE TABLE text.
	CreateSQL string
	// DependentSQL recreates the table's indexes and triggers after a swap.
	DependentSQL []string
	// Blockers say why a rebuild would be unsafe.
	Blockers []string
}

// TableDetails contains comprehensive schema metadata for a single table.
type TableDetails struct {
	Database           string
	Schema             string
	Table              string
	Type               ObjectType
	Columns            []ColumnDef
	Indexes            []IndexDef
	ForeignKeys        []ForeignKeyDef
	EstimatedRows      int64
	CanEdit            bool
	EditDisabledReason string
	Rebuild            *TableRebuild
}

// SchemaInspector is implemented by Conns with CapSchemaInspector.
// It provides lazy, 4-level database schema inspection.
type SchemaInspector interface {
	// ListDatabases returns all accessible database names.
	ListDatabases(ctx context.Context) ([]string, error)
	// ListSchemas returns schema names in the given database.
	ListSchemas(ctx context.Context, database string) ([]string, error)
	// ListObjects returns tables, views, and materialized views in a schema.
	ListObjects(ctx context.Context, database, schema string) ([]SchemaObject, error)
	// DescribeTable returns full column, index, and foreign key definitions for a table.
	DescribeTable(ctx context.Context, database, schema, table string) (TableDetails, error)
}

// ParseReferentialAction reads the action text servers report, such as "SET NULL" or "SET_NULL".
func ParseReferentialAction(text string) ReferentialAction {
	switch strings.ToUpper(strings.ReplaceAll(strings.TrimSpace(text), "_", " ")) {
	case "NO ACTION":
		return ReferentialNoAction
	case "RESTRICT":
		return ReferentialRestrict
	case "CASCADE":
		return ReferentialCascade
	case "SET NULL":
		return ReferentialSetNull
	case "SET DEFAULT":
		return ReferentialSetDefault
	}
	return ReferentialDefault
}
