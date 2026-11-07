package mssql

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
)

const pageBytes = 8192

func (c *Conn) databaseAndSchema(ctx context.Context, conn *sql.Conn, database, schema string) (db, qualifiedDB, sch string, err error) {
	cur, err := c.currentDB(ctx, conn)
	if err != nil {
		return "", "", "", err
	}
	db = database
	if db == "" {
		db = cur
	}
	if schema == "" {
		schema = "dbo"
	}
	return db, qdb(db), schema, nil
}

// ListIndexes implements engine.IndexManager.
func (c *Conn) ListIndexes(ctx context.Context, database, schema, table string) ([]engine.IndexInfo, error) {
	conn, err := c.live("list indexes")
	if err != nil {
		return nil, err
	}
	db, d, schema, err := c.databaseAndSchema(ctx, conn, database, schema)
	if err != nil {
		return nil, err
	}
	//nolint:gosec // the only spliced part is a database name quoted by qdb
	rows, err := conn.QueryContext(ctx, `SELECT i.index_id, i.name, i.is_unique, i.is_primary_key, ISNULL(i.filter_definition, ''),
       ic.is_descending_key, ic.is_included_column, c.name
FROM `+d+`.sys.indexes i
JOIN `+d+`.sys.objects o ON o.object_id = i.object_id
JOIN `+d+`.sys.schemas s ON s.schema_id = o.schema_id
JOIN `+d+`.sys.index_columns ic ON ic.object_id = i.object_id AND ic.index_id = i.index_id
JOIN `+d+`.sys.columns c ON c.object_id = ic.object_id AND c.column_id = ic.column_id
WHERE s.name = @p1 AND o.name = @p2 AND i.type > 0
ORDER BY i.index_id, ic.is_included_column, ic.key_ordinal, ic.index_column_id`, schema, table)
	if err != nil {
		return nil, c.execError(ctx, err)
	}
	defer func() { _ = rows.Close() }()

	var out []engine.IndexInfo
	ids := map[int64]int{}
	for rows.Next() {
		var id int64
		var name, filter, column string
		var unique, primary, descending, included bool
		if err := rows.Scan(&id, &name, &unique, &primary, &filter, &descending, &included, &column); err != nil {
			return nil, c.execError(ctx, err)
		}
		at, seen := ids[id]
		if !seen {
			at = len(out)
			ids[id] = at
			out = append(out, engine.IndexInfo{
				IsPrimary: primary,
				Spec:      engine.IndexSpec{Name: name, Unique: unique, PartialPredicate: filter},
			})
		}
		if included {
			out[at].Spec.IncludeColumns = append(out[at].Spec.IncludeColumns, column)
			continue
		}
		key := engine.IndexKey{Name: column}
		if descending {
			key.Kind = engine.IndexKeyDescending
		}
		out[at].Spec.Keys = append(out[at].Spec.Keys, key)
	}
	if err := rows.Err(); err != nil {
		return nil, c.execError(ctx, err)
	}
	if len(out) == 0 {
		if err := c.requireTable(ctx, conn, d, schema, table); err != nil {
			return nil, err
		}
	}
	c.addIndexSizes(ctx, conn, d, schema, table, ids, out)
	c.addIndexUsage(ctx, conn, db, d, schema, table, ids, out)
	return out, nil
}

func (c *Conn) requireTable(ctx context.Context, conn *sql.Conn, d, schema, table string) error {
	var one int
	err := conn.QueryRowContext(ctx, `SELECT 1 FROM `+d+`.sys.objects o JOIN `+d+`.sys.schemas s ON s.schema_id = o.schema_id
WHERE s.name = @p1 AND o.name = @p2 AND o.type IN ('U', 'V')`, schema, table).Scan(&one)
	if errors.Is(err, sql.ErrNoRows) {
		return &engine.Error{Kind: engine.KindNotFound, Engine: ID, Op: "list indexes",
			Msg: fmt.Sprintf("table %q not found in schema %q", table, schema)}
	}
	if err != nil {
		return c.execError(ctx, err)
	}
	return nil
}

func (c *Conn) addIndexSizes(ctx context.Context, conn *sql.Conn, d, schema, table string, ids map[int64]int, indexes []engine.IndexInfo) {
	//nolint:gosec // the only spliced part is a database name quoted by qdb
	rows, err := conn.QueryContext(ctx, `SELECT ps.index_id, SUM(ps.used_page_count)
FROM `+d+`.sys.dm_db_partition_stats ps
JOIN `+d+`.sys.objects o ON o.object_id = ps.object_id
JOIN `+d+`.sys.schemas s ON s.schema_id = o.schema_id
WHERE s.name = @p1 AND o.name = @p2 GROUP BY ps.index_id`, schema, table)
	if err != nil {
		return
	}
	defer func() { _ = rows.Close() }()
	for rows.Next() {
		var id, pages int64
		if rows.Scan(&id, &pages) != nil {
			continue
		}
		if at, ok := ids[id]; ok {
			size := uint64(max(pages, 0)) * pageBytes
			indexes[at].SizeBytes = &size
		}
	}
}

