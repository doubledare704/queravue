package postgres

import (
	"context"
	"encoding/hex"
	"errors"
	"fmt"
	"io"
	"math"
	"strconv"
	"strings"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

var _ engine.RowLoader = (*Conn)(nil)

const (
	copyChunkBytes  = 64 << 10
	rollbackTimeout = 5 * time.Second
	timestampLayout = "2006-01-02T15:04:05.999999Z07:00"
)

// LoadRows implements engine.RowLoader with COPY ... FROM STDIN in text
// format, one transaction per batch. Text format lets the server parse every
// column type, including those engine.Value has no kind for.
func (c *Conn) LoadRows(ctx context.Context, t engine.LoadTarget, columns []string, src engine.RowBatchSource) (engine.LoadStats, error) {
	const op = "load rows"
	if t.Table == "" || len(columns) == 0 {
		return engine.LoadStats{}, engine.Errorf(engine.KindInvalidConfig, c.id, op, "table and columns are required")
	}
	c.mu.Lock()
	conn := c.conn
	c.mu.Unlock()
	if conn == nil {
		return engine.LoadStats{}, &engine.Error{Kind: engine.KindConnectionLost, Engine: c.id, Op: op, Msg: "connection is closed"}
	}
	copySQL := copyStatement(t, columns)
	commit := func(ctx context.Context, rows [][]engine.Value) (engine.LoadStats, error) {
		return c.copyBatch(ctx, conn, copySQL, len(columns), rows)
	}
	return engine.DriveLoad(ctx, c.id, op, src.Next, func(rows [][]engine.Value) int { return len(rows) }, commit)
}

func copyStatement(t engine.LoadTarget, columns []string) string {
	quoted := make([]string, len(columns))
	for i, name := range columns {
		quoted[i] = sqldialect.Postgres.QuoteIdent(name)
	}
	return "COPY " + sqldialect.Postgres.QualifyTable(t.Schema, t.Table) + " (" + strings.Join(quoted, ", ") + ") FROM STDIN"
}

func (c *Conn) copyBatch(ctx context.Context, conn *pgx.Conn, copySQL string, width int, rows [][]engine.Value) (engine.LoadStats, error) {
	for i, row := range rows {
		if len(row) != width {
			return engine.LoadStats{}, engine.Errorf(engine.KindInvalidConfig, c.id, "load rows", "row %d has %d values for %d columns", i, len(row), width)
		}
	}
	tx, err := conn.Begin(ctx)
	if err != nil {
		return engine.LoadStats{}, c.loadError(ctx, err)
	}
	reader := &copyTextReader{rows: rows, octalBytea: c.variant == VariantCockroach}
	if _, err := tx.Conn().PgConn().CopyFrom(ctx, reader, copySQL); err != nil {
		rollback(tx)
		if reader.err != nil {
			return engine.LoadStats{}, reader.err
		}
		return engine.LoadStats{}, c.loadError(ctx, err)
	}
	if err := tx.Commit(ctx); err != nil {
		rollback(tx)
		return engine.LoadStats{}, c.loadError(ctx, err)
	}
	return engine.LoadStats{Rows: uint64(len(rows)), Batches: 1}, nil
}

func rollback(tx pgx.Tx) {
	ctx, cancel := context.WithTimeout(context.Background(), rollbackTimeout)
	defer cancel()
	_ = tx.Rollback(ctx)
}

// loadError classifies a failed load. Messages are built without the server's
// detail and where text, which echo the rejected row.
func (c *Conn) loadError(ctx context.Context, err error) error {
	e := &engine.Error{Engine: c.id, Op: "load rows", Err: err}
	var pgErr *pgconn.PgError
	switch {
	case ctx.Err() != nil:
		e.Kind, e.Msg = engine.KindCanceled, "load cancelled"
		if errors.Is(ctx.Err(), context.DeadlineExceeded) {
			e.Kind, e.Msg = engine.KindTimeout, "load timed out"
		}
	case errors.As(err, &pgErr):
		e.Kind, e.Msg = loadErrorKind(pgErr), engine.Redact(loadErrorMessage(pgErr), c.secret)
	case isConnLost(err):
		e.Kind, e.Msg = engine.KindConnectionLost, "connection lost during load"
	default:
		e.Kind = engine.ClassifyCommon(err)
		e.Msg = engine.Redact(trimConnectPrefix(err.Error()), c.secret)
	}
	return e
}

func loadErrorKind(pgErr *pgconn.PgError) engine.Kind {
	switch {
	case strings.HasPrefix(pgErr.Code, "23"):
		return engine.KindConstraint
	case pgErr.Code == "42P01":
		return engine.KindNotFound
	case pgErr.Code == "57014":
		return engine.KindCanceled
	}
	if k, ok := sqlStateKinds[pgErr.Code]; ok {
		return k
	}
	return engine.KindSQL
}

// valueFreeClasses are the SQLSTATE classes whose messages name objects (tables,
// columns, constraints, privileges) and never quote row values.
var valueFreeClasses = []string{"08", "23", "25", "28", "3D", "40", "42", "53", "54", "55", "57"}

func loadErrorMessage(pgErr *pgconn.PgError) string {
	for _, class := range valueFreeClasses {
		if strings.HasPrefix(pgErr.Code, class) {
			return pgErr.Message
		}
	}
	if strings.HasPrefix(pgErr.Code, "22") {
		return "a value was rejected by its column type (SQLSTATE " + pgErr.Code + ")"
	}
	return "the server rejected the data (SQLSTATE " + pgErr.Code + ")"
}

// copyTextReader encodes rows into COPY text format as the connection reads.
type copyTextReader struct {
	rows [][]engine.Value
	// octalBytea writes bytea as COPY octal escapes, which CockroachDB takes
	// as the raw bytes. PostgreSQL needs the \x hex form instead.
	octalBytea bool
	next       int
	buf        []byte
	pos        int
	err        error
}

func (r *copyTextReader) Read(p []byte) (int, error) {
	for r.pos >= len(r.buf) {
		if r.err != nil {
			return 0, r.err
		}
		if r.next >= len(r.rows) {
			return 0, io.EOF
		}
		r.fill()
	}
	n := copy(p, r.buf[r.pos:])
	r.pos += n
	return n, nil
}

func (r *copyTextReader) fill() {
	r.buf, r.pos = r.buf[:0], 0
	for r.next < len(r.rows) && len(r.buf) < copyChunkBytes {
		rowStart := len(r.buf)
		buf, err := appendCopyRow(r.buf, r.rows[r.next], r.octalBytea)
		if err != nil {
			r.buf = r.buf[:rowStart]
			r.err = fmt.Errorf("row %d: %w", r.next, err)
			return
		}
		r.buf = buf
		r.next++
	}
}

func appendCopyRow(dst []byte, row []engine.Value, octalBytea bool) ([]byte, error) {
	var err error
	for i, v := range row {
		if i > 0 {
			dst = append(dst, '\t')
		}
		if dst, err = appendCopyField(dst, v, octalBytea); err != nil {
			return dst, fmt.Errorf("column %d: %w", i, err)
		}
	}
	return append(dst, '\n'), nil
}

func appendCopyField(dst []byte, v engine.Value, octalBytea bool) ([]byte, error) {
	switch v.Kind {
	case engine.VNull:
		return append(dst, '\\', 'N'), nil
	case engine.VBool:
		return append(dst, boolLetter(v.Bool)), nil
	case engine.VInt:
		return strconv.AppendInt(dst, v.Int, 10), nil
	case engine.VFloat:
		return appendFloat(dst, v.Float), nil
	case engine.VDecimal, engine.VText, engine.VJSON, engine.VUUID:
		return appendCopyEscaped(dst, v.Str), nil
	case engine.VBytes:
		if octalBytea {
			return appendOctalBytes(dst, v.Bytes), nil
		}
		return hex.AppendEncode(append(dst, '\\', '\\', 'x'), v.Bytes), nil
	case engine.VTimestamptz:
		return v.Time.UTC().AppendFormat(dst, timestampLayout), nil
	case engine.VArray:
		literal, err := appendArrayLiteral(nil, v)
		if err != nil {
			return dst, err
		}
		return appendCopyEscaped(dst, string(literal)), nil
	}
	return dst, fmt.Errorf("unsupported value kind %d", v.Kind)
}

func appendOctalBytes(dst, raw []byte) []byte {
	for _, b := range raw {
		switch {
		case b == '\\':
			dst = append(dst, '\\', '\\')
		case b >= 0x20 && b < 0x7f:
			dst = append(dst, b)
		default:
			dst = append(dst, '\\', '0'+b>>6, '0'+(b>>3)&7, '0'+b&7)
		}
	}
	return dst
}

func boolLetter(b bool) byte {
	if b {
		return 't'
	}
	return 'f'
}

func appendFloat(dst []byte, f float64) []byte {
	switch {
	case math.IsNaN(f):
		return append(dst, "NaN"...)
	case math.IsInf(f, 1):
		return append(dst, "Infinity"...)
	case math.IsInf(f, -1):
		return append(dst, "-Infinity"...)
	}
	return strconv.AppendFloat(dst, f, 'g', -1, 64)
}

func appendCopyEscaped(dst []byte, s string) []byte {
	start := 0
	for i := 0; i < len(s); i++ {
		var esc byte
		switch s[i] {
		case '\\':
			esc = '\\'
		case '\n':
			esc = 'n'
		case '\r':
			esc = 'r'
		case '\t':
			esc = 't'
		default:
			continue
		}
		dst = append(dst, s[start:i]...)
		dst = append(dst, '\\', esc)
		start = i + 1
	}
	return append(dst, s[start:]...)
}

func appendArrayLiteral(dst []byte, v engine.Value) ([]byte, error) {
	dst = append(dst, '{')
	for i, el := range v.Array {
		if i > 0 {
			dst = append(dst, ',')
		}
		var err error
		switch el.Kind {
		case engine.VNull:
			dst = append(dst, "NULL"...)
		case engine.VArray:
			dst, err = appendArrayLiteral(dst, el)
		default:
			dst, err = appendArrayElement(dst, el)
		}
		if err != nil {
			return dst, err
		}
	}
	return append(dst, '}'), nil
}

func appendArrayElement(dst []byte, el engine.Value) ([]byte, error) {
	var text []byte
	switch el.Kind {
	case engine.VBool:
		text = []byte{boolLetter(el.Bool)}
	case engine.VInt:
		text = strconv.AppendInt(nil, el.Int, 10)
	case engine.VFloat:
		text = appendFloat(nil, el.Float)
	case engine.VDecimal, engine.VText, engine.VJSON, engine.VUUID:
		text = []byte(el.Str)
	case engine.VBytes:
		text = hex.AppendEncode([]byte(`\x`), el.Bytes)
	case engine.VTimestamptz:
		text = el.Time.UTC().AppendFormat(nil, timestampLayout)
	default:
		return dst, fmt.Errorf("unsupported array element kind %d", el.Kind)
	}
	dst = append(dst, '"')
	for _, b := range text {
		if b == '"' || b == '\\' {
			dst = append(dst, '\\')
		}
		dst = append(dst, b)
	}
	return append(dst, '"'), nil
}
