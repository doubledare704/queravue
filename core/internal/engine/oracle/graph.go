package oracle

import (
	"context"

	"github.com/doubledare704/queravue/core/internal/engine"
)

var _ engine.RelationLister = (*Conn)(nil)

// ListKeyedColumns implements engine.RelationLister.
func (c *Conn) ListKeyedColumns(ctx context.Context, _, schema string) ([]engine.KeyedColumn, error) {
	conn, err := c.live("list keyed columns")
	if err != nil {
		return nil, err
	}
	owner, err := c.owner(ctx, conn, schema)
	if err != nil {
		return nil, err
	}
	rows, err := c.runner(conn).QueryContext(ctx, `SELECT c.table_name, c.column_name, c.data_type, c.nullable, NVL(pk.position, 0)
FROM all_tab_columns c
JOIN all_objects o ON o.owner = c.owner AND o.object_name = c.table_name AND o.object_type IN ('TABLE', 'VIEW', 'MATERIALIZED VIEW')
LEFT JOIN (
  SELECT cc.owner, cc.table_name, cc.column_name, cc.position
  FROM all_constraints k
  JOIN all_cons_columns cc ON cc.owner = k.owner AND cc.constraint_name = k.constraint_name
  WHERE k.owner = :1 AND k.constraint_type = 'P'
) pk ON pk.owner = c.owner AND pk.table_name = c.table_name AND pk.column_name = c.column_name
WHERE c.owner = :2 AND c.table_name NOT LIKE 'BIN$%'
ORDER BY c.table_name, c.column_id`, owner, owner)
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
		col.Nullable = nullable == "Y"
		out = append(out, col)
	}
	if err := rows.Err(); err != nil {
		return nil, c.execError(ctx, err)
	}
	return out, nil
}

// ListRelations implements engine.RelationLister.
func (c *Conn) ListRelations(ctx context.Context, _, schema string) ([]engine.TableRelation, error) {
	conn, err := c.live("list relations")
	if err != nil {
		return nil, err
	}
	owner, err := c.owner(ctx, conn, schema)
	if err != nil {
		return nil, err
	}
	rows, err := c.runner(conn).QueryContext(ctx, `SELECT c.table_name, c.constraint_name, cc.column_name, rc.owner, rc.table_name, rcc.column_name, c.delete_rule
FROM all_constraints c
JOIN all_cons_columns cc ON cc.owner = c.owner AND cc.constraint_name = c.constraint_name
JOIN all_constraints rc ON rc.owner = c.r_owner AND rc.constraint_name = c.r_constraint_name
JOIN all_cons_columns rcc ON rcc.owner = rc.owner AND rcc.constraint_name = rc.constraint_name AND rcc.position = cc.position
WHERE c.owner = :1 AND c.constraint_type = 'R'
ORDER BY c.table_name, c.constraint_name, cc.position`, owner)
	if err != nil {
		return nil, c.execError(ctx, err)
	}
	defer func() { _ = rows.Close() }()
	var folded engine.RelationRows
	for rows.Next() {
		var table, name, col, refOwner, refTable, refCol, onDelete string
		if err := rows.Scan(&table, &name, &col, &refOwner, &refTable, &refCol, &onDelete); err != nil {
			return nil, c.execError(ctx, err)
		}
		if refOwner == owner {
			refOwner = ""
		}
		folded.Add(table, name, engine.ForeignKeyDef{
			ReferencedSchema: refOwner, ReferencedTable: refTable,
			OnDelete: engine.ParseReferentialAction(onDelete),
		}, col, refCol)
	}
	if err := rows.Err(); err != nil {
		return nil, c.execError(ctx, err)
	}
	return folded.Relations(), nil
}
