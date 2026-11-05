package sqlite

import (
	"context"
	"errors"
	"path/filepath"
	"reflect"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
)

type collectSink struct {
	cols    []engine.Column
	rows    [][]engine.Value
	batches int
	stopAt  int // return ErrStop once this many rows were received (0 = never)
}

func (s *collectSink) Columns(c []engine.Column) error { s.cols = c; return nil }
func (s *collectSink) Batch(rows [][]engine.Value) error {
	s.batches++
	if len(rows) > engine.MaxBatchRows {
		return errors.New("batch too large")
	}
	for _, r := range rows {
		s.rows = append(s.rows, append([]engine.Value(nil), r...))
	}
	if s.stopAt > 0 && len(s.rows) >= s.stopAt {
		return engine.ErrStop
	}
	return nil
}

func newExec(t *testing.T) engine.Executor {
	t.Helper()
	path := filepath.Join(t.TempDir(), "t.db")
	c, err := connect(t, map[string]string{ParamPath: path, ParamCreateIfMissing: "true"})
	if err != nil {
		t.Fatal(err)
	}
	ex, ok := engine.As[engine.Executor](c)
	if !ok {
		t.Fatal("no Executor")
	}
	return ex
}

func TestExecuteTypedRoundTrip(t *testing.T) {
	ex := newExec(t)
	ctx := context.Background()
	s := &collectSink{}
	if _, err := ex.Execute(ctx, engine.Statement{SQL: "CREATE TABLE t (i INTEGER, f REAL, s TEXT, b BLOB, j JSON, n TEXT)"}, s); err != nil {
		t.Fatal(err)
	}
	sum, err := ex.Execute(ctx, engine.Statement{SQL: "INSERT INTO t VALUES (1, 2.5, 'héllo', x'dead', '{\"a\":1}', NULL), (2, 0, '', x'', '[]', NULL)"}, s)
	if err != nil {
		t.Fatal(err)
	}
	if sum.RowsAffected != 2 || sum.HasRows {
		t.Errorf("insert summary = %+v", sum)
	}
	s = &collectSink{}
	sum, err = ex.Execute(ctx, engine.Statement{SQL: "SELECT * FROM t ORDER BY i"}, s)
	if err != nil {
		t.Fatal(err)
	}
	if !sum.HasRows || len(s.cols) != 6 || len(s.rows) != 2 {
		t.Fatalf("select: %+v cols=%d rows=%d", sum, len(s.cols), len(s.rows))
	}
	r := s.rows[0]
	if !reflect.DeepEqual(r[0], engine.Int(1)) || !reflect.DeepEqual(r[1], engine.Float(2.5)) || !reflect.DeepEqual(r[2], engine.Text("héllo")) ||
		!reflect.DeepEqual(r[4], engine.JSON(`{"a":1}`)) || r[5].Kind != engine.VNull || string(r[3].Bytes) != "\xde\xad" {
		t.Errorf("row 0 = %+v", r)
	}
	if s.cols[0].Kind != engine.VInt || s.cols[3].Kind != engine.VBytes || s.cols[4].Kind != engine.VJSON {
		t.Errorf("column kinds = %+v", s.cols)
	}
}

func TestExecuteBatchingAndStop(t *testing.T) {
	ex := newExec(t)
	const q = "WITH RECURSIVE c(x) AS (SELECT 1 UNION ALL SELECT x+1 FROM c WHERE x < 1234) SELECT x FROM c"
	s := &collectSink{}
	sum, err := ex.Execute(context.Background(), engine.Statement{SQL: q}, s)
	if err != nil {
		t.Fatal(err)
	}
	if len(s.rows) != 1234 || s.batches != 3 || sum.RowsRead != 1234 {
		t.Errorf("rows=%d batches=%d read=%d", len(s.rows), s.batches, sum.RowsRead)
	}

	s = &collectSink{stopAt: 500}
	sum, err = ex.Execute(context.Background(), engine.Statement{SQL: q}, s)
	if err != nil {
		t.Fatalf("ErrStop must not fail: %v", err)
	}
	if len(s.rows) != 500 || sum.RowsRead != 500 {
		t.Errorf("stopped rows=%d", len(s.rows))
	}
	// The conn is still usable afterwards.
	s = &collectSink{}
	if _, err := ex.Execute(context.Background(), engine.Statement{SQL: "SELECT 1"}, s); err != nil || len(s.rows) != 1 {
		t.Errorf("after stop: %v rows=%d", err, len(s.rows))
	}
}

func TestExecuteError(t *testing.T) {
	ex := newExec(t)
	_, err := ex.Execute(context.Background(), engine.Statement{SQL: "SELEKT 1"}, &collectSink{})
	if engine.KindOf(err) != engine.KindSQL {
		t.Errorf("kind = %v (%v)", engine.KindOf(err), err)
	}
}

func TestExecuteCancel(t *testing.T) {
	ex := newExec(t)
	ctx, cancel := context.WithCancel(context.Background())
	go func() { time.Sleep(100 * time.Millisecond); cancel() }()
	// Effectively endless.
	const q = "WITH RECURSIVE c(x) AS (SELECT 1 UNION ALL SELECT x+1 FROM c) SELECT count(*) FROM c"
	done := make(chan error, 1)
	go func() { _, err := ex.Execute(ctx, engine.Statement{SQL: q}, &collectSink{}); done <- err }()
	select {
	case err := <-done:
		if engine.KindOf(err) != engine.KindCanceled {
			t.Errorf("kind = %v (%v)", engine.KindOf(err), err)
		}
	case <-time.After(5 * time.Second):
		t.Fatal("cancel did not stop the statement")
	}
	s := &collectSink{}
	if _, err := ex.Execute(context.Background(), engine.Statement{SQL: "SELECT 1"}, s); err != nil || len(s.rows) != 1 {
		t.Errorf("conn unusable after cancel: %v", err)
	}
}

func TestExecuteParams(t *testing.T) {
	ex := newExec(t)
	s := &collectSink{}
	_, err := ex.Execute(context.Background(), engine.Statement{SQL: "SELECT ?, ?", Params: []engine.Value{engine.Int(7), engine.Text("x")}}, s)
	if err != nil || !reflect.DeepEqual(s.rows[0][0], engine.Int(7)) || !reflect.DeepEqual(s.rows[0][1], engine.Text("x")) {
		t.Errorf("params: %v %+v", err, s.rows)
	}
}
