//go:build duckdb

package duckdb

import (
	"context"
	"database/sql"
	"database/sql/driver"
	"errors"
	"fmt"
	"regexp"
	"strings"

	duckdbdriver "github.com/duckdb/duckdb-go/v2"

	"github.com/doubledare704/queravue/core/internal/engine"
)

var _ engine.RowLoader = (*Conn)(nil)

const columnTypesSQL = `SELECT column_name, data_type FROM duckdb_columns() WHERE ` + scopeClause + ` AND table_name = ?`

// LoadRows implements engine.RowLoader with the DuckDB appender, one
// transaction per batch. It holds the work connection for the whole load, so a
// transaction the caller left open is detected (BEGIN fails) and refused.
func (c *Conn) LoadRows(ctx context.Context, t engine.LoadTarget, columns []string, src engine.RowBatchSource) (engine.LoadStats, error) {
	const op = "load rows"
	if t.Table == "" || len(columns) == 0 {
		return engine.LoadStats{}, engine.Errorf(engine.KindInvalidConfig, ID, op, "table and columns are required")
	}
	work, meta, err := c.pools(op)
	if err != nil {
		return engine.LoadStats{}, err
	}
	converters, err := columnConverters(ctx, meta, t, columns)
	if err != nil {
		return engine.LoadStats{}, err
	}
	conn, err := work.Conn(ctx)
	if err != nil {
		return engine.LoadStats{}, loadError(ctx, err)
	}
	defer func() { _ = conn.Close() }()
	run := &loadRun{conn: conn, target: t, columns: columns, converters: converters}
	return engine.DriveLoad(ctx, ID, op, src.Next, func(rows [][]engine.Value) int { return len(rows) }, run.commitBatch)
}

func columnConverters(ctx context.Context, meta *sql.DB, t engine.LoadTarget, columns []string) ([]valueConverter, error) {
	rows, err := meta.QueryContext(ctx, columnTypesSQL, t.Database, t.Schema, t.Table)
	if err != nil {
		return nil, loadError(ctx, err)
	}
	defer func() { _ = rows.Close() }()
	types := map[string]string{}
	for rows.Next() {
		var name, typeName string
		if err := rows.Scan(&name, &typeName); err != nil {
			return nil, loadError(ctx, err)
		}
		types[strings.ToLower(name)] = typeName
	}
	if err := rows.Err(); err != nil {
		return nil, loadError(ctx, err)
	}
	if len(types) == 0 {
		return nil, engine.Errorf(engine.KindNotFound, ID, "load rows", "table %s does not exist", t.Table)
	}
	out := make([]valueConverter, len(columns))
	for i, name := range columns {
		typeName, ok := types[strings.ToLower(name)]
		if !ok {
			return nil, engine.Errorf(engine.KindNotFound, ID, "load rows", "column %s does not exist", name)
		}
		if out[i], err = converterFor(typeName); err != nil {
			return nil, engine.Errorf(engine.KindUnsupported, ID, "load rows", "column %s: %s", name, err.Error())
		}
	}
	return out, nil
}

type loadRun struct {
	conn       *sql.Conn
	target     engine.LoadTarget
	columns    []string
	converters []valueConverter
	begun      bool
}

func (r *loadRun) commitBatch(ctx context.Context, rows [][]engine.Value) (engine.LoadStats, error) {
	if err := engine.CheckLoadWidths(ID, rows, len(r.columns)); err != nil {
		return engine.LoadStats{}, err
	}
	err := r.conn.Raw(func(driverConn any) error { return r.appendInTransaction(ctx, driverConn, rows) })
	if err != nil {
		return engine.LoadStats{}, loadError(ctx, err)
	}
	r.begun = true
	return engine.LoadStats{Rows: uint64(len(rows)), Batches: 1}, nil
}

