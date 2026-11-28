package enginetest

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"io"
	"math"
	"reflect"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

// RowFixture is a table that holds one value of every engine.Value kind the
// engine supports. Columns[0] must be an integer key.
type RowFixture struct {
	// CreateSQL builds the CREATE TABLE statement for the qualified table name.
	CreateSQL string
	Columns   []string
	Rows      [][]engine.Value
	// Want is what reading Rows back should give; nil means Rows itself.
	Want [][]engine.Value
}

// RowLoaderTarget is a database under test for the RowLoader suite.
type RowLoaderTarget struct {
	Target
	Fixture RowFixture
	// KeyedTableSQL replaces the CREATE TABLE of the table with an integer key
	// column "id" and a text column "label" that most cases load into.
	KeyedTableSQL string
	// ViolatingKey is a key value the server rejects; nil means a repeat of a
	// key loaded earlier, for engines whose tables enforce a primary key.
	ViolatingKey *engine.Value
	// NoTransactions skips the case of a transaction the caller left open, for
	// engines that have none.
	NoTransactions bool
}

const (
	loadBatchRows = 100
	keyBase       = 1234500
)

// RunRowLoader checks the engine.RowLoader contract: a round trip of every
// value kind, an empty source, cancel and source errors that leave only
// committed batches, and a constraint violation in the middle of a batch.
func RunRowLoader(t *testing.T, tg RowLoaderTarget) {
	if !has(tg.Target, engine.CapBulkLoad) {
		t.Fatal("engine does not declare bulk_load")
	}
	t.Run("RoundTripEveryValueKind", func(t *testing.T) { rowRoundTrip(t, tg) })
	t.Run("EmptySource", func(t *testing.T) { rowEmptySource(t, tg) })
	t.Run("CancelMidLoad", func(t *testing.T) { rowCancelMidLoad(t, tg) })
	t.Run("SourceErrorMidLoad", func(t *testing.T) { rowSourceError(t, tg) })
	t.Run("ConstraintViolationMidBatch", func(t *testing.T) { rowConstraintViolation(t, tg) })
	t.Run("ColumnCountMismatch", func(t *testing.T) { rowColumnMismatch(t, tg) })
	t.Run("BatchLargerThanOneInsert", func(t *testing.T) { rowLargeBatch(t, tg) })
	if !tg.NoTransactions {
		t.Run("CallersOpenTransactionIsNotCommitted", func(t *testing.T) { rowOpenTransaction(t, tg) })
	}
}

type loaderSession struct {
	tg      RowLoaderTarget
	conn    engine.Conn
	loader  engine.RowLoader
	dialect sqldialect.Dialect
}

func openRowLoader(t *testing.T, tg RowLoaderTarget) *loaderSession {
	t.Helper()
	c := tg.connect(t)
	loader, ok := engine.As[engine.RowLoader](c)
	if !ok {
		t.Fatal("connection is not a RowLoader")
	}
	d, ok := sqldialect.Of(c)
	if !ok {
		t.Fatal("connection has no dialect")
	}
	return &loaderSession{tg: tg, conn: c, loader: loader, dialect: d}
}

func (s *loaderSession) table(t *testing.T, name, createSQL string) string {
	t.Helper()
	qualified := s.dialect.QualifyTableIn(s.tg.Database, s.tg.Schema, name)
	exec(t, s.conn, "DROP TABLE IF EXISTS "+qualified)
	exec(t, s.conn, strings.ReplaceAll(createSQL, "{table}", qualified))
	t.Cleanup(func() { exec(t, s.conn, "DROP TABLE IF EXISTS "+qualified) })
	return qualified
}

func (s *loaderSession) keyedTable(t *testing.T, name string) string {
	createSQL := s.tg.KeyedTableSQL
	if createSQL == "" {
		createSQL = fmt.Sprintf("CREATE TABLE {table} (%s INT PRIMARY KEY, %s VARCHAR(50))", s.dialect.QuoteIdent("id"), s.dialect.QuoteIdent("label"))
	}
	return s.table(t, name, createSQL)
}

