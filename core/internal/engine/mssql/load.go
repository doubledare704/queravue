package mssql

import (
	"context"
	"database/sql"
	"database/sql/driver"
	"encoding/hex"
	"errors"
	"fmt"
	"math"
	"regexp"
	"strconv"
	"strings"
	"time"

	mssqldb "github.com/microsoft/go-mssqldb"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

var _ engine.RowLoader = (*Conn)(nil)

const rollbackTimeout = 5 * time.Second

// LoadRows implements engine.RowLoader with the TDS bulk copy protocol, one
// transaction per batch. Constraints are checked and triggers fire, as they
// would for an INSERT.
func (c *Conn) LoadRows(ctx context.Context, t engine.LoadTarget, columns []string, src engine.RowBatchSource) (engine.LoadStats, error) {
	const op = "load rows"
	if t.Table == "" || len(columns) == 0 {
		return engine.LoadStats{}, engine.Errorf(engine.KindInvalidConfig, ID, op, "table and columns are required")
	}
	conn, err := c.live(op)
	if err != nil {
		return engine.LoadStats{}, err
	}
	if err := c.rejectOpenTransaction(ctx, conn); err != nil {
		return engine.LoadStats{}, err
	}
	run := &loadRun{
		c: c, conn: conn, columns: columns,
		table: sqldialect.MSSQL.QualifyTableIn(t.Database, t.Schema, t.Table),
	}
	if run.converters, err = c.bulkConverters(ctx, conn, t, columns); err != nil {
		return engine.LoadStats{}, err
	}
	return engine.DriveLoad(ctx, ID, op, src.Next, func(rows [][]engine.Value) int { return len(rows) }, run.commitBatch)
}

func (c *Conn) rejectOpenTransaction(ctx context.Context, conn *sql.Conn) error {
	var open int
	if err := conn.QueryRowContext(ctx, "SELECT @@TRANCOUNT").Scan(&open); err != nil {
		return c.loadError(ctx, err)
	}
	if open > 0 {
		return engine.Errorf(engine.KindUnsupported, ID, "load rows", "a transaction is open on this connection; commit or roll it back before loading")
	}
	return nil
}

type loadRun struct {
	c          *Conn
	conn       *sql.Conn
	columns    []string
	table      string
	converters []valueConverter
}

func (r *loadRun) commitBatch(ctx context.Context, rows [][]engine.Value) (engine.LoadStats, error) {
	if err := engine.CheckLoadWidths(ID, rows, len(r.columns)); err != nil {
		return engine.LoadStats{}, err
	}
	tx, err := r.conn.BeginTx(ctx, nil)
	if err != nil {
		return engine.LoadStats{}, r.c.loadError(ctx, err)
	}
	inserted, err := r.copyRows(ctx, tx, rows)
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

func (r *loadRun) copyRows(ctx context.Context, tx *sql.Tx, rows [][]engine.Value) (uint64, error) {
	options := mssqldb.BulkOptions{CheckConstraints: true, FireTriggers: true, KeepNulls: true}
	stmt, err := tx.PrepareContext(ctx, mssqldb.CopyIn(r.table, options, r.columns...))
	if err != nil {
		return 0, r.c.loadError(ctx, err)
	}
	defer func() { _ = stmt.Close() }()
	args := make([]any, len(r.columns))
	for _, row := range rows {
		for i, v := range row {
			if args[i], err = r.converters[i](v); err != nil {
				return 0, &engine.Error{Kind: engine.KindInvalidConfig, Engine: ID, Op: "load rows", Msg: fmt.Sprintf("column %s: %s", r.columns[i], err.Error())}
			}
		}
		if _, err := stmt.ExecContext(ctx, args...); err != nil {
			return 0, r.c.loadError(ctx, err)
		}
	}
	res, err := stmt.ExecContext(ctx)
	if err != nil {
		return 0, r.c.loadError(ctx, err)
	}
	inserted, err := res.RowsAffected()
	if err != nil {
		return 0, r.c.loadError(ctx, err)
	}
	return uint64(inserted), nil //nolint:gosec // a row count is non-negative
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

type valueConverter func(engine.Value) (any, error)

// bulkConverters looks up the target columns' types, because the bulk
// protocol is strict about the Go type each column accepts.
func (c *Conn) bulkConverters(ctx context.Context, conn *sql.Conn, t engine.LoadTarget, columns []string) ([]valueConverter, error) {
	db, err := c.pick(ctx, conn, t.Database)
	if err != nil {
		return nil, c.loadError(ctx, err)
	}
	//nolint:gosec // the only spliced part is the database name quoted by qdb
	rows, err := conn.QueryContext(ctx,
		`SELECT c.name, ty.name FROM `+qdb(db)+`.sys.columns c
JOIN `+qdb(db)+`.sys.types ty ON ty.user_type_id = c.user_type_id
WHERE c.object_id = OBJECT_ID(@p1)`, sqldialect.MSSQL.QualifyTableIn(db, t.Schema, t.Table))
	if err != nil {
		return nil, c.loadError(ctx, err)
	}
	defer func() { _ = rows.Close() }()
	types := map[string]string{}
	for rows.Next() {
		var name, typeName string
		if err := rows.Scan(&name, &typeName); err != nil {
			return nil, c.loadError(ctx, err)
		}
		types[strings.ToLower(name)] = strings.ToLower(typeName)
	}
	if err := rows.Err(); err != nil {
		return nil, c.loadError(ctx, err)
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
		if out[i] = converterFor(typeName); out[i] == nil {
			return nil, engine.Errorf(engine.KindUnsupported, ID, "load rows", "column %s has type %s, which bulk copy cannot write", name, typeName)
		}
	}
	return out, nil
}

func converterFor(typeName string) valueConverter {
	switch typeName {
	case "tinyint":
		return integerInRange(0, math.MaxUint8)
	case "smallint":
		return integerInRange(math.MinInt16, math.MaxInt16)
	case "int":
		return integerInRange(math.MinInt32, math.MaxInt32)
	case "bigint":
		return integerInRange(math.MinInt64, math.MaxInt64)
	case "bit":
		return bitValue
	case "real", "float":
		return floatValue
	case "decimal", "numeric", "money", "smallmoney":
		return decimalValue
	case "char", "varchar", "nchar", "nvarchar", "text", "ntext", "sysname":
		return textValue
	case "binary", "varbinary", "image":
		return bytesValue
	case "uniqueidentifier":
		return guidValue
	case "date", "datetime", "datetime2", "smalldatetime", "datetimeoffset", "time":
		return timeValue
	}
	return nil
}

func integerInRange(lo, hi int64) valueConverter {
	return func(v engine.Value) (any, error) {
		var n int64
		switch v.Kind {
		case engine.VNull:
			return nil, nil
		case engine.VInt:
			n = v.Int
		case engine.VBool:
			if v.Bool {
				n = 1
			}
		default:
			return nil, errNotAssignable(v)
		}
		if n < lo || n > hi {
			return nil, errors.New("an integer is outside the column's range")
		}
		return n, nil
	}
}

func bitValue(v engine.Value) (any, error) {
	switch v.Kind {
	case engine.VNull:
		return nil, nil
	case engine.VBool:
		return v.Bool, nil
	case engine.VInt:
		if v.Int == 0 || v.Int == 1 {
			return v.Int == 1, nil
		}
	}
	return nil, errNotAssignable(v)
}

func floatValue(v engine.Value) (any, error) {
	switch v.Kind {
	case engine.VNull:
		return nil, nil
	case engine.VFloat:
		return v.Float, nil
	case engine.VInt:
		return float64(v.Int), nil
	}
	return nil, errNotAssignable(v)
}

func decimalValue(v engine.Value) (any, error) {
	switch v.Kind {
	case engine.VNull:
		return nil, nil
	case engine.VDecimal, engine.VText:
		return v.Str, nil
	case engine.VInt:
		return v.Int, nil
	}
	return nil, errNotAssignable(v)
}

func textValue(v engine.Value) (any, error) {
	switch v.Kind {
	case engine.VNull:
		return nil, nil
	case engine.VText, engine.VDecimal, engine.VJSON, engine.VUUID:
		return v.Str, nil
	case engine.VInt:
		return strconv.FormatInt(v.Int, 10), nil
	case engine.VFloat:
		return strconv.FormatFloat(v.Float, 'g', -1, 64), nil
	}
	return nil, errNotAssignable(v)
}

func bytesValue(v engine.Value) (any, error) {
	switch v.Kind {
	case engine.VNull:
		return nil, nil
	case engine.VBytes:
		return v.Bytes, nil
	}
	return nil, errNotAssignable(v)
}

func timeValue(v engine.Value) (any, error) {
	switch v.Kind {
	case engine.VNull:
		return nil, nil
	case engine.VTimestamptz:
		return v.Time, nil
	case engine.VText:
		return v.Str, nil
	}
	return nil, errNotAssignable(v)
}

const (
	guidTextLength = 36
	guidByteLength = 16
)

// guidValue writes the wire layout, where the first three groups are little
// endian.
func guidValue(v engine.Value) (any, error) {
	switch v.Kind {
	case engine.VNull:
		return nil, nil
	case engine.VUUID, engine.VText:
		if len(v.Str) != guidTextLength {
			return nil, errors.New("not a UUID")
		}
		raw, err := hex.DecodeString(strings.ReplaceAll(v.Str, "-", ""))
		if err != nil || len(raw) != guidByteLength {
			return nil, errors.New("not a UUID")
		}
		reverse(raw[0:4])
		reverse(raw[4:6])
		reverse(raw[6:8])
		return raw, nil
	}
	return nil, errNotAssignable(v)
}

func reverse(b []byte) {
	for i, j := 0, len(b)-1; i < j; i, j = i+1, j-1 {
		b[i], b[j] = b[j], b[i]
	}
}

func errNotAssignable(v engine.Value) error {
	return fmt.Errorf("a value of kind %d cannot be stored in this column", v.Kind)
}

const (
	errDuplicateKeyInObject = 2627
	errDuplicateUniqueIndex = 2601
	errNullNotAllowed       = 515
	errConstraintConflict   = 547
)

var dataErrorNumbers = map[int32]bool{
	220: true, 232: true, 241: true, 242: true, 245: true, 248: true, 295: true,
	8114: true, 8115: true, 8152: true, 2628: true, 9803: true, 4864: true, 4863: true, 4860: true,
}

var (
	violatedConstraintRe = regexp.MustCompile(`^Violation of (?:PRIMARY KEY|UNIQUE KEY|UNIQUE) constraint '([^']*)'`)
	uniqueIndexRe        = regexp.MustCompile(`with unique index '([^']*)'`)
)

// loadError classifies a failed load. Messages name columns, keys and
// constraints but never the rejected values.
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
	if number, message, ok := serverError(err); ok {
		return serverLoadError(c, err, number, message)
	}
	classified := classify(ID, "load rows", err, c.secret)
	if classified.Kind == engine.KindUnknown && !errors.Is(err, driver.ErrBadConn) {
		classified.Msg = "a value was rejected by the bulk copy protocol"
		classified.Kind = engine.KindSQL
	}
	return classified
}

func serverError(err error) (number int32, message string, ok bool) {
	var value mssqldb.Error
	var pointer *mssqldb.Error
	switch {
	case errors.As(err, &value):
		return value.Number, value.Message, true
	case errors.As(err, &pointer) && pointer != nil:
		return pointer.Number, pointer.Message, true
	}
	return 0, "", false
}

func serverLoadError(c *Conn, err error, number int32, message string) *engine.Error {
	e := &engine.Error{Engine: ID, Op: "load rows", Err: err, Code: int(number)}
	switch {
	case number == errDuplicateKeyInObject:
		e.Kind, e.Msg = engine.KindConstraint, "duplicate value violates a unique key"
		if m := violatedConstraintRe.FindStringSubmatch(message); m != nil {
			e.Msg = "duplicate value violates constraint '" + m[1] + "'"
		}
	case number == errDuplicateUniqueIndex:
		e.Kind, e.Msg = engine.KindConstraint, "duplicate value violates a unique index"
		if m := uniqueIndexRe.FindStringSubmatch(message); m != nil {
			e.Msg = "duplicate value violates unique index '" + m[1] + "'"
		}
	case number == errNullNotAllowed, number == errConstraintConflict:
		e.Kind, e.Msg = engine.KindConstraint, engine.Redact(message, c.secret)
	case dataErrorNumbers[number]:
		e.Kind, e.Msg = engine.KindSQL, "a value was rejected by its column type"
	default:
		classified := classify(ID, "load rows", err, c.secret)
		e.Kind, e.Msg = classified.Kind, classified.Msg
		if e.Kind == engine.KindUnknown {
			e.Kind = engine.KindSQL
		}
	}
	return e
}
