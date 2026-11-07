package sqldialect

import "github.com/doubledare704/queravue/core/internal/engine"

// ColumnSpec defines a column; TypeName includes length or precision.
type ColumnSpec struct {
	Name      string
	TypeName  string
	Nullable  bool
	Default   *string
	Identity  bool
	Collation *string
}

// ForeignKeySpec defines a foreign key; an empty RefSchema means the target's schema.
type ForeignKeySpec struct {
	Name       string
	Columns    []string
	RefSchema  string
	RefTable   string
	RefColumns []string
	OnDelete   engine.ReferentialAction
	OnUpdate   engine.ReferentialAction
}

// UniqueSpec defines a unique constraint.
type UniqueSpec struct {
	Name    string
	Columns []string
}

// CheckSpec defines a check constraint.
type CheckSpec struct {
	Name       string
	Expression string
}

// TableDesign is the full definition of a new table.
type TableDesign struct {
	Columns        []ColumnSpec
	PrimaryKeyName string
	PrimaryKey     []string
	Uniques        []UniqueSpec
	Checks         []CheckSpec
	ForeignKeys    []ForeignKeySpec
	Indexes        []engine.IndexSpec
}

// Change is one ordered step of a schema change.
type Change interface{ isChange() }

// CreateTable creates the target table.
type CreateTable struct{ Design TableDesign }

// DropTable drops the target table.
type DropTable struct{}

// RenameTable renames the target table; later changes use the new name.
type RenameTable struct{ NewName string }

// AddColumn adds a column.
type AddColumn struct{ Column ColumnSpec }

// DropColumn drops a column.
type DropColumn struct{ Name string }

// RenameColumn renames a column.
type RenameColumn struct{ From, To string }

// AlterColumn changes a column from Before to After; only differences are emitted.
type AlterColumn struct{ Before, After ColumnSpec }

// AddForeignKey adds a foreign key.
type AddForeignKey struct{ ForeignKey ForeignKeySpec }

// AddUnique adds a unique constraint.
type AddUnique struct{ Unique UniqueSpec }

// AddCheck adds a check constraint.
type AddCheck struct{ Check CheckSpec }

// DropConstraint drops a foreign key, unique or check constraint by name.
type DropConstraint struct{ Name string }

// AddIndex adds a secondary index.
type AddIndex struct{ Index engine.IndexSpec }

// DropIndex drops a secondary index.
type DropIndex struct{ Name string }

func (CreateTable) isChange()    {}
func (DropTable) isChange()      {}
func (RenameTable) isChange()    {}
func (AddColumn) isChange()      {}
func (DropColumn) isChange()     {}
func (RenameColumn) isChange()   {}
func (AlterColumn) isChange()    {}
func (AddForeignKey) isChange()  {}
func (AddUnique) isChange()      {}
func (AddCheck) isChange()       {}
func (DropConstraint) isChange() {}
func (AddIndex) isChange()       {}
func (DropIndex) isChange()      {}

// Statement is one generated statement; Destructive means it can lose data or structure.
type Statement struct {
	SQL         string
	Destructive bool
	Summary     string
}

// Script is the generated statements with cautions; Transactional says a failed run rolls back completely.
type Script struct {
	Statements    []Statement
	Warnings      []string
	Transactional bool
}

// Target names the table the changes apply to.
type Target struct {
	Database string
	Schema   string
	Table    string
}
