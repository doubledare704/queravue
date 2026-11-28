//go:build duckdb

package transfer

import (
	"context"
	"database/sql"
	"database/sql/driver"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"net/url"
	"os"
	"path/filepath"
	"strings"
	"time"

	duckdbdriver "github.com/duckdb/duckdb-go/v2"

	"github.com/doubledare704/queravue/core/internal/dataformat"
	"github.com/doubledare704/queravue/core/internal/engine"
)

// ParquetAvailable reports whether this build links DuckDB for Parquet.
const ParquetAvailable = true

const (
	parquetThreads  = 1
	parquetFileName = "transfer.parquet"
	parquetTable    = "transfer_rows"
)

// ParquetConfig bounds the private DuckDB instance of one transfer. Dir is where
// its temporary files live, and MemoryLimit caps DuckDB's buffers.
type ParquetConfig struct {
	Dir         string
	MemoryLimit string
}

// ParquetRows reads the rows of an uploaded Parquet file and removes its temporary files on Close.
type ParquetRows interface {
	RowReader
	Close()
}

type scratch struct {
	dir       string
	connector *duckdbdriver.Connector
}

func openScratch(cfg ParquetConfig) (*scratch, error) {
	if err := os.MkdirAll(cfg.Dir, 0o700); err != nil {
		return nil, fmt.Errorf("transfer: create temp dir: %w", err)
	}
	dir, err := os.MkdirTemp(cfg.Dir, "transfer-")
	if err != nil {
		return nil, fmt.Errorf("transfer: create temp dir: %w", err)
	}
	q := url.Values{}
	q.Set("memory_limit", cfg.MemoryLimit)
	q.Set("temp_directory", filepath.Join(dir, "spill"))
	q.Set("threads", fmt.Sprint(parquetThreads))
	q.Set("preserve_insertion_order", "false")
	connector, err := duckdbdriver.NewConnector(filepath.Join(dir, "work.duckdb")+"?"+q.Encode(), nil)
	if err != nil {
		_ = os.RemoveAll(dir)
		return nil, fmt.Errorf("transfer: open DuckDB: %w", err)
	}
	return &scratch{dir: dir, connector: connector}, nil
}

func (s *scratch) path() string { return filepath.Join(s.dir, parquetFileName) }

func (s *scratch) close() {
	if s.connector != nil {
		_ = s.connector.Close()
		s.connector = nil
	}
	_ = os.RemoveAll(s.dir)
}

func quoteLiteral(s string) string { return "'" + strings.ReplaceAll(s, "'", "''") + "'" }

func quoteIdent(s string) string { return `"` + strings.ReplaceAll(s, `"`, `""`) + `"` }

var duckTypes = map[engine.ValueKind]string{
	engine.VBool: "BOOLEAN", engine.VInt: "BIGINT", engine.VFloat: "DOUBLE", engine.VBytes: "BLOB", engine.VTimestamptz: "TIMESTAMPTZ",
}

func duckType(kind engine.ValueKind) string {
	if t, ok := duckTypes[kind]; ok {
		return t
	}
	return "VARCHAR"
}

type parquetWriter struct {
	dst      io.Writer
	cfg      ParquetConfig
	scratch  *scratch
	conn     driver.Conn
	appender *duckdbdriver.Appender
	kinds    []engine.ValueKind
	unsent   int
	closed   bool
}

// DuckDB's appender buffers about 200k rows natively before it flushes by itself, which breaks the memory budget.
const parquetFlushRows = 2048

// NewParquetWriter buffers rows in a private DuckDB table and writes the Parquet file to dst on Close.
func NewParquetWriter(dst io.Writer, cfg ParquetConfig) (dataformat.Writer, error) {
	return &parquetWriter{dst: dst, cfg: cfg}, nil
}

