package postgres

import (
	"context"

	"github.com/doubledare704/queravue/core/internal/engine"
)

var _ engine.ColumnLister = (*Conn)(nil)

// ListColumns implements engine.ColumnLister.
func (c *Conn) ListColumns(ctx context.Context, _, schema string) ([]engine.ColumnRef, error) {
	c.mu.Lock()
	conn := c.conn
	c.mu.Unlock()
	if conn == nil {
		return nil, &engine.Error{Kind: engine.KindConnectionLost, Engine: c.id, Op: "list columns", Msg: "connection is closed"}
	}
	if schema == "" {
		schema = "public"
	}
	rows, err := conn.Query(ctx, `SELECT c.relname, a.attname, format_type(a.atttypid, a.atttypmod)
FROM pg_attribute a
JOIN pg_class c ON c.oid = a.attrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = $1
  AND c.relkind IN ('r', 'p', 'v', 'm')
  AND a.attnum > 0
  AND NOT a.attisdropped
  AND left(a.attname, 13) <> 'crdb_internal_'
ORDER BY c.relname, a.attnum`, schema)
	if err != nil {
		return nil, c.execError(ctx, err)
	}
	defer rows.Close()
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
