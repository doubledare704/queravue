// Package enginetest is the shared integration suite every SQL engine must
// pass: connect, ping, streaming, cancel, schema tree, table paging with
// filter and sort, and edits with rollback. Engine packages call Run from
// //go:build integration tests against the dev databases.
package enginetest

import (
	"context"
	"reflect"
	"runtime"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/sqlbuilder"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
)

// Target describes one database under test. The database must hold the seed
// from dev/seed/<engine>: customers, orders, order_items, logs_no_pk,
// customer_order_summary_view and million_items.
type Target struct {
	Engine engine.Engine
	Config engine.Config
	Secret engine.Secret
	// Product is the expected ServerInfo.Product.
	Product string
	// Database and Schema are the arguments for SchemaInspector calls and
	// table refs. Schema may be empty for engines without a schema level.
	Database, Schema string
	// Series100k returns SQL producing n rows (one int column "n", 1..n).
	// Zero means use million_items.
	Series func(n int) string
	// SkipEdit skips the edit test (engines without transactional DML).
	SkipEdit bool
}

func (tg Target) connect(t *testing.T) engine.Conn {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
	defer cancel()
	c, err := tg.Engine.Connect(ctx, tg.Config, tg.Secret)
	if err != nil {
		t.Fatalf("connect: %v (are the dev databases up? docker compose -f dev/docker-compose.yml up -d --wait)", err)
	}
	t.Cleanup(func() { _ = c.Close() })
	return c
}

func (tg Target) ref(table string) *queravuev1.TableRef {
	return &queravuev1.TableRef{Database: tg.Database, Schema: tg.Schema, Table: table}
}

// Run executes the whole suite.
func Run(t *testing.T, tg Target) {
	t.Run("ConnectPing", func(t *testing.T) { connectPing(t, tg) })
	t.Run("Stream100k", func(t *testing.T) { stream100k(t, tg) })
	t.Run("CancelMidStream", func(t *testing.T) { cancelMidStream(t, tg) })
	t.Run("StopEarly", func(t *testing.T) { stopEarly(t, tg) })
	t.Run("SchemaTree", func(t *testing.T) { schemaTree(t, tg) })
	t.Run("TablePageFilterSort", func(t *testing.T) { tablePage(t, tg) })
	t.Run("IndexLifecycle", func(t *testing.T) { indexLifecycle(t, tg) })
	t.Run("OnlineIndexBuild", func(t *testing.T) { onlineIndexBuild(t, tg) })
	t.Run("ListIndexesOfMissingTable", func(t *testing.T) { listIndexesOfMissingTable(t, tg) })
	t.Run("TableStats", func(t *testing.T) { tableStats(t, tg) })
	t.Run("DDLRoundTrip", func(t *testing.T) { ddlRoundTrip(t, tg) })
	t.Run("BulkColumns", func(t *testing.T) { bulkColumns(t, tg) })
	t.Run("SchemaGraph", func(t *testing.T) { schemaGraph(t, tg) })
	if !tg.SkipEdit {
		t.Run("EditAndRollback", func(t *testing.T) { editRollback(t, tg) })
	}
	t.Run("Stream1MMemory", func(t *testing.T) { stream1M(t, tg) })
}

// collector is a RowSink that counts rows and keeps the first few.
type collector struct {
	cols    []engine.Column
	rows    [][]engine.Value
	keep    int
	n       int64
	batches int
	maxB    int
	onBatch func(n int64) error
}

func (c *collector) Columns(cols []engine.Column) error { c.cols = cols; return nil }
func (c *collector) Batch(rows [][]engine.Value) error {
	c.batches++
	c.maxB = max(c.maxB, len(rows))
	for _, r := range rows {
		if len(c.rows) < c.keep {
			c.rows = append(c.rows, append([]engine.Value(nil), r...))
		}
	}
	c.n += int64(len(rows))
	if c.onBatch != nil {
		return c.onBatch(c.n)
	}
	return nil
}

