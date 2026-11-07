package mssql

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"

	"github.com/doubledare704/queravue/core/internal/engine"
)

var _ engine.SchemaInspector = (*Conn)(nil)

// qdb quotes a database name for use as a catalog prefix: [db].sys.objects.
func qdb(db string) string { return "[" + strings.ReplaceAll(db, "]", "]]") + "]" }

// currentDB returns the database the connection is in.
func (c *Conn) currentDB(ctx context.Context, conn *sql.Conn) (string, error) {
	var db string
	if err := conn.QueryRowContext(ctx, "SELECT DB_NAME()").Scan(&db); err != nil {
		return "", c.execError(ctx, err)
	}
	return db, nil
}

// pick returns database, or the connection's database when empty.
func (c *Conn) pick(ctx context.Context, conn *sql.Conn, database string) (string, error) {
	if database != "" {
		return database, nil
	}
	return c.currentDB(ctx, conn)
}

// ListDatabases implements engine.SchemaInspector. System databases are
// hidden unless the connection is in one.
func (c *Conn) ListDatabases(ctx context.Context) ([]string, error) {
	conn, err := c.live("list databases")
	if err != nil {
		return nil, err
	}
	rows, err := conn.QueryContext(ctx,
		`SELECT name FROM sys.databases
WHERE state = 0 AND HAS_DBACCESS(name) = 1 AND (database_id > 4 OR name = DB_NAME())
ORDER BY name`)
	if err != nil {
		return nil, c.execError(ctx, err)
	}
	return c.collectStrings(ctx, rows)
}

