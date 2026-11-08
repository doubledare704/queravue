package mysql

import (
	"context"

	"github.com/doubledare704/queravue/core/internal/engine"
)

var _ engine.ColumnLister = (*Conn)(nil)

// ListColumns implements engine.ColumnLister.
func (c *Conn) ListColumns(ctx context.Context, database, schema string) ([]engine.ColumnRef, error) {
	conn, err := c.live("list columns")
	if err != nil {
		return nil, err
	}
	rows, err := conn.QueryContext(ctx,
		`SELECT table_name, column_name, column_type
FROM information_schema.columns
WHERE table_schema = ?
ORDER BY table_name, ordinal_position`, dbOf(database, schema))
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
