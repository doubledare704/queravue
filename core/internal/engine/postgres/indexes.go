package postgres

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"

	"github.com/doubledare704/queravue/core/internal/engine"
)

const listIndexesSQL = `SELECT i.relname, ix.indisunique, ix.indisprimary, am.amname,
       COALESCE(pg_get_expr(ix.indpred, ix.indrelid), ''),
       ix.indnkeyatts::int,
       ARRAY(SELECT pg_get_indexdef(ix.indexrelid, n, true) FROM generate_series(1, ix.indnatts) n ORDER BY n),
       ARRAY(SELECT (ix.indoption[n-1] & 1) = 1 FROM generate_series(1, ix.indnkeyatts) n ORDER BY n),
       ARRAY(SELECT ix.indkey[n-1] = 0 FROM generate_series(1, ix.indnkeyatts) n ORDER BY n),
       pg_relation_size(i.oid),
       s.idx_scan
FROM pg_index ix
JOIN pg_class i ON i.oid = ix.indexrelid
JOIN pg_class t ON t.oid = ix.indrelid
JOIN pg_namespace n ON n.oid = t.relnamespace
JOIN pg_am am ON am.oid = i.relam
LEFT JOIN pg_stat_user_indexes s ON s.indexrelid = ix.indexrelid
WHERE n.nspname = $1 AND t.relname = $2
ORDER BY ix.indisprimary DESC, i.relname`

func schemaOrPublic(schema string) string {
	if schema == "" {
		return "public"
	}
	return schema
}

// ListIndexes implements engine.IndexManager.
func (c *Conn) ListIndexes(ctx context.Context, _, schema, table string) ([]engine.IndexInfo, error) {
	if c.variant == VariantCockroach {
		return c.listCockroachIndexes(ctx, schemaOrPublic(schema), table)
	}
	c.mu.Lock()
	conn := c.conn
	c.mu.Unlock()
	if conn == nil {
		return nil, &engine.Error{Kind: engine.KindConnectionLost, Engine: c.id, Op: "list indexes", Msg: "connection is closed"}
	}
	rows, err := conn.Query(ctx, listIndexesSQL, schemaOrPublic(schema), table)
	if err != nil {
		return nil, c.execError(ctx, err)
	}
	defer rows.Close()

	var out []engine.IndexInfo
	for rows.Next() {
		var (
			name, method, predicate string
			unique, primary         bool
			keyCount                int
			parts                   []string
			descending, expression  []bool
			size                    int64
			scans                   *int64
		)
		if err := rows.Scan(&name, &unique, &primary, &method, &predicate, &keyCount, &parts, &descending, &expression, &size, &scans); err != nil {
			return nil, c.execError(ctx, err)
		}
		info := engine.IndexInfo{IsPrimary: primary, Spec: engine.IndexSpec{
			Name: name, Unique: unique, Method: method, PartialPredicate: predicate,
		}}
		for i := 0; i < keyCount && i < len(parts); i++ {
			key := engine.IndexKey{Name: parts[i], IsExpression: expression[i]}
			if descending[i] {
				key.Kind = engine.IndexKeyDescending
			}
			info.Spec.Keys = append(info.Spec.Keys, key)
		}
		if keyCount < len(parts) {
			info.Spec.IncludeColumns = parts[keyCount:]
		}
		sz := uint64(max(size, 0))
		info.SizeBytes = &sz
		if scans != nil {
			n := uint64(max(*scans, 0))
			info.Usage = engine.IndexUsage{Available: true, Scans: &n}
		}
		out = append(out, info)
	}
	if err := rows.Err(); err != nil {
		return nil, c.execError(ctx, err)
	}
	if len(out) == 0 {
		rows.Close()
		if err := c.requireTable(ctx, schemaOrPublic(schema), table); err != nil {
			return nil, err
		}
	}
	return out, nil
}

func (c *Conn) requireTable(ctx context.Context, schema, table string) error {
	c.mu.Lock()
	conn := c.conn
	c.mu.Unlock()
	if conn == nil {
		return &engine.Error{Kind: engine.KindConnectionLost, Engine: c.id, Op: "list indexes", Msg: "connection is closed"}
	}
	var one int
	err := conn.QueryRow(ctx, `SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = $1 AND c.relname = $2 AND c.relkind IN ('r', 'p', 'v', 'm')`, schema, table).Scan(&one)
	return c.statsError(ctx, err, schema, table)
}

func (c *Conn) listCockroachIndexes(ctx context.Context, schema, table string) ([]engine.IndexInfo, error) {
	c.mu.Lock()
	conn := c.conn
	c.mu.Unlock()
	if conn == nil {
		return nil, &engine.Error{Kind: engine.KindConnectionLost, Engine: c.id, Op: "list indexes", Msg: "connection is closed"}
	}
	qualified := quoteIdent(schema) + "." + quoteIdent(table)
	rows, err := conn.Query(ctx, `SELECT index_name, non_unique, column_name, direction, storing, implicit FROM [SHOW INDEXES FROM `+qualified+`]`)
	if err != nil {
		return nil, c.missingTableOr(ctx, err, schema, table)
	}
	defer rows.Close()

	var out []engine.IndexInfo
	byName := map[string]int{}
	for rows.Next() {
		var name, column, direction string
		var nonUnique, storing, implicit bool
		if err := rows.Scan(&name, &nonUnique, &column, &direction, &storing, &implicit); err != nil {
			return nil, c.execError(ctx, err)
		}
		at, seen := byName[name]
		if !seen {
			at = len(out)
			byName[name] = at
			out = append(out, engine.IndexInfo{
				IsPrimary: name == table+"_pkey" || name == "primary",
				Spec:      engine.IndexSpec{Name: name, Unique: !nonUnique},
			})
		}
		switch {
		case implicit:
		case storing:
			out[at].Spec.IncludeColumns = append(out[at].Spec.IncludeColumns, column)
		default:
			key := engine.IndexKey{Name: column}
			if direction == "DESC" {
				key.Kind = engine.IndexKeyDescending
			}
			out[at].Spec.Keys = append(out[at].Spec.Keys, key)
		}
	}
	if err := rows.Err(); err != nil {
		return nil, c.execError(ctx, err)
	}
	return out, nil
}

