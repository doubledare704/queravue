//go:build duckdb

package duckdb

import (
	"context"
	"database/sql/driver"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"runtime/debug"
	"time"

	duckdbdriver "github.com/duckdb/duckdb-go/v2"

	"github.com/doubledare704/queravue/core/internal/engine"
)

var _ engine.Executor = (*Conn)(nil)

// Execute holds the work connection until native results have been released.
func (c *Conn) Execute(ctx context.Context, stmt engine.Statement, sink engine.RowSink) (sum engine.Summary, err error) {
	start := time.Now()
	defer func() {
		sum.Duration = time.Since(start)
		if r := recover(); r != nil {
			slog.Error("duckdb: execute panic", "panic", fmt.Sprint(r), "stack", string(debug.Stack()))
			err = &engine.Error{Kind: engine.KindUnknown, Engine: ID, Op: "execute", Msg: "internal error while running the statement"}
		}
	}()
	work, _, err := c.pools("execute")
	if err != nil {
		return sum, err
	}
	args, err := toArgs(stmt.Params)
	if err != nil {
		return sum, &engine.Error{Kind: engine.KindInvalidConfig, Engine: ID, Op: "execute", Msg: err.Error()}
	}
	conn, err := work.Conn(ctx)
	if err != nil {
		return sum, executeError(ctx, err)
	}
	defer func() { _ = conn.Close() }()
	runErr := conn.Raw(func(driverConn any) error { return run(ctx, driverConn, stmt.SQL, args, sink, &sum) })
	if errors.Is(runErr, engine.ErrStop) {
		return sum, nil
	}
	if runErr != nil {
		return sum, executeError(ctx, runErr)
	}
	return sum, nil
}

func executeError(ctx context.Context, err error) error {
	var engineErr *engine.Error
	if errors.As(err, &engineErr) {
		return err
	}
	if ctx.Err() != nil {
		return &engine.Error{Kind: engine.KindCanceled, Engine: ID, Op: "execute", Msg: "statement cancelled", Err: err}
	}
	return classify("execute", err)
}

func run(ctx context.Context, driverConn any, sqlText string, args []driver.NamedValue, sink engine.RowSink, sum *engine.Summary) error {
	preparer, ok := driverConn.(driver.ConnPrepareContext)
	if !ok {
		return errors.New("duckdb: driver connection cannot prepare statements")
	}
	prepared, err := preparer.PrepareContext(ctx, sqlText)
	if err != nil {
		return err //nolint:wrapcheck // executeError classifies the driver error
	}
	defer func() { _ = prepared.Close() }()
	st, ok := prepared.(*duckdbdriver.Stmt)
	if !ok {
		return errors.New("duckdb: unexpected prepared statement type")
	}
	kind, _ := st.StatementType()
	if returnsRows(st, kind) {
		// Close may abort an unfinished stream, so row-producing writes use the complete result.
		if kind == duckdbdriver.STATEMENT_TYPE_SELECT {
			err := st.StreamContext(ctx, args, func(rows driver.Rows) error {
				return streamRows(ctx, rows, sink, sum)
			})
			return err //nolint:wrapcheck // executeError classifies the driver error
		}
		rows, err := st.QueryContext(ctx, args)
		if err != nil {
			return err //nolint:wrapcheck // executeError classifies the driver error
		}
		defer func() { _ = rows.Close() }()
		return streamRows(ctx, rows, sink, sum)
	}
	res, err := st.ExecContext(ctx, args)
	if err != nil {
		return err //nolint:wrapcheck // executeError classifies the driver error
	}
	sum.RowsAffected, _ = res.RowsAffected()
	return nil
}

// returnsRows is false for statements whose only result is a row count or a
// success flag, which Summary reports instead.
func returnsRows(st *duckdbdriver.Stmt, kind duckdbdriver.StmtType) bool {
	columns, err := st.ColumnCount()
	if err != nil || columns == 0 {
		return false
	}
	switch kind {
	case duckdbdriver.STATEMENT_TYPE_INSERT, duckdbdriver.STATEMENT_TYPE_UPDATE, duckdbdriver.STATEMENT_TYPE_DELETE:
		name, _ := st.ColumnName(0)
		return columns != 1 || name != "Count"
	case duckdbdriver.STATEMENT_TYPE_CREATE, duckdbdriver.STATEMENT_TYPE_CREATE_FUNC, duckdbdriver.STATEMENT_TYPE_ALTER,
		duckdbdriver.STATEMENT_TYPE_DROP, duckdbdriver.STATEMENT_TYPE_ATTACH, duckdbdriver.STATEMENT_TYPE_DETACH,
		duckdbdriver.STATEMENT_TYPE_SET, duckdbdriver.STATEMENT_TYPE_VARIABLE_SET, duckdbdriver.STATEMENT_TYPE_TRANSACTION,
		duckdbdriver.STATEMENT_TYPE_LOAD, duckdbdriver.STATEMENT_TYPE_VACUUM, duckdbdriver.STATEMENT_TYPE_EXTENSION:
		return false
	}
	return true
}

func streamRows(ctx context.Context, rows driver.Rows, sink engine.RowSink, sum *engine.Summary) error {
	names := rows.Columns()
	typeNames := make([]string, len(names))
	cols := make([]engine.Column, len(names))
	typed, _ := rows.(driver.RowsColumnTypeDatabaseTypeName)
	for i, n := range names {
		if typed != nil {
			typeNames[i] = typed.ColumnTypeDatabaseTypeName(i)
		}
		cols[i] = engine.Column{Name: n, TypeName: typeNames[i], Kind: kindOfType(typeNames[i])}
	}
	sum.HasRows = true
	if err := sink.Columns(cols); err != nil {
		return err
	}

	dest := make([]driver.Value, len(names))
	batch := make([][]engine.Value, 0, engine.MaxBatchRows)
	flush := func() error {
		if err := ctx.Err(); err != nil {
			return err //nolint:wrapcheck // executeError turns it into a cancellation
		}
		if len(batch) == 0 {
			return nil
		}
		err := sink.Batch(batch)
		sum.RowsRead += int64(len(batch))
		batch = batch[:0]
		if err != nil {
			return err
		}
		return ctx.Err()
	}
	for {
		if err := ctx.Err(); err != nil {
			return err //nolint:wrapcheck // executeError turns it into a cancellation
		}
		if err := rows.Next(dest); err != nil {
			if errors.Is(err, io.EOF) {
				return flush()
			}
			return err //nolint:wrapcheck // executeError classifies the driver error
		}
		row := make([]engine.Value, len(dest))
		for i, d := range dest {
			row[i] = convert(typeNames[i], d)
		}
		batch = append(batch, row)
		if len(batch) == engine.MaxBatchRows {
			if err := flush(); err != nil {
				return err
			}
		}
	}
}
