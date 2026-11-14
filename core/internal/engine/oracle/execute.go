package oracle

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"log/slog"
	"runtime/debug"
	"strings"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

var _ engine.Executor = (*Conn)(nil)

type queryRunner interface {
	ExecContext(ctx context.Context, query string, args ...any) (sql.Result, error)
	QueryContext(ctx context.Context, query string, args ...any) (*sql.Rows, error)
	QueryRowContext(ctx context.Context, query string, args ...any) *sql.Row
}

// Execute implements engine.Executor. Rows are read from the network as the
// sink consumes them. Cancelling ctx makes the driver send a break to the
// server, which ends the statement with ORA-01013 and leaves the session
// usable.
//
// Oracle starts transactions implicitly and the driver commits after every
// statement, so SET TRANSACTION, COMMIT and ROLLBACK are turned into a driver
// transaction held on the connection.
func (c *Conn) Execute(ctx context.Context, stmt engine.Statement, sink engine.RowSink) (sum engine.Summary, err error) {
	start := time.Now()
	defer func() {
		sum.Duration = time.Since(start)
		if r := recover(); r != nil {
			slog.Error("oracle: execute panic", "panic", fmt.Sprint(r), "stack", string(debug.Stack()))
			err = &engine.Error{Kind: engine.KindUnknown, Engine: ID, Op: "execute", Msg: "internal error while running the statement"}
		}
	}()
	conn, err := c.live("execute")
	if err != nil {
		return sum, err
	}
	text := withoutTerminator(stmt.SQL)
	if handled, err := c.transactionControl(ctx, conn, text); handled {
		return sum, err
	}
	args, err := toArgs(stmt.Params)
	if err != nil {
		return sum, &engine.Error{Kind: engine.KindInvalidConfig, Engine: ID, Op: "execute", Msg: err.Error()}
	}
	runner := c.runner(conn)

	if !returnsRows(text) {
		res, err := runner.ExecContext(ctx, text, args...)
		if err != nil {
			return sum, c.execError(ctx, err)
		}
		sum.RowsAffected, _ = res.RowsAffected()
		return sum, nil
	}

	rows, err := runner.QueryContext(ctx, text, args...)
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
	kinds := make([]engine.ValueKind, len(cts))
	natives := make([]string, len(cts))
	cols := make([]engine.Column, len(cts))
	for i, ct := range cts {
		precision, scale, hasSize := ct.DecimalSize()
		natives[i] = nativeName(ct.DatabaseTypeName())
		kinds[i] = columnKind(natives[i], precision, scale, hasSize && scale != 255)
		cols[i] = engine.Column{Name: ct.Name(), TypeName: strings.ToLower(natives[i]), Kind: kinds[i]}
	}
	sum.HasRows = true
	if err := sink.Columns(cols); err != nil {
		return finish(sum, err)
	}

	vals := make([]any, len(cts))
	dest := make([]any, len(cts))
	for i := range vals {
		dest[i] = &vals[i]
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
		row := make([]engine.Value, len(vals))
		for i, v := range vals {
			row[i] = convert(kinds[i], natives[i], v)
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

// finish maps a sink error: ErrStop ends the statement cleanly.
func finish(sum engine.Summary, sinkErr error) (engine.Summary, error) {
	if errors.Is(sinkErr, engine.ErrStop) {
		return sum, nil
	}
	return sum, sinkErr
}

func (c *Conn) runner(conn *sql.Conn) queryRunner {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.tx != nil {
		return c.tx
	}
	return conn
}

// transactionControl handles the statements that start or end a transaction
// and reports whether text was one of them.
func (c *Conn) transactionControl(ctx context.Context, conn *sql.Conn, text string) (bool, error) {
	words := leadingWords(text, 3)
	switch {
	case len(words) >= 2 && words[0] == "SET" && words[1] == "TRANSACTION":
		return true, c.beginTransaction(conn)
	case len(words) == 1 && words[0] == "COMMIT":
		return true, c.endTransaction(ctx, true)
	case len(words) == 1 && words[0] == "ROLLBACK":
		return true, c.endTransaction(ctx, false)
	}
	return false, nil
}

func (c *Conn) beginTransaction(conn *sql.Conn) error {
	c.mu.Lock()
	defer c.mu.Unlock()
	if c.tx != nil {
		return nil
	}
	// The transaction outlives the request that opened it, so it takes no request context.
	tx, err := conn.BeginTx(context.Background(), nil)
	if err != nil {
		return classify("begin", err, c.secret)
	}
	c.tx = tx
	return nil
}

func (c *Conn) endTransaction(_ context.Context, commit bool) error {
	c.mu.Lock()
	tx := c.tx
	c.tx = nil
	c.mu.Unlock()
	if tx == nil {
		return nil
	}
	if commit {
		if err := tx.Commit(); err != nil {
			return classify("commit", err, c.secret)
		}
		return nil
	}
	if err := tx.Rollback(); err != nil {
		return classify("rollback", err, c.secret)
	}
	return nil
}

// execError classifies a statement failure.
func (c *Conn) execError(ctx context.Context, err error) error {
	if ctx.Err() != nil || errors.Is(err, context.Canceled) {
		return &engine.Error{Kind: engine.KindCanceled, Engine: ID, Op: "execute", Msg: "statement cancelled", Err: err}
	}
	e := classify("execute", err, c.secret)
	if e.Kind == engine.KindCanceled {
		e.Msg = "statement cancelled"
	}
	return e
}

// withoutTerminator drops the ";" or "/" that ends a statement, which the
// server rejects, but keeps the ";" a PL/SQL block needs.
func withoutTerminator(text string) string {
	ranges := sqlsplit.Split(sqlsplit.Oracle, text)
	if len(ranges) == 1 {
		return ranges[0].Text(text)
	}
	return strings.TrimSpace(text)
}

// returnsRows reports whether text is read with Query rather than Exec.
func returnsRows(text string) bool {
	switch first := leadingWords(text, 1); {
	case len(first) == 0:
		return false
	case first[0] == "SELECT" || first[0] == "WITH" || first[0] == "VALUES" || first[0] == "TABLE":
		return true
	}
	return false
}

// leadingWords returns up to n upper-cased keywords, skipping comments.
func leadingWords(s string, n int) []string {
	var out []string
	for len(out) < n {
		s = strings.TrimLeft(s, " \t\r\n(")
		switch {
		case strings.HasPrefix(s, "--"):
			i := strings.IndexByte(s, '\n')
			if i < 0 {
				return out
			}
			s = s[i+1:]
		case strings.HasPrefix(s, "/*"):
			i := strings.Index(s, "*/")
			if i < 0 {
				return out
			}
			s = s[i+2:]
		default:
			i := 0
			for i < len(s) && (s[i] >= 'a' && s[i] <= 'z' || s[i] >= 'A' && s[i] <= 'Z') {
				i++
			}
			if i == 0 {
				return out
			}
			out = append(out, strings.ToUpper(s[:i]))
			s = s[i:]
		}
	}
	return out
}
