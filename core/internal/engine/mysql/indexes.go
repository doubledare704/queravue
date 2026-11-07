package mysql

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"strconv"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func (c *Conn) indexColumnsSQL() string {
	if c.variant == VariantMySQL {
		return `SELECT index_name, non_unique, index_type, column_name, collation, expression
FROM information_schema.statistics WHERE table_schema = ? AND table_name = ? ORDER BY index_name, seq_in_index`
	}
	return `SELECT index_name, non_unique, index_type, column_name, collation, NULL
FROM information_schema.statistics WHERE table_schema = ? AND table_name = ? ORDER BY index_name, seq_in_index`
}

// ListIndexes implements engine.IndexManager.
func (c *Conn) ListIndexes(ctx context.Context, database, schema, table string) ([]engine.IndexInfo, error) {
	conn, err := c.live("list indexes")
	if err != nil {
		return nil, err
	}
	db := dbOf(database, schema)
	rows, err := conn.QueryContext(ctx, c.indexColumnsSQL(), db, table)
	if err != nil {
		return nil, c.execError(ctx, err)
	}
	defer func() { _ = rows.Close() }()

	var out []engine.IndexInfo
	byName := map[string]int{}
	for rows.Next() {
		var name, method string
		var nonUnique int
		var column, direction, expression sql.NullString
		if err := rows.Scan(&name, &nonUnique, &method, &column, &direction, &expression); err != nil {
			return nil, c.execError(ctx, err)
		}
		at, seen := byName[name]
		if !seen {
			at = len(out)
			byName[name] = at
			out = append(out, engine.IndexInfo{
				IsPrimary: name == "PRIMARY",
				Spec:      engine.IndexSpec{Name: name, Unique: nonUnique == 0, Method: method},
			})
		}
		key := engine.IndexKey{Name: column.String}
		if expression.Valid {
			key = engine.IndexKey{Name: expression.String, IsExpression: true}
		}
		if direction.String == "D" {
			key.Kind = engine.IndexKeyDescending
		}
		out[at].Spec.Keys = append(out[at].Spec.Keys, key)
	}
	if err := rows.Err(); err != nil {
		return nil, c.execError(ctx, err)
	}
	if len(out) == 0 {
		if err := c.requireTable(ctx, conn, db, table); err != nil {
			return nil, err
		}
	}
	c.addIndexSizes(ctx, conn, db, table, out)
	c.addIndexUsage(ctx, conn, db, table, out)
	return out, nil
}

func (c *Conn) requireTable(ctx context.Context, conn *sql.Conn, db, table string) error {
	var one int
	err := conn.QueryRowContext(ctx, `SELECT 1 FROM information_schema.tables WHERE table_schema = ? AND table_name = ?`, db, table).Scan(&one)
	if errors.Is(err, sql.ErrNoRows) {
		return &engine.Error{Kind: engine.KindNotFound, Engine: c.id, Op: "list indexes",
			Msg: fmt.Sprintf("table %q not found in database %q", table, db)}
	}
	if err != nil {
		return c.execError(ctx, err)
	}
	return nil
}

// Best effort: the statistics tables are missing or empty on some servers.
func (c *Conn) addIndexSizes(ctx context.Context, conn *sql.Conn, db, table string, indexes []engine.IndexInfo) {
	var pageSize uint64
	if err := conn.QueryRowContext(ctx, `SELECT @@innodb_page_size`).Scan(&pageSize); err != nil || pageSize == 0 {
		return
	}
	rows, err := conn.QueryContext(ctx, `SELECT index_name, stat_value FROM mysql.innodb_index_stats
WHERE database_name = ? AND table_name = ? AND stat_name = 'size'`, db, table)
	if err != nil {
		return
	}
	defer func() { _ = rows.Close() }()
	pages := map[string]uint64{}
	for rows.Next() {
		var name string
		var value uint64
		if rows.Scan(&name, &value) == nil {
			pages[name] = value
		}
	}
	for i := range indexes {
		if p, ok := pages[indexes[i].Spec.Name]; ok {
			size := p * pageSize
			indexes[i].SizeBytes = &size
		}
	}
}

// Best effort: needs performance_schema, which MariaDB ships disabled and TiDB lacks.
func (c *Conn) addIndexUsage(ctx context.Context, conn *sql.Conn, db, table string, indexes []engine.IndexInfo) {
	rows, err := conn.QueryContext(ctx, `SELECT index_name, count_read FROM performance_schema.table_io_waits_summary_by_index_usage
WHERE object_schema = ? AND object_name = ? AND index_name IS NOT NULL`, db, table)
	if err != nil {
		return
	}
	defer func() { _ = rows.Close() }()
	reads := map[string]uint64{}
	for rows.Next() {
		var name string
		var n uint64
		if rows.Scan(&name, &n) == nil {
			reads[name] = n
		}
	}
	for i := range indexes {
		if n, ok := reads[indexes[i].Spec.Name]; ok {
			scans := n
			indexes[i].Usage = engine.IndexUsage{Available: true, Scans: &scans}
		}
	}
}

// TableStats implements engine.StatsProvider.
func (c *Conn) TableStats(ctx context.Context, database, schema, table string) (engine.TableStats, error) {
	conn, err := c.live("table stats")
	if err != nil {
		return engine.TableStats{}, err
	}
	db := dbOf(database, schema)
	var (
		storageEngine, rowFormat, collation sql.NullString
		rowsEstimate, data, index           sql.NullInt64
		autoIncrement                       sql.NullInt64
		created, updated                    sql.NullString
	)
	err = conn.QueryRowContext(ctx, `SELECT engine, row_format, table_collation, table_rows, data_length, index_length, auto_increment, create_time, update_time
FROM information_schema.tables WHERE table_schema = ? AND table_name = ? AND table_type = 'BASE TABLE'`, db, table).
		Scan(&storageEngine, &rowFormat, &collation, &rowsEstimate, &data, &index, &autoIncrement, &created, &updated)
	if errors.Is(err, sql.ErrNoRows) {
		return engine.TableStats{}, &engine.Error{Kind: engine.KindNotFound, Engine: c.id, Op: "table stats",
			Msg: fmt.Sprintf("table %q not found in database %q", table, db)}
	}
	if err != nil {
		return engine.TableStats{}, c.execError(ctx, err)
	}
	var st engine.TableStats
	if rowsEstimate.Valid {
		st.EstimatedRows = &rowsEstimate.Int64
	}
	if data.Valid {
		v := uint64(max(data.Int64, 0))
		st.DataBytes = &v
	}
	if index.Valid {
		v := uint64(max(index.Int64, 0))
		st.IndexBytes = &v
	}
	add := func(key, label, value string) {
		st.Extras = append(st.Extras, engine.StatEntry{Key: key, Label: label, Value: value})
	}
	if storageEngine.Valid {
		add("engine", "Storage engine", storageEngine.String)
	}
	if rowFormat.Valid {
		add("row_format", "Row format", rowFormat.String)
	}
	if collation.Valid {
		add("collation", "Collation", collation.String)
	}
	if autoIncrement.Valid {
		add("auto_increment", "Next auto-increment", strconv.FormatInt(autoIncrement.Int64, 10))
	}
	if created.Valid {
		add("created", "Created", created.String)
	}
	if updated.Valid {
		add("updated", "Last updated", updated.String)
	}
	return st, nil
}