func exec(t *testing.T, c engine.Conn, sql string, params ...engine.Value) (*collector, engine.Summary) {
	t.Helper()
	ex, ok := engine.As[engine.Executor](c)
	if !ok {
		t.Fatal("connection is not an Executor")
	}
	col := &collector{keep: 1000}
	ctx, cancel := context.WithTimeout(context.Background(), 60*time.Second)
	defer cancel()
	sum, err := ex.Execute(ctx, engine.Statement{SQL: sql, Params: params}, col)
	if err != nil {
		t.Fatalf("execute %q: %v", sql, err)
	}
	return col, sum
}

func connectPing(t *testing.T, tg Target) {
	c := tg.connect(t)
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := c.Ping(ctx); err != nil {
		t.Fatal(err)
	}
	info, err := c.ServerInfo(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if info.Product != tg.Product || info.Version == "" {
		t.Errorf("ServerInfo = %+v, want product %q", info, tg.Product)
	}
	if _, ok := sqldialect.Of(c); !ok {
		t.Error("connection provides no SQL dialect")
	}
	for _, capability := range tg.Engine.Descriptor().Capabilities {
		if iface, ok := engine.CapabilityInterfaces[capability]; ok && !implements(c, iface) {
			t.Errorf("declares %s but Conn does not implement %v", capability, iface)
		}
	}
}

func series(tg Target, n int) string {
	if tg.Series != nil {
		return tg.Series(n)
	}
	return "SELECT id AS n FROM million_items WHERE id <= " + itoa(n) + " ORDER BY id"
}

func stream100k(t *testing.T, tg Target) {
	c := tg.connect(t)
	col, sum := exec(t, c, series(tg, 100_000))
	if col.n != 100_000 || sum.RowsRead != 100_000 {
		t.Errorf("rows = %d (summary %d), want 100000", col.n, sum.RowsRead)
	}
	if col.maxB > engine.MaxBatchRows {
		t.Errorf("batch of %d rows exceeds %d", col.maxB, engine.MaxBatchRows)
	}
	if len(col.cols) != 1 || col.cols[0].Kind != engine.VInt {
		t.Errorf("columns = %+v, want one int column", col.cols)
	}
	if !sum.HasRows {
		t.Error("HasRows = false")
	}
}

func cancelMidStream(t *testing.T, tg Target) {
	c := tg.connect(t)
	ex, _ := engine.As[engine.Executor](c)
	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	col := &collector{onBatch: func(n int64) error {
		if n >= 2*engine.MaxBatchRows {
			cancel()
		}
		return nil
	}}
	done := make(chan error, 1)
	go func() {
		_, err := ex.Execute(ctx, engine.Statement{SQL: series(tg, 1_000_000)}, col)
		done <- err
	}()
	select {
	case err := <-done:
		if engine.KindOf(err) != engine.KindCanceled {
			t.Fatalf("err = %v (kind %v), want canceled", err, engine.KindOf(err))
		}
	case <-time.After(30 * time.Second):
		t.Fatal("cancel did not stop the statement")
	}
	t.Logf("cancel: read %d of 1000000 rows before stopping", col.n)
	if col.n >= 1_000_000 {
		t.Errorf("read all %d rows despite cancel", col.n)
	}
	// The session must survive a cancel.
	got, _ := exec(t, c, "SELECT 1")
	if got.n != 1 {
		t.Errorf("SELECT 1 after cancel returned %d rows", got.n)
	}
}

func stopEarly(t *testing.T, tg Target) {
	c := tg.connect(t)
	ex, _ := engine.As[engine.Executor](c)
	col := &collector{onBatch: func(int64) error { return engine.ErrStop }}
	if _, err := ex.Execute(context.Background(), engine.Statement{SQL: series(tg, 1_000_000)}, col); err != nil {
		t.Fatalf("ErrStop must end cleanly, got %v", err)
	}
	if col.batches != 1 {
		t.Errorf("batches = %d, want 1", col.batches)
	}
	got, _ := exec(t, c, "SELECT 1")
	if got.n != 1 {
		t.Errorf("SELECT 1 after stop returned %d rows", got.n)
	}
}

func schemaTree(t *testing.T, tg Target) {
	c := tg.connect(t)
	si, ok := engine.As[engine.SchemaInspector](c)
	if !ok {
		t.Fatal("connection is not a SchemaInspector")
	}
	ctx, cancel := context.WithTimeout(context.Background(), 30*time.Second)
	defer cancel()

	dbs, err := si.ListDatabases(ctx)
	if err != nil || !contains(dbs, tg.Database) {
		t.Fatalf("ListDatabases = %v, %v; want %q", dbs, err, tg.Database)
	}
	schemas, err := si.ListSchemas(ctx, tg.Database)
	if err != nil || len(schemas) == 0 {
		t.Fatalf("ListSchemas = %v, %v", schemas, err)
	}
	schema := tg.Schema
	if schema == "" {
		schema = schemas[0]
	}
	if !contains(schemas, schema) {
		t.Fatalf("schemas %v lack %q", schemas, schema)
	}
	objs, err := si.ListObjects(ctx, tg.Database, schema)
	if err != nil {
		t.Fatal(err)
	}
	byName := map[string]engine.SchemaObject{}
	for _, o := range objs {
		byName[o.Name] = o
	}
	for _, n := range []string{"customers", "orders", "order_items", "logs_no_pk", "million_items"} {
		if o, ok := byName[n]; !ok || o.Type != engine.ObjectTypeTable {
			t.Errorf("object %q = %+v, want a table", n, o)
		}
	}
	if o := byName["customer_order_summary_view"]; o.Type != engine.ObjectTypeView {
		t.Errorf("view = %+v", o)
	}
	if o := byName["million_items"]; o.EstimatedRows < 100_000 {
		t.Errorf("million_items estimate = %d, want a large estimate", o.EstimatedRows)
	}

	d, err := si.DescribeTable(ctx, tg.Database, schema, "orders")
	if err != nil {
		t.Fatal(err)
	}
	if !d.CanEdit || len(d.Columns) < 3 || !d.Columns[0].IsPrimaryKey || d.Columns[0].PrimaryKeyOrder != 1 {
		t.Errorf("orders = %+v", d)
	}
	if len(d.ForeignKeys) != 1 || d.ForeignKeys[0].ReferencedTable != "customers" ||
		len(d.ForeignKeys[0].Columns) != 1 || d.ForeignKeys[0].Columns[0] != "customer_id" {
		t.Errorf("orders FKs = %+v", d.ForeignKeys)
	}
	items, err := si.DescribeTable(ctx, tg.Database, schema, "order_items")
	if err != nil {
		t.Fatal(err)
	}
	if !items.Columns[0].IsPrimaryKey || !items.Columns[1].IsPrimaryKey || items.Columns[1].PrimaryKeyOrder != 2 {
		t.Errorf("composite PK not detected: %+v", items.Columns)
	}
	nopk, err := si.DescribeTable(ctx, tg.Database, schema, "logs_no_pk")
	if err != nil {
		t.Fatal(err)
	}
	if nopk.CanEdit || nopk.EditDisabledReason == "" {
		t.Errorf("logs_no_pk must be read-only with a reason: %+v", nopk)
	}
	v, err := si.DescribeTable(ctx, tg.Database, schema, "customer_order_summary_view")
	if err != nil || v.Type != engine.ObjectTypeView || v.CanEdit {
		t.Errorf("view = %+v, %v", v, err)
	}
	if _, err := si.DescribeTable(ctx, tg.Database, schema, "no_such_table"); engine.KindOf(err) != engine.KindNotFound {
		t.Errorf("missing table err = %v, want not_found", err)
	}
}

func tablePage(t *testing.T, tg Target) {
	c := tg.connect(t)
	d, _ := sqldialect.Of(c)
	filter := &queravuev1.TableFilter{Root: &queravuev1.FilterGroup{Conditions: []*queravuev1.FilterCondition{{
		Column: "val", Op: queravuev1.FilterOp_FILTER_OP_GREATER_THAN,
		Values: []*queravuev1.Value{{Kind: &queravuev1.Value_IntValue{IntValue: 999_990}}},
	}}}}
	sorts := []*queravuev1.SortClause{{Column: "val", Direction: queravuev1.SortDirection_SORT_DIRECTION_DESC}}
	sql, params, _, err := sqlbuilder.BuildSelectOrdered(d, tg.ref("million_items"), filter, sorts, 5)
	if err != nil {
		t.Fatal(err)
	}
	col, _ := exec(t, c, sql, params...)
	if col.n != 5 {
		t.Fatalf("page rows = %d, want 5\n%s", col.n, sql)
	}
	vi := colIndex(col.cols, "val")
	if vi < 0 || col.rows[0][vi].Int != 1_000_000 || col.rows[4][vi].Int != 999_996 {
		t.Errorf("sorted page = %v", col.rows)
	}

	// Page without a sort must still work and respect the limit.
	sql, params, _, err = sqlbuilder.BuildSelectOrdered(d, tg.ref("customers"), nil, nil, 2)
	if err != nil {
		t.Fatal(err)
	}
	if col, _ = exec(t, c, sql, params...); col.n != 2 {
		t.Errorf("limit 2 returned %d rows", col.n)
	}
	// NULL placement option compiles and runs.
	sorts = []*queravuev1.SortClause{{Column: "name", Nulls: queravuev1.NullsOrder_NULLS_ORDER_LAST}}
	sql, params, _, err = sqlbuilder.BuildSelectOrdered(d, tg.ref("customers"), nil, sorts, 10)
	if err != nil {
		t.Fatal(err)
	}
	exec(t, c, sql, params...)
}

func editRollback(t *testing.T, tg Target) {
	c := tg.connect(t)
	d, _ := sqldialect.Of(c)
	count := func() int64 {
		col, _ := exec(t, c, "SELECT COUNT(*) FROM "+d.QualifyTable(tg.Schema, "customers"))
		return col.rows[0][0].Int
	}
	before := count()
	str := func(s string) *queravuev1.Value {
		return &queravuev1.Value{Kind: &queravuev1.Value_TextValue{TextValue: s}}
	}
	changes := []*queravuev1.RowChange{{
		Type: queravuev1.RowChangeType_ROW_CHANGE_TYPE_INSERT,
		Values: []*queravuev1.ColumnValue{
			{Column: "name", Value: str("Dana 'Quote' \\ Slash")},
			{Column: "email", Value: str("dana-enginetest@example.com")},
		},
	}}
	plans, preview, err := sqlbuilder.BuildApplyChanges(d, tg.ref("customers"), changes)
	if err != nil || preview == "" {
		t.Fatalf("plan: %v", err)
	}
	// Pending changes applied then rolled back leave no trace.
	exec(t, c, d.Begin())
	for _, p := range plans {
		if _, sum := exec(t, c, p.Statement.SQL, p.Statement.Params...); sum.RowsAffected != 1 {
			t.Errorf("insert affected %d rows", sum.RowsAffected)
		}
	}
	if got := count(); got != before+1 {
		t.Errorf("inside txn count = %d, want %d", got, before+1)
	}
	exec(t, c, "ROLLBACK")
	if got := count(); got != before {
		t.Fatalf("after rollback count = %d, want %d", got, before)
	}

	// Commit path: insert, update, delete, in one transaction.
	exec(t, c, d.Begin())
	for _, p := range plans {
		exec(t, c, p.Statement.SQL, p.Statement.Params...)
	}
	col, _ := exec(t, c, "SELECT id, name FROM "+d.QualifyTable(tg.Schema, "customers")+" WHERE email = "+d.FormatLiteral(engine.Text("dana-enginetest@example.com")))
	if col.n != 1 {
		t.Fatalf("inserted row not found")
	}
	if col.rows[0][1].Str != "Dana 'Quote' \\ Slash" {
		t.Errorf("quotes/backslashes mangled: %q", col.rows[0][1].Str)
	}
	key := &queravuev1.ColumnValue{Column: "id", Value: &queravuev1.Value{Kind: &queravuev1.Value_IntValue{IntValue: col.rows[0][0].Int}}}
	upd, _, err := sqlbuilder.BuildApplyChanges(d, tg.ref("customers"), []*queravuev1.RowChange{{
		Type: queravuev1.RowChangeType_ROW_CHANGE_TYPE_UPDATE, Keys: []*queravuev1.ColumnValue{key},
		Values: []*queravuev1.ColumnValue{{Column: "name", Value: str("Dana Renamed")}},
	}})
	if err != nil {
		t.Fatal(err)
	}
	del, _, err := sqlbuilder.BuildApplyChanges(d, tg.ref("customers"), []*queravuev1.RowChange{{
		Type: queravuev1.RowChangeType_ROW_CHANGE_TYPE_DELETE, Keys: []*queravuev1.ColumnValue{key},
	}})
	if err != nil {
		t.Fatal(err)
	}
	if _, sum := exec(t, c, upd[0].Statement.SQL, upd[0].Statement.Params...); sum.RowsAffected != 1 {
		t.Errorf("update affected %d", sum.RowsAffected)
	}
	if _, sum := exec(t, c, del[0].Statement.SQL, del[0].Statement.Params...); sum.RowsAffected != 1 {
		t.Errorf("delete affected %d", sum.RowsAffected)
	}
	exec(t, c, "COMMIT")
	if got := count(); got != before {
		t.Errorf("after commit count = %d, want %d", got, before)
	}
}

// stream1M streams a million rows and checks the process heap stays within
// a small window: nothing may buffer the whole result.
func stream1M(t *testing.T, tg Target) {
	c := tg.connect(t)
	ex, _ := engine.As[engine.Executor](c)
	runtime.GC()
	var base runtime.MemStats
	runtime.ReadMemStats(&base)
	var peak uint64
	col := &collector{onBatch: func(n int64) error {
		if n%(50*engine.MaxBatchRows) == 0 {
			var m runtime.MemStats
			runtime.ReadMemStats(&m)
			peak = max(peak, m.HeapAlloc)
		}
		return nil
	}}
	sum, err := ex.Execute(context.Background(), engine.Statement{SQL: series(tg, 1_000_000)}, col)
	if err != nil {
		t.Fatal(err)
	}
	if col.n != 1_000_000 || sum.RowsRead != 1_000_000 {
		t.Fatalf("rows = %d", col.n)
	}
	t.Logf("1M rows in %v; heap %d MB -> peak %d MB", sum.Duration, base.HeapAlloc>>20, peak>>20)
	const window = 32 << 20 // generous: one batch is well under 1 MB
	if peak > base.HeapAlloc+window {
		t.Errorf("heap grew from %d MB to %d MB while streaming 1M rows", base.HeapAlloc>>20, peak>>20)
	}
}

func contains(ss []string, s string) bool {
	for _, x := range ss {
		if x == s {
			return true
		}
	}
	return false
}

func colIndex(cols []engine.Column, name string) int {
	for i, c := range cols {
		if c.Name == name {
			return i
		}
	}
	return -1
}

func itoa(n int) string {
	if n == 0 {
		return "0"
	}
	var b [20]byte
	i := len(b)
	for ; n > 0; n /= 10 {
		i--
		b[i] = byte('0' + n%10)
	}
	return string(b[i:])
}

func implements(c engine.Conn, iface reflect.Type) bool {
	return reflect.TypeOf(c).Implements(iface)
}
