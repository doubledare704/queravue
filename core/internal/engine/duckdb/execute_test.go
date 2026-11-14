//go:build duckdb

package duckdb

import (
	"context"
	"math/big"
	"strings"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func TestTypeMatrix(t *testing.T) {
	c := connectTo(t, map[string]string{ParamPath: MemoryPath})
	moment := time.Date(2026, 3, 4, 5, 6, 7, 123456000, time.UTC)
	tests := []struct {
		name, expr string
		kind       engine.ValueKind
		check      func(engine.Value) bool
	}{
		{"hugeint", "170141183460469231731687303715884105727::HUGEINT", engine.VDecimal, func(v engine.Value) bool { return v.Str == "170141183460469231731687303715884105727" }},
		{"uhugeint", "340282366920938463463374607431768211455::UHUGEINT", engine.VDecimal, func(v engine.Value) bool { return v.Str == "340282366920938463463374607431768211455" }},
		{"ubigint max", "18446744073709551615::UBIGINT", engine.VDecimal, func(v engine.Value) bool { return v.Str == "18446744073709551615" }},
		{"ubigint small", "5::UBIGINT", engine.VDecimal, func(v engine.Value) bool { return v.Kind == engine.VInt && v.Int == 5 }},
		{"decimal", "12.345::DECIMAL(10,3)", engine.VDecimal, func(v engine.Value) bool { return v.Str == "12.345" }},
		{"negative decimal", "-0.50::DECIMAL(5,2)", engine.VDecimal, func(v engine.Value) bool { return v.Str == "-0.5" }},
		{"interval", "INTERVAL '1 year 2 months 3 days 4 hours 5 minutes 6.5 seconds'", engine.VText, func(v engine.Value) bool { return v.Str == "1 year 2 months 3 days 04:05:06.5" }},
		{"interval days", "INTERVAL 3 DAY", engine.VText, func(v engine.Value) bool { return v.Str == "3 days" }},
		{"interval zero", "INTERVAL 0 DAY", engine.VText, func(v engine.Value) bool { return v.Str == "00:00:00" }},
		{"interval negative time", "INTERVAL '-90 minutes'", engine.VText, func(v engine.Value) bool { return v.Str == "-01:30:00" }},
		{"list", "[1, 2, 3]", engine.VArray, func(v engine.Value) bool { return len(v.Array) == 3 && v.Array[2].Int == 3 }},
		{"nested list", "[[1], [2, 3]]", engine.VArray, func(v engine.Value) bool { return len(v.Array) == 2 && len(v.Array[1].Array) == 2 }},
		{"list of struct", "[{'a': 1}]", engine.VArray, func(v engine.Value) bool { return v.Array[0].Kind == engine.VJSON && v.Array[0].Str == `{"a":1}` }},
		{"struct", "{'b': 'x', 'a': 1}", engine.VJSON, func(v engine.Value) bool { return v.Str == `{"a":1,"b":"x"}` }},
		{"map", "MAP {'k': 1, 'j': 2}", engine.VJSON, func(v engine.Value) bool { return v.Str == `{"k":1,"j":2}` }},
		{"union", "union_value(num := 2)::UNION(num INTEGER, str VARCHAR)", engine.VText, func(v engine.Value) bool { return v.Kind == engine.VInt && v.Int == 2 }},
		{"union text", "union_value(str := 'hi')::UNION(num INTEGER, str VARCHAR)", engine.VText, func(v engine.Value) bool { return v.Str == "hi" }},
		{"enum", "'b'::ENUM('a', 'b')", engine.VText, func(v engine.Value) bool { return v.Str == "b" }},
		{"blob", `'\xAA\x00\xFF'::BLOB`, engine.VBytes, func(v engine.Value) bool { return string(v.Bytes) == "\xAA\x00\xFF" }},
		{"uuid", "'8b5d3a4e-12c7-4f0a-9d6b-0123456789ab'::UUID", engine.VUUID, func(v engine.Value) bool { return v.Str == "8b5d3a4e-12c7-4f0a-9d6b-0123456789ab" }},
		{"timestamptz", "TIMESTAMPTZ '2026-03-04 05:06:07.123456+00'", engine.VTimestamptz, func(v engine.Value) bool { return v.Time.Equal(moment) }},
		{"timestamptz offset", "TIMESTAMPTZ '2026-03-04 07:06:07.123456+02'", engine.VTimestamptz, func(v engine.Value) bool { return v.Time.Equal(moment) }},
		{"timestamp", "TIMESTAMP '2026-03-04 05:06:07.123456'", engine.VText, func(v engine.Value) bool { return v.Str == "2026-03-04 05:06:07.123456" }},
		{"date", "DATE '2026-03-04'", engine.VText, func(v engine.Value) bool { return v.Str == "2026-03-04" }},
		{"time", "TIME '05:06:07'", engine.VText, func(v engine.Value) bool { return v.Str == "05:06:07" }},
		{"json", `'{"a": [1, 2]}'::JSON`, engine.VJSON, func(v engine.Value) bool { return v.Str == `{"a":[1,2]}` }},
		{"bool", "true", engine.VBool, func(v engine.Value) bool { return v.Bool }},
		{"tinyint", "-5::TINYINT", engine.VInt, func(v engine.Value) bool { return v.Int == -5 }},
		{"float", "1.5::FLOAT", engine.VFloat, func(v engine.Value) bool { return v.Float == 1.5 }},
		{"double", "2.25::DOUBLE", engine.VFloat, func(v engine.Value) bool { return v.Float == 2.25 }},
		{"null", "NULL", engine.VText, func(v engine.Value) bool { return v.Kind == engine.VNull }},
		{"varchar", "'héllo'", engine.VText, func(v engine.Value) bool { return v.Str == "héllo" }},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, _ := query(t, c, "SELECT "+tt.expr)
			if len(got.rows) != 1 || len(got.cols) != 1 {
				t.Fatalf("shape = %d rows x %d columns", len(got.rows), len(got.cols))
			}
			if tt.name != "null" && tt.name != "ubigint small" && got.cols[0].Kind != tt.kind {
				t.Errorf("column kind = %v (%s), want %v", got.cols[0].Kind, got.cols[0].TypeName, tt.kind)
			}
			if v := got.rows[0][0]; !tt.check(v) {
				t.Errorf("value = %+v", v)
			}
		})
	}
}

