package clickhouse

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

var hiddenDatabases = []string{"system", "information_schema", "INFORMATION_SCHEMA"}

const (
	engineView             = "View"
	engineMaterializedView = "MaterializedView"
	innerTablePrefix       = ".inner"
)

const editsDisabledReason = "ClickHouse changes rows with ALTER TABLE … UPDATE and DELETE, which run as asynchronous mutations, so table edits are disabled. Use the SQL editor."

// ListDatabases implements engine.SchemaInspector. System databases are hidden.
func (c *Conn) ListDatabases(ctx context.Context) ([]string, error) {
	db, err := c.live("list databases")
	if err != nil {
		return nil, err
	}
	rows, err := db.QueryContext(ctx, "SELECT name FROM system.databases ORDER BY name")
	if err != nil {
		return nil, c.execError(ctx, err)
	}
	all, err := c.collectStrings(ctx, rows)
	if err != nil {
		return nil, err
	}
	return slices.DeleteFunc(all, func(name string) bool {
		return name != c.database && slices.Contains(hiddenDatabases, name)
	}), nil
}

// ListSchemas implements engine.SchemaInspector. The database is the only schema.
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

func (c *Conn) databaseOf(database, schema string) string {
	switch {
	case schema != "":
		return schema
	case database != "":
		return database
	}
	return c.database
}

func objectTypeOf(tableEngine string) engine.ObjectType {
	switch tableEngine {
	case engineView:
		return engine.ObjectTypeView
	case engineMaterializedView:
		return engine.ObjectTypeMaterializedView
	}
	return engine.ObjectTypeTable
}

// ListObjects implements engine.SchemaInspector.
func (c *Conn) ListObjects(ctx context.Context, database, schema string) ([]engine.SchemaObject, error) {
	db, err := c.live("list objects")
	if err != nil {
		return nil, err
	}
	rows, err := db.QueryContext(ctx,
		`SELECT name, engine, total_rows, total_bytes FROM system.tables
WHERE database = ? AND NOT is_temporary AND NOT startsWith(name, ?) ORDER BY name`,
		c.databaseOf(database, schema), innerTablePrefix)
	if err != nil {
		return nil, c.execError(ctx, err)
	}
	defer func() { _ = rows.Close() }()
	var objs []engine.SchemaObject
	for rows.Next() {
		var name, tableEngine string
		var totalRows, totalBytes sql.NullInt64
		if err := rows.Scan(&name, &tableEngine, &totalRows, &totalBytes); err != nil {
			return nil, c.execError(ctx, err)
		}
		obj := engine.SchemaObject{Name: name, Type: objectTypeOf(tableEngine), TableEngine: tableEngine, EstimatedRows: -1}
		if totalRows.Valid {
			obj.EstimatedRows = totalRows.Int64
		}
		if totalBytes.Valid && totalBytes.Int64 > 0 {
			obj.SizeBytes = uint64(totalBytes.Int64)
		}
		objs = append(objs, obj)
	}
	if err := rows.Err(); err != nil {
		return nil, c.execError(ctx, err)
	}
	return objs, nil
}

// DescribeTable implements engine.SchemaInspector.
func (c *Conn) DescribeTable(ctx context.Context, database, schema, table string) (engine.TableDetails, error) {
	db, err := c.live("describe table")
	if err != nil {
		return engine.TableDetails{}, err
	}
	dbName := c.databaseOf(database, schema)
	details := engine.TableDetails{Database: database, Schema: schema, Table: table, EstimatedRows: -1}

	var tableEngine, sortingKey, primaryKey, partitionKey string
	var totalRows sql.NullInt64
	err = db.QueryRowContext(ctx,
		`SELECT engine, sorting_key, primary_key, partition_key, total_rows FROM system.tables
WHERE database = ? AND name = ?`, dbName, table).Scan(&tableEngine, &sortingKey, &primaryKey, &partitionKey, &totalRows)
	if errors.Is(err, sql.ErrNoRows) {
		return details, &engine.Error{Kind: engine.KindNotFound, Engine: ID, Op: "describe table",
			Msg: fmt.Sprintf("table %q not found in database %q", table, dbName)}
	}
	if err != nil {
		return details, c.execError(ctx, err)
	}
	details.Type = objectTypeOf(tableEngine)
	details.TableEngine = tableEngine
	if totalRows.Valid {
		details.EstimatedRows = totalRows.Int64
	}

	primaryOrder := keyColumnOrder(primaryKey)
	rows, err := db.QueryContext(ctx,
		`SELECT name, type, default_kind, default_expression FROM system.columns
WHERE database = ? AND table = ? ORDER BY position`, dbName, table)
	if err != nil {
		return details, c.execError(ctx, err)
	}
	defer func() { _ = rows.Close() }()
	for rows.Next() {
		var name, typeName, defaultKind, defaultExpression string
		if err := rows.Scan(&name, &typeName, &defaultKind, &defaultExpression); err != nil {
			return details, c.execError(ctx, err)
		}
		column := engine.ColumnDef{
			Name: name, TypeName: typeName, Kind: kindOf(typeName), Nullable: isNullable(typeName),
			PrimaryKeyOrder: primaryOrder[name], IsPrimaryKey: primaryOrder[name] > 0,
		}
		if defaultKind == "DEFAULT" && defaultExpression != "" {
			column.DefaultValue = &defaultExpression
		}
		details.Columns = append(details.Columns, column)
	}
	if err := rows.Err(); err != nil {
		return details, c.execError(ctx, err)
	}

	details.Indexes = keyIndexes(sortingKey, primaryKey, partitionKey)
	details.CanEdit = false
	details.EditDisabledReason = editsDisabledReason
	if details.Type != engine.ObjectTypeTable {
		details.EditDisabledReason = "Views are read-only."
	}
	return details, nil
}

func keyIndexes(sortingKey, primaryKey, partitionKey string) []engine.IndexDef {
	var out []engine.IndexDef
	add := func(name, key string, primary bool) {
		if key = strings.TrimSpace(key); key != "" {
			out = append(out, engine.IndexDef{Name: name, Columns: splitTopLevel(key), IsPrimary: primary})
		}
	}
	add("sorting key", sortingKey, false)
	if primaryKey != sortingKey {
		add("primary key", primaryKey, true)
	}
	add("partition key", partitionKey, false)
	return out
}

func keyColumnOrder(key string) map[string]int {
	order := map[string]int{}
	for i, item := range splitTopLevel(key) {
		if name := strings.Trim(item, "`"); isPlainIdentifier(name) {
			order[name] = i + 1
		}
	}
	return order
}

func splitTopLevel(expr string) []string {
	var parts []string
	depth, start := 0, 0
	for i, r := range expr {
		switch r {
		case '(':
			depth++
		case ')':
			depth--
		case ',':
			if depth == 0 {
				parts = append(parts, strings.TrimSpace(expr[start:i]))
				start = i + 1
			}
		}
	}
	if tail := strings.TrimSpace(expr[start:]); tail != "" {
		parts = append(parts, tail)
	}
	return parts
}

func isPlainIdentifier(s string) bool {
	if s == "" {
		return false
	}
	for _, r := range s {
		if r != '_' && (r < 'a' || r > 'z') && (r < 'A' || r > 'Z') && (r < '0' || r > '9') {
			return false
		}
	}
	return true
}
