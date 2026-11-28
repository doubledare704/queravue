package api_test

import (
	"context"
	"fmt"
	"io"
	"reflect"
	"strings"
	"testing"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

const peopleCSV = "id,name,joined,score\n1,Ada,2024-02-29T12:00:00Z,1.5\n2,Bob,,2\n3,\"Cy, \"\"C\"\"\",2024-03-01,\n"

func csvHeader(table string) *queravuev1.ImportHeader {
	return &queravuev1.ImportHeader{
		Target: existingTable(table), Format: queravuev1.TransferFormat_TRANSFER_FORMAT_CSV,
		FormatOptions: csvOptions(true),
	}
}

func TestImportCSVIntoExistingTableCoercesToColumnTypes(t *testing.T) {
	conn := peopleConn(0)
	env := newXferEnv(t, conn, false)
	res := env.runImport(t, csvHeader("people"), peopleCSV, 7)
	if res.err != nil || res.summary.GetRowsCommitted() != 3 {
		t.Fatalf("err = %v, summary = %v", res.err, res.summary)
	}
	rows := conn.committedRows()
	if len(rows) != 3 || !same(rows[0][0], engine.Int(1)) || !same(rows[0][3], engine.Float(1.5)) || rows[1][2].Kind != engine.VNull || !same(rows[2][1], engine.Text(`Cy, "C"`)) {
		t.Errorf("rows = %+v", rows)
	}
	if rows[0][2].Kind != engine.VTimestamptz || rows[2][2].Time != time.Date(2024, 3, 1, 0, 0, 0, 0, time.UTC) {
		t.Errorf("timestamps = %v, %v", rows[0][2], rows[2][2])
	}
	if got := strings.Join(conn.loadCols, ","); got != "id,name,joined,score" {
		t.Errorf("columns = %s", got)
	}
}

func TestImportMappingPicksAndRenamesColumns(t *testing.T) {
	conn := peopleConn(0)
	env := newXferEnv(t, conn, false)
	hdr := csvHeader("people")
	hdr.Mappings = []*queravuev1.ColumnMapping{{SourceIndex: 1, TargetColumn: "name"}, {SourceIndex: 0, TargetColumn: "id"}}
	res := env.runImport(t, hdr, peopleCSV, 1<<10)
	if res.err != nil || res.summary.GetRowsCommitted() != 3 {
		t.Fatalf("err = %v, summary = %v", res.err, res.summary)
	}
	if got := strings.Join(conn.loadCols, ","); got != "name,id" || !same(conn.committedRows()[0][1], engine.Int(1)) {
		t.Errorf("columns = %s, row = %+v", got, conn.committedRows()[0])
	}

	hdr = csvHeader("people")
	hdr.Mappings = []*queravuev1.ColumnMapping{{SourceIndex: 0, TargetColumn: "missing"}}
	res = env.runImport(t, hdr, peopleCSV, 1<<10)
	if res.err.GetKind() != queravuev1.TransferErrorKind_TRANSFER_ERROR_KIND_MAPPING || len(conn.committedRows()) != 3 {
		t.Errorf("unknown target column: %v", res.err)
	}
}

func TestImportStopPolicyReportsTheLineAndKeepsEarlierBatches(t *testing.T) {
	conn := peopleConn(0)
	env := newXferEnv(t, conn, false)
	data := "id,name\n1,a\n2,\"multi\nline\"\n3,b\nx,c\n5,d\n"
	hdr := csvHeader("people")
	res := env.runImport(t, hdr, data, 5)
	if res.err.GetKind() != queravuev1.TransferErrorKind_TRANSFER_ERROR_KIND_MAPPING || !strings.Contains(res.err.GetMessage(), "line 6") {
		t.Fatalf("err = %v", res.err)
	}
	if res.summary.GetRowsCommitted() != 3 || len(conn.committedRows()) != 3 {
		t.Errorf("summary = %v, committed %d rows", res.summary, len(conn.committedRows()))
	}
	if errs := res.summary.GetRowErrors(); len(errs) != 1 || errs[0].GetLine() != 6 || errs[0].GetColumn() != "id" {
		t.Errorf("row errors = %v", errs)
	}
	if strings.Contains(res.err.GetMessage(), "x") && strings.Contains(res.err.GetMessage(), `"x"`) {
		t.Error("the error quotes the value")
	}
}

func TestImportSkipPolicyReportsBadRowsWithLines(t *testing.T) {
	conn := peopleConn(0)
	env := newXferEnv(t, conn, false)
	hdr := csvHeader("people")
	hdr.ErrorPolicy = queravuev1.ImportErrorPolicy_IMPORT_ERROR_POLICY_SKIP
	data := "id,name\n1,a\nx,b\n3,c\n4\n5,e\n"
	res := env.runImport(t, hdr, data, 4)
	if res.err != nil || res.summary.GetRowsCommitted() != 3 || res.summary.GetRowsSkipped() != 2 {
		t.Fatalf("err = %v, summary = %v", res.err, res.summary)
	}
	var lines []uint64
	for _, e := range res.summary.GetRowErrors() {
		lines = append(lines, e.GetLine())
	}
	if fmt.Sprint(lines) != "[3 5]" {
		t.Errorf("error lines = %v", lines)
	}
}

func TestImportSkipPolicyStopsAfterMaxRowErrors(t *testing.T) {
	env := newXferEnv(t, peopleConn(0), false)
	hdr := csvHeader("people")
	hdr.ErrorPolicy = queravuev1.ImportErrorPolicy_IMPORT_ERROR_POLICY_SKIP
	hdr.MaxRowErrors = 2
	res := env.runImport(t, hdr, "id\n1\nx\ny\nz\n5\n", 64)
	if res.err == nil || res.summary.GetRowsSkipped() != 2 || len(res.summary.GetRowErrors()) != 2 {
		t.Errorf("err = %v, summary = %v", res.err, res.summary)
	}
}

func TestImportSkipPolicyRetriesAConstraintFailureRowByRow(t *testing.T) {
	conn := peopleConn(0)
	env := newXferEnv(t, conn, false)
	hdr := csvHeader("people")
	hdr.ErrorPolicy = queravuev1.ImportErrorPolicy_IMPORT_ERROR_POLICY_SKIP
	res := env.runImport(t, hdr, "id,name\n1,a\n2,b\n2,dup\n4,d\n5,e\n", 1<<10)
	if res.err != nil || res.summary.GetRowsCommitted() != 4 || res.summary.GetRowsSkipped() != 1 {
		t.Fatalf("err = %v, summary = %v", res.err, res.summary)
	}
	if e := res.summary.GetRowErrors(); len(e) != 1 || e[0].GetLine() != 4 {
		t.Errorf("row errors = %v", e)
	}
}

func TestImportStopPolicyReportsAConstraintFailureWithItsBatch(t *testing.T) {
	conn := peopleConn(0)
	env := newXferEnv(t, conn, false)
	res := env.runImport(t, csvHeader("people"), "id,name\n1,a\n1,b\n", 1<<10)
	if res.err.GetKind() != queravuev1.TransferErrorKind_TRANSFER_ERROR_KIND_CONSTRAINT || !strings.Contains(res.err.GetMessage(), "lines 2 and 3") {
		t.Errorf("err = %v", res.err)
	}
	if res.summary.GetRowsCommitted() != 0 {
		t.Errorf("summary = %v", res.summary)
	}
}

func TestImportCancelStopsAfterTheCurrentBatchAndReportsCommittedRows(t *testing.T) {
	conn := peopleConn(0)
	env := newXferEnv(t, conn, false)
	var data strings.Builder
	data.WriteString("id,name\n")
	for i := 1; i <= 3000; i++ {
		fmt.Fprintf(&data, "%d,n%d\n", i, i)
	}
	ctx, cancel := context.WithCancel(context.Background())
	conn.afterBatch = func(batch int) {
		if batch == 2 {
			cancel()
		}
	}
	hdr := csvHeader("people")
	hdr.SessionId = env.session.ID
	s := &importStream{ctx: ctx, in: importMessages(hdr, data.String(), 1<<12)}
	if err := env.svc.Import(s); err != nil {
		t.Fatal(err)
	}
	res := collectImport(s.out)
	if res.err.GetKind() != queravuev1.TransferErrorKind_TRANSFER_ERROR_KIND_CANCELED {
		t.Fatalf("err = %v", res.err)
	}
	if committed := len(conn.committedRows()); committed != 1000 || res.summary.GetRowsCommitted() != 1000 {
		t.Errorf("committed %d rows, summary = %v", committed, res.summary)
	}
}

func TestImportProductionNeedsConfirmation(t *testing.T) {
	conn := peopleConn(0)
	env := newXferEnv(t, conn, true)
	res := env.runImport(t, csvHeader("people"), peopleCSV, 1<<10)
	if res.err.GetKind() != queravuev1.TransferErrorKind_TRANSFER_ERROR_KIND_CONFIRMATION_REQUIRED || len(conn.committedRows()) != 0 || len(conn.statements) != 0 {
		t.Fatalf("err = %v, rows = %d", res.err, len(conn.committedRows()))
	}
	hdr := csvHeader("people")
	hdr.Confirmed = true
	res = env.runImport(t, hdr, peopleCSV, 1<<10)
	if res.err != nil || res.summary.GetRowsCommitted() != 3 {
		t.Errorf("confirmed: err = %v, summary = %v", res.err, res.summary)
	}
}

func TestImportRejectsWhatCannotRun(t *testing.T) {
	env := newXferEnv(t, peopleConn(0), false)
	hdr := csvHeader("people")
	hdr.SingleTransaction = true
	if res := env.runImport(t, hdr, peopleCSV, 64); res.err.GetKind() != queravuev1.TransferErrorKind_TRANSFER_ERROR_KIND_UNSUPPORTED {
		t.Errorf("single transaction: %v", res.err)
	}
	for name, hdr := range map[string]*queravuev1.ImportHeader{
		"collection on a SQL connection": {Target: &queravuev1.ImportHeader_Collection{Collection: &queravuev1.CollectionRef{Collection: "c"}}, Format: queravuev1.TransferFormat_TRANSFER_FORMAT_NDJSON},
		"no target":                      {Format: queravuev1.TransferFormat_TRANSFER_FORMAT_CSV},
	} {
		hdr.SessionId = env.session.ID
		s := &importStream{in: importMessages(hdr, "x", 8)}
		if code := status.Code(env.svc.Import(s)); code != codes.FailedPrecondition && code != codes.InvalidArgument {
			t.Errorf("%s: code = %v", name, code)
		}
	}
	for name, in := range map[string][]*queravuev1.ImportRequest{
		"empty stream": nil,
		"chunk first":  chunked("x", 1),
		"unknown":      {{Message: &queravuev1.ImportRequest_Header{Header: &queravuev1.ImportHeader{SessionId: "gone", Format: queravuev1.TransferFormat_TRANSFER_FORMAT_CSV}}}},
		"no format":    {{Message: &queravuev1.ImportRequest_Header{Header: &queravuev1.ImportHeader{SessionId: env.session.ID}}}},
	} {
		if err := env.svc.Import(&importStream{in: in}); status.Code(err) == codes.OK {
			t.Errorf("%s: no error", name)
		}
	}
}

func TestImportCreatesTheNewTableAndReturnsItsDDL(t *testing.T) {
	conn := peopleConn(0)
	env := newXferEnv(t, conn, false)
	hdr := &queravuev1.ImportHeader{
		Target: &queravuev1.ImportHeader_NewTable{NewTable: &queravuev1.NewTable{
			Table: &queravuev1.TableRef{Schema: "public", Table: "fresh"},
			Columns: []*queravuev1.ColumnDetails{
				{Name: "id", TypeName: "bigint", Kind: queravuev1.ValueKind_VALUE_KIND_INT, IsPrimaryKey: true, PrimaryKeyOrder: 1},
				{Name: "name", TypeName: "text", Kind: queravuev1.ValueKind_VALUE_KIND_TEXT, Nullable: true},
			},
		}},
		Format: queravuev1.TransferFormat_TRANSFER_FORMAT_CSV, FormatOptions: csvOptions(true),
	}
	res := env.runImport(t, hdr, "a,b\n1,x\n2,y\n", 5)
	if res.err != nil || res.summary.GetRowsCommitted() != 2 {
		t.Fatalf("err = %v, summary = %v", res.err, res.summary)
	}
	ddl := res.summary.GetDdl()
	if !strings.Contains(ddl, `CREATE TABLE "public"."fresh"`) || !strings.Contains(ddl, "bigint") || !strings.Contains(ddl, "PRIMARY KEY") {
		t.Errorf("ddl = %s", ddl)
	}
	if len(conn.statements) != 1 || conn.statements[0] != strings.TrimSpace(ddl) {
		t.Errorf("statements = %q", conn.statements)
	}
	if !same(conn.committedRows()[1][0], engine.Int(2)) {
		t.Errorf("rows = %+v", conn.committedRows())
	}
}

func TestImportSQLScriptStopsAtTheFirstFailingStatement(t *testing.T) {
	conn := peopleConn(0)
	env := newXferEnv(t, conn, false)
	script := "-- header\nINSERT INTO t VALUES (1);\nINSERT INTO t VALUES ('a;b');\n\nFAIL here;\nINSERT INTO t VALUES (3);\n"
	hdr := &queravuev1.ImportHeader{Format: queravuev1.TransferFormat_TRANSFER_FORMAT_SQL}
	res := env.runImport(t, hdr, script, 9)
	if res.err.GetKind() != queravuev1.TransferErrorKind_TRANSFER_ERROR_KIND_SERVER || !strings.Contains(res.err.GetMessage(), "line 5") {
		t.Fatalf("err = %v", res.err)
	}
	if got := res.summary.GetRowErrors(); len(got) != 1 || got[0].GetLine() != 5 || res.summary.GetRowsCommitted() != 2 {
		t.Errorf("summary = %v", res.summary)
	}
	if len(conn.statements) != 3 {
		t.Errorf("statements = %q", conn.statements)
	}
}

func TestImportSQLScriptRunsEveryStatement(t *testing.T) {
	conn := peopleConn(0)
	env := newXferEnv(t, conn, false)
	res := env.runImport(t, &queravuev1.ImportHeader{Format: queravuev1.TransferFormat_TRANSFER_FORMAT_SQL}, "INSERT INTO t VALUES (1);INSERT INTO t VALUES (2)", 4)
	if res.err != nil || res.summary.GetRowsCommitted() != 2 || len(conn.statements) != 2 {
		t.Errorf("err = %v, summary = %v, statements = %q", res.err, res.summary, conn.statements)
	}
}

func TestImportDocumentsAndFlatCSVIntoACollection(t *testing.T) {
	conn := &xferDocConn{}
	env := newXferEnv(t, conn, false)
	hdr := &queravuev1.ImportHeader{
		Target: &queravuev1.ImportHeader_Collection{Collection: &queravuev1.CollectionRef{Database: "app", Collection: "people"}},
		Format: queravuev1.TransferFormat_TRANSFER_FORMAT_NDJSON,
	}
	res := env.runImport(t, hdr, "{\"name\":\"Ada\",\"n\":3}\n{\"name\":\"Bob\"}\nnot json\n", 6)
	if res.err.GetKind() != queravuev1.TransferErrorKind_TRANSFER_ERROR_KIND_PARSE || !strings.Contains(res.err.GetMessage(), "line 3") {
		t.Fatalf("err = %v", res.err)
	}
	if len(conn.loaded) != 2 || !strings.Contains(conn.loaded[0], `"n":{"$numberInt":"3"}`) || res.summary.GetRowsCommitted() != 2 {
		t.Errorf("loaded = %q, summary = %v", conn.loaded, res.summary)
	}

	conn.loaded = nil
	hdr.Format = queravuev1.TransferFormat_TRANSFER_FORMAT_CSV
	hdr.FormatOptions = csvOptions(true)
	res = env.runImport(t, hdr, "name,city\nAda,London\nBob,\n", 5)
	if res.err != nil || len(conn.loaded) != 2 || conn.loaded[0] != `{"name":"Ada","city":"London"}` || conn.loaded[1] != `{"name":"Bob","city":null}` {
		t.Errorf("err = %v, loaded = %q", res.err, conn.loaded)
	}
}

type inferStream struct {
	grpc.ServerStream
	in   []*queravuev1.InferImportRequest
	next int
	resp *queravuev1.InferImportResponse
}

func (s *inferStream) Context() context.Context { return context.Background() }
func (s *inferStream) Recv() (*queravuev1.InferImportRequest, error) {
	if s.next >= len(s.in) {
		return nil, io.EOF
	}
	s.next++
	return s.in[s.next-1], nil
}
func (s *inferStream) SendAndClose(r *queravuev1.InferImportResponse) error {
	s.resp = r
	return nil
}

func (e *xferEnv) infer(t *testing.T, hdr *queravuev1.InferImportHeader, data string) *queravuev1.InferImportResponse {
	t.Helper()
	hdr.SessionId = e.session.ID
	s := &inferStream{in: []*queravuev1.InferImportRequest{{Message: &queravuev1.InferImportRequest_Header{Header: hdr}}}}
	for i := 0; i < len(data); i += 11 {
		s.in = append(s.in, &queravuev1.InferImportRequest{Message: &queravuev1.InferImportRequest_Chunk{Chunk: []byte(data[i:min(i+11, len(data))])}})
	}
	if err := e.svc.InferImport(s); err != nil {
		t.Fatal(err)
	}
	return s.resp
}

func TestInferImportDetectsFormatHeaderAndTypes(t *testing.T) {
	env := newXferEnv(t, peopleConn(0), false)
	resp := env.infer(t, &queravuev1.InferImportHeader{Filename: "people.csv"}, peopleCSV+"4,Di,2024-01-02T00:00:00Z,2e3\n")
	if resp.GetError() != nil || resp.GetFormat() != queravuev1.TransferFormat_TRANSFER_FORMAT_CSV || !resp.GetFormatOptions().GetHeader() {
		t.Fatalf("response = %v", resp)
	}
	want := map[string]struct {
		kind     queravuev1.ValueKind
		typeName string
		nullable bool
	}{
		"id":     {queravuev1.ValueKind_VALUE_KIND_INT, "bigint", false},
		"name":   {queravuev1.ValueKind_VALUE_KIND_TEXT, "text", false},
		"joined": {queravuev1.ValueKind_VALUE_KIND_TIMESTAMPTZ, "timestamptz", true},
		"score":  {queravuev1.ValueKind_VALUE_KIND_FLOAT, "double precision", true},
	}
	if len(resp.GetColumns()) != 4 {
		t.Fatalf("columns = %v", resp.GetColumns())
	}
	for _, c := range resp.GetColumns() {
		w := want[c.GetName()]
		if c.GetInferredKind() != w.kind || c.GetSuggestedTypeName() != w.typeName || c.GetNullable() != w.nullable {
			t.Errorf("column %s = %v, want %+v", c.GetName(), c, w)
		}
	}
	if len(resp.GetPreviewRows().GetRows()) != 4 {
		t.Errorf("preview rows = %d", len(resp.GetPreviewRows().GetRows()))
	}
}

func TestInferImportOtherFormats(t *testing.T) {
	env := newXferEnv(t, peopleConn(0), false)
	if r := env.infer(t, &queravuev1.InferImportHeader{}, "1;2\n3;4\n"); r.GetFormat() != queravuev1.TransferFormat_TRANSFER_FORMAT_CSV || r.GetFormatOptions().GetDelimiter() != ";" || r.GetFormatOptions().GetHeader() {
		t.Errorf("semicolon file: %v", r)
	}
	if r := env.infer(t, &queravuev1.InferImportHeader{}, "a\tb\nx\ty\n"); r.GetFormat() != queravuev1.TransferFormat_TRANSFER_FORMAT_TSV || !r.GetFormatOptions().GetHeader() {
		t.Errorf("tsv file: %v", r)
	}
	r := env.infer(t, &queravuev1.InferImportHeader{}, `[{"id":1,"name":"a"},{"id":2,"name":"b"}]`)
	if r.GetFormat() != queravuev1.TransferFormat_TRANSFER_FORMAT_JSON || len(r.GetColumns()) != 2 || r.GetColumns()[0].GetName() != "id" {
		t.Errorf("json file: %v", r)
	}
	if r := env.infer(t, &queravuev1.InferImportHeader{}, "INSERT INTO t VALUES (1);"); r.GetFormat() != queravuev1.TransferFormat_TRANSFER_FORMAT_SQL {
		t.Errorf("sql file: %v", r)
	}
	if r := env.infer(t, &queravuev1.InferImportHeader{}, "  \n"); r.GetError().GetKind() != queravuev1.TransferErrorKind_TRANSFER_ERROR_KIND_PARSE {
		t.Errorf("empty file: %v", r)
	}
}

func TestInferImportForADocumentConnectionPreviewsDocuments(t *testing.T) {
	env := newXferEnv(t, &xferDocConn{}, false)
	r := env.infer(t, &queravuev1.InferImportHeader{}, "{\"a\":1}\n{\"a\":2}\n")
	if r.GetFormat() != queravuev1.TransferFormat_TRANSFER_FORMAT_NDJSON || len(r.GetColumns()) != 0 || len(r.GetPreviewDocumentsEjson()) != 2 || !strings.Contains(r.GetPreviewDocumentsEjson()[0], "$numberInt") {
		t.Errorf("response = %v", r)
	}
}

func same(a, b engine.Value) bool { return reflect.DeepEqual(a, b) }