func TestHugeintRoundTripsExactly(t *testing.T) {
	c := connectTo(t, map[string]string{ParamPath: MemoryPath})
	query(t, c, "CREATE TABLE big (id INTEGER PRIMARY KEY, h HUGEINT, d DECIMAL(38,10))")
	want, _ := new(big.Int).SetString("-85070591730234615865843651857942052864", 10)
	query(t, c, "INSERT INTO big VALUES (1, ?, ?)", engine.Decimal(want.String()), engine.Decimal("1234567890123456789.0123456789"))
	got, _ := query(t, c, "SELECT h, d FROM big")
	if got.rows[0][0].Str != want.String() || got.rows[0][1].Str != "1234567890123456789.0123456789" {
		t.Errorf("row = %+v", got.rows[0])
	}
}

func TestParametersBindEveryKind(t *testing.T) {
	c := connectTo(t, map[string]string{ParamPath: MemoryPath})
	query(t, c, "CREATE TABLE p (b BOOLEAN, i BIGINT, f DOUBLE, d DECIMAL(10,2), s VARCHAR, bl BLOB, ts TIMESTAMPTZ, u UUID, j JSON)")
	moment := time.Date(2026, 1, 2, 3, 4, 5, 0, time.UTC)
	_, sum := query(t, c, "INSERT INTO p VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)",
		engine.Bool(true), engine.Int(42), engine.Float(1.5), engine.Decimal("12.50"), engine.Text("it's"), engine.Bytes([]byte{0, 1}),
		engine.Timestamptz(moment), engine.UUID("8b5d3a4e-12c7-4f0a-9d6b-0123456789ab"), engine.JSON(`{"k":1}`))
	if sum.RowsAffected != 1 || sum.HasRows {
		t.Errorf("summary = %+v", sum)
	}
	query(t, c, "INSERT INTO p (i) VALUES (?)", engine.Null())
	got, _ := query(t, c, "SELECT * FROM p WHERE i = ?", engine.Int(42))
	row := got.rows[0]
	if !row[0].Bool || row[1].Int != 42 || row[2].Float != 1.5 || row[3].Str != "12.5" || row[4].Str != "it's" ||
		string(row[5].Bytes) != "\x00\x01" || !row[6].Time.Equal(moment) || row[7].Str != "8b5d3a4e-12c7-4f0a-9d6b-0123456789ab" || row[8].Str != `{"k":1}` {
		t.Errorf("row = %+v", row)
	}
}

func TestStatementsWithoutRowsReportCounts(t *testing.T) {
	c := connectTo(t, map[string]string{ParamPath: MemoryPath})
	for _, sqlText := range []string{"CREATE TABLE t (a INTEGER)", "CREATE SEQUENCE s", "SET threads = 1"} {
		if _, sum := query(t, c, sqlText); sum.HasRows {
			t.Errorf("%s reported rows", sqlText)
		}
	}
	_, sum := query(t, c, "INSERT INTO t SELECT * FROM range(10)")
	if sum.RowsAffected != 10 || sum.HasRows {
		t.Errorf("insert summary = %+v", sum)
	}
	if _, sum = query(t, c, "UPDATE t SET a = a + 1 WHERE a < 4"); sum.RowsAffected != 4 {
		t.Errorf("update summary = %+v", sum)
	}
	if _, sum = query(t, c, "DELETE FROM t WHERE a > 100"); sum.RowsAffected != 0 || sum.HasRows {
		t.Errorf("delete summary = %+v", sum)
	}
	got, sum := query(t, c, "INSERT INTO t VALUES (99) RETURNING a")
	if !sum.HasRows || got.rows[0][0].Int != 99 {
		t.Errorf("RETURNING = %+v, %+v", got.rows, sum)
	}
	if got, sum = query(t, c, "SELECT * FROM t WHERE false"); !sum.HasRows || len(got.cols) != 1 || len(got.rows) != 0 {
		t.Errorf("empty result = %+v, %+v", got, sum)
	}
}

