package mysql

import (
	"context"

	"github.com/doubledare704/queravue/core/internal/engine"
)

var _ engine.RelationLister = (*Conn)(nil)

// ListKeyedColumns implements engine.RelationLister.
func (c *Conn) ListKeyedColumns(ctx context.Context, database, schema string) ([]engine.KeyedColumn, error) {
	conn, err := c.live("list keyed columns")
	if err != nil {
		return nil, err
	}
	rows, err := conn.QueryContext(ctx,
		`SELECT c.table_name, c.column_name, c.column_type, c.is_nullable, COALESCE(k.ordinal_position, 0)
FROM information_schema.columns c
LEFT JOIN information_schema.key_column_usage k
  ON k.table_schema = c.table_schema AND k.table_name = c.table_name
 AND k.column_name = c.column_name AND k.constraint_name = 'PRIMARY'
WHERE c.table_schema = ?
ORDER BY c.table_name, c.ordinal_position`, dbOf(database, schema))
	if err != nil {
		return nil, c.execError(ctx, err)
	}
	defer func() { _ = rows.Close() }()
	var out []engine.KeyedColumn
	for rows.Next() {
		var col engine.KeyedColumn
		var nullable string
		if err := rows.Scan(&col.Table, &col.Name, &col.TypeName, &nullable, &col.PrimaryKeyOrder); err != nil {
			return nil, c.execError(ctx, err)
		}
		col.Nullable = nullable == "YES"
		out = append(out, col)
	}
	if err := rows.Err(); err != nil {
		return nil, c.execError(ctx, err)
	}
	return out, nil
}

// ListRelations implements engine.RelationLister.
func (c *Conn) ListRelations(ctx context.Context, database, schema string) ([]engine.TableRelation, error) {
	conn, err := c.live("list relations")
	if err != nil {
		return nil, err
	}
	listed := dbOf(database, schema)
	rows, err := conn.QueryContext(ctx,
		`SELECT k.table_name, k.constraint_name, k.column_name,
       k.referenced_table_schema, k.referenced_table_name, k.referenced_column_name,
       r.delete_rule, r.update_rule
FROM information_schema.key_column_usage k
JOIN information_schema.referential_constraints r
  ON r.constraint_schema = k.constraint_schema AND r.constraint_name = k.constraint_name AND r.table_name = k.table_name
WHERE k.table_schema = ? AND k.referenced_table_name IS NOT NULL
ORDER BY k.table_name, k.constraint_name, k.ordinal_position`, listed)
	if err != nil {
		return nil, c.execError(ctx, err)
	}
	defer func() { _ = rows.Close() }()
	var folded engine.RelationRows
	for rows.Next() {
		var table, name, col, refSchema, refTable, refCol, onDelete, onUpdate string
		if err := rows.Scan(&table, &name, &col, &refSchema, &refTable, &refCol, &onDelete, &onUpdate); err != nil {
			return nil, c.execError(ctx, err)
		}
		if refSchema == listed {
			refSchema = ""
		}
		folded.Add(table, name, engine.ForeignKeyDef{
			ReferencedSchema: refSchema, ReferencedTable: refTable,
			OnDelete: engine.ParseReferentialAction(onDelete), OnUpdate: engine.ParseReferentialAction(onUpdate),
		}, col, refCol)
	}
	if err := rows.Err(); err != nil {
		return nil, c.execError(ctx, err)
	}
	return folded.Relations(), nil
}
