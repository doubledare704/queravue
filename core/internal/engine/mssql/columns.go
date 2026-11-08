package mssql

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
	db, err := c.pick(ctx, conn, database)
	if err != nil {
		return nil, err
	}
	if schema == "" {
		schema = "dbo"
	}
	//nolint:gosec // the only spliced parts are database names quoted by qdb
	rows, err := conn.QueryContext(ctx,
		`SELECT o.name, c.name, t.name
FROM `+qdb(db)+`.sys.columns c
JOIN `+qdb(db)+`.sys.objects o ON o.object_id = c.object_id
JOIN `+qdb(db)+`.sys.schemas s ON s.schema_id = o.schema_id
JOIN `+qdb(db)+`.sys.types t ON t.user_type_id = c.user_type_id
WHERE s.name = @p1 AND o.type IN ('U', 'V') AND o.is_ms_shipped = 0
ORDER BY o.name, c.column_id`, schema)
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
