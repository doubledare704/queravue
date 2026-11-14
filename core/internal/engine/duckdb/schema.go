//go:build duckdb

package duckdb

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"slices"
	"strings"

	"github.com/doubledare704/queravue/core/internal/engine"
)

var _ engine.SchemaInspector = (*Conn)(nil)

const scopeClause = `database_name = COALESCE(NULLIF(?, ''), current_database()) AND schema_name = COALESCE(NULLIF(?, ''), 'main')`

const (
	listDatabasesSQL = `SELECT database_name FROM duckdb_databases() WHERE NOT internal ORDER BY database_name`
	listSchemasSQL   = `SELECT schema_name FROM duckdb_schemas()
WHERE database_name = COALESCE(NULLIF(?, ''), current_database()) AND schema_name NOT IN ('information_schema', 'pg_catalog')
ORDER BY schema_name`
	listObjectsSQL = `SELECT table_name, 'table', estimated_size FROM duckdb_tables() WHERE ` + scopeClause + ` AND NOT internal
UNION ALL
SELECT view_name, 'view', -1 FROM duckdb_views() WHERE ` + scopeClause + ` AND NOT internal
ORDER BY 1`
	objectTypeSQL = `SELECT 'table', estimated_size FROM duckdb_tables() WHERE ` + scopeClause + ` AND table_name = ?
UNION ALL
SELECT 'view', -1 FROM duckdb_views() WHERE ` + scopeClause + ` AND view_name = ?`
	describeColumnsSQL = `SELECT column_name, data_type, is_nullable, column_default
FROM duckdb_columns() WHERE ` + scopeClause + ` AND table_name = ? ORDER BY column_index`
	describeConstraintsSQL = `SELECT constraint_type, constraint_name, constraint_column_names, referenced_table, referenced_column_names
FROM duckdb_constraints() WHERE ` + scopeClause + ` AND table_name = ? AND constraint_type IN ('PRIMARY KEY', 'UNIQUE', 'FOREIGN KEY')
ORDER BY constraint_index`
	describeIndexesSQL = `SELECT index_name, is_unique, sql FROM duckdb_indexes() WHERE ` + scopeClause + ` AND table_name = ? ORDER BY index_name`
)

// ListDatabases implements engine.SchemaInspector. A DuckDB database is a
// catalog: the opened file plus every ATTACHed one.
func (c *Conn) ListDatabases(ctx context.Context) ([]string, error) {
	return c.listStrings(ctx, "list databases", listDatabasesSQL)
}

// ListSchemas implements engine.SchemaInspector.
func (c *Conn) ListSchemas(ctx context.Context, database string) ([]string, error) {
	return c.listStrings(ctx, "list schemas", listSchemasSQL, database)
}

func (c *Conn) listStrings(ctx context.Context, op, query string, args ...any) ([]string, error) {
	meta, err := c.metaPool(op)
	if err != nil {
		return nil, err
	}
	rows, err := meta.QueryContext(ctx, query, args...)
	if err != nil {
		return nil, classify(op, err)
	}
	defer func() { _ = rows.Close() }()
	var out []string
	for rows.Next() {
		var s string
		if err := rows.Scan(&s); err != nil {
			return nil, classify(op, err)
		}
		out = append(out, s)
	}
	if err := rows.Err(); err != nil {
		return nil, classify(op, err)
	}
	return out, nil
}

// ListObjects implements engine.SchemaInspector.
func (c *Conn) ListObjects(ctx context.Context, database, schema string) ([]engine.SchemaObject, error) {
	meta, err := c.metaPool("list objects")
	if err != nil {
		return nil, err
	}
	rows, err := meta.QueryContext(ctx, listObjectsSQL, database, schema, database, schema)
	if err != nil {
		return nil, classify("list objects", err)
	}
	defer func() { _ = rows.Close() }()
	var out []engine.SchemaObject
	for rows.Next() {
		var name, kind string
		var estimated int64
		if err := rows.Scan(&name, &kind, &estimated); err != nil {
			return nil, classify("list objects", err)
		}
		object := engine.SchemaObject{Name: name, Type: engine.ObjectTypeTable, EstimatedRows: estimated}
		if kind == "view" {
			object.Type = engine.ObjectTypeView
		}
		out = append(out, object)
	}
	if err := rows.Err(); err != nil {
		return nil, classify("list objects", err)
	}
	return out, nil
}

