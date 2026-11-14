package clickhouse

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"log/slog"
	"reflect"
	"runtime/debug"
	"strings"
	"time"

	chdriver "github.com/ClickHouse/clickhouse-go/v2"

	"github.com/doubledare704/queravue/core/internal/engine"
)

var _ engine.Executor = (*Conn)(nil)

// Execute implements engine.Executor. Cancelling ctx makes the driver send a cancel packet, which stops the query on the server.
func (c *Conn) Execute(ctx context.Context, stmt engine.Statement, sink engine.RowSink) (sum engine.Summary, err error) {
	start := time.Now()
	defer func() {
		sum.Duration = time.Since(start)
		if r := recover(); r != nil {
			slog.Error("clickhouse: execute panic", "panic", fmt.Sprint(r), "stack", string(debug.Stack()))
			err = &engine.Error{Kind: engine.KindUnknown, Engine: ID, Op: "execute", Msg: "internal error while running the statement"}
		}
	}()
	db, err := c.live("execute")
	if err != nil {
		return sum, err
	}
	args, err := toArgs(stmt.Params)
	if err != nil {
		return sum, &engine.Error{Kind: engine.KindInvalidConfig, Engine: ID, Op: "execute", Msg: err.Error()}
	}
	if !returnsRows(stmt.SQL) {
		if _, err := db.ExecContext(ctx, stmt.SQL, args...); err != nil {
			return sum, c.execError(ctx, err)
		}
		return sum, nil
	}
	rows, err := db.QueryContext(ctx, stmt.SQL, args...)
	if err != nil {
		return sum, c.execError(ctx, err)
	}
	defer func() { _ = rows.Close() }()
	return c.stream(ctx, rows, sink, sum)
}

func (c *Conn) stream(ctx context.Context, rows *sql.Rows, sink engine.RowSink, sum engine.Summary) (engine.Summary, error) {
	cts, err := rows.ColumnTypes()
	if err != nil {
		return sum, c.execError(ctx, err)
	}
	typeNames := make([]string, len(cts))
	cols := make([]engine.Column, len(cts))
	for i, ct := range cts {
		typeNames[i] = ct.DatabaseTypeName()
		cols[i] = engine.Column{Name: ct.Name(), TypeName: typeNames[i], Kind: kindOf(typeNames[i])}
	}
	sum.HasRows = len(cts) > 0
	if sum.HasRows {
		if err := sink.Columns(cols); err != nil {
			return finish(sum, err)
		}
	}

	targets := make([]reflect.Value, len(cts))
	dest := make([]any, len(cts))
	for i, ct := range cts {
		targets[i] = reflect.New(ct.ScanType())
		dest[i] = targets[i].Interface()
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
		if err := rows.Scan(dest...); err != nil {
			return sum, c.execError(ctx, err)
		}
		row := make([]engine.Value, len(targets))
		for i, target := range targets {
			row[i] = convert(typeNames[i], target.Elem())
		}
		batch = append(batch, row)
		if len(batch) == engine.MaxBatchRows {
			if err := flush(); err != nil {
				return finish(sum, err)
			}
		}
	}
	if err := rows.Err(); err != nil {
		return sum, c.execError(ctx, err)
	}
	if err := flush(); err != nil {
		return finish(sum, err)
	}
	return sum, nil
}

func finish(sum engine.Summary, sinkErr error) (engine.Summary, error) {
	if errors.Is(sinkErr, engine.ErrStop) {
		return sum, nil
	}
	return sum, sinkErr
}

func (c *Conn) execError(ctx context.Context, err error) error {
	if ctx.Err() != nil || errors.Is(err, context.Canceled) {
		return &engine.Error{Kind: engine.KindCanceled, Engine: ID, Op: "execute", Msg: "statement cancelled", Err: err}
	}
	e := classify(ID, "execute", err, c.secret)
	var exception *chdriver.Exception
	if e.Kind == engine.KindUnknown && errors.As(err, &exception) {
		e.Kind = engine.KindSQL
	}
	return e
}

func returnsRows(sql string) bool {
	switch firstWord(sql) {
	case "SELECT", "WITH", "SHOW", "DESCRIBE", "DESC", "EXPLAIN", "EXISTS", "CHECK", "VALUES":
		return true
	}
	return false
}

func firstWord(s string) string {
	for {
		s = strings.TrimLeft(s, " \t\r\n(")
		switch {
		case strings.HasPrefix(s, "--"), strings.HasPrefix(s, "#"):
			i := strings.IndexByte(s, '\n')
			if i < 0 {
				return ""
			}
			s = s[i+1:]
		case strings.HasPrefix(s, "/*"):
			i := strings.Index(s, "*/")
			if i < 0 {
				return ""
			}
			s = s[i+2:]
		default:
			i := 0
			for i < len(s) && (s[i] >= 'a' && s[i] <= 'z' || s[i] >= 'A' && s[i] <= 'Z') {
				i++
			}
			return strings.ToUpper(s[:i])
		}
	}
}
