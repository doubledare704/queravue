package engine

import (
	"context"
	"errors"
	"time"
)

// MaxBatchRows is the largest number of rows passed to RowSink.Batch.
const MaxBatchRows = 500

// ErrStop returned from a RowSink method ends the statement cleanly: the
// engine stops reading rows, cancels the server-side query if it is still
// producing rows, and Execute returns a Summary with a nil error.
var ErrStop = errors.New("engine: stop reading rows")

// ValueKind is the type of a Value.
type ValueKind uint8

// Value kinds. Types without a dedicated kind arrive as VText.
const (
	VNull ValueKind = iota
	VBool
	VInt
	VFloat
	VDecimal
	VText
	VBytes
	VTimestamptz
	VJSON
	VUUID
	VArray
)

// Value is one typed cell. Only the field matching Kind is meaningful.
type Value struct {
	Kind  ValueKind
	Bool  bool
	Int   int64
	Float float64
	// Str holds VDecimal, VText, VJSON and VUUID content.
	Str   string
	Bytes []byte
	Time  time.Time
	Array []Value
}

// Null returns a SQL NULL value.
func Null() Value { return Value{Kind: VNull} }

// Bool returns a boolean value.
func Bool(b bool) Value { return Value{Kind: VBool, Bool: b} }

// Int returns an integer value.
func Int(i int64) Value { return Value{Kind: VInt, Int: i} }

// Float returns a floating-point value.
func Float(f float64) Value { return Value{Kind: VFloat, Float: f} }

// Decimal returns an exact decimal given in its text form.
func Decimal(s string) Value { return Value{Kind: VDecimal, Str: s} }

// Text returns a text value.
func Text(s string) Value { return Value{Kind: VText, Str: s} }

// Bytes returns a binary value.
func Bytes(b []byte) Value { return Value{Kind: VBytes, Bytes: b} }

// Timestamptz returns a timestamp-with-time-zone value.
func Timestamptz(t time.Time) Value { return Value{Kind: VTimestamptz, Time: t} }

// JSON returns a JSON value given as text.
func JSON(s string) Value { return Value{Kind: VJSON, Str: s} }

// UUID returns a UUID value in canonical text form.
func UUID(s string) Value { return Value{Kind: VUUID, Str: s} }

// Array returns an array value.
func Array(v []Value) Value { return Value{Kind: VArray, Array: v} }

// Column describes one result column.
type Column struct {
	Name string
	// TypeName is the engine-native type, e.g. "int4".
	TypeName string
	// Kind is the general kind of the column's values.
	Kind ValueKind
}

// Statement is one statement to run.
type Statement struct {
	SQL    string
	Params []Value
}

// Summary describes a finished statement.
type Summary struct {
	// RowsAffected is the server's row count for INSERT/UPDATE/DELETE; 0 for
	// statements that return rows.
	RowsAffected int64
	// Duration is the wall time of the statement, including row transfer.
	Duration time.Duration
	// Notices are server notices and warnings raised by the statement.
	Notices []string
	// HasRows is true if the statement returned a result set.
	HasRows bool
	// RowsRead is the number of rows passed to the sink.
	RowsRead int64
}

// RowSink receives a statement's result. Implementations must not retain the
// slices after returning. Returning an error stops the statement; ErrStop
// stops it without failing.
type RowSink interface {
	// Columns is called once, before any Batch, for statements that return a
	// result set (possibly with zero rows).
	Columns(cols []Column) error
	// Batch delivers 1..MaxBatchRows rows.
	Batch(rows [][]Value) error
}

// Executor is implemented by Conns with CapExecute. A Conn runs one statement
// at a time; callers serialise.
type Executor interface {
	// Execute runs stmt, streaming rows into sink. Cancelling ctx cancels the
	// statement on the server. Errors are *Error with KindSQL (with Position
	// where known), KindCanceled or KindConnectionLost.
	Execute(ctx context.Context, stmt Statement, sink RowSink) (Summary, error)
}