func (w *parquetWriter) Columns(ctx context.Context, columns []engine.Column) error {
	if w.scratch != nil || w.closed {
		return errors.New("transfer: columns already set or writer closed")
	}
	if len(columns) == 0 {
		return newError(KindUnsupported, "a Parquet file needs at least one column")
	}
	s, err := openScratch(w.cfg)
	if err != nil {
		return err
	}
	w.scratch = s
	if err := w.createTable(ctx, columns); err != nil {
		w.Abort()
		return err
	}
	return nil
}

func (w *parquetWriter) createTable(ctx context.Context, columns []engine.Column) error {
	conn, err := w.scratch.connector.Connect(ctx)
	if err != nil {
		return fmt.Errorf("transfer: connect DuckDB: %w", err)
	}
	w.conn = conn
	names := uniqueColumnNames(columns)
	defs := make([]string, len(columns))
	for i, c := range columns {
		w.kinds = append(w.kinds, c.Kind)
		defs[i] = quoteIdent(names[i]) + " " + duckType(c.Kind)
	}
	if err := w.exec(ctx, "CREATE TABLE "+parquetTable+" ("+strings.Join(defs, ", ")+")"); err != nil {
		return err
	}
	w.appender, err = duckdbdriver.NewAppenderFromConn(conn, "", parquetTable)
	if err != nil {
		return fmt.Errorf("transfer: open appender: %w", err)
	}
	return nil
}

// uniqueColumnNames makes names DuckDB accepts: not empty and distinct ignoring case.
// Names the result already has keep their spelling; the second and later copies get a suffix.
func uniqueColumnNames(columns []engine.Column) []string {
	taken := map[string]bool{}
	for _, c := range columns {
		taken[strings.ToLower(c.Name)] = true
	}
	seen := map[string]bool{}
	names := make([]string, len(columns))
	for i, c := range columns {
		name := strings.ToValidUTF8(c.Name, "\xef\xbf\xbd")
		if name == "" {
			name = fmt.Sprintf("column_%d", i+1)
		}
		if seen[strings.ToLower(name)] {
			base := name
			for n := 2; seen[strings.ToLower(name)] || taken[strings.ToLower(name)]; n++ {
				name = fmt.Sprintf("%s_%d", base, n)
			}
		}
		seen[strings.ToLower(name)] = true
		names[i] = name
	}
	return names
}

func (w *parquetWriter) exec(ctx context.Context, statement string) error {
	execer, ok := w.conn.(driver.ExecerContext)
	if !ok {
		return errors.New("transfer: DuckDB connection cannot execute statements")
	}
	if _, err := execer.ExecContext(ctx, statement, nil); err != nil {
		return fmt.Errorf("transfer: DuckDB: %w", err)
	}
	return nil
}

func (w *parquetWriter) Batch(ctx context.Context, rows [][]engine.Value) error {
	if w.appender == nil || w.closed {
		return errors.New("transfer: writer requires columns and must be open")
	}
	args := make([]driver.Value, len(w.kinds))
	for _, row := range rows {
		if err := ctx.Err(); err != nil {
			return fmt.Errorf("transfer: %w", err)
		}
		if len(row) != len(w.kinds) {
			return fmt.Errorf("transfer: row has %d values, expected %d", len(row), len(w.kinds))
		}
		for i, v := range row {
			arg, err := parquetArg(v, w.kinds[i])
			if err != nil {
				return err
			}
			args[i] = arg
		}
		if err := w.appender.AppendRow(args...); err != nil {
			return fmt.Errorf("transfer: append row: %w", err)
		}
		if w.unsent++; w.unsent >= parquetFlushRows {
			if err := w.appender.FlushWithCancel(ctx); err != nil {
				return fmt.Errorf("transfer: flush appender: %w", err)
			}
			w.unsent = 0
		}
	}
	return nil
}

