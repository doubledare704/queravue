package sqlite

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"log/slog"
	"runtime/debug"
	"strings"
	"time"

	sqlite "modernc.org/sqlite"
	sqlite3 "modernc.org/sqlite/lib"

	"github.com/doubledare704/queravue/core/internal/engine"
)

var _ engine.Executor = (*Conn)(nil)

// Execute implements engine.Executor. Cancelling ctx interrupts the running
// statement (sqlite3_interrupt).
func (c *Conn) Execute(ctx context.Context, stmt engine.Statement, sink engine.RowSink) (sum engine.Summary, err error) {
	start := time.Now()
	defer func() {
		sum.Duration = time.Since(start)
		if r := recover(); r != nil {
			slog.Error("sqlite: execute panic", "panic", fmt.Sprint(r), "stack", string(debug.Stack()))
			err = &engine.Error{Kind: engine.KindUnknown, Engine: ID, Op: "execute", Msg: "internal error while running the statement"}
		}
	}()
	c.mu.Lock()
	db := c.db
	c.mu.Unlock()
	if db == nil {
		return sum, &engine.Error{Kind: engine.KindConnectionLost, Engine: ID, Op: "execute", Msg: "connection is closed"}
	}
	args, err := toArgs(stmt.Params)
	if err != nil {
		return sum, &engine.Error{Kind: engine.KindInvalidConfig, Engine: ID, Op: "execute", Msg: err.Error()}
	}

	var before int64
	_ = db.QueryRowContext(ctx, "SELECT total_changes()").Scan(&before)

	qctx, cancelQuery := context.WithCancel(ctx)
	defer cancelQuery()
	rows, err := db.QueryContext(qctx, stmt.SQL, args...)
	if err != nil {
		return sum, execError(ctx, err)
	}
	defer func() { _ = rows.Close() }()

	names, err := rows.Columns()
	if err != nil {
		return sum, execError(ctx, err)
	}
	decl := make([]string, len(names))
	if cts, err := rows.ColumnTypes(); err == nil {
		for i, ct := range cts {
			decl[i] = strings.ToUpper(ct.DatabaseTypeName())
		}
	}
	if len(names) > 0 {
		cols := make([]engine.Column, len(names))
		for i, n := range names {
			cols[i] = engine.Column{Name: n, TypeName: strings.ToLower(decl[i]), Kind: declKind(decl[i])}
		}
		sum.HasRows = true
		if err := sink.Columns(cols); err != nil {
			return finish(ctx, sum, rows, cancelQuery, err, db, before)
		}
	}

	dest := make([]any, len(names))
	ptrs := make([]any, len(names))
	for i := range dest {
		ptrs[i] = &dest[i]
	}
	batch := make([][]engine.Value, 0, engine.MaxBatchRows)
	flush := func() error {
		if len(batch) == 0 {
			return nil
		}
		err := sink.Batch(batch)
		sum.RowsRead += int64(len(batch))
		batch = batch[:0]
		return err
	}
	for rows.Next() {
		if len(names) == 0 {
			continue
		}
		if err := rows.Scan(ptrs...); err != nil {
			return sum, execError(ctx, err)
		}
		row := make([]engine.Value, len(dest))
		for i, d := range dest {
			row[i] = convert(decl[i], d)
		}
		batch = append(batch, row)
		if len(batch) == engine.MaxBatchRows {
			if err := flush(); err != nil {
				return finish(ctx, sum, rows, cancelQuery, err, db, before)
			}
		}
	}
	if rows.Err() == nil {
		if err := flush(); err != nil {
			return finish(ctx, sum, rows, cancelQuery, err, db, before)
		}
	}
	return finish(ctx, sum, rows, cancelQuery, nil, db, before)
}

func finish(ctx context.Context, sum engine.Summary, rows *sql.Rows, cancelQuery context.CancelFunc, sinkErr error, db *sql.DB, before int64) (engine.Summary, error) {
	if sinkErr != nil {
		cancelQuery()
	}
	_ = rows.Close()
	if sinkErr != nil {
		if errors.Is(sinkErr, engine.ErrStop) {
			return sum, nil
		}
		return sum, sinkErr
	}
	if err := rows.Err(); err != nil {
		return sum, execError(ctx, err)
	}
	if !sum.HasRows {
		var after int64
		if err := db.QueryRowContext(ctx, "SELECT total_changes()").Scan(&after); err == nil {
			sum.RowsAffected = after - before
		}
	}
	return sum, nil
}

func execError(ctx context.Context, err error) error {
	e := &engine.Error{Engine: ID, Op: "execute", Err: err, Msg: err.Error()}
	var se *sqlite.Error
	switch {
	case ctx.Err() != nil || errors.Is(err, context.Canceled):
		e.Kind, e.Msg = engine.KindCanceled, "statement cancelled"
	case errors.As(err, &se):
		if se.Code()&0xff == sqlite3.SQLITE_INTERRUPT {
			e.Kind, e.Msg = engine.KindCanceled, "statement cancelled"
		} else {
			e.Kind = engine.KindSQL
		}
	default:
		e.Kind = engine.KindUnknown
	}
	return e
}

// declKind maps a declared column type (SQLite affinity rules, roughly) to a
// column kind hint.
func declKind(decl string) engine.ValueKind {
	switch {
	case strings.Contains(decl, "BOOL"):
		return engine.VBool
	case strings.Contains(decl, "INT"):
		return engine.VInt
	case strings.Contains(decl, "REAL"), strings.Contains(decl, "FLOA"), strings.Contains(decl, "DOUBLE"):
		return engine.VFloat
	case strings.Contains(decl, "BLOB"):
		return engine.VBytes
	case strings.Contains(decl, "JSON"):
		return engine.VJSON
	case strings.Contains(decl, "TIMESTAMP"), strings.Contains(decl, "DATETIME"):
		return engine.VTimestamptz
	}
	return engine.VText
}

// convert maps a driver value to a typed value. SQLite is dynamically typed,
// so the value decides, with the declared type refining text.
func convert(decl string, v any) engine.Value {
	switch x := v.(type) {
	case nil:
		return engine.Null()
	case bool:
		return engine.Bool(x)
	case int64:
		return engine.Int(x)
	case float64:
		return engine.Float(x)
	case []byte:
		return engine.Bytes(append([]byte(nil), x...))
	case time.Time:
		return engine.Timestamptz(x)
	case string:
		if strings.Contains(decl, "JSON") {
			return engine.JSON(x)
		}
		return engine.Text(x)
	}
	return engine.Text(fmt.Sprint(v))
}

func toArgs(vals []engine.Value) ([]any, error) {
	out := make([]any, len(vals))
	for i, v := range vals {
		switch v.Kind {
		case engine.VNull:
			out[i] = nil
		case engine.VBool:
			out[i] = v.Bool
		case engine.VInt:
			out[i] = v.Int
		case engine.VFloat:
			out[i] = v.Float
		case engine.VDecimal, engine.VText, engine.VJSON, engine.VUUID:
			out[i] = v.Str
		case engine.VBytes:
			out[i] = v.Bytes
		case engine.VTimestamptz:
			out[i] = v.Time
		default:
			return nil, fmt.Errorf("parameter %d: unsupported type", i+1)
		}
	}
	return out, nil
}
