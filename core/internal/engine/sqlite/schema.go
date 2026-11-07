package sqlite

import (
	"context"
	"fmt"
	"strings"

	"github.com/doubledare704/queravue/core/internal/engine"
)

var _ engine.SchemaInspector = (*Conn)(nil)

// ListDatabases implements engine.SchemaInspector.
func (c *Conn) ListDatabases(ctx context.Context) ([]string, error) {
	rows, err := c.db.QueryContext(ctx, "PRAGMA database_list;")
	if err != nil {
		return nil, classify("list databases", err)
	}
	defer func() { _ = rows.Close() }()

	var dbs []string
	for rows.Next() {
		var seq int
		var name, file string
		if err := rows.Scan(&seq, &name, &file); err != nil {
			return nil, classify("scan database", err)
		}
		if name != "" {
			dbs = append(dbs, name)
		}
	}
	if err := rows.Err(); err != nil {
		return nil, classify("list databases", err)
	}
	if len(dbs) == 0 {
		dbs = []string{"main"}
	}
	return dbs, nil
}

// ListSchemas implements engine.SchemaInspector.
func (c *Conn) ListSchemas(_ context.Context, database string) ([]string, error) {
	if database == "" {
		database = "main"
	}
	return []string{database}, nil
}

// ListObjects implements engine.SchemaInspector.
func (c *Conn) ListObjects(ctx context.Context, database, schema string) ([]engine.SchemaObject, error) {
	target := schema
	if target == "" {
		target = database
	}
	if target == "" {
		target = "main"
	}

	query := fmt.Sprintf(`SELECT name, type FROM %s.sqlite_master WHERE type IN ('table', 'view') AND name NOT LIKE 'sqlite_%%' ORDER BY name;`, quoteIdent(target)) //nolint:gosec // query targets quoted identifier
	rows, err := c.db.QueryContext(ctx, query)
	if err != nil {
		return nil, classify("list objects", err)
	}
	defer func() { _ = rows.Close() }()

	var objs []engine.SchemaObject
	for rows.Next() {
		var name, objType string
		if err := rows.Scan(&name, &objType); err != nil {
			return nil, classify("scan object", err)
		}
		t := engine.ObjectTypeTable
		if objType == "view" {
			t = engine.ObjectTypeView
		}
		objs = append(objs, engine.SchemaObject{
			Name:          name,
			Type:          t,
			EstimatedRows: -1,
		})
	}
	if err := rows.Err(); err != nil {
		return nil, classify("list objects", err)
	}
	return objs, nil
}

