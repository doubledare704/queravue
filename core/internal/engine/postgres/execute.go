package postgres

import (
	"context"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net"
	"runtime/debug"
	"strconv"
	"strings"
	"sync"
	"time"

	"github.com/jackc/pgx/v5"
	"github.com/jackc/pgx/v5/pgconn"
	"github.com/jackc/pgx/v5/pgconn/ctxwatch"

	"github.com/doubledare704/queravue/core/internal/engine"
)

var _ engine.Executor = (*Conn)(nil)

// cancelDeadlineDelay bounds how long a cancelled statement may take to
// unwind before the socket is cut.
const cancelDeadlineDelay = 5 * time.Second

// buildWatcher makes a cancelled context send a native cancel request, so the
// server stops the query and the connection stays usable for the next one.
func buildWatcher(pc *pgconn.PgConn) ctxwatch.Handler {
	return &pgconn.CancelRequestContextWatcherHandler{Conn: pc, DeadlineDelay: cancelDeadlineDelay}
}

// notices collects server notices for the running statement.
type notices struct {
	mu   sync.Mutex
	msgs []string
}

func (n *notices) add(_ *pgconn.PgConn, notice *pgconn.Notice) {
	n.mu.Lock()
	defer n.mu.Unlock()
	msg := notice.Severity + ": " + notice.Message
	n.msgs = append(n.msgs, msg)
}

func (n *notices) take() []string {
	n.mu.Lock()
	defer n.mu.Unlock()
	out := n.msgs
	n.msgs = nil
	return out
}

// Execute implements engine.Executor. Results use the text wire format
// (simple protocol) and are converted by type OID.
func (c *Conn) Execute(ctx context.Context, stmt engine.Statement, sink engine.RowSink) (sum engine.Summary, err error) {
	start := time.Now()
	defer func() {
		sum.Duration = time.Since(start)
		if r := recover(); r != nil {
			slog.Error("postgres: execute panic", "panic", fmt.Sprint(r), "stack", string(debug.Stack()))
			err = &engine.Error{Kind: engine.KindUnknown, Engine: c.id, Op: "execute", Msg: "internal error while running the statement"}
		}
	}()
	c.mu.Lock()
	conn := c.conn
	c.mu.Unlock()
	if conn == nil {
		return sum, &engine.Error{Kind: engine.KindConnectionLost, Engine: c.id, Op: "execute", Msg: "connection is closed"}
	}
	c.notices.take()

	args, err := toArgs(stmt.Params)
	if err != nil {
		return sum, &engine.Error{Kind: engine.KindInvalidConfig, Engine: c.id, Op: "execute", Msg: err.Error()}
	}

	qctx, cancelQuery := context.WithCancel(ctx)
	defer cancelQuery()

	rows, err := conn.Query(qctx, stmt.SQL, args...)
	if err != nil {
		sum.Notices = c.notices.take()
		return sum, c.execError(ctx, err)
	}
	defer rows.Close()

	fds := rows.FieldDescriptions()
	var oids []uint32
	if len(fds) > 0 {
		cols := make([]engine.Column, len(fds))
		oids = make([]uint32, len(fds))
		for i, fd := range fds {
			oids[i] = fd.DataTypeOID
			cols[i] = engine.Column{Name: fd.Name, TypeName: typeName(fd.DataTypeOID), Kind: kindOf(fd.DataTypeOID)}
		}
		sum.HasRows = true
		if err := sink.Columns(cols); err != nil {
			return c.finish(ctx, sum, rows, cancelQuery, err)
		}
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
		raw := rows.RawValues()
		row := make([]engine.Value, len(raw))
		for i, b := range raw {
			row[i] = convert(oids[i], b)
		}
		batch = append(batch, row)
		if len(batch) == engine.MaxBatchRows {
			if err := flush(); err != nil {
				return c.finish(ctx, sum, rows, cancelQuery, err)
			}
		}
	}
	if rows.Err() == nil {
		if err := flush(); err != nil {
			return c.finish(ctx, sum, rows, cancelQuery, err)
		}
	}
	return c.finish(ctx, sum, rows, cancelQuery, nil)
}

// finish closes rows and builds the result. A sink error stops the query on
// the server first, so an abandoned 1M-row SELECT does not keep streaming.
func (c *Conn) finish(ctx context.Context, sum engine.Summary, rows pgx.Rows, cancelQuery context.CancelFunc, sinkErr error) (engine.Summary, error) {
	if sinkErr != nil {
		cancelQuery()
	}
	rows.Close()
	sum.Notices = c.notices.take()
	if sinkErr != nil {
		if errors.Is(sinkErr, engine.ErrStop) {
			return sum, nil
		}
		return sum, sinkErr
	}
	if err := rows.Err(); err != nil {
		return sum, c.execError(ctx, err)
	}
	if !sum.HasRows {
		sum.RowsAffected = rows.CommandTag().RowsAffected()
	}
	return sum, nil
}

