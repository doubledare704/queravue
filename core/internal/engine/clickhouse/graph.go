package clickhouse

import (
	"context"

	"github.com/doubledare704/queravue/core/internal/engine"
)

var (
	_ engine.RelationLister = (*Conn)(nil)
	_ engine.ColumnLister   = (*Conn)(nil)
)

const listColumnsSQL = `SELECT c.table, c.name, c.type, t.primary_key
FROM system.columns c
JOIN system.tables t ON t.database = c.database AND t.name = c.table
WHERE c.database = ? AND NOT startsWith(c.table, ?)
ORDER BY c.table, c.position`

// ListKeyedColumns implements engine.RelationLister.
func (c *Conn) ListKeyedColumns(ctx context.Context, database, schema string) ([]engine.KeyedColumn, error) {
	db, err := c.live("list keyed columns")
	if err != nil {
		return nil, err
	}
	rows, err := db.QueryContext(ctx, listColumnsSQL, c.databaseOf(database, schema), innerTablePrefix)
	if err != nil {
		return nil, c.execError(ctx, err)
	}
	defer func() { _ = rows.Close() }()
	var out []engine.KeyedColumn
	orders := map[string]map[string]int{}
	for rows.Next() {
		var col engine.KeyedColumn
		var primaryKey string
		if err := rows.Scan(&col.Table, &col.Name, &col.TypeName, &primaryKey); err != nil {
			return nil, c.execError(ctx, err)
		}
		if _, ok := orders[col.Table]; !ok {
			orders[col.Table] = keyColumnOrder(primaryKey)
		}
		col.Nullable = isNullable(col.TypeName)
		col.PrimaryKeyOrder = orders[col.Table][col.Name]
		out = append(out, col)
	}
	if err := rows.Err(); err != nil {
		return nil, c.execError(ctx, err)
	}
	return out, nil
}

// ListRelations implements engine.RelationLister. ClickHouse has no foreign keys.
func (c *Conn) ListRelations(context.Context, string, string) ([]engine.TableRelation, error) {
	if _, err := c.live("list relations"); err != nil {
		return nil, err
	}
	return nil, nil
}

// ListColumns implements engine.ColumnLister.
func (c *Conn) ListColumns(ctx context.Context, database, schema string) ([]engine.ColumnRef, error) {
	db, err := c.live("list columns")
	if err != nil {
		return nil, err
	}
	rows, err := db.QueryContext(ctx,
		`SELECT table, name, type FROM system.columns WHERE database = ? AND NOT startsWith(table, ?) ORDER BY table, position`,
		c.databaseOf(database, schema), innerTablePrefix)
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
