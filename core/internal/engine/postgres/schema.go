package postgres

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"github.com/jackc/pgx/v5"

	"github.com/doubledare704/queravue/core/internal/engine"
)

var _ engine.SchemaInspector = (*Conn)(nil)

// ListDatabases implements engine.SchemaInspector.
func (c *Conn) ListDatabases(ctx context.Context) ([]string, error) {
	c.mu.Lock()
	conn := c.conn
	c.mu.Unlock()
	if conn == nil {
		return nil, &engine.Error{Kind: engine.KindConnectionLost, Engine: c.id, Op: "list databases", Msg: "connection is closed"}
	}

	query := `SELECT datname FROM pg_database WHERE datistemplate = false ORDER BY datname;`
	rows, err := conn.Query(ctx, query)
	if err != nil {
		return nil, c.execError(ctx, err)
	}
	defer rows.Close()

	var dbs []string
	for rows.Next() {
		var name string
		if err := rows.Scan(&name); err != nil {
			return nil, c.execError(ctx, err)
		}
		dbs = append(dbs, name)
	}
	if err := rows.Err(); err != nil {
		return nil, c.execError(ctx, err)
	}
	return dbs, nil
}

// ListSchemas implements engine.SchemaInspector.
func (c *Conn) ListSchemas(ctx context.Context, _ string) ([]string, error) {
	c.mu.Lock()
	conn := c.conn
	c.mu.Unlock()
	if conn == nil {
		return nil, &engine.Error{Kind: engine.KindConnectionLost, Engine: c.id, Op: "list schemas", Msg: "connection is closed"}
	}

	query := `SELECT nspname FROM pg_namespace 
WHERE nspname NOT IN ('pg_toast', 'pg_catalog', 'information_schema') 
  AND nspname NOT LIKE 'pg_temp_%' 
  AND nspname NOT LIKE 'pg_toast_temp_%' 
ORDER BY nspname;`
	rows, err := conn.Query(ctx, query)
	if err != nil {
		return nil, c.execError(ctx, err)
	}
	defer rows.Close()

	var schemas []string
	for rows.Next() {
		var name string
		if err := rows.Scan(&name); err != nil {
			return nil, c.execError(ctx, err)
		}
		schemas = append(schemas, name)
	}
	if err := rows.Err(); err != nil {
		return nil, c.execError(ctx, err)
	}
	return schemas, nil
}

// ListObjects implements engine.SchemaInspector.
func (c *Conn) ListObjects(ctx context.Context, _, schema string) ([]engine.SchemaObject, error) {
	c.mu.Lock()
	conn := c.conn
	c.mu.Unlock()
	if conn == nil {
		return nil, &engine.Error{Kind: engine.KindConnectionLost, Engine: c.id, Op: "list objects", Msg: "connection is closed"}
	}

	if schema == "" {
		schema = "public"
	}

	query := `SELECT c.relname,
       c.relkind,
       CASE 
         WHEN c.relkind = 'v' THEN -1
         ELSE COALESCE(GREATEST(c.reltuples::bigint, 0), 0)
       END AS est_rows
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = $1
  AND c.relkind IN ('r', 'p', 'v', 'm')
ORDER BY c.relname;`

	rows, err := conn.Query(ctx, c.forVariant(query), schema)
	if err != nil {
		return nil, c.execError(ctx, err)
	}
	defer rows.Close()

	var objs []engine.SchemaObject
	for rows.Next() {
		var name string
		var relkind byte
		var estRows int64

		if err := rows.Scan(&name, &relkind, &estRows); err != nil {
			return nil, c.execError(ctx, err)
		}

		t := engine.ObjectTypeTable
		switch relkind {
		case 'v':
			t = engine.ObjectTypeView
		case 'm':
			t = engine.ObjectTypeMaterializedView
		}

		objs = append(objs, engine.SchemaObject{
			Name:          name,
			Type:          t,
			EstimatedRows: estRows,
		})
	}
	if err := rows.Err(); err != nil {
		return nil, c.execError(ctx, err)
	}
	return objs, nil
}