func parquetArg(v engine.Value, kind engine.ValueKind) (driver.Value, error) {
	if v.Kind == engine.VNull {
		return nil, nil
	}
	if duckType(kind) == "VARCHAR" {
		return strings.ToValidUTF8(dataformat.ValueText(v), "�"), nil
	}
	typed, err := Coerce(v, kind)
	if err != nil {
		return nil, newError(KindMapping, "a value does not fit the Parquet column type %s", duckType(kind))
	}
	switch typed.Kind {
	case engine.VBool:
		return typed.Bool, nil
	case engine.VInt:
		return typed.Int, nil
	case engine.VFloat:
		return typed.Float, nil
	case engine.VBytes:
		return typed.Bytes, nil
	case engine.VTimestamptz:
		return typed.Time, nil
	}
	return nil, newError(KindMapping, "a value does not fit the Parquet column type %s", duckType(kind))
}

func (w *parquetWriter) Close(ctx context.Context) error {
	if w.closed {
		return nil
	}
	if w.scratch == nil {
		return errors.New("transfer: writer requires columns")
	}
	defer w.Abort()
	if err := w.appender.Close(); err != nil {
		return fmt.Errorf("transfer: flush appender: %w", err)
	}
	w.appender = nil
	if err := w.exec(ctx, "COPY "+parquetTable+" TO "+quoteLiteral(w.scratch.path())+" (FORMAT parquet, ROW_GROUP_SIZE 20000)"); err != nil {
		return err
	}
	f, err := os.Open(w.scratch.path())
	if err != nil {
		return fmt.Errorf("transfer: open parquet output: %w", err)
	}
	defer func() { _ = f.Close() }()
	if _, err := io.Copy(w.dst, f); err != nil {
		return fmt.Errorf("transfer: write parquet: %w", err)
	}
	return nil
}

// Abort releases DuckDB and deletes the temporary files; it is safe to call more than once.
func (w *parquetWriter) Abort() {
	if w.closed {
		return
	}
	w.closed = true
	if w.appender != nil {
		_ = w.appender.Close()
	}
	if w.conn != nil {
		_ = w.conn.Close()
	}
	if w.scratch != nil {
		w.scratch.close()
	}
}

type parquetColumn struct {
	name   string
	expr   string
	kind   engine.ValueKind
	nested string
}

var passThroughTypes = map[string]engine.ValueKind{
	"BOOLEAN": engine.VBool, "TINYINT": engine.VInt, "SMALLINT": engine.VInt, "INTEGER": engine.VInt, "BIGINT": engine.VInt,
	"UTINYINT": engine.VInt, "USMALLINT": engine.VInt, "UINTEGER": engine.VInt, "FLOAT": engine.VFloat, "DOUBLE": engine.VFloat,
	"VARCHAR": engine.VText, "BLOB": engine.VBytes, "TIMESTAMP WITH TIME ZONE": engine.VTimestamptz,
}

var timestampTypes = map[string]bool{"TIMESTAMP": true, "TIMESTAMP_S": true, "TIMESTAMP_MS": true, "TIMESTAMP_NS": true, "DATE": true}

func classifyParquetColumn(name, typeName string) parquetColumn {
	col := parquetColumn{name: name}
	ident := quoteIdent(name)
	upper := strings.ToUpper(typeName)
	switch {
	case strings.HasSuffix(upper, "]") || strings.HasPrefix(upper, "STRUCT") || strings.HasPrefix(upper, "MAP") || strings.HasPrefix(upper, "UNION"):
		col.nested = typeName
	case passThroughTypes[upper] != engine.VNull:
		col.kind, col.expr = passThroughTypes[upper], ident
	case timestampTypes[upper]:
		col.kind, col.expr = engine.VTimestamptz, "CAST("+ident+" AS TIMESTAMPTZ)"
	case strings.HasPrefix(upper, "DECIMAL") || upper == "UBIGINT" || upper == "HUGEINT" || upper == "UHUGEINT":
		col.kind, col.expr = engine.VDecimal, "CAST("+ident+" AS VARCHAR)"
	case upper == "UUID":
		col.kind, col.expr = engine.VUUID, "CAST("+ident+" AS VARCHAR)"
	default:
		col.kind, col.expr = engine.VText, "CAST("+ident+" AS VARCHAR)"
	}
	return col
}

