package mysql

import (
	"context"
	"database/sql"
	"errors"
	"fmt"
	"log/slog"
	"runtime/debug"
	"strconv"
	"strings"
	"sync"
	"time"

	drv "github.com/go-sql-driver/mysql"

	"github.com/doubledare704/queravue/core/internal/engine"
)

var _ engine.Executor = (*Conn)(nil)

// killTimeout bounds the KILL QUERY side request.
const killTimeout = 5 * time.Second

// Execute implements engine.Executor. Rows are read from the socket as the
// sink consumes them; nothing buffers the full result.
//
// Cancelling ctx (or the sink returning an error) sends KILL QUERY on a
// second connection. The statement itself runs on a context that is not
// cancelled by ctx, because the driver reacts to cancellation by closing the
// socket, which would leave the query running and lose the session.
func (c *Conn) Execute(ctx context.Context, stmt engine.Statement, sink engine.RowSink) (sum engine.Summary, err error) {
	start := time.Now()
	defer func() {
		sum.Duration = time.Since(start)
		if r := recover(); r != nil {
			slog.Error("mysql: execute panic", "panic", fmt.Sprint(r), "stack", string(debug.Stack()))
			err = &engine.Error{Kind: engine.KindUnknown, Engine: c.id, Op: "execute", Msg: "internal error while running the statement"}
		}
	}()
	conn, err := c.live("execute")
	if err != nil {
		return sum, err
	}
	args, err := toArgs(stmt.Params)
	if err != nil {
		return sum, &engine.Error{Kind: engine.KindInvalidConfig, Engine: c.id, Op: "execute", Msg: err.Error()}
	}

	qctx, cutSocket := context.WithCancel(context.WithoutCancel(ctx))
	defer cutSocket()

	// The watcher kills the running query when ctx is cancelled. Execute
	// waits for it before returning, so a late KILL can never hit the next
	// statement on this connection.
	done := make(chan struct{})
	var wg sync.WaitGroup
	var cancelled bool
	var cmu sync.Mutex
	kill := func() {
		if err := c.killQuery(); err != nil {
			cutSocket() // last resort: drop the socket
		}
	}
	wg.Add(1)
	go func() {
		defer wg.Done()
		select {
		case <-ctx.Done():
			cmu.Lock()
			cancelled = true
			cmu.Unlock()
			kill()
		case <-done:
		}
	}()
	defer func() {
		close(done)
		wg.Wait()
		cmu.Lock()
		was := cancelled
		cmu.Unlock()
		if was && err == nil {
			err = &engine.Error{Kind: engine.KindCanceled, Engine: c.id, Op: "execute", Msg: "statement cancelled"}
		}
	}()

	if !returnsRows(stmt.SQL) {
		res, err := conn.ExecContext(qctx, stmt.SQL, args...)
		if err != nil {
			return sum, c.execError(ctx, err)
		}
		sum.RowsAffected, _ = res.RowsAffected()
		return sum, nil
	}

	rows, err := conn.QueryContext(qctx, stmt.SQL, args...)
	if err != nil {
		return sum, c.execError(ctx, err)
	}
	defer func() { _ = rows.Close() }()

	cts, err := rows.ColumnTypes()
	if err != nil {
		return sum, c.execError(ctx, err)
	}
	var kinds []engine.ValueKind
	var typeNames []string
	if len(cts) > 0 {
		cols := make([]engine.Column, len(cts))
		kinds = make([]engine.ValueKind, len(cts))
		typeNames = make([]string, len(cts))
		for i, ct := range cts {
			tn := ct.DatabaseTypeName()
			typeNames[i] = tn
			kinds[i] = kindOf(tn)
			cols[i] = engine.Column{Name: ct.Name(), TypeName: strings.ToLower(tn), Kind: kinds[i]}
		}
		sum.HasRows = true
		if err := sink.Columns(cols); err != nil {
			return c.finish(ctx, sum, rows, kill, err)
		}
	}

	raw := make([]sql.RawBytes, len(cts))
	dest := make([]any, len(cts))
	for i := range raw {
		dest[i] = &raw[i]
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
		row := make([]engine.Value, len(raw))
		for i, b := range raw {
			row[i] = convert(typeNames[i], b)
		}
		batch = append(batch, row)
		if len(batch) == engine.MaxBatchRows {
			if err := flush(); err != nil {
				return c.finish(ctx, sum, rows, kill, err)
			}
		}
	}
	if rows.Err() == nil {
		if err := flush(); err != nil {
			return c.finish(ctx, sum, rows, kill, err)
		}
	}
	return c.finish(ctx, sum, rows, kill, nil)
}