// DescribeTable implements engine.SchemaInspector.
func (c *Conn) DescribeTable(ctx context.Context, database, schema, table string) (engine.TableDetails, error) {
	meta, err := c.metaPool("describe table")
	if err != nil {
		return engine.TableDetails{}, err
	}
	if schema == "" {
		schema = "main"
	}
	details := engine.TableDetails{Database: database, Schema: schema, Table: table, Type: engine.ObjectTypeTable, EstimatedRows: -1}

	var kind string
	err = meta.QueryRowContext(ctx, objectTypeSQL, database, schema, table, database, schema, table).Scan(&kind, &details.EstimatedRows)
	if errors.Is(err, sql.ErrNoRows) {
		return details, &engine.Error{Kind: engine.KindNotFound, Engine: ID, Op: "describe table", Msg: fmt.Sprintf("table %q not found", table)}
	}
	if err != nil {
		return details, classify("describe table", err)
	}
	if kind == "view" {
		details.Type = engine.ObjectTypeView
	}
	if err := c.describeColumns(ctx, meta, &details, database); err != nil {
		return details, err
	}
	if details.Type == engine.ObjectTypeTable {
		if err := c.describeConstraints(ctx, meta, &details, database); err != nil {
			return details, err
		}
		if err := c.describeIndexes(ctx, meta, &details, database); err != nil {
			return details, err
		}
	}
	setEditability(&details)
	return details, nil
}

func (c *Conn) describeColumns(ctx context.Context, meta *sql.DB, details *engine.TableDetails, database string) error {
	rows, err := meta.QueryContext(ctx, describeColumnsSQL, database, details.Schema, details.Table)
	if err != nil {
		return classify("describe columns", err)
	}
	defer func() { _ = rows.Close() }()
	for rows.Next() {
		var name, typeName string
		var nullable bool
		var dflt sql.NullString
		if err := rows.Scan(&name, &typeName, &nullable, &dflt); err != nil {
			return classify("describe columns", err)
		}
		col := engine.ColumnDef{Name: name, TypeName: typeName, Kind: kindOfType(typeName), Nullable: nullable}
		if dflt.Valid {
			col.DefaultValue = &dflt.String
			col.Identity = isIdentity(dflt.String)
		}
		details.Columns = append(details.Columns, col)
	}
	if err := rows.Err(); err != nil {
		return classify("describe columns", err)
	}
	return nil
}

func (c *Conn) describeConstraints(ctx context.Context, meta *sql.DB, details *engine.TableDetails, database string) error {
	rows, err := meta.QueryContext(ctx, describeConstraintsSQL, database, details.Schema, details.Table)
	if err != nil {
		return classify("describe constraints", err)
	}
	defer func() { _ = rows.Close() }()
	for rows.Next() {
		var kind, name string
		var columns, refColumns any
		var refTable sql.NullString
		if err := rows.Scan(&kind, &name, &columns, &refTable, &refColumns); err != nil {
			return classify("describe constraints", err)
		}
		cols := stringList(columns)
		switch kind {
		case "PRIMARY KEY":
			for order, col := range cols {
				if i := slices.IndexFunc(details.Columns, func(d engine.ColumnDef) bool { return d.Name == col }); i >= 0 {
					details.Columns[i].IsPrimaryKey, details.Columns[i].PrimaryKeyOrder = true, order+1
				}
			}
			details.Indexes = append(details.Indexes, engine.IndexDef{Name: name, Columns: cols, IsUnique: true, IsPrimary: true})
		case "UNIQUE":
			details.Indexes = append(details.Indexes, engine.IndexDef{Name: name, Columns: cols, IsUnique: true})
		case "FOREIGN KEY":
			details.ForeignKeys = append(details.ForeignKeys, engine.ForeignKeyDef{
				Name: name, Columns: cols, ReferencedSchema: details.Schema, ReferencedTable: refTable.String,
				ReferencedColumns: stringList(refColumns), OnDelete: engine.ReferentialNoAction, OnUpdate: engine.ReferentialNoAction,
			})
		}
	}
	if err := rows.Err(); err != nil {
		return classify("describe constraints", err)
	}
	return nil
}

