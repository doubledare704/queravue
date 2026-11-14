package oracle

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strings"

	"github.com/doubledare704/queravue/core/internal/engine"
)

var _ engine.SchemaInspector = (*Conn)(nil)

// ListDatabases implements engine.SchemaInspector. A connection reaches one
// container, so that is the only database.
func (c *Conn) ListDatabases(ctx context.Context) ([]string, error) {
	conn, err := c.live("list databases")
	if err != nil {
		return nil, err
	}
	var name string
	err = c.runner(conn).QueryRowContext(ctx,
		`SELECT COALESCE(SYS_CONTEXT('USERENV', 'CON_NAME'), SYS_CONTEXT('USERENV', 'DB_NAME')) FROM dual`).Scan(&name)
	if err != nil {
		return nil, c.execError(ctx, err)
	}
	return []string{name}, nil
}

// ListSchemas implements engine.SchemaInspector. Schemas are users;
// Oracle-maintained ones are hidden unless the connection asks for them.
func (c *Conn) ListSchemas(ctx context.Context, _ string) ([]string, error) {
	conn, err := c.live("list schemas")
	if err != nil {
		return nil, err
	}
	query := `SELECT username FROM all_users WHERE oracle_maintained = 'N' ORDER BY username`
	if c.showSystem {
		query = `SELECT username FROM all_users ORDER BY username`
	}
	rows, err := c.runner(conn).QueryContext(ctx, query)
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

// owner returns schema, or the connection's current schema when empty.
func (c *Conn) owner(ctx context.Context, conn *sql.Conn, schema string) (string, error) {
	if schema != "" {
		return schema, nil
	}
	var current string
	if err := c.runner(conn).QueryRowContext(ctx, `SELECT SYS_CONTEXT('USERENV', 'CURRENT_SCHEMA') FROM dual`).Scan(&current); err != nil {
		return "", c.execError(ctx, err)
	}
	return current, nil
}

// ListObjects implements engine.SchemaInspector.
func (c *Conn) ListObjects(ctx context.Context, _, schema string) ([]engine.SchemaObject, error) {
	conn, err := c.live("list objects")
	if err != nil {
		return nil, err
	}
	owner, err := c.owner(ctx, conn, schema)
	if err != nil {
		return nil, err
	}
	rows, err := c.runner(conn).QueryContext(ctx, `SELECT o.object_name, o.object_type, t.num_rows
FROM all_objects o
LEFT JOIN all_tables t ON t.owner = o.owner AND t.table_name = o.object_name AND o.object_type = 'TABLE'
WHERE o.owner = :1 AND o.object_type IN ('TABLE', 'VIEW', 'MATERIALIZED VIEW')
  AND o.object_name NOT LIKE 'BIN$%'
  AND NOT EXISTS (SELECT 1 FROM all_mviews m WHERE m.owner = o.owner AND m.mview_name = o.object_name AND o.object_type = 'TABLE')
ORDER BY o.object_name`, owner)
	if err != nil {
		return nil, c.execError(ctx, err)
	}
	defer func() { _ = rows.Close() }()
	var objs []engine.SchemaObject
	for rows.Next() {
		var name, typ string
		var estimate sql.NullInt64
		if err := rows.Scan(&name, &typ, &estimate); err != nil {
			return nil, c.execError(ctx, err)
		}
		obj := engine.SchemaObject{Name: name, Type: objectType(typ), EstimatedRows: -1}
		if estimate.Valid {
			obj.EstimatedRows = estimate.Int64
		}
		objs = append(objs, obj)
	}
	if err := rows.Err(); err != nil {
		return nil, c.execError(ctx, err)
	}
	return objs, nil
}

func objectType(oracleType string) engine.ObjectType {
	switch oracleType {
	case "VIEW":
		return engine.ObjectTypeView
	case "MATERIALIZED VIEW":
		return engine.ObjectTypeMaterializedView
	}
	return engine.ObjectTypeTable
}

type tableColumn struct {
	name, dataType, nullable, identity string
	length, charLength, precision      sql.NullInt64
	scale                              sql.NullInt64
	charUsed                           sql.NullString
	defaultText                        sql.NullString
}

// DescribeTable implements engine.SchemaInspector.
func (c *Conn) DescribeTable(ctx context.Context, _, schema, table string) (engine.TableDetails, error) {
	details := engine.TableDetails{Schema: schema, Table: table, Type: engine.ObjectTypeTable, EstimatedRows: -1}
	conn, err := c.live("describe table")
	if err != nil {
		return details, err
	}
	owner, err := c.owner(ctx, conn, schema)
	if err != nil {
		return details, err
	}
	details.Schema = owner

	typ, estimate, err := c.objectInfo(ctx, conn, owner, table)
	if err != nil {
		return details, err
	}
	details.Type, details.EstimatedRows = typ, estimate

	if details.Columns, err = c.describeColumns(ctx, conn, owner, table); err != nil {
		return details, err
	}
	pk, err := c.describeConstraints(ctx, conn, owner, table, &details)
	if err != nil {
		return details, err
	}
	if details.Indexes, err = c.describeIndexes(ctx, conn, owner, table, pk.indexName); err != nil {
		return details, err
	}
	for i := range details.Columns {
		if order, ok := pk.order[details.Columns[i].Name]; ok {
			details.Columns[i].IsPrimaryKey, details.Columns[i].PrimaryKeyOrder = true, order
		}
	}
	c.decideEditable(&details, pk)
	return details, nil
}

func (c *Conn) objectInfo(ctx context.Context, conn *sql.Conn, owner, table string) (engine.ObjectType, int64, error) {
	var typ string
	var estimate sql.NullInt64
	err := c.runner(conn).QueryRowContext(ctx, `SELECT o.object_type, t.num_rows
FROM all_objects o
LEFT JOIN all_tables t ON t.owner = o.owner AND t.table_name = o.object_name AND o.object_type = 'TABLE'
WHERE o.owner = :1 AND o.object_name = :2 AND o.object_type IN ('TABLE', 'VIEW', 'MATERIALIZED VIEW')`, owner, table).Scan(&typ, &estimate)
	if errors.Is(err, sql.ErrNoRows) {
		return "", -1, &engine.Error{Kind: engine.KindNotFound, Engine: ID, Op: "describe table",
			Msg: fmt.Sprintf("table %q not found in schema %q", table, owner)}
	}
	if err != nil {
		return "", -1, c.execError(ctx, err)
	}
	rowsEstimate := int64(-1)
	if estimate.Valid {
		rowsEstimate = estimate.Int64
	}
	return objectType(typ), rowsEstimate, nil
}

func (c *Conn) describeColumns(ctx context.Context, conn *sql.Conn, owner, table string) ([]engine.ColumnDef, error) {
	rows, err := c.runner(conn).QueryContext(ctx, `SELECT column_name, data_type, data_length, char_length, char_used, data_precision, data_scale,
       nullable, identity_column, data_default
FROM all_tab_columns WHERE owner = :1 AND table_name = :2 ORDER BY column_id`, owner, table)
	if err != nil {
		return nil, c.execError(ctx, err)
	}
	defer func() { _ = rows.Close() }()
	var cols []engine.ColumnDef
	for rows.Next() {
		var tc tableColumn
		if err := rows.Scan(&tc.name, &tc.dataType, &tc.length, &tc.charLength, &tc.charUsed, &tc.precision, &tc.scale,
			&tc.nullable, &tc.identity, &tc.defaultText); err != nil {
			return nil, c.execError(ctx, err)
		}
		cols = append(cols, columnDef(tc))
	}
	if err := rows.Err(); err != nil {
		return nil, c.execError(ctx, err)
	}
	return cols, nil
}

func columnDef(tc tableColumn) engine.ColumnDef {
	def := engine.ColumnDef{
		Name:     tc.name,
		TypeName: typeLabel(tc),
		Kind:     kindOfDataType(tc.dataType, tc.precision.Int64, tc.scale.Int64, tc.precision.Valid),
		Nullable: tc.nullable == "Y",
		Identity: tc.identity == "YES",
	}
	if text := strings.TrimSpace(tc.defaultText.String); tc.defaultText.Valid && text != "" && !def.Identity {
		def.DefaultValue = &text
	}
	return def
}

// typeLabel renders a column type as in a CREATE TABLE: VARCHAR2(50 CHAR), NUMBER(10,2).
func typeLabel(tc tableColumn) string {
	switch tc.dataType {
	case "VARCHAR2", "NVARCHAR2", "CHAR", "NCHAR":
		if tc.charUsed.String == "C" || strings.HasPrefix(tc.dataType, "N") {
			return fmt.Sprintf("%s(%d CHAR)", tc.dataType, tc.charLength.Int64)
		}
		return fmt.Sprintf("%s(%d)", tc.dataType, tc.length.Int64)
	case "RAW":
		return fmt.Sprintf("RAW(%d)", tc.length.Int64)
	case "NUMBER":
		switch {
		case !tc.precision.Valid && tc.scale.Valid && tc.scale.Int64 == 0:
			return "NUMBER(*,0)"
		case !tc.precision.Valid:
			return "NUMBER"
		case tc.scale.Valid && tc.scale.Int64 != 0:
			return fmt.Sprintf("NUMBER(%d,%d)", tc.precision.Int64, tc.scale.Int64)
		}
		return fmt.Sprintf("NUMBER(%d)", tc.precision.Int64)
	case "FLOAT":
		if tc.precision.Valid {
			return fmt.Sprintf("FLOAT(%d)", tc.precision.Int64)
		}
	}
	return tc.dataType
}

type primaryKey struct {
	order     map[string]int
	indexName string
}

func (c *Conn) describeConstraints(ctx context.Context, conn *sql.Conn, owner, table string, details *engine.TableDetails) (primaryKey, error) {
	pk := primaryKey{order: map[string]int{}}
	rows, err := c.runner(conn).QueryContext(ctx, `SELECT c.constraint_name, c.constraint_type, c.delete_rule, c.index_name, cc.column_name, cc.position,
       rc.owner, rc.table_name, rcc.column_name
FROM all_constraints c
JOIN all_cons_columns cc ON cc.owner = c.owner AND cc.constraint_name = c.constraint_name
LEFT JOIN all_constraints rc ON rc.owner = c.r_owner AND rc.constraint_name = c.r_constraint_name
LEFT JOIN all_cons_columns rcc ON rcc.owner = rc.owner AND rcc.constraint_name = rc.constraint_name AND rcc.position = cc.position
WHERE c.owner = :1 AND c.table_name = :2 AND c.constraint_type IN ('P', 'R')
ORDER BY c.constraint_name, cc.position`, owner, table)
	if err != nil {
		return pk, c.execError(ctx, err)
	}
	defer func() { _ = rows.Close() }()
	var fk *engine.ForeignKeyDef
	for rows.Next() {
		var name, kind, column string
		var deleteRule, indexName, refOwner, refTable, refColumn sql.NullString
		var position int
		if err := rows.Scan(&name, &kind, &deleteRule, &indexName, &column, &position, &refOwner, &refTable, &refColumn); err != nil {
			return pk, c.execError(ctx, err)
		}
		if kind == "P" {
			pk.order[column] = position
			pk.indexName = indexName.String
			continue
		}
		if fk == nil || fk.Name != name {
			ref := refOwner.String
			if ref == owner {
				ref = ""
			}
			details.ForeignKeys = append(details.ForeignKeys, engine.ForeignKeyDef{
				Name: name, ReferencedSchema: ref, ReferencedTable: refTable.String,
				OnDelete: engine.ParseReferentialAction(deleteRule.String),
			})
			fk = &details.ForeignKeys[len(details.ForeignKeys)-1]
		}
		fk.Columns = append(fk.Columns, column)
		fk.ReferencedColumns = append(fk.ReferencedColumns, refColumn.String)
	}
	return pk, rows.Err()
}

func (c *Conn) describeIndexes(ctx context.Context, conn *sql.Conn, owner, table, primaryIndex string) ([]engine.IndexDef, error) {
	rows, err := c.runner(conn).QueryContext(ctx, `SELECT i.index_name, i.uniqueness, ic.column_name, ie.column_expression
FROM all_indexes i
JOIN all_ind_columns ic ON ic.index_owner = i.owner AND ic.index_name = i.index_name
LEFT JOIN all_ind_expressions ie ON ie.index_owner = ic.index_owner AND ie.index_name = ic.index_name AND ie.column_position = ic.column_position
WHERE i.table_owner = :1 AND i.table_name = :2
ORDER BY i.index_name, ic.column_position`, owner, table)
	if err != nil {
		return nil, c.execError(ctx, err)
	}
	defer func() { _ = rows.Close() }()
	var out []engine.IndexDef
	for rows.Next() {
		var name, uniqueness, column string
		var expression sql.NullString
		if err := rows.Scan(&name, &uniqueness, &column, &expression); err != nil {
			return nil, c.execError(ctx, err)
		}
		if len(out) == 0 || out[len(out)-1].Name != name {
			out = append(out, engine.IndexDef{Name: name, IsUnique: uniqueness == "UNIQUE", IsPrimary: name == primaryIndex})
		}
		last := &out[len(out)-1]
		last.Columns = append(last.Columns, indexKey(column, expression).Name)
	}
	return out, rows.Err()
}

// decideEditable allows edits for tables with a primary key, or a unique
// index over NOT NULL columns; views are read-only.
func (c *Conn) decideEditable(details *engine.TableDetails, pk primaryKey) {
	switch {
	case details.Type != engine.ObjectTypeTable:
		details.EditDisabledReason = "Views are read-only."
		return
	case len(pk.order) > 0:
		details.CanEdit = true
		return
	}
	notNull := map[string]bool{}
	for _, col := range details.Columns {
		notNull[col.Name] = !col.Nullable
	}
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
			return
		}
	}
	details.EditDisabledReason = "Table has no primary key or unique NOT NULL column. Edits are disabled."
}