// DescribeTable implements engine.SchemaInspector.
func (c *Conn) DescribeTable(ctx context.Context, database, schema, table string) (engine.TableDetails, error) {
	c.mu.Lock()
	conn := c.conn
	c.mu.Unlock()
	if conn == nil {
		return engine.TableDetails{}, &engine.Error{Kind: engine.KindConnectionLost, Engine: c.id, Op: "describe table", Msg: "connection is closed"}
	}

	if schema == "" {
		schema = "public"
	}

	details := engine.TableDetails{
		Database:      database,
		Schema:        schema,
		Table:         table,
		Type:          engine.ObjectTypeTable,
		EstimatedRows: -1,
	}

	// 1. Get relation OID, relkind, and row estimate
	var relOID uint32
	var relkind byte
	var estRows int64
	relQuery := `SELECT c.oid, c.relkind,
       CASE 
         WHEN c.relkind = 'v' THEN -1
         ELSE COALESCE(GREATEST(c.reltuples::bigint, 0), 0)
       END AS est_rows
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = $1 AND c.relname = $2;`

	err := conn.QueryRow(ctx, c.forVariant(relQuery), schema, table).Scan(&relOID, &relkind, &estRows)
	if err != nil {
		if errors.Is(err, pgx.ErrNoRows) {
			return details, &engine.Error{Kind: engine.KindNotFound, Engine: c.id, Op: "describe table", Msg: fmt.Sprintf("table %q not found in schema %q", table, schema)}
		}
		return details, c.execError(ctx, err)
	}

	details.EstimatedRows = estRows
	switch relkind {
	case 'v':
		details.Type = engine.ObjectTypeView
	case 'm':
		details.Type = engine.ObjectTypeMaterializedView
	default:
		details.Type = engine.ObjectTypeTable
	}

	// 2. Query columns
	colQuery := `SELECT a.attname,
       format_type(a.atttypid, a.atttypmod) AS full_type,
       t.typname,
       t.oid,
       NOT a.attnotnull AS is_nullable,
       pg_get_expr(ad.adbin, ad.adrelid) AS default_val,
       COALESCE(i.indisprimary AND (a.attnum = ANY(i.indkey)), false) AS is_pk,
       COALESCE(array_position(i.indkey, a.attnum), 0) AS pk_pos,
       COALESCE(a.attidentity::text, '') <> '' AS is_identity,
       CASE WHEN a.attcollation <> 0 AND a.attcollation <> t.typcollation
            THEN (SELECT collname FROM pg_collation WHERE oid = a.attcollation) END AS collation
FROM pg_attribute a
JOIN pg_type t ON t.oid = a.atttypid
LEFT JOIN pg_attrdef ad ON ad.adrelid = a.attrelid AND ad.adnum = a.attnum
LEFT JOIN pg_index i ON i.indrelid = a.attrelid AND i.indisprimary
WHERE a.attrelid = $1 AND a.attnum > 0 AND NOT a.attisdropped%s
ORDER BY a.attnum;`
	// CockroachDB gives tables without a primary key a hidden rowid column
	// that SELECT * does not return; it must not count as a key.
	hidden := ""
	if c.variant == VariantCockroach {
		hidden = " AND NOT a.attishidden"
	}
	colQuery = fmt.Sprintf(colQuery, hidden)
	if c.variant == VariantPostgres {
		// indkey is an int2vector, indexed from 0 in PostgreSQL (from 1 in
		// CockroachDB), so array_position is one short of the 1-based order.
		colQuery = strings.Replace(colQuery, "COALESCE(array_position(i.indkey, a.attnum), 0)",
			"COALESCE(array_position(i.indkey, a.attnum) + 1, 0)", 1)
	}

	colRows, err := conn.Query(ctx, colQuery, relOID)
	if err != nil {
		return details, c.execError(ctx, err)
	}
	defer colRows.Close()

	hasPK := false
	notNullCols := make(map[string]bool)

	for colRows.Next() {
		var name, fullType, rawType string
		var typeOID uint32
		var nullable, isPK bool
		var defaultVal *string
		var pkPos int
		var identity bool
		var collation *string

		if err := colRows.Scan(&name, &fullType, &rawType, &typeOID, &nullable, &defaultVal, &isPK, &pkPos, &identity, &collation); err != nil {
			return details, c.execError(ctx, err)
		}

		if isPK {
			hasPK = true
		}
		if !nullable {
			notNullCols[name] = true
		}

		details.Columns = append(details.Columns, engine.ColumnDef{
			Name:            name,
			TypeName:        fullType,
			Kind:            kindOf(typeOID),
			Nullable:        nullable,
			DefaultValue:    defaultVal,
			IsPrimaryKey:    isPK,
			PrimaryKeyOrder: pkPos,
			Identity:        identity,
			Collation:       collation,
		})
	}
	if err := colRows.Err(); err != nil {
		return details, c.execError(ctx, err)
	}

	// 3. Query indexes
	idxQuery := `SELECT c2.relname AS index_name,
       i.indisunique,
       i.indisprimary,
       ARRAY(
         SELECT pg_get_indexdef(i.indexrelid, k + 1, true)
         FROM generate_subscripts(i.indkey, 1) as k
         ORDER BY k
       ) AS index_columns
FROM pg_index i
JOIN pg_class c2 ON c2.oid = i.indexrelid
WHERE i.indrelid = $1
ORDER BY c2.relname;`

	idxRows, err := conn.Query(ctx, idxQuery, relOID)
	if err == nil {
		defer idxRows.Close()
		for idxRows.Next() {
			var name string
			var isUnique, isPrimary bool
			var columns []string
			if err := idxRows.Scan(&name, &isUnique, &isPrimary, &columns); err == nil {
				if c.variant == VariantCockroach && isPrimary && !allVisible(columns, details.Columns) {
					continue // implicit rowid primary key
				}
				details.Indexes = append(details.Indexes, engine.IndexDef{
					Name:      name,
					Columns:   columns,
					IsUnique:  isUnique,
					IsPrimary: isPrimary,
				})
			}
		}
	}

	// 4. Query foreign keys
	fkQuery := `SELECT con.conname,
       ARRAY(
         SELECT a.attname
         FROM unnest(con.conkey) WITH ORDINALITY AS u(attnum, ord)
         JOIN pg_attribute a ON a.attrelid = con.conrelid AND a.attnum = u.attnum
         ORDER BY u.ord
       ) AS src_cols,
       ref_ns.nspname AS ref_schema,
       ref_cl.relname AS ref_table,
       ARRAY(
         SELECT a.attname
         FROM unnest(con.confkey) WITH ORDINALITY AS u(attnum, ord)
         JOIN pg_attribute a ON a.attrelid = con.confrelid AND a.attnum = u.attnum
         ORDER BY u.ord
       ) AS ref_cols,
       con.confdeltype::text, con.confupdtype::text
FROM pg_constraint con
JOIN pg_class ref_cl ON ref_cl.oid = con.confrelid
JOIN pg_namespace ref_ns ON ref_ns.oid = ref_cl.relnamespace
WHERE con.conrelid = $1 AND con.contype = 'f'
ORDER BY con.conname;`

	fkRows, err := conn.Query(ctx, fkQuery, relOID)
	if err == nil {
		defer fkRows.Close()
		for fkRows.Next() {
			var name, refSchema, refTable string
			var srcCols, refCols []string
			var onDelete, onUpdate string
			if err := fkRows.Scan(&name, &srcCols, &refSchema, &refTable, &refCols, &onDelete, &onUpdate); err == nil {
				details.ForeignKeys = append(details.ForeignKeys, engine.ForeignKeyDef{
					Name:              name,
					Columns:           srcCols,
					ReferencedSchema:  refSchema,
					ReferencedTable:   refTable,
					ReferencedColumns: refCols,
					OnDelete:          pgReferentialAction(onDelete),
					OnUpdate:          pgReferentialAction(onUpdate),
				})
			}
		}
	}

	// 5. Determine editability
	switch {
	case details.Type == engine.ObjectTypeView || details.Type == engine.ObjectTypeMaterializedView:
		details.CanEdit = false
		details.EditDisabledReason = "Views and materialized views are read-only."
	case hasPK:
		details.CanEdit = true
	default:
		hasUniqueNotNull := false
		for _, idx := range details.Indexes {
			if idx.IsUnique && len(idx.Columns) > 0 {
				allNotNull := true
				for _, c := range idx.Columns {
					if !notNullCols[c] {
						allNotNull = false
						break
					}
				}
				if allNotNull {
					hasUniqueNotNull = true
					break
				}
			}
		}
		if hasUniqueNotNull {
			details.CanEdit = true
		} else {
			details.CanEdit = false
			details.EditDisabledReason = "Table has no primary key or unique NOT NULL column. Edits are disabled."
		}
	}

	return details, nil
}

// forVariant adapts catalog queries to the server variant. CockroachDB does
// not maintain pg_class.reltuples; its row estimates come from table
// statistics (0 until statistics exist).
func (c *Conn) forVariant(query string) string {
	if c.variant != VariantCockroach {
		return query
	}
	return strings.ReplaceAll(query, "c.reltuples::bigint",
		"COALESCE((SELECT s.estimated_row_count FROM crdb_internal.table_row_statistics s WHERE s.table_id = c.oid::int), 0)")
}

// allVisible reports whether every index column is a listed (visible) column.
func allVisible(indexCols []string, cols []engine.ColumnDef) bool {
	for _, ic := range indexCols {
		found := false
		for _, cd := range cols {
			if cd.Name == ic {
				found = true
				break
			}
		}
		if !found {
			return false
		}
	}
	return true
}

func pgReferentialAction(code string) engine.ReferentialAction {
	switch code {
	case "a":
		return engine.ReferentialNoAction
	case "r":
		return engine.ReferentialRestrict
	case "c":
		return engine.ReferentialCascade
	case "n":
		return engine.ReferentialSetNull
	case "d":
		return engine.ReferentialSetDefault
	}
	return engine.ReferentialDefault
}
