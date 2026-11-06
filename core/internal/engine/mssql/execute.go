package mssql

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"runtime/debug"
	"strings"
	"time"

	mssqldb "github.com/microsoft/go-mssqldb"

	"github.com/doubledare704/queravue/core/internal/engine"
)

var _ engine.Executor = (*Conn)(nil)

// Execute implements engine.Executor. Rows are read from the TDS stream as
// the sink consumes them. Cancelling ctx makes the driver send a TDS
// attention signal, which stops the query on the server and leaves the
// session usable.
//
// Only the first result set of a batch is returned; see
// docs/engines/mssql.md.
func (c *Conn) Execute(ctx context.Context, stmt engine.Statement, sink engine.RowSink) (sum engine.Summary, err error) {
	start := time.Now()
	defer func() {
		sum.Duration = time.Since(start)
		if r := recover(); r != nil {
			slog.Error("mssql: execute panic", "panic", fmt.Sprint(r), "stack", string(debug.Stack()))
			err = &engine.Error{Kind: engine.KindUnknown, Engine: ID, Op: "execute", Msg: "internal error while running the statement"}
		}
	}()
	conn, err := c.live("execute")
	if err != nil {
		return sum, err
	}
	args, err := toArgs(stmt.Params)
	if err != nil {
		return sum, &engine.Error{Kind: engine.KindInvalidConfig, Engine: ID, Op: "execute", Msg: err.Error()}
	}

	if !returnsRows(stmt.SQL) {
		res, err := conn.ExecContext(ctx, stmt.SQL, args...)
		if err != nil {
			return sum, c.execError(ctx, err)
		}
		sum.RowsAffected, _ = res.RowsAffected()
		return sum, nil
	}

	rows, err := conn.QueryContext(ctx, stmt.SQL, args...)
	if err != nil {
		return sum, c.execError(ctx, err)
	}
	defer func() { _ = rows.Close() }()

	cts, err := rows.ColumnTypes()
	if err != nil {
		return sum, c.execError(ctx, err)
	}
	var typeNames []string
	if len(cts) > 0 {
		cols := make([]engine.Column, len(cts))
		typeNames = make([]string, len(cts))
		for i, ct := range cts {
			tn := strings.ToUpper(ct.DatabaseTypeName())
			typeNames[i] = tn
			cols[i] = engine.Column{Name: ct.Name(), TypeName: strings.ToLower(tn), Kind: kindOf(tn)}
		}
		sum.HasRows = true
		if err := sink.Columns(cols); err != nil {
			return c.finish(ctx, sum, err)
		}
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
			row[i] = convert(typeNames[i], v)
		}
		batch = append(batch, row)
		if len(batch) == engine.MaxBatchRows {
			if err := flush(); err != nil {
				return c.finish(ctx, sum, err)
			}
		}
	}
	if err := rows.Err(); err != nil {
		return sum, c.execError(ctx, err)
	}
	if err := flush(); err != nil {
		return c.finish(ctx, sum, err)
	}
	return sum, nil
}

// finish maps a sink error: ErrStop ends the statement cleanly. The deferred
// rows.Close in Execute then drains or cancels the rest of the stream.
func (c *Conn) finish(_ context.Context, sum engine.Summary, sinkErr error) (engine.Summary, error) {
	if errors.Is(sinkErr, engine.ErrStop) {
		return sum, nil
	}
	return sum, sinkErr
}

// execError classifies a statement failure.
func (c *Conn) execError(ctx context.Context, err error) error {
	if ctx.Err() != nil || errors.Is(err, context.Canceled) {
		return &engine.Error{Kind: engine.KindCanceled, Engine: ID, Op: "execute", Msg: "statement cancelled", Err: err}
	}
	e := classify(ID, "execute", err, c.secret)
	var se mssqldb.Error
	var sp *mssqldb.Error
	if e.Kind == engine.KindUnknown && (errors.As(err, &se) || errors.As(err, &sp)) {
		e.Kind = engine.KindSQL
	}
	return e
}

// returnsRows reports whether sql is read with Query (may return a result
// set) rather than Exec (reports rows affected). Only plain DML without an
// OUTPUT clause is Exec'd.
func returnsRows(sql string) bool {
	switch firstWord(sql) {
	case "INSERT", "UPDATE", "DELETE", "MERGE":
		return strings.Contains(strings.ToUpper(sql), "OUTPUT")
	}
	return true
}

// firstWord returns the upper-cased first keyword, skipping comments.
func firstWord(s string) string {
	for {
		s = strings.TrimLeft(s, " \t\r\n(")
		switch {
		case strings.HasPrefix(s, "--"):
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

// kindOf maps an upper-case type name to a value kind.
func kindOf(typeName string) engine.ValueKind {
	switch typeName {
	case "BIGINT", "INT", "SMALLINT", "TINYINT":
		return engine.VInt
	case "BIT":
		return engine.VBool
	case "REAL", "FLOAT":
		return engine.VFloat
	case "DECIMAL", "NUMERIC", "MONEY", "SMALLMONEY":
		return engine.VDecimal
	case "DATETIME", "DATETIME2", "SMALLDATETIME", "DATETIMEOFFSET":
		return engine.VTimestamptz
	case "UNIQUEIDENTIFIER":
		return engine.VUUID
	case "BINARY", "VARBINARY", "IMAGE", "TIMESTAMP", "ROWVERSION":
		return engine.VBytes
	case "JSON":
		return engine.VJSON
	}
	return engine.VText
}

// convert turns one driver value into a typed value. Anything unexpected
// falls back to text, so a result is never lost to a decode bug.
func convert(typeName string, v any) engine.Value {
	switch x := v.(type) {
	case nil:
		return engine.Null()
	case int64:
		return engine.Int(x)
	case bool:
		return engine.Bool(x)
	case float64:
		return engine.Float(x)
	case string:
		if kindOf(typeName) == engine.VJSON {
			return engine.JSON(x)
		}
		return engine.Text(x)
	case time.Time:
		switch typeName {
		case "DATE":
			return engine.Text(x.Format("2006-01-02"))
		case "TIME":
			return engine.Text(x.Format("15:04:05.9999999"))
		}
		return engine.Timestamptz(x)
	case []byte:
		switch kindOf(typeName) {
		case engine.VDecimal:
			return engine.Decimal(string(x))
		case engine.VUUID:
			var u mssqldb.UniqueIdentifier
			if err := u.Scan(x); err == nil {
				return engine.UUID(u.String())
			}
			return engine.Bytes(append([]byte(nil), x...))
		case engine.VBytes:
			return engine.Bytes(append([]byte(nil), x...))
		}
		return engine.Text(string(x))
	}
	return engine.Text(fmt.Sprint(v))
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
			out[i] = v.Time
		default:
			return nil, fmt.Errorf("parameter %d: unsupported type", i+1)
		}
	}
	return out, nil
}