// Best effort: the DMV needs VIEW SERVER STATE and counts only since the last server restart.
func (c *Conn) addIndexUsage(ctx context.Context, conn *sql.Conn, db, d, schema, table string, ids map[int64]int, indexes []engine.IndexInfo) {
	var since sql.NullTime
	if conn.QueryRowContext(ctx, `SELECT sqlserver_start_time FROM sys.dm_os_sys_info`).Scan(&since) != nil {
		return
	}
	//nolint:gosec // the only spliced part is a database name quoted by qdb
	rows, err := conn.QueryContext(ctx, `SELECT u.index_id, u.user_seeks + u.user_scans + u.user_lookups,
       (SELECT MAX(t) FROM (VALUES (u.last_user_seek), (u.last_user_scan), (u.last_user_lookup)) v(t))
FROM sys.dm_db_index_usage_stats u
JOIN `+d+`.sys.objects o ON o.object_id = u.object_id
JOIN `+d+`.sys.schemas s ON s.schema_id = o.schema_id
WHERE u.database_id = DB_ID(@p1) AND s.name = @p2 AND o.name = @p3`, db, schema, table)
	if err != nil {
		return
	}
	defer func() { _ = rows.Close() }()
	seen := map[int64]bool{}
	for rows.Next() {
		var id, reads int64
		var last sql.NullTime
		if rows.Scan(&id, &reads, &last) != nil {
			continue
		}
		at, ok := ids[id]
		if !ok {
			continue
		}
		seen[id] = true
		scans := uint64(max(reads, 0))
		usage := engine.IndexUsage{Available: true, Scans: &scans}
		if last.Valid {
			t := last.Time.UTC()
			usage.LastUsed = &t
		}
		if since.Valid {
			t := since.Time.UTC()
			usage.TrackingSince = &t
		}
		indexes[at].Usage = usage
	}
	for id, at := range ids {
		if seen[id] {
			continue
		}
		zero := uint64(0)
		usage := engine.IndexUsage{Available: true, Scans: &zero}
		if since.Valid {
			t := since.Time.UTC()
			usage.TrackingSince = &t
		}
		indexes[at].Usage = usage
	}
}

// TableStats implements engine.StatsProvider.
func (c *Conn) TableStats(ctx context.Context, database, schema, table string) (engine.TableStats, error) {
	conn, err := c.live("table stats")
	if err != nil {
		return engine.TableStats{}, err
	}
	_, d, schema, err := c.databaseAndSchema(ctx, conn, database, schema)
	if err != nil {
		return engine.TableStats{}, err
	}
	var rowsEstimate, data, index sql.NullInt64
	var created, modified sql.NullTime
	err = conn.QueryRowContext(ctx, `SELECT SUM(CASE WHEN ps.index_id < 2 THEN ps.row_count ELSE 0 END),
       SUM(CASE WHEN ps.index_id < 2 THEN ps.in_row_data_page_count + ps.lob_used_page_count + ps.row_overflow_used_page_count ELSE 0 END),
       SUM(CASE WHEN ps.index_id >= 2 THEN ps.used_page_count ELSE 0 END),
       MIN(o.create_date), MIN(o.modify_date)
FROM `+d+`.sys.objects o
JOIN `+d+`.sys.schemas s ON s.schema_id = o.schema_id
JOIN `+d+`.sys.dm_db_partition_stats ps ON ps.object_id = o.object_id
WHERE s.name = @p1 AND o.name = @p2 AND o.type = 'U'
GROUP BY o.object_id`, schema, table).Scan(&rowsEstimate, &data, &index, &created, &modified)
	if errors.Is(err, sql.ErrNoRows) {
		return engine.TableStats{}, &engine.Error{Kind: engine.KindNotFound, Engine: ID, Op: "table stats",
			Msg: fmt.Sprintf("table %q not found in schema %q", table, schema)}
	}
	if err != nil {
		return engine.TableStats{}, c.execError(ctx, err)
	}
	st := engine.TableStats{}
	if rowsEstimate.Valid {
		st.EstimatedRows = &rowsEstimate.Int64
	}
	if data.Valid {
		v := uint64(max(data.Int64, 0)) * pageBytes
		st.DataBytes = &v
	}
	if index.Valid {
		v := uint64(max(index.Int64, 0)) * pageBytes
		st.IndexBytes = &v
	}
	if created.Valid {
		st.Extras = append(st.Extras, engine.StatEntry{Key: "created", Label: "Created", Value: created.Time.UTC().Format(time.RFC3339)})
	}
	if modified.Valid {
		st.Extras = append(st.Extras, engine.StatEntry{Key: "modified", Label: "Schema last modified", Value: modified.Time.UTC().Format(time.RFC3339)})
	}
	return st, nil
}
