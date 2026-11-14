package oracle

import (
	"context"

	"github.com/doubledare704/queravue/core/internal/engine"
)

var _ engine.ColumnLister = (*Conn)(nil)

// ListColumns implements engine.ColumnLister.
func (c *Conn) ListColumns(ctx context.Context, _, schema string) ([]engine.ColumnRef, error) {
	conn, err := c.live("list columns")
	if err != nil {
		return nil, err
	}
	owner, err := c.owner(ctx, conn, schema)
	if err != nil {
		return nil, err
	}
	rows, err := c.runner(conn).QueryContext(ctx, `SELECT c.table_name, c.column_name, c.data_type
FROM all_tab_columns c
JOIN all_objects o ON o.owner = c.owner AND o.object_name = c.table_name AND o.object_type IN ('TABLE', 'VIEW', 'MATERIALIZED VIEW')
WHERE c.owner = :1 AND c.table_name NOT LIKE 'BIN$%'
ORDER BY c.table_name, c.column_id`, owner)
	if err != nil {
		return nil, c.execError(ctx, err)
	}
	defer func() { _ = rows.Close() }()
	var out []engine.ColumnRef
	for rows.Next() {
		var ref engine.ColumnRef
		if err := rows.Scan(&ref.Table, &ref.Name, &ref.TypeName); err != nil {
			return nil, c.execError(ctx, err)
		}
		out = append(out, ref)
	}
	if err := rows.Err(); err != nil {
		return nil, c.execError(ctx, err)
	}
	return out, nil
}
