package mssql

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
	db, err := c.pick(ctx, conn, database)
	if err != nil {
		return nil, err
	}
	if schema == "" {
		schema = "dbo"
	}
	d := qdb(db)
	//nolint:gosec // the only spliced parts are database names quoted by qdb
	rows, err := conn.QueryContext(ctx,
		`SELECT o.name, c.name, t.name, c.is_nullable, COALESCE(pk.key_ordinal, 0)
FROM `+d+`.sys.columns c
JOIN `+d+`.sys.objects o ON o.object_id = c.object_id
JOIN `+d+`.sys.schemas s ON s.schema_id = o.schema_id
JOIN `+d+`.sys.types t ON t.user_type_id = c.user_type_id
LEFT JOIN (
  SELECT ic.object_id, ic.column_id, ic.key_ordinal
  FROM `+d+`.sys.indexes i
  JOIN `+d+`.sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
  WHERE i.is_primary_key = 1
) pk ON pk.object_id = c.object_id AND pk.column_id = c.column_id
WHERE s.name = @p1 AND o.type IN ('U', 'V') AND o.is_ms_shipped = 0
ORDER BY o.name, c.column_id`, schema)
	if err != nil {
		return nil, c.execError(ctx, err)
	}
	defer func() { _ = rows.Close() }()
	var out []engine.KeyedColumn
	for rows.Next() {
		var col engine.KeyedColumn
		if err := rows.Scan(&col.Table, &col.Name, &col.TypeName, &col.Nullable, &col.PrimaryKeyOrder); err != nil {
			return nil, c.execError(ctx, err)
		}
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
	db, err := c.pick(ctx, conn, database)
	if err != nil {
		return nil, err
	}
	if schema == "" {
		schema = "dbo"
	}
	d := qdb(db)
	//nolint:gosec // the only spliced parts are database names quoted by qdb
	rows, err := conn.QueryContext(ctx,
		`SELECT pt.name, fk.name, pc.name, rs.name, rt.name, rc.name,
       fk.delete_referential_action_desc, fk.update_referential_action_desc
FROM `+d+`.sys.foreign_keys fk
JOIN `+d+`.sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
JOIN `+d+`.sys.tables pt ON pt.object_id = fk.parent_object_id
JOIN `+d+`.sys.schemas ps ON ps.schema_id = pt.schema_id
JOIN `+d+`.sys.columns pc ON pc.object_id = fkc.parent_object_id AND pc.column_id = fkc.parent_column_id
JOIN `+d+`.sys.tables rt ON rt.object_id = fk.referenced_object_id
JOIN `+d+`.sys.schemas rs ON rs.schema_id = rt.schema_id
JOIN `+d+`.sys.columns rc ON rc.object_id = fkc.referenced_object_id AND rc.column_id = fkc.referenced_column_id
WHERE ps.name = @p1
ORDER BY pt.name, fk.name, fkc.constraint_column_id`, schema)
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