// finish closes rows and builds the result. A sink error stops the query on
// the server first, so an abandoned 1M-row SELECT does not keep streaming.
func (c *Conn) finish(ctx context.Context, sum engine.Summary, rows *sql.Rows, kill func(), sinkErr error) (engine.Summary, error) {
	if sinkErr != nil {
		kill()
	}
	_ = rows.Close()
	if sinkErr != nil {
		if errors.Is(sinkErr, engine.ErrStop) {
			return sum, nil
		}
		return sum, sinkErr
	}
	if err := rows.Err(); err != nil {
		return sum, c.execError(ctx, err)
	}
	return sum, nil
}

// killQuery stops the statement running on the session connection.
func (c *Conn) killQuery() error {
	c.mu.Lock()
	db := c.db
	c.mu.Unlock()
	if db == nil {
		return errors.New("closed")
	}
	kctx, cancel := context.WithTimeout(context.Background(), killTimeout)
	defer cancel()
	if _, err := db.ExecContext(kctx, "KILL QUERY "+strconv.FormatUint(c.connID, 10)); err != nil {
		return fmt.Errorf("%s: kill query: %w", c.id, err)
	}
	return nil
}

// execError classifies a statement failure.
func (c *Conn) execError(ctx context.Context, err error) error {
	var me *drv.MySQLError
	if ctx.Err() != nil || (errors.As(err, &me) && me.Number == errQueryInterrupt) {
		return &engine.Error{Kind: engine.KindCanceled, Engine: c.id, Op: "execute", Msg: "statement cancelled", Err: err}
	}
	e := classify(c.id, "execute", err, c.secret)
	if errors.As(err, &me) && e.Kind == engine.KindUnknown {
		e.Kind = engine.KindSQL
	}
	return e
}

// returnsRows reports whether sql is read with Query (may return a result
// set) rather than Exec (reports rows affected). Only plain DML is Exec'd.
func returnsRows(sql string) bool {
	w := firstWord(sql)
	switch w {
	case "INSERT", "UPDATE", "DELETE", "REPLACE":
		return strings.Contains(strings.ToUpper(sql), "RETURNING")
	}
	return true
}

// firstWord returns the upper-cased first keyword, skipping comments.
func firstWord(s string) string {
	for {
		s = strings.TrimLeft(s, " \t\r\n(")
		switch {
		case strings.HasPrefix(s, "--") || strings.HasPrefix(s, "#"):
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

// kindOf maps a column type name (driver DatabaseTypeName) to a value kind.
func kindOf(typeName string) engine.ValueKind {
	t := strings.TrimPrefix(strings.ToUpper(typeName), "UNSIGNED ")
	switch t {
	case "TINYINT", "SMALLINT", "MEDIUMINT", "INT", "BIGINT", "YEAR":
		return engine.VInt
	case "FLOAT", "DOUBLE":
		return engine.VFloat
	case "DECIMAL":
		return engine.VDecimal
	case "DATETIME", "TIMESTAMP":
		return engine.VTimestamptz
	case "JSON":
		return engine.VJSON
	case "BLOB", "TINYBLOB", "MEDIUMBLOB", "LONGBLOB", "BINARY", "VARBINARY", "BIT", "GEOMETRY":
		return engine.VBytes
	}
	return engine.VText
}

// convert turns one text-format value into a typed value. Anything it cannot
// parse (zero dates, out-of-range numbers) falls back to text, so a result is
// never lost to a decode bug.
func convert(typeName string, raw sql.RawBytes) engine.Value {
	if raw == nil {
		return engine.Null()
	}
	s := string(raw) // copies; raw is reused by the driver
	switch kindOf(typeName) {
	case engine.VInt:
		if i, err := strconv.ParseInt(s, 10, 64); err == nil {
			return engine.Int(i)
		}
		if strings.HasPrefix(strings.ToUpper(typeName), "UNSIGNED") {
			return engine.Decimal(s) // above MaxInt64
		}
	case engine.VFloat:
		if f, err := strconv.ParseFloat(s, 64); err == nil {
			return engine.Float(f)
		}
	case engine.VDecimal:
		return engine.Decimal(s)
	case engine.VTimestamptz:
		if t, ok := parseDateTime(s); ok {
			return engine.Timestamptz(t)
		}
	case engine.VJSON:
		return engine.JSON(s)
	case engine.VBytes:
		return engine.Bytes([]byte(s))
	}
	return engine.Text(s)
}

var dtLayouts = []string{"2006-01-02 15:04:05.999999", "2006-01-02 15:04:05"}

// parseDateTime parses DATETIME/TIMESTAMP text as UTC. Zero dates like
// 0000-00-00 are not valid times and return false.
func parseDateTime(s string) (time.Time, bool) {
	for _, l := range dtLayouts {
		if t, err := time.ParseInLocation(l, s, time.UTC); err == nil {
			return t, true
		}
	}
	return time.Time{}, false
}

// toArgs converts bind parameters to driver arguments.
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
			out[i] = v.Time.UTC().Format("2006-01-02 15:04:05.999999")
		default:
			return nil, fmt.Errorf("parameter %d: unsupported type", i+1)
		}
	}
	return out, nil
}
