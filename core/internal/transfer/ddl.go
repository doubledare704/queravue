package transfer

import (
	"slices"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

// DesignOfTable is the CREATE TABLE of td for a dump: columns and primary key.
func DesignOfTable(td engine.TableDetails, only []string) *sqldialect.TableDesign {
	design := &sqldialect.TableDesign{}
	keyed := map[int]string{}
	for _, col := range td.Columns {
		if len(only) > 0 && !slices.Contains(only, col.Name) {
			continue
		}
		design.Columns = append(design.Columns, sqldialect.ColumnSpec{
			Name: col.Name, TypeName: col.TypeName, Nullable: col.Nullable,
			Default: col.DefaultValue, Identity: col.Identity, Collation: col.Collation,
		})
		if col.IsPrimaryKey {
			keyed[col.PrimaryKeyOrder] = col.Name
		}
	}
	orders := make([]int, 0, len(keyed))
	for order := range keyed {
		orders = append(orders, order)
	}
	slices.Sort(orders)
	for _, order := range orders {
		design.PrimaryKey = append(design.PrimaryKey, keyed[order])
	}
	return design
}

// DesignOfColumns is the CREATE TABLE of a query result, with the engine's own type names.
func DesignOfColumns(cols []engine.Column) *sqldialect.TableDesign {
	design := &sqldialect.TableDesign{}
	for _, col := range cols {
		typeName := col.TypeName
		if typeName == "" {
			typeName = "TEXT"
		}
		design.Columns = append(design.Columns, sqldialect.ColumnSpec{Name: col.Name, TypeName: typeName, Nullable: true})
	}
	return design
}

// CreateTableScript is the reviewed DDL that creates a table for an import.
func CreateTableScript(d sqldialect.Dialect, target sqldialect.Target, design sqldialect.TableDesign) (sqldialect.Script, error) {
	script, err := sqldialect.BuildDDL(d, target, nil, []sqldialect.Change{sqldialect.CreateTable{Design: design}})
	if err != nil {
		return sqldialect.Script{}, newError(KindMapping, "cannot build CREATE TABLE: %v", err)
	}
	return script, nil
}