type parquetReader struct {
	scratch *scratch
	db      *sql.DB
	rows    *sql.Rows
	columns []parquetColumn
	line    int64
	lines   []int64
}

func spoolToFile(ctx context.Context, src io.Reader, s *scratch) error {
	f, err := os.OpenFile(s.path(), os.O_CREATE|os.O_WRONLY|os.O_EXCL, 0o600)
	if err != nil {
		return fmt.Errorf("transfer: create temp file: %w", err)
	}
	_, copyErr := io.Copy(f, &ctxReader{ctx: ctx, r: src})
	if err := f.Close(); err != nil && copyErr == nil {
		copyErr = err
	}
	if copyErr != nil {
		return fmt.Errorf("transfer: spool upload: %w", copyErr)
	}
	return nil
}

type ctxReader struct {
	ctx context.Context //nolint:containedctx // adapts io.Reader to a cancellable copy
	r   io.Reader
}

func (r *ctxReader) Read(p []byte) (int, error) {
	if err := r.ctx.Err(); err != nil {
		return 0, fmt.Errorf("transfer: %w", err)
	}
	n, err := r.r.Read(p)
	if err != nil && !errors.Is(err, io.EOF) {
		return n, fmt.Errorf("transfer: read upload: %w", err)
	}
	return n, err //nolint:wrapcheck // io.EOF must stay io.EOF
}

// OpenParquetReader spools the upload to a temporary file and reads it through a private DuckDB.
func OpenParquetReader(ctx context.Context, src io.Reader, cfg ParquetConfig) (ParquetRows, error) {
	s, err := openScratch(cfg)
	if err != nil {
		return nil, err
	}
	r := &parquetReader{scratch: s}
	fail := func(err error) (ParquetRows, error) {
		r.Close()
		return nil, err
	}
	if err := spoolToFile(ctx, src, s); err != nil {
		return fail(err)
	}
	if err := r.describe(ctx); err != nil {
		return fail(err)
	}
	return r, nil
}

func (r *parquetReader) describe(ctx context.Context) error {
	r.db = sql.OpenDB(r.scratch.connector)
	r.db.SetMaxOpenConns(1)
	if _, err := r.db.ExecContext(ctx, "SET TimeZone='UTC'"); err != nil {
		return fmt.Errorf("transfer: DuckDB: %w", err)
	}
	rows, err := r.db.QueryContext(ctx, "DESCRIBE SELECT * FROM read_parquet("+quoteLiteral(r.scratch.path())+")") //nolint:gosec // the path is a core-made temp file, quoted
	if err != nil {
		if ctx.Err() != nil {
			return fmt.Errorf("transfer: %w", ctx.Err())
		}
		slog.Debug("transfer: describe parquet", "err", err)
		return newError(KindParse, "the file is not a readable Parquet file")
	}
	defer func() { _ = rows.Close() }()
	for rows.Next() {
		var name, typeName string
		var ignored sql.NullString
		if err := rows.Scan(&name, &typeName, &ignored, &ignored, &ignored, &ignored); err != nil {
			return fmt.Errorf("transfer: describe parquet: %w", err)
		}
		col := classifyParquetColumn(name, typeName)
		if col.nested != "" {
			return newError(KindUnsupported, "column %q has the nested type %s; nested Parquet types are not supported", name, col.nested)
		}
		r.columns = append(r.columns, col)
	}
	if err := rows.Err(); err != nil {
		return fmt.Errorf("transfer: describe parquet: %w", err)
	}
	return nil
}

func (r *parquetReader) Columns(context.Context) ([]string, error) {
	names := make([]string, len(r.columns))
	for i, c := range r.columns {
		names[i] = c.name
	}
	return names, nil
}

func (r *parquetReader) Lines() []int64 { return r.lines }