func TestSessionStateSpansStatements(t *testing.T) {
	c := connectTo(t, map[string]string{ParamPath: MemoryPath})
	query(t, c, "CREATE TEMP TABLE scratch AS SELECT 1 AS a")
	query(t, c, "SET search_path = 'main'")
	if got, _ := query(t, c, "SELECT a FROM scratch"); got.rows[0][0].Int != 1 {
		t.Errorf("temp table lost: %+v", got.rows)
	}
}

func TestSyntaxAndCatalogErrorsAreSQLErrors(t *testing.T) {
	c := connectTo(t, map[string]string{ParamPath: MemoryPath})
	ex, _ := engine.As[engine.Executor](c)
	for _, sqlText := range []string{"selec 1", "SELECT * FROM nope", "SELECT 'a'::INTEGER"} {
		_, err := ex.Execute(context.Background(), engine.Statement{SQL: sqlText}, &collector{})
		if engine.KindOf(err) != engine.KindSQL {
			t.Errorf("%q: %v (kind %v), want sql", sqlText, err, engine.KindOf(err))
		}
	}
	if got, _ := query(t, c, "SELECT 1"); len(got.rows) != 1 {
		t.Error("the session does not answer after errors")
	}
}

func TestCancelInterruptsARunningStatement(t *testing.T) {
	c := connectTo(t, map[string]string{ParamPath: MemoryPath})
	ex, _ := engine.As[engine.Executor](c)
	for name, sqlText := range map[string]string{
		"aggregate over a cross join": "SELECT count(*) FROM range(100000000000) a, range(1000) b",
		"insert from a cross join":    "CREATE TABLE sink AS SELECT a.range, b.range FROM range(100000000000) a, range(1000) b",
	} {
		t.Run(name, func(t *testing.T) {
			ctx, cancel := context.WithTimeout(context.Background(), 600*time.Millisecond)
			defer cancel()
			started := time.Now()
			_, err := ex.Execute(ctx, engine.Statement{SQL: sqlText}, &collector{})
			took := time.Since(started)
			if engine.KindOf(err) != engine.KindCanceled {
				t.Fatalf("err = %v (kind %v), want canceled", err, engine.KindOf(err))
			}
			if took > 5*time.Second {
				t.Errorf("stopped after %v", took)
			}
			t.Logf("stopped after %v", took.Round(time.Millisecond))
			if got, _ := query(t, c, "SELECT 1"); len(got.rows) != 1 {
				t.Error("the session does not answer after a cancel")
			}
		})
	}
}

func TestQueryFilesDirectly(t *testing.T) {
	c := connectTo(t, map[string]string{ParamPath: MemoryPath})
	dir := t.TempDir()
	parquet, csv := dir+"/n.parquet", dir+"/n.csv"
	query(t, c, "COPY (SELECT i AS id, 'v' || i AS label FROM range(1, 101) t(i)) TO '"+parquet+"' (FORMAT parquet)")
	query(t, c, "COPY (SELECT i AS id, 'v' || i AS label FROM range(1, 51) t(i)) TO '"+csv+"' (HEADER, DELIMITER ',')")
	got, _ := query(t, c, "SELECT count(*), max(id) FROM read_parquet('"+parquet+"')")
	if got.rows[0][0].Int != 100 || got.rows[0][1].Int != 100 {
		t.Errorf("parquet = %+v", got.rows)
	}
	got, _ = query(t, c, "SELECT label FROM read_csv('"+csv+"') WHERE id = 7")
	if got.rows[0][0].Str != "v7" {
		t.Errorf("csv = %+v", got.rows)
	}
	got, _ = query(t, c, "SELECT * FROM '"+parquet+"' LIMIT 3")
	if len(got.rows) != 3 || len(got.cols) != 2 {
		t.Errorf("replacement scan = %+v", got)
	}
	_, err := func() (any, error) {
		ex, _ := engine.As[engine.Executor](c)
		return ex.Execute(context.Background(), engine.Statement{SQL: "SELECT * FROM read_parquet('" + dir + "/missing.parquet')"}, &collector{})
	}()
	if err == nil || !strings.Contains(err.Error(), "missing.parquet") {
		t.Errorf("missing file err = %v", err)
	}
}

func TestStopEarlyKeepsSessionUsable(t *testing.T) {
	c := connectTo(t, map[string]string{ParamPath: MemoryPath})
	ex, _ := engine.As[engine.Executor](c)
	stops := &stopAfterFirstBatch{}
	if _, err := ex.Execute(context.Background(), engine.Statement{SQL: "SELECT * FROM range(100000)"}, stops); err != nil {
		t.Fatal(err)
	}
	if stops.batches != 1 {
		t.Errorf("batches = %d", stops.batches)
	}
}

type stopAfterFirstBatch struct{ batches int }

func (s *stopAfterFirstBatch) Columns([]engine.Column) error { return nil }
func (s *stopAfterFirstBatch) Batch([][]engine.Value) error {
	s.batches++
	return engine.ErrStop
}
