package diagram_test

import (
	"context"
	"errors"
	"fmt"
	"reflect"
	"sync"
	"testing"

	"github.com/doubledare704/queravue/core/internal/diagram"
	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/session"
)

func TestAssemble(t *testing.T) {
	objects := []engine.SchemaObject{
		{Name: "customers", Type: engine.ObjectTypeTable, EstimatedRows: 10},
		{Name: "orders", Type: engine.ObjectTypeTable, EstimatedRows: -1},
		{Name: "totals", Type: engine.ObjectTypeView},
	}
	columns := []engine.KeyedColumn{
		{Table: "customers", Name: "id", TypeName: "int", PrimaryKeyOrder: 1},
		{Table: "customers", Name: "name", TypeName: "text", Nullable: true},
		{Table: "ghost", Name: "x", TypeName: "int"},
		{Table: "orders", Name: "id", TypeName: "int", PrimaryKeyOrder: 1},
		{Table: "orders", Name: "customer_id", TypeName: "int"},
		{Table: "totals", Name: "sum", TypeName: "numeric", Nullable: true},
	}
	fk := engine.ForeignKeyDef{Name: "fk_customer", Columns: []string{"customer_id"}, ReferencedTable: "customers", ReferencedColumns: []string{"id"}}
	relations := []engine.TableRelation{
		{Table: "orders", ForeignKeyDef: fk},
		{Table: "ghost", ForeignKeyDef: fk},
	}

	g := diagram.Assemble(objects, columns, relations)

	if len(g.Tables) != 3 {
		t.Fatalf("tables = %d, want 3", len(g.Tables))
	}
	names := func(tb diagram.Table) (out []string) {
		for _, c := range tb.Columns {
			out = append(out, c.Name)
		}
		return out
	}
	if got := names(g.Tables[0]); !reflect.DeepEqual(got, []string{"id", "name"}) {
		t.Errorf("customers columns = %v", got)
	}
	if g.Tables[0].EstimatedRows != 10 || g.Tables[1].EstimatedRows != -1 || g.Tables[2].Type != engine.ObjectTypeView {
		t.Errorf("object fields were not carried over: %+v", g.Tables)
	}
	if got := g.Tables[1].Relations; !reflect.DeepEqual(got, []diagram.Relation{{ForeignKeyDef: fk}}) {
		t.Errorf("orders relations = %+v", got)
	}
	if len(g.Tables[0].Relations) != 0 || len(g.Tables[2].Relations) != 0 {
		t.Error("relations landed on the wrong table")
	}
}

func TestAssembleCapsColumnsPerTable(t *testing.T) {
	columns := make([]engine.KeyedColumn, diagram.MaxColumnsPerTable+5)
	for i := range columns {
		columns[i] = engine.KeyedColumn{Table: "wide", Name: fmt.Sprintf("c%d", i)}
	}
	g := diagram.Assemble([]engine.SchemaObject{{Name: "wide"}, {Name: "narrow"}}, columns, nil)
	if len(g.Tables[0].Columns) != diagram.MaxColumnsPerTable || !g.Tables[0].ColumnsTruncated {
		t.Errorf("wide: %d columns, truncated=%v", len(g.Tables[0].Columns), g.Tables[0].ColumnsTruncated)
	}
	if g.Tables[1].ColumnsTruncated {
		t.Error("narrow must not be marked truncated")
	}
}

type graphConn struct {
	objectCalls int
	failWith    error
}

func (*graphConn) Ping(context.Context) error { return nil }
func (*graphConn) ServerInfo(context.Context) (engine.ServerInfo, error) {
	return engine.ServerInfo{}, nil
}
func (*graphConn) Close() error                                          { return nil }
func (*graphConn) ListDatabases(context.Context) ([]string, error)       { return nil, nil }
func (*graphConn) ListSchemas(context.Context, string) ([]string, error) { return nil, nil }
func (*graphConn) DescribeTable(context.Context, string, string, string) (engine.TableDetails, error) {
	return engine.TableDetails{}, nil
}
func (c *graphConn) ListObjects(context.Context, string, string) ([]engine.SchemaObject, error) {
	c.objectCalls++
	return []engine.SchemaObject{{Name: "t"}}, c.failWith
}
func (*graphConn) ListKeyedColumns(context.Context, string, string) ([]engine.KeyedColumn, error) {
	return []engine.KeyedColumn{{Table: "t", Name: "id"}}, nil
}
func (*graphConn) ListRelations(context.Context, string, string) ([]engine.TableRelation, error) {
	return nil, nil
}

