package mysql

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"

	"github.com/doubledare704/queravue/core/internal/engine"
)

var _ engine.SchemaInspector = (*Conn)(nil)

// MySQL has no schema level below a database: a "schema" is a database. Per
// ADR 0007 the tree is databases → one synthetic schema named like the
// database → objects, and tables are always addressed as `db`.`table`.

// systemSchemas are hidden from the database list.
const systemSchemasSQL = `('information_schema','mysql','performance_schema','sys','metrics_schema','inspection_schema')`

// ListDatabases implements engine.SchemaInspector.
func (c *Conn) ListDatabases(ctx context.Context) ([]string, error) {
	conn, err := c.live("list databases")
	if err != nil {
		return nil, err
	}
	rows, err := conn.QueryContext(ctx,
		`SELECT schema_name FROM information_schema.schemata WHERE LOWER(schema_name) NOT IN `+systemSchemasSQL+` ORDER BY schema_name`)
	if err != nil {
		return nil, c.execError(ctx, err)
	}
	return c.collectStrings(ctx, rows)
}

// ListSchemas implements engine.SchemaInspector. It returns the database
// itself as the only schema.
func (c *Conn) ListSchemas(_ context.Context, database string) ([]string, error) {
	if _, err := c.live("list schemas"); err != nil {
		return nil, err
	}
	if database == "" {
		return nil, nil
	}
	return []string{database}, nil
}

func (c *Conn) collectStrings(ctx context.Context, rows *sql.Rows) ([]string, error) {
	defer func() { _ = rows.Close() }()
	var out []string
	for rows.Next() {
		var s string
		if err := rows.Scan(&s); err != nil {
			return nil, c.execError(ctx, err)
		}
		out = append(out, s)
	}
	if err := rows.Err(); err != nil {
		return nil, c.execError(ctx, err)
	}
	return out, nil
}

// dbOf picks the database to inspect: the schema (== database) wins.
func dbOf(database, schema string) string {
	if schema != "" {
		return schema
	}
	return database
}

// ListObjects implements engine.SchemaInspector. Row estimates come from
// information_schema.tables.table_rows (exact for MyISAM, an InnoDB estimate
// otherwise; TiDB reports its statistics).
func (c *Conn) ListObjects(ctx context.Context, database, schema string) ([]engine.SchemaObject, error) {
	conn, err := c.live("list objects")
	if err != nil {
		return nil, err
	}
	rows, err := conn.QueryContext(ctx,
		`SELECT table_name, table_type, CAST(COALESCE(table_rows, -1) AS SIGNED)
FROM information_schema.tables
WHERE table_schema = ? AND table_type IN ('BASE TABLE','VIEW')
ORDER BY table_name`, dbOf(database, schema))
	if err != nil {
		return nil, c.execError(ctx, err)
	}
	defer func() { _ = rows.Close() }()
	var objs []engine.SchemaObject
	for rows.Next() {
		var name, typ string
		var est int64
		if err := rows.Scan(&name, &typ, &est); err != nil {
			return nil, c.execError(ctx, err)
		}
		o := engine.SchemaObject{Name: name, Type: engine.ObjectTypeTable, EstimatedRows: est}
		if typ == "VIEW" {
			o.Type, o.EstimatedRows = engine.ObjectTypeView, -1
		}
		objs = append(objs, o)
	}
	if err := rows.Err(); err != nil {
		return nil, c.execError(ctx, err)
	}
	return objs, nil
}

