package sqlite

import (
	"context"
	"database/sql"
	"errors"
	"strings"

	sqlite "modernc.org/sqlite"
	sqlite3 "modernc.org/sqlite/lib"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

var _ engine.RowLoader = (*Conn)(nil)

const (
	maxBoundVariables = 32000
	maxRowsPerInsert  = 500
)

// LoadRows implements engine.RowLoader with prepared multi-row INSERTs in one
// transaction per batch.
func (c *Conn) LoadRows(ctx context.Context, t engine.LoadTarget, columns []string, src engine.RowBatchSource) (engine.LoadStats, error) {
	const op = "load rows"
	if t.Table == "" || len(columns) == 0 {
		return engine.LoadStats{}, engine.Errorf(engine.KindInvalidConfig, ID, op, "table and columns are required")
	}
	if len(columns) > maxBoundVariables {
		return engine.LoadStats{}, engine.Errorf(engine.KindInvalidConfig, ID, op, "too many columns")
	}
	c.mu.Lock()
	db := c.db
	c.mu.Unlock()
	if db == nil {
		return engine.LoadStats{}, &engine.Error{Kind: engine.KindConnectionLost, Engine: ID, Op: op, Msg: "connection is closed"}
	}
	insert := insertBuilder{target: t, columns: columns, rowsPerStatement: min(maxRowsPerInsert, maxBoundVariables/len(columns))}
	commit := func(ctx context.Context, rows [][]engine.Value) (engine.LoadStats, error) {
		return commitBatch(ctx, db, insert, rows)
	}
	return engine.DriveLoad(ctx, ID, op, src.Next, func(rows [][]engine.Value) int { return len(rows) }, commit)
}

type insertBuilder struct {
	target           engine.LoadTarget
	columns          []string
	rowsPerStatement int
}

func (b insertBuilder) sql(rows int) string {
	quoted := make([]string, len(b.columns))
	for i, name := range b.columns {
		quoted[i] = sqldialect.SQLite.QuoteIdent(name)
	}
	tuple := "(" + strings.TrimSuffix(strings.Repeat("?,", len(b.columns)), ",") + ")"
	var sb strings.Builder
	sb.WriteString("INSERT INTO " + sqldialect.SQLite.QualifyTable(b.target.Schema, b.target.Table) + " (" + strings.Join(quoted, ", ") + ") VALUES ")
	for i := range rows {
		if i > 0 {
			sb.WriteByte(',')
		}
		sb.WriteString(tuple)
	}
	return sb.String()
}

func commitBatch(ctx context.Context, db *sql.DB, insert insertBuilder, rows [][]engine.Value) (engine.LoadStats, error) {
	for i, row := range rows {
		if len(row) != len(insert.columns) {
			return engine.LoadStats{}, engine.Errorf(engine.KindInvalidConfig, ID, "load rows", "row %d has %d values for %d columns", i, len(row), len(insert.columns))
		}
	}
	tx, err := db.BeginTx(ctx, nil)
	if err != nil {
		return engine.LoadStats{}, loadError(ctx, err)
	}
	if err := insertRows(ctx, tx, insert, rows); err != nil {
		_ = tx.Rollback()
		return engine.LoadStats{}, err
	}
	if err := tx.Commit(); err != nil {
		_ = tx.Rollback()
		return engine.LoadStats{}, loadError(ctx, err)
	}
	return engine.LoadStats{Rows: uint64(len(rows)), Batches: 1}, nil
}

func insertRows(ctx context.Context, tx *sql.Tx, insert insertBuilder, rows [][]engine.Value) error {
	statements := map[int]*sql.Stmt{}
	defer func() {
		for _, s := range statements {
			_ = s.Close()
		}
	}()
	args := make([]any, 0, insert.rowsPerStatement*len(insert.columns))
	for start := 0; start < len(rows); start += insert.rowsPerStatement {
		chunk := rows[start:min(start+insert.rowsPerStatement, len(rows))]
		stmt, ok := statements[len(chunk)]
		if !ok {
			var err error
			if stmt, err = tx.PrepareContext(ctx, insert.sql(len(chunk))); err != nil {
				return loadError(ctx, err)
			}
			statements[len(chunk)] = stmt
		}
		args = args[:0]
		for _, row := range chunk {
			rowArgs, err := toArgs(row)
			if err != nil {
				return &engine.Error{Kind: engine.KindInvalidConfig, Engine: ID, Op: "load rows", Msg: err.Error()}
			}
			args = append(args, rowArgs...)
		}
		if _, err := stmt.ExecContext(ctx, args...); err != nil {
			return loadError(ctx, err)
		}
	}
	return nil
}

// loadError classifies a failed load. Messages name columns and constraints
// but never the rejected values.
func loadError(ctx context.Context, err error) error {
	e := &engine.Error{Engine: ID, Op: "load rows", Err: err, Msg: err.Error()}
	var se *sqlite.Error
	switch {
	case ctx.Err() != nil || errors.Is(err, context.Canceled):
		e.Kind, e.Msg = engine.KindCanceled, "load cancelled"
		if errors.Is(ctx.Err(), context.DeadlineExceeded) {
			e.Kind, e.Msg = engine.KindTimeout, "load timed out"
		}
	case errors.As(err, &se):
		e.Kind = loadErrorKind(se.Code())
	default:
		e.Kind = engine.ClassifyCommon(err)
	}
	return e
}

func loadErrorKind(code int) engine.Kind {
	switch code & 0xff {
	case sqlite3.SQLITE_CONSTRAINT:
		return engine.KindConstraint
	case sqlite3.SQLITE_INTERRUPT:
		return engine.KindCanceled
	case sqlite3.SQLITE_PERM, sqlite3.SQLITE_AUTH, sqlite3.SQLITE_READONLY:
		return engine.KindAuth
	case sqlite3.SQLITE_BUSY, sqlite3.SQLITE_LOCKED:
		return engine.KindTimeout
	}
	return engine.KindSQL
}
