package sqlite

import (
	"context"
	"database/sql"
	"fmt"
	"slices"

	"github.com/doubledare704/queravue/core/internal/engine"
)

var _ engine.RelationLister = (*Conn)(nil)

const keyedColumnsQuery = `SELECT m.name, p.name, p.type, p."notnull", p.pk
FROM %s.sqlite_master m
JOIN pragma_table_info(m.name, ?) p
WHERE m.type IN ('table', 'view') AND m.name NOT LIKE 'sqlite_%%'
ORDER BY m.name, p.cid`

const relationsQuery = `SELECT m.name, f.id, f."table", f."from", f."to", f.on_delete, f.on_update
FROM %s.sqlite_master m
JOIN pragma_foreign_key_list(m.name, ?) f
WHERE m.type = 'table' AND m.name NOT LIKE 'sqlite_%%'
ORDER BY m.name, f.id, f.seq`

func attachedName(database, schema string) string {
	switch {
	case schema != "":
		return schema
	case database != "":
		return database
	}
	return "main"
}

// ListKeyedColumns implements engine.RelationLister.
func (c *Conn) ListKeyedColumns(ctx context.Context, database, schema string) ([]engine.KeyedColumn, error) {
	target := attachedName(database, schema)
	query := fmt.Sprintf(keyedColumnsQuery, quoteIdent(target)) //nolint:gosec // query targets quoted identifier
	rows, err := c.db.QueryContext(ctx, query, target)
	if err != nil {
		return nil, classify("list keyed columns", err)
	}
	defer func() { _ = rows.Close() }()
	var out []engine.KeyedColumn
	for rows.Next() {
		var col engine.KeyedColumn
		var notNull int
		if err := rows.Scan(&col.Table, &col.Name, &col.TypeName, &notNull, &col.PrimaryKeyOrder); err != nil {
			return nil, classify("scan keyed column", err)
		}
		col.Nullable = notNull == 0
		out = append(out, col)
	}
	if err := rows.Err(); err != nil {
		return nil, classify("list keyed columns", err)
	}
	return out, nil
}

// ListRelations implements engine.RelationLister. SQLite foreign keys have no
// names; they get the ones DescribeTable gives them. They cannot point into
// another attached database, so ReferencedSchema stays empty.
func (c *Conn) ListRelations(ctx context.Context, database, schema string) ([]engine.TableRelation, error) {
	target := attachedName(database, schema)
	query := fmt.Sprintf(relationsQuery, quoteIdent(target)) //nolint:gosec // query targets quoted identifier
	rows, err := c.db.QueryContext(ctx, query, target)
	if err != nil {
		return nil, classify("list relations", err)
	}
	defer func() { _ = rows.Close() }()
	var folded engine.RelationRows
	for rows.Next() {
		var table, refTable, from, onDelete, onUpdate string
		var id int
		// A reference without a column list points at the primary key; filled in below.
		var to sql.NullString
		if err := rows.Scan(&table, &id, &refTable, &from, &to, &onDelete, &onUpdate); err != nil {
			return nil, classify("scan relation", err)
		}
		folded.Add(table, fmt.Sprintf("fk_%s_%d", table, id), engine.ForeignKeyDef{
			ReferencedTable: refTable,
			OnDelete:        engine.ParseReferentialAction(onDelete), OnUpdate: engine.ParseReferentialAction(onUpdate),
		}, from, to.String)
	}
	if err := rows.Err(); err != nil {
		return nil, classify("list relations", err)
	}
	relations := folded.Relations()
	if err := c.fillImplicitKeyReferences(ctx, database, schema, relations); err != nil {
		return nil, err
	}
	return relations, nil
}

func referencesImplicitKey(r engine.TableRelation) bool {
	return len(r.ReferencedColumns) > 0 && r.ReferencedColumns[0] == ""
}

func (c *Conn) fillImplicitKeyReferences(ctx context.Context, database, schema string, relations []engine.TableRelation) error {
	if !slices.ContainsFunc(relations, referencesImplicitKey) {
		return nil
	}
	columns, err := c.ListKeyedColumns(ctx, database, schema)
	if err != nil {
		return err
	}
	keyOf := map[string][]string{}
	for _, col := range columns {
		if col.PrimaryKeyOrder == 0 {
			continue
		}
		key := keyOf[col.Table]
		for len(key) < col.PrimaryKeyOrder {
			key = append(key, "")
		}
		key[col.PrimaryKeyOrder-1] = col.Name
		keyOf[col.Table] = key
	}
	for i := range relations {
		if key := keyOf[relations[i].ReferencedTable]; referencesImplicitKey(relations[i]) && len(key) == len(relations[i].Columns) {
			relations[i].ReferencedColumns = key
		}
	}
	return nil
}