func (r *loadRun) appendInTransaction(ctx context.Context, driverConn any, rows [][]engine.Value) error {
	raw, ok := driverConn.(driver.Conn)
	execer, execOK := driverConn.(driver.ExecerContext)
	if !ok || !execOK {
		return errors.New("duckdb: unexpected driver connection type")
	}
	if _, err := execer.ExecContext(ctx, "BEGIN TRANSACTION", nil); err != nil {
		if !r.begun && strings.Contains(err.Error(), "within a transaction") {
			return engine.Errorf(engine.KindUnsupported, ID, "load rows", "a transaction is open on this connection; commit or roll it back before loading")
		}
		return err //nolint:wrapcheck // loadError classifies the driver error
	}
	if err := r.appendRows(ctx, raw, rows); err != nil {
		_, _ = execer.ExecContext(context.WithoutCancel(ctx), "ROLLBACK", nil)
		return err
	}
	if err := ctx.Err(); err != nil {
		_, _ = execer.ExecContext(context.WithoutCancel(ctx), "ROLLBACK", nil)
		return fmt.Errorf("cancelled before commit: %w", err)
	}
	if _, err := execer.ExecContext(ctx, "COMMIT", nil); err != nil {
		_, _ = execer.ExecContext(context.WithoutCancel(ctx), "ROLLBACK", nil)
		return err //nolint:wrapcheck // loadError classifies the driver error
	}
	return nil
}

func (r *loadRun) appendRows(ctx context.Context, raw driver.Conn, rows [][]engine.Value) (err error) {
	appender, err := duckdbdriver.NewAppenderWithColumns(raw, r.target.Database, r.target.Schema, r.target.Table, r.columns)
	if err != nil {
		return err //nolint:wrapcheck // loadError classifies the driver error
	}
	closed := false
	defer func() {
		if !closed {
			_ = appender.Clear()
			_ = appender.Close()
		}
	}()
	args := make([]driver.Value, len(r.columns))
	for _, row := range rows {
		for i, v := range row {
			if args[i], err = r.converters[i](v); err != nil {
				return &engine.Error{Kind: engine.KindInvalidConfig, Engine: ID, Op: "load rows", Msg: fmt.Sprintf("column %s: %s", r.columns[i], err.Error())}
			}
		}
		if err := appender.AppendRow(args...); err != nil {
			return err //nolint:wrapcheck // loadError classifies the driver error
		}
	}
	closed = true
	return appender.CloseWithCancel(ctx) //nolint:wrapcheck // loadError classifies the driver error
}

var (
	duplicateKeyRe = regexp.MustCompile(`(?i)violates (primary key|unique) constraint`)
	foreignKeyRe   = regexp.MustCompile(`(?i)violates foreign key constraint`)
	notNullRe      = regexp.MustCompile(`NOT NULL constraint failed: ([^\s]+)`)
	checkRe        = regexp.MustCompile(`CHECK constraint failed: ([^\s]+)`)
)

// loadError classifies a failed load. DuckDB quotes the offending key in
// duplicate and foreign key messages, so those are rebuilt without it.
func loadError(ctx context.Context, err error) error {
	var typed *engine.Error
	if errors.As(err, &typed) {
		return typed
	}
	if ctx.Err() != nil {
		kind, msg := engine.KindCanceled, "load cancelled"
		if errors.Is(ctx.Err(), context.DeadlineExceeded) {
			kind, msg = engine.KindTimeout, "load timed out"
		}
		return &engine.Error{Kind: kind, Engine: ID, Op: "load rows", Msg: msg, Err: err}
	}
	e := classify("load rows", err)
	text := err.Error()
	switch {
	case duplicateKeyRe.MatchString(text):
		e.Kind, e.Msg = engine.KindConstraint, "duplicate value violates a "+strings.ToLower(duplicateKeyRe.FindStringSubmatch(text)[1])+" constraint"
	case foreignKeyRe.MatchString(text):
		e.Kind, e.Msg = engine.KindConstraint, "a value violates a foreign key constraint"
	case notNullRe.MatchString(text):
		e.Kind, e.Msg = engine.KindConstraint, "NOT NULL constraint failed: "+notNullRe.FindStringSubmatch(text)[1]
	case checkRe.MatchString(text):
		e.Kind, e.Msg = engine.KindConstraint, "CHECK constraint failed: "+checkRe.FindStringSubmatch(text)[1]
	case strings.Contains(text, "Conversion Error"), strings.Contains(text, "Out of Range Error"):
		e.Kind, e.Msg = engine.KindSQL, "a value was rejected by its column type"
	}
	return e
}
