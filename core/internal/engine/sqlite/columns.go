package sqlite

import (
	"context"
	"fmt"

	"github.com/doubledare704/queravue/core/internal/engine"
)

var _ engine.ColumnLister = (*Conn)(nil)

const listColumnsQuery = `SELECT m.name, p.name, p.type
FROM %s.sqlite_master m
JOIN pragma_table_info(m.name, ?) p
WHERE m.type IN ('table', 'view') AND m.name NOT LIKE 'sqlite_%%'
ORDER BY m.name, p.cid`

// ListColumns implements engine.ColumnLister.
func (c *Conn) ListColumns(ctx context.Context, database, schema string) ([]engine.ColumnRef, error) {
	target := schema
	if target == "" {
		target = database
	}
	if target == "" {
		target = "main"
	}
	query := fmt.Sprintf(listColumnsQuery, quoteIdent(target)) //nolint:gosec // query targets quoted identifier
	rows, err := c.db.QueryContext(ctx, query, target)
	if err != nil {
		return nil, classify("list columns", err)
	}
	defer func() { _ = rows.Close() }()
	var out []engine.ColumnRef
	for rows.Next() {
		var ref engine.ColumnRef
		if err := rows.Scan(&ref.Table, &ref.Name, &ref.TypeName); err != nil {
			return nil, classify("scan column", err)
		}
		out = append(out, ref)
	}
	if err := rows.Err(); err != nil {
		return nil, classify("list columns", err)
	}
	return out, nil
}