// execError classifies a statement failure.
func (c *Conn) execError(ctx context.Context, err error) error {
	e := &engine.Error{Engine: c.id, Op: "execute", Err: err}
	var pgErr *pgconn.PgError
	switch {
	case ctx.Err() != nil || (errors.As(err, &pgErr) && pgErr.Code == "57014" && errors.Is(err, context.Canceled)):
		e.Kind, e.Msg = engine.KindCanceled, "statement cancelled"
	case errors.As(err, &pgErr):
		e.Kind = engine.KindSQL
		e.Msg = engine.Redact(pgErr.Message, c.secret)
		e.Position = int(pgErr.Position)
		if pgErr.Code == "57014" {
			e.Kind, e.Msg = engine.KindCanceled, "statement cancelled"
		}
	case isConnLost(err):
		e.Kind, e.Msg = engine.KindConnectionLost, "connection lost: "+engine.Redact(trimConnectPrefix(err.Error()), c.secret)
	default:
		e.Kind, e.Msg = engine.KindUnknown, engine.Redact(err.Error(), c.secret)
	}
	return e
}

func isConnLost(err error) bool {
	var ne net.Error
	return errors.Is(err, io.EOF) || errors.Is(err, io.ErrUnexpectedEOF) || errors.As(err, &ne) ||
		strings.Contains(err.Error(), "conn closed") || strings.Contains(err.Error(), "conn is closed")
}

// Type OIDs we convert; everything else is text.
const (
	oidBool        = 16
	oidBytea       = 17
	oidName        = 19
	oidInt8        = 20
	oidInt2        = 21
	oidInt4        = 23
	oidText        = 25
	oidOID         = 26
	oidJSON        = 114
	oidFloat4      = 700
	oidFloat8      = 701
	oidBPChar      = 1042
	oidVarchar     = 1043
	oidTimestamptz = 1184
	oidNumeric     = 1700
	oidUUID        = 2950
	oidJSONB       = 3802
)

// arrayElem maps array type OIDs to their element OID.
var arrayElem = map[uint32]uint32{
	1000: oidBool, 1001: oidBytea, 1002: 18, 1003: oidName, 1005: oidInt2, 1007: oidInt4,
	1009: oidText, 1014: oidBPChar, 1015: oidVarchar, 1016: oidInt8, 1021: oidFloat4,
	1022: oidFloat8, 1028: oidOID, 1185: oidTimestamptz, 1231: oidNumeric, 2951: oidUUID,
	199: oidJSON, 3807: oidJSONB, 1182: 1082, 1115: 1114,
}

var typeNames = map[uint32]string{
	oidBool: "bool", oidBytea: "bytea", oidName: "name", oidInt8: "int8", oidInt2: "int2",
	oidInt4: "int4", oidText: "text", oidOID: "oid", oidJSON: "json", oidFloat4: "float4",
	oidFloat8: "float8", oidBPChar: "bpchar", oidVarchar: "varchar", oidTimestamptz: "timestamptz",
	oidNumeric: "numeric", oidUUID: "uuid", oidJSONB: "jsonb", 1082: "date", 1083: "time",
	1114: "timestamp", 1186: "interval", 1266: "timetz", 142: "xml",
}

func typeName(oid uint32) string {
	if n, ok := typeNames[oid]; ok {
		return n
	}
	if el, ok := arrayElem[oid]; ok {
		return typeName(el) + "[]"
	}
	return "oid:" + strconv.FormatUint(uint64(oid), 10)
}

func kindOf(oid uint32) engine.ValueKind {
	if _, ok := arrayElem[oid]; ok {
		return engine.VArray
	}
	switch oid {
	case oidBool:
		return engine.VBool
	case oidInt2, oidInt4, oidInt8, oidOID:
		return engine.VInt
	case oidFloat4, oidFloat8:
		return engine.VFloat
	case oidNumeric:
		return engine.VDecimal
	case oidBytea:
		return engine.VBytes
	case oidTimestamptz:
		return engine.VTimestamptz
	case oidJSON, oidJSONB:
		return engine.VJSON
	case oidUUID:
		return engine.VUUID
	}
	return engine.VText
}

// convert turns one text-format column value into a typed value. Anything it
// cannot parse falls back to text, so a result is never lost to a decode bug.
func convert(oid uint32, raw []byte) engine.Value {
	if raw == nil {
		return engine.Null()
	}
	if el, ok := arrayElem[oid]; ok {
		if v, ok := parseArray(string(raw), el); ok {
			return v
		}
		return engine.Text(string(raw))
	}
	return convertScalar(oid, string(raw))
}

