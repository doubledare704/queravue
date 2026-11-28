package oracle

import (
	"context"
	"database/sql"
	"errors"
	"math"
	"strconv"
	"strings"
	"time"

	"github.com/sijms/go-ora/v2/network"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

var _ engine.RowLoader = (*Conn)(nil)

const (
	maxRowsPerBind     = 10000
	maxNumberMagnitude = 1e125
	rollbackTimeout    = 5 * time.Second
)

// LoadRows implements engine.RowLoader with array binding: one INSERT is sent
// with a column-wise array per bind variable, so a chunk of rows costs one
// round trip. Each batch commits in a transaction of its own.
func (c *Conn) LoadRows(ctx context.Context, t engine.LoadTarget, columns []string, src engine.RowBatchSource) (engine.LoadStats, error) {
	const op = "load rows"
	if t.Table == "" || len(columns) == 0 {
		return engine.LoadStats{}, engine.Errorf(engine.KindInvalidConfig, ID, op, "table and columns are required")
	}
	conn, err := c.live(op)
	if err != nil {
		return engine.LoadStats{}, err
	}
	if c.transactionOpen() {
		return engine.LoadStats{}, engine.Errorf(engine.KindUnsupported, ID, op, "a transaction is open on this connection; commit or roll it back before loading")
	}
	run := &loadRun{c: c, conn: conn, width: len(columns), insertSQL: insertStatement(t, columns)}
	return engine.DriveLoad(ctx, ID, op, src.Next, func(rows [][]engine.Value) int { return len(rows) }, run.commitBatch)
}

func (c *Conn) transactionOpen() bool {
	c.mu.Lock()
	defer c.mu.Unlock()
	return c.tx != nil
}

func insertStatement(t engine.LoadTarget, columns []string) string {
	quoted := make([]string, len(columns))
	placeholders := make([]string, len(columns))
	for i, name := range columns {
		quoted[i] = sqldialect.Oracle.QuoteIdent(name)
		placeholders[i] = sqldialect.Oracle.Placeholder(i + 1)
	}
	return "INSERT INTO " + sqldialect.Oracle.QualifyTable(t.Schema, t.Table) +
		" (" + strings.Join(quoted, ", ") + ") VALUES (" + strings.Join(placeholders, ", ") + ")"
}

type loadRun struct {
	c         *Conn
	conn      *sql.Conn
	width     int
	insertSQL string
}

func (r *loadRun) commitBatch(ctx context.Context, rows [][]engine.Value) (engine.LoadStats, error) {
	if err := engine.CheckLoadWidths(ID, rows, r.width); err != nil {
		return engine.LoadStats{}, err
	}
	tx, err := r.conn.BeginTx(ctx, nil)
	if err != nil {
		return engine.LoadStats{}, r.c.loadError(ctx, err)
	}
	inserted, err := r.insertChunks(ctx, tx, rows)
	if err != nil {
		rollback(tx)
		return engine.LoadStats{}, err
	}
	if err := ctx.Err(); err != nil {
		rollback(tx)
		return engine.LoadStats{}, r.c.loadError(ctx, err)
	}
	if err := tx.Commit(); err != nil {
		return engine.LoadStats{}, r.c.loadError(ctx, err)
	}
	return engine.LoadStats{Rows: inserted, Batches: 1}, nil
}

func (r *loadRun) insertChunks(ctx context.Context, tx *sql.Tx, rows [][]engine.Value) (uint64, error) {
	var inserted uint64
	for start := 0; start < len(rows); start += maxRowsPerBind {
		if err := ctx.Err(); err != nil {
			return 0, r.c.loadError(ctx, err)
		}
		chunk := rows[start:min(start+maxRowsPerBind, len(rows))]
		args, err := columnArrays(chunk, r.width)
		if err != nil {
			return 0, &engine.Error{Kind: engine.KindInvalidConfig, Engine: ID, Op: "load rows", Msg: err.Error()}
		}
		res, err := tx.ExecContext(ctx, r.insertSQL, args...)
		if err != nil {
			return 0, r.c.loadError(ctx, err)
		}
		changed, err := res.RowsAffected()
		if err != nil {
			return 0, r.c.loadError(ctx, err)
		}
		inserted += uint64(changed) //nolint:gosec // a row count is non-negative
	}
	return inserted, nil
}

// columnArrays turns rows into one slice per column, which go-ora binds as an
// array.
func columnArrays(rows [][]engine.Value, width int) ([]any, error) {
	columns := make([][]any, width)
	for i := range columns {
		columns[i] = make([]any, len(rows))
	}
	for r, row := range rows {
		args, err := toArgs(row)
		if err != nil {
			return nil, err
		}
		for i, arg := range args {
			columns[i][r] = bindable(arg)
		}
	}
	out := make([]any, width)
	for i := range columns {
		out[i] = columns[i]
	}
	return out, nil
}

// bindable sends floats that go-ora's NUMBER encoding cannot carry (NaN,
// infinities, beyond 1e125) as text, which BINARY_DOUBLE columns convert.
func bindable(arg any) any {
	f, ok := arg.(float64)
	if !ok || (!math.IsNaN(f) && !math.IsInf(f, 0) && math.Abs(f) < maxNumberMagnitude) {
		return arg
	}
	switch {
	case math.IsNaN(f):
		return "NaN"
	case math.IsInf(f, 1):
		return "Inf"
	case math.IsInf(f, -1):
		return "-Inf"
	}
	return strconv.FormatFloat(f, 'g', -1, 64)
}

func rollback(tx *sql.Tx) {
	done := make(chan struct{})
	go func() {
		defer close(done)
		_ = tx.Rollback()
	}()
	select {
	case <-done:
	case <-time.After(rollbackTimeout):
	}
}

const (
	oraUniqueViolated  = 1
	oraNullViolated    = 1400
	oraCheckViolated   = 2290
	oraParentMissing   = 2291
	oraChildFound      = 2292
	oraNullUpdate      = 1407
	oraInvalidNumber   = 1722
	oraNumberPrecision = 1438
	oraValueTooLarge   = 12899
)

var constraintCodes = map[int]bool{
	oraUniqueViolated: true, oraNullViolated: true, oraCheckViolated: true,
	oraParentMissing: true, oraChildFound: true, oraNullUpdate: true,
}

var dataCodes = map[int]bool{oraInvalidNumber: true, oraNumberPrecision: true, oraValueTooLarge: true}

// loadError classifies a failed load. ORA messages name constraints and
// columns, not the rejected values.
func (c *Conn) loadError(ctx context.Context, err error) error {
	var typed *engine.Error
	if errors.As(err, &typed) {
		return typed
	}
	if ctx.Err() != nil || errors.Is(err, context.Canceled) {
		kind, msg := engine.KindCanceled, "load cancelled"
		if errors.Is(ctx.Err(), context.DeadlineExceeded) {
			kind, msg = engine.KindTimeout, "load timed out"
		}
		return &engine.Error{Kind: kind, Engine: ID, Op: "load rows", Msg: msg, Err: err}
	}
	classified := classify("load rows", err, c.secret)
	var oe *network.OracleError
	if errors.As(err, &oe) && oe != nil {
		classified.Msg = firstLine(classified.Msg)
		switch {
		case constraintCodes[oe.ErrCode]:
			classified.Kind = engine.KindConstraint
		case dataCodes[oe.ErrCode]:
			classified.Msg = "a value was rejected by its column type (ORA-" + zeroPad(oe.ErrCode) + ")"
		}
	}
	return classified
}

// firstLine drops the detail lines that follow the ORA code: since 23ai the
// unique violation adds one that quotes the offending key values.
func firstLine(msg string) string {
	first, _, _ := strings.Cut(msg, "\n")
	return strings.TrimSpace(first)
}

func zeroPad(code int) string {
	s := strconv.Itoa(code)
	for len(s) < 5 {
		s = "0" + s
	}
	return s
}
