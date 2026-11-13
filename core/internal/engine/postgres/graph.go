package postgres

import (
	"context"
	"strings"

	"github.com/jackc/pgx/v5"

	"github.com/doubledare704/queravue/core/internal/engine"
)

var _ engine.RelationLister = (*Conn)(nil)

const keyedColumnsQuery = `SELECT c.relname, a.attname, format_type(a.atttypid, a.atttypmod),
       NOT a.attnotnull,
       COALESCE(array_position(i.indkey, a.attnum), 0)
FROM pg_attribute a
JOIN pg_class c ON c.oid = a.attrelid
JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_index i ON i.indrelid = a.attrelid AND i.indisprimary
WHERE n.nspname = $1
  AND c.relkind IN ('r', 'p', 'v', 'm')
  AND a.attnum > 0
  AND NOT a.attisdropped
  AND left(a.attname, 13) <> 'crdb_internal_'
ORDER BY c.relname, a.attnum`

const relationsQuery = `SELECT cl.relname, con.conname,
       ARRAY(
         SELECT a.attname
         FROM unnest(con.conkey) WITH ORDINALITY AS u(attnum, ord)
         JOIN pg_attribute a ON a.attrelid = con.conrelid AND a.attnum = u.attnum
         ORDER BY u.ord
       ),
       ref_ns.nspname, ref_cl.relname,
       ARRAY(
         SELECT a.attname
         FROM unnest(con.confkey) WITH ORDINALITY AS u(attnum, ord)
         JOIN pg_attribute a ON a.attrelid = con.confrelid AND a.attnum = u.attnum
         ORDER BY u.ord
       ),
       con.confdeltype::text, con.confupdtype::text
FROM pg_constraint con
JOIN pg_class cl ON cl.oid = con.conrelid
JOIN pg_namespace n ON n.oid = cl.relnamespace
JOIN pg_class ref_cl ON ref_cl.oid = con.confrelid
JOIN pg_namespace ref_ns ON ref_ns.oid = ref_cl.relnamespace
WHERE n.nspname = $1 AND con.contype = 'f'
ORDER BY cl.relname, con.conname`

func (c *Conn) graphConn(op, schema string) (*pgx.Conn, string, error) {
	c.mu.Lock()
	conn := c.conn
	c.mu.Unlock()
	if conn == nil {
		return nil, "", &engine.Error{Kind: engine.KindConnectionLost, Engine: c.id, Op: op, Msg: "connection is closed"}
	}
	if schema == "" {
		schema = "public"
	}
	return conn, schema, nil
}

// ListKeyedColumns implements engine.RelationLister.
func (c *Conn) ListKeyedColumns(ctx context.Context, _, schema string) ([]engine.KeyedColumn, error) {
	conn, schema, err := c.graphConn("list keyed columns", schema)
	if err != nil {
		return nil, err
	}
	query := keyedColumnsQuery
	switch c.variant {
	case VariantPostgres:
		// indkey is indexed from 0 in PostgreSQL and from 1 in CockroachDB.
		query = strings.Replace(query, "array_position(i.indkey, a.attnum)", "array_position(i.indkey, a.attnum) + 1", 1)
	case VariantCockroach:
		// The hidden rowid of a table without a primary key is not a column.
		query = strings.Replace(query, "AND NOT a.attisdropped", "AND NOT a.attisdropped AND NOT a.attishidden", 1)
	}
	rows, err := conn.Query(ctx, query, schema)
	if err != nil {
		return nil, c.execError(ctx, err)
	}
	defer rows.Close()
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
func (c *Conn) ListRelations(ctx context.Context, _, schema string) ([]engine.TableRelation, error) {
	conn, schema, err := c.graphConn("list relations", schema)
	if err != nil {
		return nil, err
	}
	rows, err := conn.Query(ctx, relationsQuery, schema)
	if err != nil {
		return nil, c.execError(ctx, err)
	}
	defer rows.Close()
	var out []engine.TableRelation
	for rows.Next() {
		var rel engine.TableRelation
		var onDelete, onUpdate string
		if err := rows.Scan(&rel.Table, &rel.Name, &rel.Columns, &rel.ReferencedSchema, &rel.ReferencedTable,
			&rel.ReferencedColumns, &onDelete, &onUpdate); err != nil {
			return nil, c.execError(ctx, err)
		}
		rel.OnDelete, rel.OnUpdate = pgReferentialAction(onDelete), pgReferentialAction(onUpdate)
		if rel.ReferencedSchema == schema {
			rel.ReferencedSchema = ""
		}
		out = append(out, rel)
	}
	if err := rows.Err(); err != nil {
		return nil, c.execError(ctx, err)
	}
	return out, nil
}