func (c *Conn) describeIndexes(ctx context.Context, meta *sql.DB, details *engine.TableDetails, database string) error {
	rows, err := meta.QueryContext(ctx, describeIndexesSQL, database, details.Schema, details.Table)
	if err != nil {
		return classify("describe indexes", err)
	}
	defer func() { _ = rows.Close() }()
	for rows.Next() {
		var name string
		var unique bool
		var ddl sql.NullString
		if err := rows.Scan(&name, &unique, &ddl); err != nil {
			return classify("describe indexes", err)
		}
		details.Indexes = append(details.Indexes, engine.IndexDef{Name: name, Columns: indexColumns(ddl.String), IsUnique: unique})
	}
	if err := rows.Err(); err != nil {
		return classify("describe indexes", err)
	}
	return nil
}

func stringList(v any) []string {
	items, _ := v.([]any)
	out := make([]string, len(items))
	for i, item := range items {
		out[i] = fmt.Sprint(item)
	}
	return out
}

func setEditability(d *engine.TableDetails) {
	switch {
	case d.Type == engine.ObjectTypeView:
		d.EditDisabledReason = "Views are read-only."
	case hasKey(d):
		d.CanEdit = true
	default:
		d.EditDisabledReason = "Table has no primary key or unique NOT NULL column. Edits are disabled."
	}
}

func hasKey(d *engine.TableDetails) bool {
	return slices.ContainsFunc(d.Indexes, func(idx engine.IndexDef) bool {
		return idx.IsUnique && len(idx.Columns) > 0 && !slices.ContainsFunc(idx.Columns, func(name string) bool { return isNullableColumn(d, name) })
	})
}

func isNullableColumn(d *engine.TableDetails, name string) bool {
	i := slices.IndexFunc(d.Columns, func(c engine.ColumnDef) bool { return c.Name == name })
	return i < 0 || d.Columns[i].Nullable
}

// indexColumns reads the key list of a stored CREATE INDEX statement, which
// DuckDB does not expose any other way.
func indexColumns(ddl string) []string {
	open := firstOutsideQuotes(ddl, '(')
	closing := strings.LastIndex(ddl, ")")
	if open < 0 || closing <= open {
		return nil
	}
	var out []string
	for _, part := range splitTopLevel(ddl[open+1 : closing]) {
		out = append(out, unquoteIdent(strings.TrimSpace(part)))
	}
	return out
}

func firstOutsideQuotes(s string, target rune) int {
	quoted := false
	for i, r := range s {
		switch {
		case r == '"':
			quoted = !quoted
		case r == target && !quoted:
			return i
		}
	}
	return -1
}

func splitTopLevel(s string) []string {
	var parts []string
	depth, quoted, start := 0, false, 0
	for i, r := range s {
		switch {
		case r == '"':
			quoted = !quoted
		case quoted:
		case r == '(':
			depth++
		case r == ')':
			depth--
		case r == ',' && depth == 0:
			parts = append(parts, s[start:i])
			start = i + 1
		}
	}
	return append(parts, s[start:])
}

func unquoteIdent(s string) string {
	if len(s) >= 2 && s[0] == '"' && s[len(s)-1] == '"' {
		return strings.ReplaceAll(s[1:len(s)-1], `""`, `"`)
	}
	return s
}
