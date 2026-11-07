package api

import (
	"errors"

	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

func changeFromProto(c *queravuev1.SchemaChange) (sqldialect.Change, error) {
	switch v := c.GetChange().(type) {
	case *queravuev1.SchemaChange_CreateTable:
		return sqldialect.CreateTable{Design: designFromProto(v.CreateTable.GetDesign())}, nil
	case *queravuev1.SchemaChange_DropTable:
		return sqldialect.DropTable{}, nil
	case *queravuev1.SchemaChange_RenameTable:
		return sqldialect.RenameTable{NewName: v.RenameTable.GetNewName()}, nil
	case *queravuev1.SchemaChange_AddColumn:
		return sqldialect.AddColumn{Column: columnFromProto(v.AddColumn.GetColumn())}, nil
	case *queravuev1.SchemaChange_DropColumn:
		return sqldialect.DropColumn{Name: v.DropColumn.GetName()}, nil
	case *queravuev1.SchemaChange_RenameColumn:
		return sqldialect.RenameColumn{From: v.RenameColumn.GetFrom(), To: v.RenameColumn.GetTo()}, nil
	case *queravuev1.SchemaChange_AlterColumn:
		return sqldialect.AlterColumn{Before: columnFromProto(v.AlterColumn.GetBefore()), After: columnFromProto(v.AlterColumn.GetAfter())}, nil
	case *queravuev1.SchemaChange_AddForeignKey:
		return sqldialect.AddForeignKey{ForeignKey: foreignKeyFromProto(v.AddForeignKey.GetForeignKey())}, nil
	case *queravuev1.SchemaChange_AddUnique:
		return sqldialect.AddUnique{Unique: uniqueFromProto(v.AddUnique.GetUnique())}, nil
	case *queravuev1.SchemaChange_AddCheck:
		return sqldialect.AddCheck{Check: checkFromProto(v.AddCheck.GetCheck())}, nil
	case *queravuev1.SchemaChange_DropConstraint:
		return sqldialect.DropConstraint{Name: v.DropConstraint.GetName()}, nil
	case *queravuev1.SchemaChange_AddIndex:
		return sqldialect.AddIndex{Index: indexSpecFromProto(v.AddIndex.GetIndex())}, nil
	case *queravuev1.SchemaChange_DropIndex:
		return sqldialect.DropIndex{Name: v.DropIndex.GetName()}, nil
	}
	return nil, errors.New("a change must set one of its steps")
}

func columnFromProto(c *queravuev1.ColumnSpec) sqldialect.ColumnSpec {
	return sqldialect.ColumnSpec{
		Name: c.GetName(), TypeName: c.GetTypeName(), Nullable: c.GetNullable(),
		Default: c.DefaultExpression, Identity: c.GetIdentity(), Collation: c.Collation,
	}
}

func foreignKeyFromProto(f *queravuev1.ForeignKeySpec) sqldialect.ForeignKeySpec {
	return sqldialect.ForeignKeySpec{
		Name: f.GetName(), Columns: f.GetColumns(),
		RefSchema: f.GetReferencedTable().GetSchema(), RefTable: f.GetReferencedTable().GetTable(), RefColumns: f.GetReferencedColumns(),
		OnDelete: referentialActionFromProto(f.GetOnDelete()), OnUpdate: referentialActionFromProto(f.GetOnUpdate()),
	}
}

func uniqueFromProto(u *queravuev1.UniqueSpec) sqldialect.UniqueSpec {
	return sqldialect.UniqueSpec{Name: u.GetName(), Columns: u.GetColumns()}
}

func checkFromProto(c *queravuev1.CheckSpec) sqldialect.CheckSpec {
	return sqldialect.CheckSpec{Name: c.GetName(), Expression: c.GetExpression()}
}

func designFromProto(d *queravuev1.TableDesign) sqldialect.TableDesign {
	out := sqldialect.TableDesign{PrimaryKeyName: d.GetPrimaryKeyName(), PrimaryKey: d.GetPrimaryKeyColumns()}
	for _, c := range d.GetColumns() {
		out.Columns = append(out.Columns, columnFromProto(c))
	}
	for _, u := range d.GetUniques() {
		out.Uniques = append(out.Uniques, uniqueFromProto(u))
	}
	for _, c := range d.GetChecks() {
		out.Checks = append(out.Checks, checkFromProto(c))
	}
	for _, f := range d.GetForeignKeys() {
		out.ForeignKeys = append(out.ForeignKeys, foreignKeyFromProto(f))
	}
	for _, ix := range d.GetIndexes() {
		out.Indexes = append(out.Indexes, indexSpecFromProto(ix))
	}
	return out
}
