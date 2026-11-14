//go:build integration

package oracle

import (
	"context"
	"fmt"
	"os"
	"runtime"
	"strings"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
)

// The measurements recorded in docs/perf/iteration-10.md. They take a while
// and write scratch tables, so they run only with ORACLE_PERF=1.
func perfSetup(t *testing.T) (engine.Conn, engine.Executor) {
	t.Helper()
	if os.Getenv("ORACLE_PERF") != "1" {
		t.Skip("set ORACLE_PERF=1 to run the Oracle measurements")
	}
	tg := target()
	c, err := tg.Engine.Connect(context.Background(), tg.Config, tg.Secret)
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = c.Close() })
	ex, _ := engine.As[engine.Executor](c)
	return c, ex
}

func perfExec(t *testing.T, ex engine.Executor, sql string) {
	t.Helper()
	if _, err := ex.Execute(context.Background(), engine.Statement{SQL: sql}, discard{}); err != nil {
		t.Fatalf("%.80s: %v", sql, err)
	}
}

type heapSink struct {
	rows int64
	peak uint64
}

func (h *heapSink) Columns([]engine.Column) error { return nil }
func (h *heapSink) Batch(rows [][]engine.Value) error {
	h.rows += int64(len(rows))
	if h.rows%(10*engine.MaxBatchRows) == 0 || len(rows) < engine.MaxBatchRows || h.rows <= engine.MaxBatchRows {
		runtime.GC()
		var m runtime.MemStats
		runtime.ReadMemStats(&m)
		h.peak = max(h.peak, m.HeapAlloc)
	}
	return nil
}

func TestPerfStreamWide(t *testing.T) {
	_, ex := perfSetup(t)
	for _, n := range []int{10_000, 100_000, 1_000_000} {
		runtime.GC()
		var base runtime.MemStats
		runtime.ReadMemStats(&base)
		sink := &heapSink{}
		sum, err := ex.Execute(context.Background(), engine.Statement{SQL: fmt.Sprintf(`SELECT "id", "val", "label" FROM "million_items" WHERE "id" <= %d`, n)}, sink)
		if err != nil {
			t.Fatal(err)
		}
		t.Logf("PERF stream %d rows x 3 columns: %v (%.0f rows/s), heap %d MB -> peak %d MB",
			n, sum.Duration.Round(time.Millisecond), float64(sum.RowsRead)/sum.Duration.Seconds(), base.HeapAlloc>>20, sink.peak>>20)
	}
}

func eachLOBMode(t *testing.T, run func(t *testing.T)) {
	t.Helper()
	for _, mode := range []string{"PRE", "POST"} {
		t.Run(mode, func(t *testing.T) {
			saved := lobFetchMode
			lobFetchMode = mode
			t.Cleanup(func() { lobFetchMode = saved })
			run(t)
		})
	}
}

func TestPerfLOBStream(t *testing.T) {
	eachLOBMode(t, perfLOBStream)
}

func TestPerfSmallLOBs(t *testing.T) {
	eachLOBMode(t, perfSmallLOBs)
}

func perfLOBStream(t *testing.T) {
	_, ex := perfSetup(t)
	perfExec(t, ex, `DROP TABLE IF EXISTS "qv_perf_lob"`)
	perfExec(t, ex, `CREATE TABLE "qv_perf_lob" ("id" NUMBER(10) PRIMARY KEY, "body" CLOB)`)
	t.Cleanup(func() { perfExec(t, ex, `DROP TABLE IF EXISTS "qv_perf_lob"`) })
	perfExec(t, ex, `DECLARE
  body CLOB;
BEGIN
  DBMS_LOB.CREATETEMPORARY(body, TRUE);
  FOR i IN 1 .. 1000 LOOP
    DBMS_LOB.WRITEAPPEND(body, 4000, RPAD('x', 4000, 'x'));
  END LOOP;
  FOR r IN 1 .. 50 LOOP
    INSERT INTO "qv_perf_lob" VALUES (r, body);
  END LOOP;
  COMMIT;
END;`)
	runtime.GC()
	var base runtime.MemStats
	runtime.ReadMemStats(&base)
	sink := &heapSink{}
	sum, err := ex.Execute(context.Background(), engine.Statement{SQL: `SELECT "id", "body" FROM "qv_perf_lob"`}, sink)
	if err != nil {
		t.Fatal(err)
	}
	t.Logf("PERF [%s] stream 50 rows x 4 MB CLOB (200 MB): %v, live heap %d MB -> peak %d MB", lobFetchMode, sum.Duration.Round(time.Millisecond), base.HeapAlloc>>20, sink.peak>>20)
}

