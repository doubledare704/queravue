package dataformat

import (
	"context"
	"errors"
	"fmt"
	"io"
	"strings"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

// SQLDumpOptions supplies the target dialect and an optional table design.
type SQLDumpOptions struct {
	Dialect        sqldialect.Dialect
	Target         sqldialect.Target
	Create         *sqldialect.TableDesign
	MaxBytes       int
	MaxRecordBytes int
}

type sqlWriter struct {
	dst                 io.Writer
	opts                SQLDumpOptions
	prefix              string
	columns, rows, size int
	started, closed     bool
	err                 error
}

// NewSQLWriter groups rows up to MaxBytes and emits larger rows as single INSERTs.
func NewSQLWriter(dst io.Writer, opts SQLDumpOptions) (Writer, error) {
	if opts.Dialect == nil {
		return nil, errors.New("dataformat: SQL dump requires a dialect")
	}
	if opts.Target.Table == "" {
		opts.Target.Table = "export"
	}
	common := Options{Format: SQL, MaxBytes: opts.MaxBytes, MaxRecordBytes: opts.MaxRecordBytes}
	if err := common.normalize(); err != nil {
		return nil, err
	}
	opts.MaxBytes, opts.MaxRecordBytes = common.MaxBytes, common.MaxRecordBytes
	return &sqlWriter{dst: dst, opts: opts}, nil
}

func (w *sqlWriter) Columns(ctx context.Context, columns []engine.Column) error {
	if w.started || w.closed {
		return errors.New("dataformat: columns already set or writer closed")
	}
	if len(columns) == 0 {
		return errors.New("dataformat: SQL dump requires at least one column")
	}
	if err := ctx.Err(); err != nil {
		return fmt.Errorf("dataformat: %w", err)
	}
	d, t := w.opts.Dialect, w.opts.Target
	names := make([]string, len(columns))
	for i, col := range columns {
		names[i] = d.QuoteIdent(col.Name)
	}
	table := d.QualifyTable(t.Schema, t.Table)
	if t.Database != "" {
		table = d.QualifyTableIn(t.Database, t.Schema, t.Table)
	}
	w.prefix = "INSERT INTO " + table + " (" + strings.Join(names, ", ") + ") VALUES\n"
	if len(w.prefix)+4 > w.opts.MaxRecordBytes {
		return errors.New("dataformat: INSERT header exceeds byte limit")
	}
	if w.opts.Create != nil {
		script, err := sqldialect.BuildDDL(d, t, nil, []sqldialect.Change{sqldialect.CreateTable{Design: *w.opts.Create}})
		if err != nil {
			return fmt.Errorf("dataformat: build dump DDL: %w", err)
		}
		for _, statement := range script.Statements {
			if err := w.write(strings.TrimSuffix(strings.TrimSpace(statement.SQL), ";") + ";\n"); err != nil {
				return err
			}
		}
	}
	w.started, w.columns = true, len(columns)
	return nil
}

func (w *sqlWriter) Batch(ctx context.Context, rows [][]engine.Value) error {
	if w.err != nil {
		return w.err
	}
	if !w.started || w.closed {
		return errors.New("dataformat: SQL dump requires columns and must be open")
	}
	for _, row := range rows {
		if err := ctx.Err(); err != nil {
			return fmt.Errorf("dataformat: %w", err)
		}
		tuple, err := w.tuple(row)
		if err != nil {
			return err
		}
		if w.rows != 0 && (w.rows >= w.rowLimit() || w.size+2+len(tuple)+2 > w.opts.MaxBytes) {
			if err := w.endStatement(); err != nil {
				return err
			}
		}
		separator := ",\n"
		if w.rows == 0 {
			separator = w.prefix
		}
		if err := w.write(separator); err != nil {
			return err
		}
		if err := w.write(tuple); err != nil {
			return err
		}
		w.size += len(separator) + len(tuple)
		w.rows++
	}
	return nil
}

func (w *sqlWriter) tuple(row []engine.Value) (string, error) {
	if len(row) != w.columns {
		return "", fmt.Errorf("dataformat: row has %d values, expected %d", len(row), w.columns)
	}
	var out strings.Builder
	out.WriteByte('(')
	for i, value := range row {
		remaining := w.opts.MaxRecordBytes - len(w.prefix) - out.Len() - 3
		if !valueFits(value, &remaining, 0) {
			return "", errRecordSize
		}
		literal, err := sqldialect.FormatDumpLiteral(w.opts.Dialect, value)
		if err != nil {
			return "", fmt.Errorf("dataformat: encode SQL column %d: %w", i+1, err)
		}
		if i > 0 {
			out.WriteString(", ")
		}
		if len(w.prefix)+out.Len()+len(literal)+3 > w.opts.MaxRecordBytes {
			return "", errRecordSize
		}
		out.WriteString(literal)
	}
	out.WriteByte(')')
	return out.String(), nil
}

func (w *sqlWriter) rowLimit() int {
	if w.opts.Dialect.Lexer() == sqlsplit.Oracle {
		return 1
	}
	return engine.MaxBatchRows
}

func (w *sqlWriter) endStatement() error {
	w.rows, w.size = 0, 0
	return w.write(";\n")
}

func (w *sqlWriter) Close(ctx context.Context) error {
	if w.closed || w.err != nil {
		return w.err
	}
	if err := ctx.Err(); err != nil {
		return fmt.Errorf("dataformat: %w", err)
	}
	w.closed = true
	if w.rows != 0 {
		return w.endStatement()
	}
	return nil
}

func (w *sqlWriter) write(s string) error {
	if w.err == nil {
		w.err = writeString(w.dst, s)
	}
	return w.err
}