// DescribeTable implements engine.SchemaInspector.
func (c *Conn) DescribeTable(ctx context.Context, database, schema, table string) (engine.TableDetails, error) {
	target := schema
	if target == "" {
		target = database
	}
	if target == "" {
		target = "main"
	}

	details := engine.TableDetails{
		Database:      database,
		Schema:        target,
		Table:         table,
		Type:          engine.ObjectTypeTable,
		EstimatedRows: -1,
	}

	// 1. Check object type (table or view)
	var typeStr string
	typeQuery := fmt.Sprintf(`SELECT type FROM %s.sqlite_master WHERE name = ? LIMIT 1;`, quoteIdent(target)) //nolint:gosec // target is quoted identifier
	if err := c.db.QueryRowContext(ctx, typeQuery, table).Scan(&typeStr); err == nil && typeStr == "view" {
		details.Type = engine.ObjectTypeView
	}

	// 2. Read column info
	colQuery := fmt.Sprintf(`PRAGMA %s.table_info(%s);`, quoteIdent(target), quoteIdent(table))
	colRows, err := c.db.QueryContext(ctx, colQuery)
	if err != nil {
		return details, classify("describe table columns", err)
	}
	defer func() { _ = colRows.Close() }()

	hasPK := false
	notNullCols := make(map[string]bool)

	for colRows.Next() {
		var cid, notnull, pk int
		var name, typeName string
		var dfltVal *string

		if err := colRows.Scan(&cid, &name, &typeName, &notnull, &dfltVal, &pk); err != nil {
			return details, classify("scan column info", err)
		}

		isPK := pk > 0
		if isPK {
			hasPK = true
		}
		nullable := notnull == 0
		if !nullable {
			notNullCols[name] = true
		}

		details.Columns = append(details.Columns, engine.ColumnDef{
			Name:            name,
			TypeName:        typeName,
			Kind:            mapSQLiteType(typeName),
			Nullable:        nullable,
			DefaultValue:    dfltVal,
			IsPrimaryKey:    isPK,
			PrimaryKeyOrder: pk,
		})
	}
	if err := colRows.Err(); err != nil {
		return details, classify("read column rows", err)
	}

	// 3. Read index info
	idxQuery := fmt.Sprintf(`PRAGMA %s.index_list(%s);`, quoteIdent(target), quoteIdent(table))
	idxRows, err := c.db.QueryContext(ctx, idxQuery)
	if err == nil {
		defer func() { _ = idxRows.Close() }()
		type rawIdx struct {
			seq     int
			name    string
			unique  bool
			origin  string
			partial int
		}
		var indexes []rawIdx
		for idxRows.Next() {
			var seq, unique, partial int
			var name, origin string
			if err := idxRows.Scan(&seq, &name, &unique, &origin, &partial); err == nil {
				indexes = append(indexes, rawIdx{
					seq:     seq,
					name:    name,
					unique:  unique == 1,
					origin:  origin,
					partial: partial,
				})
			}
		}

		for _, ri := range indexes {
			colListQuery := fmt.Sprintf(`PRAGMA %s.index_info(%s);`, quoteIdent(target), quoteIdent(ri.name))
			infoRows, err := c.db.QueryContext(ctx, colListQuery)
			if err != nil {
				continue
			}
			var idxCols []string
			for infoRows.Next() {
				var seqno, cid int
				var colName string
				if err := infoRows.Scan(&seqno, &cid, &colName); err == nil {
					idxCols = append(idxCols, colName)
				}
			}
			_ = infoRows.Close()

			details.Indexes = append(details.Indexes, engine.IndexDef{
				Name:      ri.name,
				Columns:   idxCols,
				IsUnique:  ri.unique,
				IsPrimary: ri.origin == "pk",
			})
		}
	}

	// 4. Read foreign keys
	fkQuery := fmt.Sprintf(`PRAGMA %s.foreign_key_list(%s);`, quoteIdent(target), quoteIdent(table))
	fkRows, err := c.db.QueryContext(ctx, fkQuery)
	if err == nil {
		defer func() { _ = fkRows.Close() }()
		type fkPart struct {
			id       int
			seq      int
			refTable string
			from     string
			to       string
			onDelete string
			onUpdate string
		}
		fkGroups := make(map[int][]fkPart)
		for fkRows.Next() {
			var id, seq int
			var refTable, from, to, onUpdate, onDelete, match string
			if err := fkRows.Scan(&id, &seq, &refTable, &from, &to, &onUpdate, &onDelete, &match); err == nil {
				fkGroups[id] = append(fkGroups[id], fkPart{
					id:       id,
					seq:      seq,
					refTable: refTable,
					from:     from,
					to:       to,
					onDelete: onDelete,
					onUpdate: onUpdate,
				})
			}
		}

		for id, parts := range fkGroups {
			if len(parts) == 0 {
				continue
			}
			var fromCols, toCols []string
			for _, p := range parts {
				fromCols = append(fromCols, p.from)
				toCols = append(toCols, p.to)
			}
			details.ForeignKeys = append(details.ForeignKeys, engine.ForeignKeyDef{
				Name:              fmt.Sprintf("fk_%s_%d", table, id),
				Columns:           fromCols,
				ReferencedSchema:  target,
				ReferencedTable:   parts[0].refTable,
				ReferencedColumns: toCols,
				OnDelete:          engine.ParseReferentialAction(parts[0].onDelete),
				OnUpdate:          engine.ParseReferentialAction(parts[0].onUpdate),
			})
		}
	}

	// 5. Determine editability
	switch {
	case details.Type == engine.ObjectTypeView:
		details.CanEdit = false
		details.EditDisabledReason = "Views are read-only."
	case hasPK:
		details.CanEdit = true
	default:
		// Check for unique index where all columns are NOT NULL
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

func quoteIdent(s string) string {
	return `"` + strings.ReplaceAll(s, `"`, `""`) + `"`
}

func mapSQLiteType(t string) engine.ValueKind {
	upper := strings.ToUpper(strings.TrimSpace(t))
	switch {
	case strings.Contains(upper, "INT"):
		return engine.VInt
	case strings.Contains(upper, "CHAR"), strings.Contains(upper, "CLOB"), strings.Contains(upper, "TEXT"):
		return engine.VText
	case strings.Contains(upper, "BLOB"):
		return engine.VBytes
	case strings.Contains(upper, "REAL"), strings.Contains(upper, "FLOAT"), strings.Contains(upper, "DOUBLE"):
		return engine.VFloat
	case strings.Contains(upper, "DECIMAL"), strings.Contains(upper, "NUMERIC"):
		return engine.VDecimal
	case strings.Contains(upper, "BOOL"):
		return engine.VBool
	case strings.Contains(upper, "JSON"):
		return engine.VJSON
	case strings.Contains(upper, "TIME"), strings.Contains(upper, "DATE"):
		return engine.VTimestamptz
	default:
		return engine.VText
	}
}
