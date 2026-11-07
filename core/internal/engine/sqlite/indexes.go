package sqlite

import (
	"context"
	"database/sql"
	"fmt"
	"strconv"
	"strings"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func schemaOf(database, schema string) string {
	switch {
	case schema != "":
		return schema
	case database != "":
		return database
	}
	return "main"
}

// ListIndexes implements engine.IndexManager. SQLite keeps no usage statistics.
func (c *Conn) ListIndexes(ctx context.Context, database, schema, table string) ([]engine.IndexInfo, error) {
	target := schemaOf(database, schema)
	rows, err := c.db.QueryContext(ctx, fmt.Sprintf(`PRAGMA %s.index_list(%s);`, quoteIdent(target), quoteIdent(table)))
	if err != nil {
		return nil, classify("list indexes", err)
	}
	type listed struct {
		name    string
		unique  bool
		primary bool
		partial bool
	}
	var found []listed
	for rows.Next() {
		var seq, unique, partial int
		var name, origin string
		if err := rows.Scan(&seq, &name, &unique, &origin, &partial); err != nil {
			_ = rows.Close()
			return nil, classify("list indexes", err)
		}
		found = append(found, listed{name: name, unique: unique == 1, primary: origin == "pk", partial: partial == 1})
	}
	if err := rows.Err(); err != nil {
		_ = rows.Close()
		return nil, classify("list indexes", err)
	}
	_ = rows.Close()

	if len(found) == 0 {
		if err := c.requireTable(ctx, target, table); err != nil {
			return nil, err
		}
	}
	out := make([]engine.IndexInfo, 0, len(found))
	for _, f := range found {
		info := engine.IndexInfo{IsPrimary: f.primary, Spec: engine.IndexSpec{Name: f.name, Unique: f.unique}}
		keys, err := c.indexKeys(ctx, target, f.name)
		if err != nil {
			return nil, err
		}
		info.Spec.Keys = keys
		if f.partial {
			info.Spec.PartialPredicate = c.partialPredicate(ctx, target, f.name)
		}
		info.SizeBytes = c.indexSize(ctx, target, f.name)
		out = append(out, info)
	}
	return out, nil
}

func (c *Conn) requireTable(ctx context.Context, target, table string) error {
	var one int
	err := c.db.QueryRowContext(ctx, fmt.Sprintf(`SELECT 1 FROM %s.sqlite_master WHERE name = ? AND type IN ('table', 'view')`, quoteIdent(target)), table).Scan(&one)
	if err == sql.ErrNoRows {
		return &engine.Error{Kind: engine.KindNotFound, Engine: ID, Op: "list indexes", Msg: fmt.Sprintf("table %q not found", table)}
	}
	if err != nil {
		return classify("list indexes", err)
	}
	return nil
}

func (c *Conn) indexKeys(ctx context.Context, target, index string) ([]engine.IndexKey, error) {
	rows, err := c.db.QueryContext(ctx, fmt.Sprintf(`PRAGMA %s.index_xinfo(%s);`, quoteIdent(target), quoteIdent(index)))
	if err != nil {
		return nil, classify("list indexes", err)
	}
	defer func() { _ = rows.Close() }()
	var keys []engine.IndexKey
	for rows.Next() {
		var seqno, cid, desc, key int
		var name, coll sql.NullString
		if err := rows.Scan(&seqno, &cid, &name, &desc, &coll, &key); err != nil {
			return nil, classify("list indexes", err)
		}
		if key == 0 {
			continue
		}
		k := engine.IndexKey{Name: name.String, IsExpression: cid == -2}
		if cid == -2 {
			k.Name = "<expression>"
		}
		if desc == 1 {
			k.Kind = engine.IndexKeyDescending
		}
		keys = append(keys, k)
	}
	if err := rows.Err(); err != nil {
		return nil, classify("list indexes", err)
	}
	return keys, nil
}

// SQLite does not expose the predicate, so it is cut from the stored CREATE INDEX text.
func (c *Conn) partialPredicate(ctx context.Context, target, index string) string {
	var ddl sql.NullString
	err := c.db.QueryRowContext(ctx, fmt.Sprintf(`SELECT sql FROM %s.sqlite_master WHERE type = 'index' AND name = ?`, quoteIdent(target)), index).Scan(&ddl)
	if err != nil || !ddl.Valid {
		return ""
	}
	at := strings.LastIndex(strings.ToUpper(ddl.String), " WHERE ")
	if at < 0 {
		return ""
	}
	return strings.TrimSpace(ddl.String[at+len(" WHERE "):])
}

// dbstat is a compile-time option: without it sizes stay unknown.
func (c *Conn) indexSize(ctx context.Context, target, object string) *uint64 {
	var size sql.NullInt64
	err := c.db.QueryRowContext(ctx, `SELECT SUM(pgsize) FROM dbstat WHERE name = ? AND schema = ?`, object, target).Scan(&size)
	if err != nil || !size.Valid {
		return nil
	}
	v := uint64(max(size.Int64, 0))
	return &v
}

// TableStats implements engine.StatsProvider.
func (c *Conn) TableStats(ctx context.Context, database, schema, table string) (engine.TableStats, error) {
	target := schemaOf(database, schema)
	if err := c.requireTable(ctx, target, table); err != nil {
		return engine.TableStats{}, err
	}
	var st engine.TableStats
	st.DataBytes = c.indexSize(ctx, target, table)
	if indexes, err := c.ListIndexes(ctx, database, schema, table); err == nil {
		var total uint64
		var hasIndexSize bool
		for _, ix := range indexes {
			if ix.SizeBytes != nil && !ix.IsPrimary {
				total += *ix.SizeBytes
				hasIndexSize = true
			}
		}
		if hasIndexSize {
			st.IndexBytes = &total
		}
	}
	var stat sql.NullString
	err := c.db.QueryRowContext(ctx, fmt.Sprintf(`SELECT stat FROM %s.sqlite_stat1 WHERE tbl = ? AND idx IS NULL`, quoteIdent(target)), table).Scan(&stat)
	if err == nil && stat.Valid {
		if n, perr := strconv.ParseInt(strings.Fields(stat.String)[0], 10, 64); perr == nil {
			st.EstimatedRows = &n
		}
	}
	var pageSize, pageCount int64
	if c.db.QueryRowContext(ctx, fmt.Sprintf(`PRAGMA %s.page_size;`, quoteIdent(target))).Scan(&pageSize) == nil {
		st.Extras = append(st.Extras, engine.StatEntry{Key: "page_size", Label: "Page size", Value: strconv.FormatInt(pageSize, 10)})
	}
	if c.db.QueryRowContext(ctx, fmt.Sprintf(`PRAGMA %s.page_count;`, quoteIdent(target))).Scan(&pageCount) == nil {
		st.Extras = append(st.Extras, engine.StatEntry{Key: "page_count", Label: "Pages in database", Value: strconv.FormatInt(pageCount, 10)})
	}
	return st, nil
}
