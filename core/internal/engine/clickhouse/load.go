package clickhouse

import (
	"context"
	"errors"
	"regexp"
	"strings"

	chdriver "github.com/ClickHouse/clickhouse-go/v2"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

var _ engine.RowLoader = (*Conn)(nil)

// LoadRows implements engine.RowLoader with native-protocol batch inserts: one
// block per batch on a connection of its own. ClickHouse has no transactions;
// a block is inserted whole or not at all, and a CHECK constraint is applied to
// the whole block before it is written.
func (c *Conn) LoadRows(ctx context.Context, t engine.LoadTarget, columns []string, src engine.RowBatchSource) (engine.LoadStats, error) {
	const op = "load rows"
	if t.Table == "" || len(columns) == 0 {
		return engine.LoadStats{}, engine.Errorf(engine.KindInvalidConfig, ID, op, "table and columns are required")
	}
	db, err := c.live(op)
	if err != nil {
		return engine.LoadStats{}, err
	}
	database := firstNonEmpty(t.Schema, t.Database, c.database)
	converters, err := c.columnConverters(ctx, db, database, t.Table, columns)
	if err != nil {
		return engine.LoadStats{}, err
	}
	options := *c.options
	native, err := chdriver.Open(&options)
	if err != nil {
		return engine.LoadStats{}, c.loadError(ctx, err)
	}
	defer func() { _ = native.Close() }()
	run := &loadRun{
		c: c, native: native, columns: columns, converters: converters,
		insertSQL: insertStatement(database, t.Table, columns),
	}
	return engine.DriveLoad(ctx, ID, op, src.Next, func(rows [][]engine.Value) int { return len(rows) }, run.commitBatch)
}

func firstNonEmpty(values ...string) string {
	for _, v := range values {
		if v != "" {
			return v
		}
	}
	return ""
}

func insertStatement(database, table string, columns []string) string {
	quoted := make([]string, len(columns))
	for i, name := range columns {
		quoted[i] = sqldialect.ClickHouse.QuoteIdent(name)
	}
	return "INSERT INTO " + sqldialect.ClickHouse.QualifyTable(database, table) + " (" + strings.Join(quoted, ", ") + ")"
}

type loadRun struct {
	c          *Conn
	native     chdriver.Conn
	columns    []string
	converters []valueConverter
	insertSQL  string
}

func (r *loadRun) commitBatch(ctx context.Context, rows [][]engine.Value) (engine.LoadStats, error) {
	if err := engine.CheckLoadWidths(ID, rows, len(r.columns)); err != nil {
		return engine.LoadStats{}, err
	}
	batch, err := r.native.PrepareBatch(ctx, r.insertSQL)
	if err != nil {
		return engine.LoadStats{}, r.c.loadError(ctx, err)
	}
	args := make([]any, len(r.columns))
	for _, row := range rows {
		for i, v := range row {
			if args[i], err = r.converters[i](v); err != nil {
				_ = batch.Abort()
				return engine.LoadStats{}, r.rowError(i, err)
			}
		}
		if err := batch.Append(args...); err != nil {
			_ = batch.Abort()
			return engine.LoadStats{}, r.appendError(ctx, err)
		}
	}
	if err := batch.Send(); err != nil {
		return engine.LoadStats{}, r.c.loadError(ctx, err)
	}
	// The native protocol reports no inserted-row count, and ClickHouse drops no rows of a block it accepts.
	return engine.LoadStats{Rows: uint64(len(rows)), Batches: 1}, nil
}

// appendError hides the driver's message: it quotes the value it could not
// convert.
func (r *loadRun) appendError(ctx context.Context, err error) error {
	if ctx.Err() != nil || errors.Is(err, context.Canceled) {
		return r.c.loadError(ctx, err)
	}
	return &engine.Error{Kind: engine.KindInvalidConfig, Engine: ID, Op: "load rows", Msg: "a value cannot be stored in its column", Err: err}
}

func (r *loadRun) rowError(column int, err error) error {
	if errors.Is(err, errNullNotAllowed) {
		return &engine.Error{Kind: engine.KindConstraint, Engine: ID, Op: "load rows", Msg: "column " + r.columns[column] + " does not accept NULL", Err: err}
	}
	return &engine.Error{Kind: engine.KindInvalidConfig, Engine: ID, Op: "load rows", Msg: "column " + r.columns[column] + ": " + err.Error(), Err: err}
}

const (
	codeViolatedConstraint = 469
	codeCannotParse        = 27
	codeTypeMismatch       = 53
	codeCannotConvertType  = 70
	codeIncorrectData      = 117
	codeValueOutOfRange    = 321
)

var dataCodes = map[int32]bool{codeCannotParse: true, codeTypeMismatch: true, codeCannotConvertType: true, codeIncorrectData: true, codeValueOutOfRange: true}

var violatedConstraintRe = regexp.MustCompile("^Constraint `([^`]*)`")

// loadError classifies a failed load. A violated CHECK constraint names the
// constraint, not the "Column values" the server appends to its message.
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
	classified := classify(ID, "load rows", err, c.secret)
	var ex *chdriver.Exception
	if !errors.As(err, &ex) {
		return classified
	}
	classified.Code = int(ex.Code)
	switch {
	case ex.Code == codeViolatedConstraint:
		classified.Kind, classified.Msg = engine.KindConstraint, "a CHECK constraint was violated"
		if m := violatedConstraintRe.FindStringSubmatch(ex.Message); m != nil {
			classified.Msg = "CHECK constraint '" + m[1] + "' was violated"
		}
	case dataCodes[ex.Code]:
		classified.Msg = "a value was rejected by its column type"
	}
	return classified
}
