package transfer_test

import (
	"context"
	"io"
	"strings"
	"testing"
	"testing/iotest"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqlsplit"
	"github.com/doubledare704/queravue/core/internal/transfer"
)

type recordingExecutor struct {
	statements []string
	failOn     string
}

func (e *recordingExecutor) Execute(_ context.Context, stmt engine.Statement, _ engine.RowSink) (engine.Summary, error) {
	e.statements = append(e.statements, stmt.SQL)
	if e.failOn != "" && strings.Contains(stmt.SQL, e.failOn) {
		return engine.Summary{}, &engine.Error{Kind: engine.KindSQL, Msg: "boom"}
	}
	return engine.Summary{RowsAffected: 2}, nil
}

func runScript(t *testing.T, d sqlsplit.Dialect, script string, ex *recordingExecutor) transfer.ScriptResult {
	t.Helper()
	runner := &transfer.ScriptRunner{
		Executor: ex, Dialect: d, MaxStatementBytes: 1 << 10,
		BytesRead: func() uint64 { return 0 }, Progress: func(uint64, uint64) error { return nil },
	}
	return runner.Run(context.Background(), iotest.OneByteReader(strings.NewReader(script)))
}

func TestScriptRunnerSplitsAcrossReadsAndCountsRows(t *testing.T) {
	ex := &recordingExecutor{}
	res := runScript(t, sqlsplit.Postgres, "\xef\xbb\xbf-- c\nINSERT INTO t VALUES ('a;b');\n$$x;y$$;\nSELECT 1", ex)
	if res.Err != nil || res.Statements != 3 || res.Committed != 6 {
		t.Fatalf("result = %+v", res)
	}
	want := []string{"INSERT INTO t VALUES ('a;b')", "$$x;y$$", "SELECT 1"}
	for i, w := range want {
		if ex.statements[i] != w {
			t.Errorf("statement %d = %q, want %q", i, ex.statements[i], w)
		}
	}
}

func TestScriptRunnerReportsTheLineOfTheFailingStatement(t *testing.T) {
	ex := &recordingExecutor{failOn: "BAD"}
	res := runScript(t, sqlsplit.Postgres, "SELECT 1;\n\n/* two\nlines */ SELECT 2;\nBAD thing\n;\nSELECT 3;", ex)
	if res.Err == nil || res.Line != 5 || res.Statements != 2 || !strings.Contains(res.Err.Message, "line 5") || len(ex.statements) != 3 {
		t.Errorf("result = %+v, statements = %q", res, ex.statements)
	}
}

func TestScriptRunnerKeepsTheMySQLDelimiterAcrossReads(t *testing.T) {
	ex := &recordingExecutor{}
	res := runScript(t, sqlsplit.MySQL, "DELIMITER $$\nCREATE PROCEDURE p() BEGIN SELECT 1; END$$\nDELIMITER ;\nSELECT 2;\n", ex)
	if res.Err != nil || len(ex.statements) != 2 || ex.statements[0] != "CREATE PROCEDURE p() BEGIN SELECT 1; END" {
		t.Errorf("result = %+v, statements = %q", res, ex.statements)
	}
}

func TestScriptRunnerRejectsAStatementOverTheLimit(t *testing.T) {
	ex := &recordingExecutor{}
	res := runScript(t, sqlsplit.Postgres, "SELECT 1;\nINSERT INTO t VALUES ('"+strings.Repeat("x", 4<<10), ex)
	if res.Err == nil || res.Err.Kind != transfer.KindParse || res.Line != 2 {
		t.Errorf("result = %+v", res)
	}
}

func TestScriptRunnerStopsWhenTheSourceFails(t *testing.T) {
	runner := &transfer.ScriptRunner{
		Executor: &recordingExecutor{}, Dialect: sqlsplit.Postgres,
		BytesRead: func() uint64 { return 0 }, Progress: func(uint64, uint64) error { return nil },
	}
	res := runner.Run(context.Background(), io.MultiReader(strings.NewReader("SELECT 1;"), iotest.ErrReader(io.ErrClosedPipe)))
	if res.Err == nil || res.Statements != 1 {
		t.Errorf("result = %+v", res)
	}
}