func (r *parquetReader) Next(ctx context.Context) ([][]engine.Value, error) {
	if len(r.columns) == 0 {
		return nil, io.EOF
	}
	if r.rows == nil {
		exprs := make([]string, len(r.columns))
		for i, c := range r.columns {
			exprs[i] = c.expr
		}
		rows, err := r.db.QueryContext(duckdbdriver.WithStreamingResults(ctx), "SELECT "+strings.Join(exprs, ", ")+" FROM read_parquet("+quoteLiteral(r.scratch.path())+")") //nolint:gosec // the path is a core-made temp file, quoted; identifiers are quoted
		if err != nil {
			return nil, fmt.Errorf("transfer: read parquet: %w", err)
		}
		r.rows = rows
	}
	r.lines = r.lines[:0]
	var batch [][]engine.Value
	size := 0
	dest := make([]any, len(r.columns))
	ptrs := make([]any, len(r.columns))
	for i := range ptrs {
		ptrs[i] = &dest[i]
	}
	for len(batch) < engine.MaxBatchRows && size < dataformat.MaxBatchBytes && r.rows.Next() {
		if err := r.rows.Scan(ptrs...); err != nil {
			return nil, fmt.Errorf("transfer: read parquet: %w", err)
		}
		row := make([]engine.Value, len(dest))
		for i, v := range dest {
			row[i] = parquetValue(r.columns[i].kind, v)
			size += 16 + len(row[i].Str) + len(row[i].Bytes)
		}
		r.line++
		r.lines = append(r.lines, r.line)
		batch = append(batch, row)
	}
	if err := r.rows.Err(); err != nil {
		if ctx.Err() != nil {
			return nil, fmt.Errorf("transfer: %w", ctx.Err())
		}
		return nil, fmt.Errorf("transfer: read parquet: %w", err)
	}
	if len(batch) == 0 {
		return nil, io.EOF
	}
	return batch, nil
}

func parquetValue(kind engine.ValueKind, v any) engine.Value {
	switch x := v.(type) {
	case nil:
		return engine.Null()
	case bool:
		return engine.Bool(x)
	case int8:
		return engine.Int(int64(x))
	case int16:
		return engine.Int(int64(x))
	case int32:
		return engine.Int(int64(x))
	case int64:
		return engine.Int(x)
	case uint8:
		return engine.Int(int64(x))
	case uint16:
		return engine.Int(int64(x))
	case uint32:
		return engine.Int(int64(x))
	case float32:
		return engine.Float(float64(x))
	case float64:
		return engine.Float(x)
	case []byte:
		return engine.Bytes(append([]byte(nil), x...))
	case time.Time:
		return engine.Timestamptz(x)
	case string:
		switch kind {
		case engine.VDecimal:
			return engine.Decimal(x)
		case engine.VUUID:
			return engine.UUID(x)
		}
		return engine.Text(x)
	}
	return engine.Text(fmt.Sprint(v))
}

// Close deletes the temporary files and releases DuckDB.
func (r *parquetReader) Close() {
	if r.rows != nil {
		_ = r.rows.Close()
	}
	if r.db != nil {
		_ = r.db.Close()
	}
	r.scratch.close()
}

const parquetPreviewRows = 20

// InferParquet reads the columns and a preview of a whole Parquet file. A file
// cut short, as InferImport's sample is, gets no columns and a warning.
func InferParquet(ctx context.Context, src io.Reader, cfg ParquetConfig) (Inferred, *Error) {
	out := Inferred{Format: Parquet}
	rd, err := OpenParquetReader(ctx, src, cfg)
	if err != nil {
		typed := Classify(err)
		if typed.Kind == KindParse {
			out.Warnings = append(out.Warnings, "Parquet keeps its columns at the end of the file; send the whole file to infer them")
			return out, nil
		}
		return out, typed
	}
	defer rd.Close()
	pr, _ := rd.(*parquetReader)
	for _, c := range pr.columns {
		out.Columns = append(out.Columns, dataformat.InferredColumn{Name: c.name, Kind: c.kind, Nullable: true})
	}
	rows, err := rd.Next(ctx)
	if err != nil && !errors.Is(err, io.EOF) {
		return out, Classify(err)
	}
	out.Preview = rows[:min(len(rows), parquetPreviewRows)]
	return out, nil
}