func (c *Conn) missingTableOr(ctx context.Context, err error, schema, table string) error {
	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) && pgErr.Code == "42P01" {
		return &engine.Error{Kind: engine.KindNotFound, Engine: c.id, Op: "list indexes",
			Msg: fmt.Sprintf("table %q not found in schema %q", table, schema)}
	}
	return c.execError(ctx, err)
}

func quoteIdent(s string) string {
	return `"` + strings.ReplaceAll(s, `"`, `""`) + `"`
}

const tableStatsSQL = `SELECT c.reltuples::bigint,
       pg_relation_size(c.oid), pg_indexes_size(c.oid), pg_total_relation_size(c.oid),
       s.n_live_tup, s.n_dead_tup, s.last_vacuum, s.last_autovacuum, s.last_analyze, s.last_autoanalyze
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
LEFT JOIN pg_stat_user_tables s ON s.relid = c.oid
WHERE n.nspname = $1 AND c.relname = $2 AND c.relkind IN ('r', 'p', 'm')`

// TableStats implements engine.StatsProvider.
func (c *Conn) TableStats(ctx context.Context, _, schema, table string) (engine.TableStats, error) {
	if c.variant == VariantCockroach {
		return c.cockroachTableStats(ctx, schemaOrPublic(schema), table)
	}
	c.mu.Lock()
	conn := c.conn
	c.mu.Unlock()
	if conn == nil {
		return engine.TableStats{}, &engine.Error{Kind: engine.KindConnectionLost, Engine: c.id, Op: "table stats", Msg: "connection is closed"}
	}
	var (
		rowsEstimate, data, index, total  int64
		live, dead                        *int64
		vacuum, autovacuum, analyze, auto *time.Time
	)
	err := conn.QueryRow(ctx, tableStatsSQL, schemaOrPublic(schema), table).
		Scan(&rowsEstimate, &data, &index, &total, &live, &dead, &vacuum, &autovacuum, &analyze, &auto)
	if err != nil {
		return engine.TableStats{}, c.statsError(ctx, err, schema, table)
	}
	st := engine.TableStats{DataBytes: u64(data), IndexBytes: u64(index), TotalBytes: u64(total)}
	if rowsEstimate >= 0 {
		st.EstimatedRows = &rowsEstimate
	}
	add := func(key, label, value string) {
		st.Extras = append(st.Extras, engine.StatEntry{Key: key, Label: label, Value: value})
	}
	if live != nil {
		add("live_tuples", "Live rows", fmt.Sprint(*live))
	}
	if dead != nil {
		add("dead_tuples", "Dead rows", fmt.Sprint(*dead))
	}
	for _, t := range []struct {
		key, label string
		at         *time.Time
	}{
		{"last_vacuum", "Last vacuum", vacuum},
		{"last_autovacuum", "Last autovacuum", autovacuum},
		{"last_analyze", "Last analyze", analyze},
		{"last_autoanalyze", "Last autoanalyze", auto},
	} {
		if t.at != nil {
			add(t.key, t.label, t.at.UTC().Format(time.RFC3339))
		}
	}
	return st, nil
}

func (c *Conn) cockroachTableStats(ctx context.Context, schema, table string) (engine.TableStats, error) {
	c.mu.Lock()
	conn := c.conn
	c.mu.Unlock()
	if conn == nil {
		return engine.TableStats{}, &engine.Error{Kind: engine.KindConnectionLost, Engine: c.id, Op: "table stats", Msg: "connection is closed"}
	}
	var estimate int64
	err := conn.QueryRow(ctx, c.forVariant(`SELECT c.reltuples::bigint FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = $1 AND c.relname = $2 AND c.relkind IN ('r', 'p', 'm')`), schema, table).Scan(&estimate)
	if err != nil {
		return engine.TableStats{}, c.statsError(ctx, err, schema, table)
	}
	return engine.TableStats{EstimatedRows: &estimate}, nil
}

func (c *Conn) statsError(ctx context.Context, err error, schema, table string) error {
	if err == nil {
		return nil
	}
	if errors.Is(err, pgx.ErrNoRows) {
		return &engine.Error{Kind: engine.KindNotFound, Engine: c.id, Op: "table",
			Msg: fmt.Sprintf("table %q not found in schema %q", table, schemaOrPublic(schema))}
	}
	return c.execError(ctx, err)
}

func u64(n int64) *uint64 {
	v := uint64(max(n, 0))
	return &v
}
