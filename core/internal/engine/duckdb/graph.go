//go:build duckdb

package duckdb

import (
	"context"
	"database/sql"

	"github.com/doubledare704/queravue/core/internal/engine"
)

var (
	_ engine.RelationLister = (*Conn)(nil)
	_ engine.ColumnLister   = (*Conn)(nil)
)

const (
	listColumnsSQL = `SELECT table_name, column_name, data_type, is_nullable
FROM duckdb_columns() WHERE ` + scopeClause + ` AND NOT internal ORDER BY table_name, column_index`
	listPrimaryKeysSQL = `SELECT table_name, constraint_column_names FROM duckdb_constraints()
WHERE ` + scopeClause + ` AND constraint_type = 'PRIMARY KEY'`
	listRelationsSQL = `SELECT table_name, constraint_name, constraint_column_names, referenced_table, referenced_column_names
FROM duckdb_constraints() WHERE ` + scopeClause + ` AND constraint_type = 'FOREIGN KEY' ORDER BY table_name, constraint_name`
)

// ListColumns implements engine.ColumnLister.
func (c *Conn) ListColumns(ctx context.Context, database, schema string) ([]engine.ColumnRef, error) {
	keyed, err := c.ListKeyedColumns(ctx, database, schema)
	if err != nil {
		return nil, err
	}
	out := make([]engine.ColumnRef, len(keyed))
	for i, k := range keyed {
		out[i] = engine.ColumnRef{Table: k.Table, Name: k.Name, TypeName: k.TypeName}
	}
	return out, nil
}

// ListKeyedColumns implements engine.RelationLister.
func (c *Conn) ListKeyedColumns(ctx context.Context, database, schema string) ([]engine.KeyedColumn, error) {
	meta, err := c.metaPool("list keyed columns")
	if err != nil {
		return nil, err
	}
	keyOrder, err := c.primaryKeyOrders(ctx, meta, database, schema)
	if err != nil {
		return nil, err
	}
	rows, err := meta.QueryContext(ctx, listColumnsSQL, database, schema)
	if err != nil {
		return nil, classify("list keyed columns", err)
	}
	defer func() { _ = rows.Close() }()
	var out []engine.KeyedColumn
	for rows.Next() {
		var col engine.KeyedColumn
		if err := rows.Scan(&col.Table, &col.Name, &col.TypeName, &col.Nullable); err != nil {
			return nil, classify("list keyed columns", err)
		}
		col.PrimaryKeyOrder = keyOrder[col.Table][col.Name]
		out = append(out, col)
	}
	if err := rows.Err(); err != nil {
		return nil, classify("list keyed columns", err)
	}
	return out, nil
}

func (c *Conn) primaryKeyOrders(ctx context.Context, meta *sql.DB, database, schema string) (map[string]map[string]int, error) {
	rows, err := meta.QueryContext(ctx, listPrimaryKeysSQL, database, schema)
	if err != nil {
		return nil, classify("list primary keys", err)
	}
	defer func() { _ = rows.Close() }()
	orders := map[string]map[string]int{}
	for rows.Next() {
		var table string
		var columns any
		if err := rows.Scan(&table, &columns); err != nil {
			return nil, classify("list primary keys", err)
		}
		orders[table] = map[string]int{}
		for i, name := range stringList(columns) {
			orders[table][name] = i + 1
		}
	}
	if err := rows.Err(); err != nil {
		return nil, classify("list primary keys", err)
	}
	return orders, nil
}

// ListRelations implements engine.RelationLister. DuckDB foreign keys have no
// referential actions, so every relation reports NO ACTION, and they can only
// point into the same schema.
func (c *Conn) ListRelations(ctx context.Context, database, schema string) ([]engine.TableRelation, error) {
	meta, err := c.metaPool("list relations")
	if err != nil {
		return nil, err
	}
	rows, err := meta.QueryContext(ctx, listRelationsSQL, database, schema)
	if err != nil {
		return nil, classify("list relations", err)
	}
	defer func() { _ = rows.Close() }()
	var out []engine.TableRelation
	for rows.Next() {
		var table, name, refTable string
		var columns, refColumns any
		if err := rows.Scan(&table, &name, &columns, &refTable, &refColumns); err != nil {
			return nil, classify("list relations", err)
		}
		out = append(out, engine.TableRelation{Table: table, ForeignKeyDef: engine.ForeignKeyDef{
			Name: name, Columns: stringList(columns), ReferencedTable: refTable, ReferencedColumns: stringList(refColumns),
			OnDelete: engine.ReferentialNoAction, OnUpdate: engine.ReferentialNoAction,
		}})
	}
	if err := rows.Err(); err != nil {
		return nil, classify("list relations", err)
	}
	return out, nil
}