func (s *loaderSession) load(ctx context.Context, name string, columns []string, src engine.RowBatchSource) (engine.LoadStats, error) {
	target := engine.LoadTarget{Database: s.tg.Database, Schema: s.tg.Schema, Table: name}
	return s.loader.LoadRows(ctx, target, columns, src)
}

func (s *loaderSession) count(t *testing.T, qualified string) uint64 {
	t.Helper()
	col, _ := exec(t, s.conn, "SELECT COUNT(*) FROM "+qualified)
	return countCell(t, col.rows[0][0])
}

func countCell(t *testing.T, cell engine.Value) uint64 {
	t.Helper()
	if cell.Kind == engine.VInt {
		return uint64(cell.Int) //nolint:gosec // COUNT(*) is non-negative
	}
	n, err := strconv.ParseUint(cell.Str, 10, 64)
	if err != nil {
		t.Fatalf("COUNT(*) = %s", describe(cell))
	}
	return n
}

var keyedColumns = []string{"id", "label"}

type rowSource struct {
	batches [][][]engine.Value
	next    int
	before  func(i int)
	failAt  int
	failErr error
}

func (s *rowSource) Next(context.Context) ([][]engine.Value, error) {
	i := s.next
	s.next++
	if s.before != nil {
		s.before(i)
	}
	if s.failErr != nil && i == s.failAt {
		return nil, s.failErr
	}
	if i >= len(s.batches) {
		return nil, io.EOF
	}
	return s.batches[i], nil
}

func keyedBatches(batches int, rowOf func(batch, row int) engine.Value) [][][]engine.Value {
	out := make([][][]engine.Value, batches)
	for b := range out {
		out[b] = make([][]engine.Value, loadBatchRows)
		for r := range out[b] {
			key := keyBase + b*loadBatchRows + r + 1
			out[b][r] = []engine.Value{rowOf(b, r), engine.Text(fmt.Sprintf("label-%d", key))}
		}
	}
	return out
}

func sequentialKeys(b, r int) engine.Value {
	return engine.Int(int64(keyBase + b*loadBatchRows + r + 1))
}

func rowRoundTrip(t *testing.T, tg RowLoaderTarget) {
	s := openRowLoader(t, tg)
	const name = "qv_load_roundtrip"
	qualified := s.table(t, name, tg.Fixture.CreateSQL)
	half := len(tg.Fixture.Rows) / 2
	src := &rowSource{batches: [][][]engine.Value{tg.Fixture.Rows[:half], tg.Fixture.Rows[half:]}}
	stats, err := s.load(context.Background(), name, tg.Fixture.Columns, src)
	if err != nil {
		t.Fatal(err)
	}
	if stats.Rows != uint64(len(tg.Fixture.Rows)) || stats.Batches != 2 {
		t.Errorf("stats = %+v, want %d rows in 2 batches", stats, len(tg.Fixture.Rows))
	}
	quoted := make([]string, len(tg.Fixture.Columns))
	for i, name := range tg.Fixture.Columns {
		quoted[i] = s.dialect.QuoteIdent(name)
	}
	got, _ := exec(t, s.conn, "SELECT "+strings.Join(quoted, ", ")+" FROM "+qualified+" ORDER BY "+quoted[0])
	want := tg.Fixture.Want
	if want == nil {
		want = tg.Fixture.Rows
	}
	if len(got.rows) != len(want) {
		t.Fatalf("read back %d rows, want %d", len(got.rows), len(want))
	}
	for i := range want {
		for j := range want[i] {
			if !valuesEqual(got.rows[i][j], want[i][j]) {
				t.Errorf("row %d column %s = %s, want %s", i, tg.Fixture.Columns[j], describe(got.rows[i][j]), describe(want[i][j]))
			}
		}
	}
}

func rowEmptySource(t *testing.T, tg RowLoaderTarget) {
	s := openRowLoader(t, tg)
	const name = "qv_load_empty"
	qualified := s.keyedTable(t, name)
	stats, err := s.load(context.Background(), name, keyedColumns, &rowSource{})
	if err != nil || stats != (engine.LoadStats{}) {
		t.Fatalf("stats = %+v, err = %v", stats, err)
	}
	if n := s.count(t, qualified); n != 0 {
		t.Errorf("%d rows after an empty load", n)
	}
}