func perfSmallLOBs(t *testing.T) {
	_, ex := perfSetup(t)
	perfExec(t, ex, `DROP TABLE IF EXISTS "qv_perf_small_lob"`)
	perfExec(t, ex, `CREATE TABLE "qv_perf_small_lob" ("id" NUMBER(10) PRIMARY KEY, "body" CLOB, "bin" BLOB)`)
	t.Cleanup(func() { perfExec(t, ex, `DROP TABLE IF EXISTS "qv_perf_small_lob"`) })
	perfExec(t, ex, `INSERT INTO "qv_perf_small_lob" SELECT LEVEL, TO_CLOB(RPAD('x', 200, 'x')), TO_BLOB(HEXTORAW('00FF')) FROM dual CONNECT BY LEVEL <= 10000`)
	sink := &heapSink{}
	sum, err := ex.Execute(context.Background(), engine.Statement{SQL: `SELECT "id", "body", "bin" FROM "qv_perf_small_lob"`}, sink)
	if err != nil {
		t.Fatal(err)
	}
	t.Logf("PERF [%s] stream 10000 rows with a small CLOB and BLOB each: %v (%.0f rows/s), peak live heap %d MB", lobFetchMode, sum.Duration.Round(time.Millisecond), float64(sum.RowsRead)/sum.Duration.Seconds(), sink.peak>>20)
}

func TestPerfCatalogCost(t *testing.T) {
	c, ex := perfSetup(t)
	const tables = 500
	drop := func() {
		perfExec(t, ex, `BEGIN FOR t IN (SELECT table_name FROM user_tables WHERE table_name LIKE 'qv_perf_%') LOOP EXECUTE IMMEDIATE 'DROP TABLE "' || t.table_name || '" CASCADE CONSTRAINTS PURGE'; END LOOP; END;`)
	}
	drop()
	t.Cleanup(drop)
	perfExec(t, ex, `CREATE TABLE "qv_perf_root" ("id" NUMBER(10) PRIMARY KEY)`)
	perfExec(t, ex, fmt.Sprintf(`BEGIN
  FOR i IN 1 .. %d LOOP
    EXECUTE IMMEDIATE 'CREATE TABLE "qv_perf_t' || i || '" ("id" NUMBER(10) PRIMARY KEY, "root_id" NUMBER(10) REFERENCES "qv_perf_root" ("id"), "c1" VARCHAR2(40), "c2" VARCHAR2(40), "c3" NUMBER(10,2), "c4" DATE, "c5" TIMESTAMP, "c6" VARCHAR2(100), "c7" NUMBER, "c8" CLOB, "c9" RAW(16), "c10" VARCHAR2(10), "c11" NUMBER(5), "c12" VARCHAR2(30), "c13" DATE)';
  END LOOP;
END;`, tables))
	perfExec(t, ex, `BEGIN DBMS_STATS.GATHER_SCHEMA_STATS(USER); END;`)

	ctx := context.Background()
	owner := "QUERAVUE"
	time1 := func(label string, fn func() (int, error)) {
		var took [2]time.Duration
		var n int
		for i := range took {
			started := time.Now()
			var err error
			if n, err = fn(); err != nil {
				t.Fatalf("%s: %v", label, err)
			}
			took[i] = time.Since(started).Round(time.Millisecond)
		}
		t.Logf("PERF catalog %s: first %v, second %v (%d rows)", label, took[0], took[1], n)
	}
	conn := c.(*Conn)
	time1("ListObjects (500 tables)", func() (int, error) { o, err := conn.ListObjects(ctx, "", owner); return len(o), err })
	time1("ListColumns (completion)", func() (int, error) { o, err := conn.ListColumns(ctx, "", owner); return len(o), err })
	time1("ListKeyedColumns (graph)", func() (int, error) { o, err := conn.ListKeyedColumns(ctx, "", owner); return len(o), err })
	time1("ListRelations (graph)", func() (int, error) { o, err := conn.ListRelations(ctx, "", owner); return len(o), err })
	time1("DescribeTable (one table)", func() (int, error) {
		d, err := conn.DescribeTable(ctx, "", owner, "qv_perf_t250")
		return len(d.Columns), err
	})
	time1("ListIndexes (one table)", func() (int, error) { o, err := conn.ListIndexes(ctx, "", owner, "qv_perf_t250"); return len(o), err })
	for _, check := range []struct{ label, sql string }{
		{"all_tab_columns, all owners", `SELECT COUNT(*) FROM all_tab_columns`},
		{"all_tab_columns, owner filter", `SELECT COUNT(*) FROM all_tab_columns WHERE owner = 'QUERAVUE'`},
		{"all_constraints, all owners", `SELECT COUNT(*) FROM all_constraints`},
		{"all_cons_columns, all owners", `SELECT COUNT(*) FROM all_cons_columns`},
	} {
		started := time.Now()
		out := &collected{}
		if _, err := ex.Execute(ctx, engine.Statement{SQL: check.sql}, out); err != nil {
			t.Fatal(err)
		}
		t.Logf("PERF view %s: %v (%s rows)", check.label, time.Since(started).Round(time.Millisecond), strings.TrimSpace(out.rows[0][0].Str))
	}
}