// ListSchemas implements engine.SchemaInspector.
func (c *Conn) ListSchemas(ctx context.Context, database string) ([]string, error) {
	conn, err := c.live("list schemas")
	if err != nil {
		return nil, err
	}
	db, err := c.pick(ctx, conn, database)
	if err != nil {
		return nil, err
	}
	// schema_id 2-4 are guest, INFORMATION_SCHEMA and sys; >= 16384 are the
	// fixed database role schemas (db_owner, ...).
	//nolint:gosec // the only spliced parts are database names quoted by qdb
	rows, err := conn.QueryContext(ctx,
		`SELECT name FROM `+qdb(db)+`.sys.schemas WHERE schema_id NOT IN (2, 3, 4) AND schema_id < 16384 ORDER BY name`)
	if err != nil {
		return nil, c.execError(ctx, err)
	}
	return c.collectStrings(ctx, rows)
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

// rowCountSQL returns a scalar subquery with the row estimate of the object
// whose object_id is alias.object_id. In the connection's own database it
// reads sys.dm_db_partition_stats (a DMV scoped to the current database);
// for other databases it falls back to sys.partitions.
func rowCountSQL(db string, current bool, alias string) string {
	if current {
		return `COALESCE((SELECT SUM(p.row_count) FROM sys.dm_db_partition_stats p WHERE p.object_id = ` + alias + `.object_id AND p.index_id IN (0, 1)), -1)`
	}
	return `COALESCE((SELECT SUM(p.rows) FROM ` + qdb(db) + `.sys.partitions p WHERE p.object_id = ` + alias + `.object_id AND p.index_id IN (0, 1)), -1)`
}

// ListObjects implements engine.SchemaInspector.
func (c *Conn) ListObjects(ctx context.Context, database, schema string) ([]engine.SchemaObject, error) {
	conn, err := c.live("list objects")
	if err != nil {
		return nil, err
	}
	cur, err := c.currentDB(ctx, conn)
	if err != nil {
		return nil, err
	}
	db := database
	if db == "" {
		db = cur
	}
	if schema == "" {
		schema = "dbo"
	}
	//nolint:gosec // the only spliced parts are database names quoted by qdb
	rows, err := conn.QueryContext(ctx,
		`SELECT o.name, o.type, CAST(`+rowCountSQL(db, strings.EqualFold(db, cur), "o")+` AS bigint)
FROM `+qdb(db)+`.sys.objects o
JOIN `+qdb(db)+`.sys.schemas s ON s.schema_id = o.schema_id
WHERE s.name = @p1 AND o.type IN ('U', 'V') AND o.is_ms_shipped = 0
ORDER BY o.name`, schema)
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
		if strings.TrimSpace(typ) == "V" {
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
	cur, err := c.currentDB(ctx, conn)
	if err != nil {
		return engine.TableDetails{}, err
	}
	db := database
	if db == "" {
		db = cur
	}
	if schema == "" {
		schema = "dbo"
	}
	d := qdb(db)
	details := engine.TableDetails{
		Database: database, Schema: schema, Table: table,
		Type: engine.ObjectTypeTable, EstimatedRows: -1,
	}

	var objectID int64
	var typ string
	var est int64
	err = conn.QueryRowContext(ctx,
		`SELECT o.object_id, o.type, CAST(`+rowCountSQL(db, strings.EqualFold(db, cur), "o")+` AS bigint)
FROM `+d+`.sys.objects o JOIN `+d+`.sys.schemas s ON s.schema_id = o.schema_id
WHERE s.name = @p1 AND o.name = @p2 AND o.type IN ('U', 'V')`, schema, table).Scan(&objectID, &typ, &est)
	if errors.Is(err, sql.ErrNoRows) {
		return details, &engine.Error{Kind: engine.KindNotFound, Engine: ID, Op: "describe table",
			Msg: fmt.Sprintf("table %q not found in schema %q", table, schema)}
	}
	if err != nil {
		return details, c.execError(ctx, err)
	}
	details.EstimatedRows = est
	if strings.TrimSpace(typ) == "V" {
		details.Type, details.EstimatedRows = engine.ObjectTypeView, -1
	}

	// Columns.
	//nolint:gosec // the only spliced parts are database names quoted by qdb
	crows, err := conn.QueryContext(ctx,
		`SELECT c.name, ty.name, c.max_length, c.precision, c.scale, c.is_nullable, dc.definition, c.is_identity, c.collation_name
FROM `+d+`.sys.columns c
JOIN `+d+`.sys.types ty ON ty.user_type_id = c.user_type_id
LEFT JOIN `+d+`.sys.default_constraints dc ON dc.object_id = c.default_object_id
WHERE c.object_id = @p1 ORDER BY c.column_id`, objectID)
	if err != nil {
		return details, c.execError(ctx, err)
	}
	notNull := map[string]bool{}
	for crows.Next() {
		var name, tyName string
		var maxLen, prec, scale int
		var nullable, identity bool
		var def, collation sql.NullString
		if err := crows.Scan(&name, &tyName, &maxLen, &prec, &scale, &nullable, &def, &identity, &collation); err != nil {
			_ = crows.Close()
			return details, c.execError(ctx, err)
		}
		cd := engine.ColumnDef{Name: name, TypeName: typeLabel(tyName, maxLen, prec, scale), Kind: kindOf(strings.ToUpper(tyName)), Nullable: nullable, Identity: identity}
		if collation.Valid {
			cd.Collation = &collation.String
		}
		if def.Valid {
			s := def.String
			cd.DefaultValue = &s
		}
		notNull[name] = !nullable
		details.Columns = append(details.Columns, cd)
	}
	err = crows.Err()
	_ = crows.Close()
	if err != nil {
		return details, c.execError(ctx, err)
	}

	// Indexes (key columns only; heaps have index_id 0 and are skipped).
	//nolint:gosec // the only spliced parts are database names quoted by qdb
	irows, err := conn.QueryContext(ctx,
		`SELECT i.name, i.is_unique, i.is_primary_key, ic.key_ordinal, c.name
FROM `+d+`.sys.indexes i
JOIN `+d+`.sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN `+d+`.sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
WHERE i.object_id = @p1 AND i.index_id > 0 AND ic.is_included_column = 0 AND ic.key_ordinal > 0
ORDER BY i.name, ic.key_ordinal`, objectID)
	if err != nil {
		return details, c.execError(ctx, err)
	}
	var cur2 *engine.IndexDef
	pkOrder := map[string]int{}
	for irows.Next() {
		var name, col string
		var unique, primary bool
		var ord int
		if err := irows.Scan(&name, &unique, &primary, &ord, &col); err != nil {
			_ = irows.Close()
			return details, c.execError(ctx, err)
		}
		if cur2 == nil || cur2.Name != name {
			details.Indexes = append(details.Indexes, engine.IndexDef{Name: name, IsUnique: unique, IsPrimary: primary})
			cur2 = &details.Indexes[len(details.Indexes)-1]
		}
		cur2.Columns = append(cur2.Columns, col)
		if primary {
			pkOrder[col] = ord
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
	//nolint:gosec // the only spliced parts are database names quoted by qdb
	frows, err := conn.QueryContext(ctx,
		`SELECT fk.name, pc.name, rs.name, rt.name, rc.name, fk.delete_referential_action_desc, fk.update_referential_action_desc
FROM `+d+`.sys.foreign_keys fk
JOIN `+d+`.sys.foreign_key_columns fkc ON fkc.constraint_object_id = fk.object_id
JOIN `+d+`.sys.columns pc ON pc.object_id = fkc.parent_object_id AND pc.column_id = fkc.parent_column_id
JOIN `+d+`.sys.tables rt ON rt.object_id = fk.referenced_object_id
JOIN `+d+`.sys.schemas rs ON rs.schema_id = rt.schema_id
JOIN `+d+`.sys.columns rc ON rc.object_id = fkc.referenced_object_id AND rc.column_id = fkc.referenced_column_id
WHERE fk.parent_object_id = @p1
ORDER BY fk.name, fkc.constraint_column_id`, objectID)
	if err != nil {
		return details, c.execError(ctx, err)
	}
	var fk *engine.ForeignKeyDef
	for frows.Next() {
		var name, col, refSchema, refTable, refCol, onDelete, onUpdate string
		if err := frows.Scan(&name, &col, &refSchema, &refTable, &refCol, &onDelete, &onUpdate); err != nil {
			_ = frows.Close()
			return details, c.execError(ctx, err)
		}
		if fk == nil || fk.Name != name {
			details.ForeignKeys = append(details.ForeignKeys, engine.ForeignKeyDef{
				Name: name, ReferencedSchema: refSchema, ReferencedTable: refTable,
				OnDelete: engine.ParseReferentialAction(onDelete), OnUpdate: engine.ParseReferentialAction(onUpdate),
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

// typeLabel renders a column type like SSMS: nvarchar(max), decimal(18,2).
func typeLabel(name string, maxLen, prec, scale int) string {
	switch strings.ToLower(name) {
	case "varchar", "varbinary", "char", "binary":
		if maxLen == -1 {
			return name + "(max)"
		}
		return fmt.Sprintf("%s(%d)", name, maxLen)
	case "nvarchar", "nchar":
		if maxLen == -1 {
			return name + "(max)"
		}
		return fmt.Sprintf("%s(%d)", name, maxLen/2)
	case "decimal", "numeric":
		return fmt.Sprintf("%s(%d,%d)", name, prec, scale)
	case "datetime2", "datetimeoffset", "time":
		return fmt.Sprintf("%s(%d)", name, scale)
	}
	return name
}