func rowCancelMidLoad(t *testing.T, tg RowLoaderTarget) {
	s := openRowLoader(t, tg)
	const name = "qv_load_cancel"
	qualified := s.keyedTable(t, name)
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	src := &rowSource{batches: keyedBatches(10, sequentialKeys), before: func(i int) {
		if i == 3 {
			cancel()
		}
	}}
	stats, err := s.load(ctx, name, keyedColumns, src)
	if engine.KindOf(err) != engine.KindCanceled || !errors.Is(err, context.Canceled) {
		t.Fatalf("err = %v, want a cancelled error", err)
	}
	if want := uint64(3 * loadBatchRows); stats.Rows != want || stats.Batches != 3 {
		t.Errorf("stats = %+v, want %d rows in 3 batches", stats, want)
	}
	if n := s.count(t, qualified); n != stats.Rows {
		t.Errorf("%d rows stored, stats say %d", n, stats.Rows)
	}
}

func rowSourceError(t *testing.T, tg RowLoaderTarget) {
	s := openRowLoader(t, tg)
	const name = "qv_load_source_error"
	qualified := s.keyedTable(t, name)
	boom := errors.New("line 301 is malformed")
	src := &rowSource{batches: keyedBatches(10, sequentialKeys), failAt: 3, failErr: boom}
	stats, err := s.load(context.Background(), name, keyedColumns, src)
	if !errors.Is(err, boom) {
		t.Fatalf("err = %v, want the source error", err)
	}
	if want := uint64(3 * loadBatchRows); stats.Rows != want {
		t.Errorf("stats.Rows = %d, want %d", stats.Rows, want)
	}
	if n := s.count(t, qualified); n != stats.Rows {
		t.Errorf("%d rows stored, stats say %d", n, stats.Rows)
	}
}

func rowConstraintViolation(t *testing.T, tg RowLoaderTarget) {
	s := openRowLoader(t, tg)
	const name = "qv_load_constraint"
	qualified := s.keyedTable(t, name)
	batches := keyedBatches(5, sequentialKeys)
	violating := engine.Int(keyBase + 5)
	if tg.ViolatingKey != nil {
		violating = *tg.ViolatingKey
	}
	batches[2][50][0] = violating
	stats, err := s.load(context.Background(), name, keyedColumns, &rowSource{batches: batches})
	if engine.KindOf(err) != engine.KindConstraint {
		t.Fatalf("err = %v, want a constraint error", err)
	}
	if stats.Rows < 2*loadBatchRows {
		t.Errorf("stats.Rows = %d, want at least the two clean batches", stats.Rows)
	}
	if n := s.count(t, qualified); n != stats.Rows {
		t.Errorf("%d rows stored, stats say %d", n, stats.Rows)
	}
	if strings.Contains(err.Error(), fmt.Sprint(violating.Int)) || strings.Contains(err.Error(), "label-") {
		t.Errorf("error message quotes row data: %v", err)
	}
}

func rowColumnMismatch(t *testing.T, tg RowLoaderTarget) {
	s := openRowLoader(t, tg)
	const name = "qv_load_mismatch"
	qualified := s.keyedTable(t, name)
	src := &rowSource{batches: [][][]engine.Value{{{engine.Int(keyBase + 1)}}}}
	stats, err := s.load(context.Background(), name, keyedColumns, src)
	if engine.KindOf(err) != engine.KindInvalidConfig || stats.Rows != 0 {
		t.Fatalf("stats = %+v, err = %v", stats, err)
	}
	if n := s.count(t, qualified); n != 0 {
		t.Errorf("%d rows stored", n)
	}
}

