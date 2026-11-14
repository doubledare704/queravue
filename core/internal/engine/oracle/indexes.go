package oracle

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"regexp"
	"strings"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
)

var (
	_ engine.IndexManager  = (*Conn)(nil)
	_ engine.StatsProvider = (*Conn)(nil)
)

// ListIndexes implements engine.IndexManager. Usage is not reported: Oracle
// keeps index usage only when monitoring is on, and reading it needs DBA views.
func (c *Conn) ListIndexes(ctx context.Context, _, schema, table string) ([]engine.IndexInfo, error) {
	conn, err := c.live("list indexes")
	if err != nil {
		return nil, err
	}
	owner, err := c.owner(ctx, conn, schema)
	if err != nil {
		return nil, err
	}
	rows, err := c.runner(conn).QueryContext(ctx, `SELECT i.index_name, i.uniqueness, i.index_type, ic.column_name, ic.descend, ie.column_expression,
       (SELECT k.constraint_name FROM all_constraints k WHERE k.owner = i.table_owner AND k.table_name = i.table_name
          AND k.constraint_type = 'P' AND k.index_name = i.index_name FETCH FIRST 1 ROWS ONLY)
FROM all_indexes i
JOIN all_ind_columns ic ON ic.index_owner = i.owner AND ic.index_name = i.index_name
LEFT JOIN all_ind_expressions ie ON ie.index_owner = ic.index_owner AND ie.index_name = ic.index_name AND ie.column_position = ic.column_position
WHERE i.table_owner = :1 AND i.table_name = :2
ORDER BY i.index_name, ic.column_position`, owner, table)
	if err != nil {
		return nil, c.execError(ctx, err)
	}
	defer func() { _ = rows.Close() }()

	var out []engine.IndexInfo
	for rows.Next() {
		var name, uniqueness, indexType, column, descend string
		var expression, primaryConstraint sql.NullString
		if err := rows.Scan(&name, &uniqueness, &indexType, &column, &descend, &expression, &primaryConstraint); err != nil {
			return nil, c.execError(ctx, err)
		}
		if len(out) == 0 || out[len(out)-1].Spec.Name != name {
			out = append(out, engine.IndexInfo{
				IsPrimary: primaryConstraint.Valid,
				Spec:      engine.IndexSpec{Name: name, Unique: uniqueness == "UNIQUE", Method: indexMethod(indexType)},
			})
		}
		key := indexKey(column, expression)
		if descend == "DESC" {
			key.Kind = engine.IndexKeyDescending
		}
		last := &out[len(out)-1]
		last.Spec.Keys = append(last.Spec.Keys, key)
	}
	if err := rows.Err(); err != nil {
		return nil, c.execError(ctx, err)
	}
	if len(out) == 0 {
		if err := c.requireTable(ctx, conn, owner, table, "list indexes"); err != nil {
			return nil, err
		}
	}
	c.addIndexSizes(ctx, conn, owner, out)
	return out, nil
}

var quotedColumn = regexp.MustCompile(`^"([^"]+)"$`)

// indexKey names an index key part. A descending column is stored as the
// expression "COL", which stays a plain column; any other expression is kept.
func indexKey(column string, expression sql.NullString) engine.IndexKey {
	if !expression.Valid {
		return engine.IndexKey{Name: column}
	}
	if m := quotedColumn.FindStringSubmatch(strings.TrimSpace(expression.String)); m != nil {
		return engine.IndexKey{Name: m[1]}
	}
	return engine.IndexKey{Name: expression.String, IsExpression: true}
}

func indexMethod(indexType string) string {
	if indexType == "BITMAP" {
		return "bitmap"
	}
	return ""
}

func (c *Conn) requireTable(ctx context.Context, conn *sql.Conn, owner, table, op string) error {
	var one int
	err := c.runner(conn).QueryRowContext(ctx, `SELECT 1 FROM all_objects WHERE owner = :1 AND object_name = :2
AND object_type IN ('TABLE', 'VIEW', 'MATERIALIZED VIEW')`, owner, table).Scan(&one)
	if errors.Is(err, sql.ErrNoRows) {
		return &engine.Error{Kind: engine.KindNotFound, Engine: ID, Op: op,
			Msg: fmt.Sprintf("table %q not found in schema %q", table, owner)}
	}
	if err != nil {
		return c.execError(ctx, err)
	}
	return nil
}

// addIndexSizes is best effort: user_segments covers only the connected user.
func (c *Conn) addIndexSizes(ctx context.Context, conn *sql.Conn, owner string, indexes []engine.IndexInfo) {
	rows, err := c.runner(conn).QueryContext(ctx, `SELECT segment_name, bytes FROM all_segments WHERE owner = :1 AND segment_type LIKE 'INDEX%'`, owner)
	if err != nil {
		return
	}
	defer func() { _ = rows.Close() }()
	sizes := map[string]uint64{}
	for rows.Next() {
		var name string
		var bytes sql.NullInt64
		if rows.Scan(&name, &bytes) == nil && bytes.Valid {
			sizes[name] = uint64(max(bytes.Int64, 0))
		}
	}
	for i := range indexes {
		if size, ok := sizes[indexes[i].Spec.Name]; ok {
			indexes[i].SizeBytes = &size
		}
	}
}

// TableStats implements engine.StatsProvider.
func (c *Conn) TableStats(ctx context.Context, _, schema, table string) (engine.TableStats, error) {
	conn, err := c.live("table stats")
	if err != nil {
		return engine.TableStats{}, err
	}
	owner, err := c.owner(ctx, conn, schema)
	if err != nil {
		return engine.TableStats{}, err
	}
	var numRows, blocks, avgRowLen sql.NullInt64
	var analyzed sql.NullTime
	err = c.runner(conn).QueryRowContext(ctx, `SELECT num_rows, blocks, avg_row_len, last_analyzed FROM all_tables WHERE owner = :1 AND table_name = :2`,
		owner, table).Scan(&numRows, &blocks, &avgRowLen, &analyzed)
	if errors.Is(err, sql.ErrNoRows) {
		return engine.TableStats{}, &engine.Error{Kind: engine.KindNotFound, Engine: ID, Op: "table stats",
			Msg: fmt.Sprintf("table %q not found in schema %q", table, owner)}
	}
	if err != nil {
		return engine.TableStats{}, c.execError(ctx, err)
	}
	st := engine.TableStats{}
	if numRows.Valid {
		st.EstimatedRows = &numRows.Int64
	}
	if blocks.Valid {
		var blockSize sql.NullInt64
		if c.runner(conn).QueryRowContext(ctx, `SELECT value FROM v$parameter WHERE name = 'db_block_size'`).Scan(&blockSize) != nil || !blockSize.Valid {
			blockSize = sql.NullInt64{Int64: 8192, Valid: true}
		}
		data := uint64(max(blocks.Int64, 0)) * uint64(blockSize.Int64) //nolint:gosec // block size is positive
		st.DataBytes = &data
	}
	if avgRowLen.Valid {
		st.Extras = append(st.Extras, engine.StatEntry{Key: "avg_row_len", Label: "Average row length", Value: fmt.Sprintf("%d bytes", avgRowLen.Int64)})
	}
	if analyzed.Valid {
		st.Extras = append(st.Extras, engine.StatEntry{Key: "last_analyzed", Label: "Statistics last gathered", Value: analyzed.Time.UTC().Format(time.RFC3339)})
	}
	return st, nil
}