type plainConn struct{}

func (plainConn) Ping(context.Context) error { return nil }
func (plainConn) ServerInfo(context.Context) (engine.ServerInfo, error) {
	return engine.ServerInfo{}, nil
}
func (plainConn) Close() error { return nil }

type opener struct{ conn engine.Conn }

func (o opener) Open(context.Context, string) (engine.Conn, engine.Descriptor, error) {
	return o.conn, engine.Descriptor{}, nil
}

func open(t *testing.T, conn engine.Conn) *session.Session {
	t.Helper()
	mgr := session.NewManager(opener{conn: conn})
	t.Cleanup(mgr.Shutdown)
	sess, err := mgr.Open(context.Background(), "c")
	if err != nil {
		t.Fatal(err)
	}
	return sess
}

func TestStoreLoadsOnceUntilRefreshedOrInvalidated(t *testing.T) {
	conn := &graphConn{}
	sess := open(t, conn)
	store := diagram.NewStore()
	ctx := context.Background()

	for range 2 {
		g, err := store.Get(ctx, sess, diagram.Scope{Database: "db", Schema: "public"}, false)
		if err != nil || len(g.Tables) != 1 || len(g.Tables[0].Columns) != 1 {
			t.Fatalf("Get = %+v, %v", g, err)
		}
	}
	if conn.objectCalls != 1 {
		t.Errorf("loads after two reads = %d, want 1", conn.objectCalls)
	}
	if _, err := store.Get(ctx, sess, diagram.Scope{Database: "db", Schema: "other"}, false); err != nil || conn.objectCalls != 2 {
		t.Errorf("another schema must load on its own: calls = %d, err = %v", conn.objectCalls, err)
	}
	if _, err := store.Get(ctx, sess, diagram.Scope{Database: "db", Schema: "public"}, true); err != nil || conn.objectCalls != 3 {
		t.Errorf("refresh must reload: calls = %d, err = %v", conn.objectCalls, err)
	}
	store.Invalidate("someone-else")
	if _, _ = store.Get(ctx, sess, diagram.Scope{Database: "db", Schema: "public"}, false); conn.objectCalls != 3 {
		t.Errorf("invalidating another session reloaded: calls = %d", conn.objectCalls)
	}
	store.Invalidate(sess.ID)
	if _, _ = store.Get(ctx, sess, diagram.Scope{Database: "db", Schema: "public"}, false); conn.objectCalls != 4 {
		t.Errorf("invalidate must drop the graph: calls = %d", conn.objectCalls)
	}
}

func TestStoreDoesNotCacheFailures(t *testing.T) {
	boom := errors.New("boom")
	conn := &graphConn{failWith: boom}
	sess := open(t, conn)
	store := diagram.NewStore()
	if _, err := store.Get(context.Background(), sess, diagram.Scope{}, false); !errors.Is(err, boom) {
		t.Fatalf("err = %v, want boom", err)
	}
	conn.failWith = nil
	if g, err := store.Get(context.Background(), sess, diagram.Scope{}, false); err != nil || len(g.Tables) != 1 {
		t.Errorf("after the failure cleared: %+v, %v", g, err)
	}
}

func TestLoadNeedsRelationListerOrDocumentStore(t *testing.T) {
	sess := open(t, plainConn{})
	if _, err := diagram.Load(context.Background(), sess, diagram.Scope{}); !errors.Is(err, diagram.ErrNotSupported) {
		t.Errorf("err = %v, want ErrNotSupported", err)
	}
}