func convertScalar(oid uint32, s string) engine.Value {
	switch oid {
	case oidBool:
		switch s {
		case "t", "true":
			return engine.Bool(true)
		case "f", "false":
			return engine.Bool(false)
		}
	case oidInt2, oidInt4, oidInt8, oidOID:
		if i, err := strconv.ParseInt(s, 10, 64); err == nil {
			return engine.Int(i)
		}
	case oidFloat4, oidFloat8:
		if f, err := strconv.ParseFloat(s, 64); err == nil {
			return engine.Float(f)
		}
	case oidNumeric:
		return engine.Decimal(s)
	case oidBytea:
		if b, ok := parseBytea(s); ok {
			return engine.Bytes(b)
		}
	case oidTimestamptz:
		if t, ok := parseTimestamptz(s); ok {
			return engine.Timestamptz(t)
		}
	case oidJSON, oidJSONB:
		return engine.JSON(s)
	case oidUUID:
		return engine.UUID(s)
	}
	return engine.Text(s)
}

func parseBytea(s string) ([]byte, bool) {
	if !strings.HasPrefix(s, `\x`) {
		return nil, false
	}
	h := s[2:]
	if len(h)%2 != 0 {
		return nil, false
	}
	out := make([]byte, len(h)/2)
	for i := range out {
		hi, ok1 := hexVal(h[2*i])
		lo, ok2 := hexVal(h[2*i+1])
		if !ok1 || !ok2 {
			return nil, false
		}
		out[i] = hi<<4 | lo
	}
	return out, true
}

func hexVal(c byte) (byte, bool) {
	switch {
	case c >= '0' && c <= '9':
		return c - '0', true
	case c >= 'a' && c <= 'f':
		return c - 'a' + 10, true
	case c >= 'A' && c <= 'F':
		return c - 'A' + 10, true
	}
	return 0, false
}

var tsLayouts = []string{
	"2006-01-02 15:04:05.999999999Z07",
	"2006-01-02 15:04:05.999999999Z07:00",
	"2006-01-02 15:04:05.999999999Z07:00:00",
}

// parseTimestamptz parses postgres text output. infinity, BC dates and
// years beyond Go's range return false (the caller keeps the text).
func parseTimestamptz(s string) (time.Time, bool) {
	for _, l := range tsLayouts {
		if t, err := time.Parse(l, s); err == nil {
			return t, true
		}
	}
	return time.Time{}, false
}

// parseArray parses a text-format array literal, including nested arrays.
// A leading dimension decoration like "[1:2]={...}" is skipped.
func parseArray(s string, elem uint32) (engine.Value, bool) {
	if strings.HasPrefix(s, "[") {
		i := strings.Index(s, "=")
		if i < 0 {
			return engine.Value{}, false
		}
		s = s[i+1:]
	}
	p := arrayParser{s: s, elem: elem}
	v, ok := p.parse()
	if !ok || p.i != len(p.s) {
		return engine.Value{}, false
	}
	return v, true
}

type arrayParser struct {
	s    string
	i    int
	elem uint32
}

func (p *arrayParser) parse() (engine.Value, bool) {
	if p.i >= len(p.s) || p.s[p.i] != '{' {
		return engine.Value{}, false
	}
	p.i++
	vals := []engine.Value{}
	if p.i < len(p.s) && p.s[p.i] == '}' {
		p.i++
		return engine.Array(vals), true
	}
	for {
		if p.i >= len(p.s) {
			return engine.Value{}, false
		}
		switch p.s[p.i] {
		case '{':
			v, ok := p.parse()
			if !ok {
				return engine.Value{}, false
			}
			vals = append(vals, v)
		case '"':
			str, ok := p.quoted()
			if !ok {
				return engine.Value{}, false
			}
			vals = append(vals, convertScalar(p.elem, str))
		default:
			j := p.i
			for j < len(p.s) && p.s[j] != ',' && p.s[j] != '}' {
				j++
			}
			tok := p.s[p.i:j]
			p.i = j
			if tok == "NULL" {
				vals = append(vals, engine.Null())
			} else {
				vals = append(vals, convertScalar(p.elem, tok))
			}
		}
		if p.i >= len(p.s) {
			return engine.Value{}, false
		}
		c := p.s[p.i]
		p.i++
		if c == '}' {
			return engine.Array(vals), true
		}
		if c != ',' {
			return engine.Value{}, false
		}
	}
}

func (p *arrayParser) quoted() (string, bool) {
	p.i++ // opening quote
	var b strings.Builder
	for p.i < len(p.s) {
		c := p.s[p.i]
		switch c {
		case '\\':
			p.i++
			if p.i >= len(p.s) {
				return "", false
			}
			b.WriteByte(p.s[p.i])
		case '"':
			p.i++
			return b.String(), true
		default:
			b.WriteByte(c)
		}
		p.i++
	}
	return "", false
}

// toArgs converts bind parameters to pgx arguments.
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