func rowLargeBatch(t *testing.T, tg RowLoaderTarget) {
	s := openRowLoader(t, tg)
	const name = "qv_load_large_batch"
	const rows = 2500
	qualified := s.keyedTable(t, name)
	batch := make([][]engine.Value, rows)
	for i := range batch {
		batch[i] = []engine.Value{engine.Int(int64(keyBase + i + 1)), engine.Text(fmt.Sprintf("label-%d", keyBase+i+1))}
	}
	stats, err := s.load(context.Background(), name, keyedColumns, &rowSource{batches: [][][]engine.Value{batch}})
	if err != nil {
		t.Fatal(err)
	}
	if stats.Rows != rows || stats.Batches != 1 {
		t.Errorf("stats = %+v, want %d rows in 1 batch", stats, rows)
	}
	if n := s.count(t, qualified); n != rows {
		t.Errorf("%d rows stored, want %d", n, rows)
	}
}

func rowOpenTransaction(t *testing.T, tg RowLoaderTarget) {
	s := openRowLoader(t, tg)
	const name = "qv_load_open_transaction"
	qualified := s.keyedTable(t, name)
	exec(t, s.conn, s.dialect.Begin())
	exec(t, s.conn, "INSERT INTO "+qualified+" ("+s.dialect.QuoteIdent("id")+", "+s.dialect.QuoteIdent("label")+") VALUES (1, 'caller')")
	stats, loadErr := s.load(context.Background(), name, keyedColumns, &rowSource{batches: keyedBatches(1, sequentialKeys)})
	exec(t, s.conn, "ROLLBACK")
	if n := s.count(t, qualified); n != stats.Rows {
		t.Errorf("after the caller's ROLLBACK %d rows remain; the load reported %d (error: %v)", n, stats.Rows, loadErr)
	}
}

func valuesEqual(got, want engine.Value) bool {
	if got.Kind != want.Kind {
		return false
	}
	switch want.Kind {
	case engine.VNull:
		return true
	case engine.VBool:
		return got.Bool == want.Bool
	case engine.VInt:
		return got.Int == want.Int
	case engine.VFloat:
		return got.Float == want.Float || math.IsNaN(got.Float) && math.IsNaN(want.Float)
	case engine.VDecimal, engine.VText, engine.VUUID:
		return got.Str == want.Str
	case engine.VJSON:
		return jsonEqual(got.Str, want.Str)
	case engine.VBytes:
		return string(got.Bytes) == string(want.Bytes)
	case engine.VTimestamptz:
		return got.Time.Equal(want.Time)
	case engine.VArray:
		if len(got.Array) != len(want.Array) {
			return false
		}
		for i := range want.Array {
			if !valuesEqual(got.Array[i], want.Array[i]) {
				return false
			}
		}
		return true
	}
	return false
}

func jsonEqual(a, b string) bool {
	var x, y any
	if json.Unmarshal([]byte(a), &x) != nil || json.Unmarshal([]byte(b), &y) != nil {
		return a == b
	}
	return reflect.DeepEqual(x, y)
}

func describe(v engine.Value) string {
	switch v.Kind {
	case engine.VNull:
		return "NULL"
	case engine.VBool:
		return fmt.Sprintf("bool(%t)", v.Bool)
	case engine.VInt:
		return fmt.Sprintf("int(%d)", v.Int)
	case engine.VFloat:
		return fmt.Sprintf("float(%v)", v.Float)
	case engine.VDecimal, engine.VText, engine.VJSON, engine.VUUID:
		return fmt.Sprintf("kind%d(%q)", v.Kind, v.Str)
	case engine.VBytes:
		return fmt.Sprintf("bytes(%x)", v.Bytes)
	case engine.VTimestamptz:
		return "time(" + v.Time.UTC().Format(time.RFC3339Nano) + ")"
	case engine.VArray:
		parts := make([]string, len(v.Array))
		for i, el := range v.Array {
			parts[i] = describe(el)
		}
		return "[" + strings.Join(parts, ", ") + "]"
	}
	return fmt.Sprintf("kind%d", v.Kind)
}

// FixedBatches is a RowBatchSource that yields the given batches once.
func FixedBatches(batches ...[][]engine.Value) engine.RowBatchSource {
	return &rowSource{batches: batches}
}

// Exec runs a statement that returns no rows and fails the test on error.
func Exec(t *testing.T, c engine.Conn, sql string) {
	t.Helper()
	exec(t, c, sql)
}