// DescribeTable implements engine.SchemaInspector.
func (c *Conn) DescribeTable(ctx context.Context, database, schema, table string) (engine.TableDetails, error) {
	conn, err := c.live("describe table")
	if err != nil {
		return engine.TableDetails{}, err
	}
	db := dbOf(database, schema)
	details := engine.TableDetails{
		Database: database, Schema: schema, Table: table,
		Type: engine.ObjectTypeTable, EstimatedRows: -1,
	}

	var typ string
	var est int64
	err = conn.QueryRowContext(ctx,
		`SELECT table_type, CAST(COALESCE(table_rows, -1) AS SIGNED)
FROM information_schema.tables WHERE table_schema = ? AND table_name = ?`, db, table).Scan(&typ, &est)
	if errors.Is(err, sql.ErrNoRows) {
		return details, &engine.Error{Kind: engine.KindNotFound, Engine: c.id, Op: "describe table",
			Msg: fmt.Sprintf("table %q not found in database %q", table, db)}
	}
	if err != nil {
		return details, c.execError(ctx, err)
	}
	details.EstimatedRows = est
	if strings.Contains(typ, "VIEW") {
		details.Type, details.EstimatedRows = engine.ObjectTypeView, -1
	}

	// Columns.
	crows, err := conn.QueryContext(ctx,
		`SELECT column_name, column_type, data_type, is_nullable, column_default
FROM information_schema.columns WHERE table_schema = ? AND table_name = ? ORDER BY ordinal_position`, db, table)
	if err != nil {
		return details, c.execError(ctx, err)
	}
	notNull := map[string]bool{}
	for crows.Next() {
		var name, colType, dataType, nullable string
		var def sql.NullString
		if err := crows.Scan(&name, &colType, &dataType, &nullable, &def); err != nil {
			_ = crows.Close()
			return details, c.execError(ctx, err)
		}
		cd := engine.ColumnDef{Name: name, TypeName: colType, Kind: columnKind(dataType, colType), Nullable: nullable == "YES"}
		if def.Valid {
			d := def.String
			cd.DefaultValue = &d
		}
		notNull[name] = !cd.Nullable
		details.Columns = append(details.Columns, cd)
	}
	err = crows.Err()
	_ = crows.Close()
	if err != nil {
		return details, c.execError(ctx, err)
	}

	// Indexes (also gives the primary key and its column order).
	irows, err := conn.QueryContext(ctx,
		`SELECT index_name, non_unique, seq_in_index, column_name
FROM information_schema.statistics WHERE table_schema = ? AND table_name = ?
ORDER BY index_name, seq_in_index`, db, table)
	if err != nil {
		return details, c.execError(ctx, err)
	}
	var cur *engine.IndexDef
	pkOrder := map[string]int{}
	for irows.Next() {
		var name string
		var nonUnique, seq int
		var col sql.NullString
		if err := irows.Scan(&name, &nonUnique, &seq, &col); err != nil {
			_ = irows.Close()
			return details, c.execError(ctx, err)
		}
		if cur == nil || cur.Name != name {
			details.Indexes = append(details.Indexes, engine.IndexDef{
				Name: name, IsUnique: nonUnique == 0, IsPrimary: name == "PRIMARY",
			})
			cur = &details.Indexes[len(details.Indexes)-1]
		}
		if col.Valid { // NULL for functional index parts
			cur.Columns = append(cur.Columns, col.String)
			if cur.IsPrimary {
				pkOrder[col.String] = seq
			}
		}
	}
	err = irows.Err()
	_ = irows.Close()
	if err != nil {
		return details, c.execError(ctx, err)
	}
	hasPK := len(pkOrder) > 0
	for i := range details.Columns {
		if o, ok := pkOrder[details.Columns[i].Name]; ok {
			details.Columns[i].IsPrimaryKey, details.Columns[i].PrimaryKeyOrder = true, o
		}
	}

	// Foreign keys.
	frows, err := conn.QueryContext(ctx,
		`SELECT constraint_name, column_name, referenced_table_schema, referenced_table_name, referenced_column_name
FROM information_schema.key_column_usage
WHERE table_schema = ? AND table_name = ? AND referenced_table_name IS NOT NULL
ORDER BY constraint_name, ordinal_position`, db, table)
	if err != nil {
		return details, c.execError(ctx, err)
	}
	var fk *engine.ForeignKeyDef
	for frows.Next() {
		var name, col, refSchema, refTable, refCol string
		if err := frows.Scan(&name, &col, &refSchema, &refTable, &refCol); err != nil {
			_ = frows.Close()
			return details, c.execError(ctx, err)
		}
		if fk == nil || fk.Name != name {
			details.ForeignKeys = append(details.ForeignKeys, engine.ForeignKeyDef{
				Name: name, ReferencedSchema: refSchema, ReferencedTable: refTable,
			})
			fk = &details.ForeignKeys[len(details.ForeignKeys)-1]
		}
		fk.Columns = append(fk.Columns, col)
		fk.ReferencedColumns = append(fk.ReferencedColumns, refCol)
	}
	err = frows.Err()
	_ = frows.Close()
	if err != nil {
		return details, c.execError(ctx, err)
	}

	// Editability.
	switch {
	case details.Type == engine.ObjectTypeView:
		details.EditDisabledReason = "Views are read-only."
	case hasPK:
		details.CanEdit = true
	default:
		for _, idx := range details.Indexes {
			if !idx.IsUnique || len(idx.Columns) == 0 {
				continue
			}
			all := true
			for _, col := range idx.Columns {
				all = all && notNull[col]
			}
			if all {
				details.CanEdit = true
				break
			}
		}
		if !details.CanEdit {
			details.EditDisabledReason = "Table has no primary key or unique NOT NULL column. Edits are disabled."
		}
	}
	return details, nil
}

// columnKind maps information_schema data_type/column_type to a value kind.
// It matches kindOf for result columns, except that tinyint(1) is boolean.
func columnKind(dataType, columnType string) engine.ValueKind {
	dt := strings.ToLower(dataType)
	if dt == "tinyint" && strings.HasPrefix(strings.ToLower(columnType), "tinyint(1)") {
		return engine.VBool
	}
	return kindOf(dt)
}