func TestLoadWaitsForARunningStatementAndStopsWithItsContext(t *testing.T) {
	sess := open(t, &graphConn{})
	_, finish, err := sess.Begin(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	if _, err := diagram.Load(ctx, sess, diagram.Scope{}); !errors.Is(err, context.Canceled) {
		t.Errorf("err while busy and cancelled = %v, want context.Canceled", err)
	}
	finish()
	if _, err := diagram.Load(context.Background(), sess, diagram.Scope{}); err != nil {
		t.Errorf("after the statement finished: %v", err)
	}
}

func BenchmarkAssemble500Tables(b *testing.B) {
	const tables, columnsEach = 500, 15
	objects := make([]engine.SchemaObject, tables)
	columns := make([]engine.KeyedColumn, 0, tables*columnsEach)
	relations := make([]engine.TableRelation, 0, tables)
	for i := range objects {
		name := fmt.Sprintf("table_%03d", i)
		objects[i] = engine.SchemaObject{Name: name, Type: engine.ObjectTypeTable}
		for c := range columnsEach {
			columns = append(columns, engine.KeyedColumn{Table: name, Name: fmt.Sprintf("col_%d", c), TypeName: "text"})
		}
		if i > 0 {
			relations = append(relations, engine.TableRelation{Table: name, ForeignKeyDef: engine.ForeignKeyDef{
				Name: "fk_" + name, Columns: []string{"col_1"}, ReferencedTable: objects[i/2].Name, ReferencedColumns: []string{"col_0"},
			}})
		}
	}
	b.ReportAllocs()
	for b.Loop() {
		diagram.Assemble(objects, columns, relations)
	}
}

type sampledConn struct {
	plainConn
	engine.DocumentStore
	mu          sync.Mutex
	sampleSizes []uint32
	failOn      string
	panicOn     string
}

func (*sampledConn) ListDatabases(context.Context) ([]string, error)       { return nil, nil }
func (*sampledConn) ListSchemas(context.Context, string) ([]string, error) { return nil, nil }
func (*sampledConn) DescribeTable(context.Context, string, string, string) (engine.TableDetails, error) {
	return engine.TableDetails{}, nil
}
func (*sampledConn) ListObjects(context.Context, string, string) ([]engine.SchemaObject, error) {
	return []engine.SchemaObject{
		{Name: "customers", Type: engine.ObjectTypeCollection},
		{Name: "orders", Type: engine.ObjectTypeCollection},
	}, nil
}

func (c *sampledConn) SampleFieldPaths(ctx context.Context, _, collection string, opts engine.PathSampleOptions) (engine.FieldPathSample, error) {
	c.mu.Lock()
	c.sampleSizes = append(c.sampleSizes, opts.SampleSize)
	c.mu.Unlock()
	switch collection {
	case c.failOn:
		return engine.FieldPathSample{}, errors.New("sample refused")
	case c.panicOn:
		panic("driver bug")
	}
	if err := ctx.Err(); err != nil {
		return engine.FieldPathSample{}, err
	}
	id := engine.FieldPathStat{Path: "_id", Frequency: 1, Types: []engine.FieldType{{Type: "objectId", Count: 3}}}
	if collection == "orders" {
		ref := engine.FieldPathStat{Path: "customerId", Frequency: 1, Types: []engine.FieldType{{Type: "objectId", Count: 3}}}
		return engine.FieldPathSample{Paths: []engine.FieldPathStat{id, ref}, Sampled: 3}, nil
	}
	return engine.FieldPathSample{Paths: []engine.FieldPathStat{id}, Sampled: 3}, nil
}

func TestLoadInfersTheGraphOfADocumentStore(t *testing.T) {
	conn := &sampledConn{}
	g, err := diagram.Load(context.Background(), open(t, conn), diagram.Scope{Database: "shop", SampleSize: 5000})
	if err != nil {
		t.Fatal(err)
	}
	if len(g.Tables) != 2 || len(g.Tables[1].Relations) != 1 {
		t.Fatalf("graph = %+v", g)
	}
	r := g.Tables[1].Relations[0]
	if !r.Inferred || r.ReferencedTable != "customers" || r.Confidence != 0.9 {
		t.Errorf("orders relation = %+v", r)
	}
	if !reflect.DeepEqual(conn.sampleSizes, []uint32{diagram.MaxSampleSize, diagram.MaxSampleSize}) {
		t.Errorf("sample sizes = %v, want the clamped size per collection", conn.sampleSizes)
	}
}

func TestLoadSampledReportsAFailedOrPanickingSample(t *testing.T) {
	for _, conn := range []*sampledConn{{failOn: "orders"}, {panicOn: "customers"}} {
		_, err := diagram.Load(context.Background(), open(t, conn), diagram.Scope{})
		if err == nil {
			t.Errorf("failOn=%q panicOn=%q: no error", conn.failOn, conn.panicOn)
		}
	}
}

func TestLoadSampledStopsWithItsContext(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	if _, err := diagram.Load(ctx, open(t, &sampledConn{}), diagram.Scope{}); !errors.Is(err, context.Canceled) {
		t.Errorf("err = %v, want context.Canceled", err)
	}
}
