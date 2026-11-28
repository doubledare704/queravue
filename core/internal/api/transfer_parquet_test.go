//go:build duckdb

package api_test

import (
	"context"
	"database/sql/driver"
	"os"
	"path/filepath"
	"strings"
	"testing"
	"time"

	duckdbdriver "github.com/duckdb/duckdb-go/v2"

	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

func parquetExportOf(t *testing.T, env *xferEnv) []byte {
	t.Helper()
	out := env.exportTable(t, &queravuev1.ExportTableRequest{
		Table:   &queravuev1.TableRef{Table: "people"},
		Options: &queravuev1.ExportOptions{Format: queravuev1.TransferFormat_TRANSFER_FORMAT_PARQUET},
	})
	if out.err != nil {
		t.Fatalf("export error: %v", out.err)
	}
	return out.body
}

func parquetFixtureConn() *xferConn {
	stamp := time.Date(2024, 2, 29, 12, 0, 0, 0, time.UTC)
	conn := &xferConn{table: peopleTable(), selectCols: []engine.Column{
		{Name: "id", Kind: engine.VInt}, {Name: "name", Kind: engine.VText}, {Name: "joined", Kind: engine.VTimestamptz},
		{Name: "score", Kind: engine.VFloat}, {Name: "ok", Kind: engine.VBool}, {Name: "price", Kind: engine.VDecimal},
	}}
	for i := 1; i <= 1200; i++ {
		conn.selectRows = append(conn.selectRows, []engine.Value{
			engine.Int(int64(i)), engine.Text("name é " + strings.Repeat("x", i%7)), engine.Timestamptz(stamp.Add(time.Duration(i) * time.Minute)),
			engine.Float(float64(i) / 4), engine.Bool(i%2 == 0), engine.Decimal("12.50"),
		})
	}
	conn.selectRows[4][1] = engine.Null()
	return conn
}

func TestParquetRoundTripThroughExportAndImport(t *testing.T) {
	src := newXferEnv(t, parquetFixtureConn(), false)
	file := parquetExportOf(t, src)
	if len(file) < 8 || string(file[:4]) != "PAR1" {
		t.Fatalf("not a Parquet file: %q", file[:min(8, len(file))])
	}

	dst := &xferConn{table: engine.TableDetails{Columns: []engine.ColumnDef{
		{Name: "id", Kind: engine.VInt}, {Name: "name", Kind: engine.VText}, {Name: "joined", Kind: engine.VTimestamptz},
		{Name: "score", Kind: engine.VFloat}, {Name: "ok", Kind: engine.VBool}, {Name: "price", Kind: engine.VDecimal},
	}}}
	env := newXferEnv(t, dst, false)
	hdr := &queravuev1.ImportHeader{Target: existingTable("t"), Format: queravuev1.TransferFormat_TRANSFER_FORMAT_PARQUET}
	res := env.runImport(t, hdr, string(file), 64<<10)
	if res.err != nil || res.summary.GetRowsCommitted() != 1200 {
		t.Fatalf("err = %v, summary = %v", res.err, res.summary)
	}
	want := src.session.Conn.(*xferConn).selectRows
	got := dst.committedRows()
	for i := range want {
		for j := range want[i] {
			wantValue := want[i][j]
			if wantValue.Kind == engine.VTimestamptz {
				wantValue.Time = wantValue.Time.UTC()
				got[i][j].Time = got[i][j].Time.UTC()
			}
			if !same(got[i][j], wantValue) {
				t.Fatalf("row %d column %d = %+v, want %+v", i, j, got[i][j], wantValue)
			}
		}
	}
	assertNoTemporaryFiles(t, env)
}

func assertNoTemporaryFiles(t *testing.T, env *xferEnv) {
	t.Helper()
	left, _ := filepath.Glob(filepath.Join(env.results.Dir(), "transfer-*"))
	if len(left) != 0 {
		t.Errorf("temporary files left behind: %v", left)
	}
}

func TestParquetExportCancelRemovesTheTemporaryFiles(t *testing.T) {
	env := newXferEnv(t, parquetFixtureConn(), false)
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	rec := &exportRecorder[*queravuev1.ExportTableResponse]{ctx: ctx}
	_ = env.svc.ExportTable(&queravuev1.ExportTableRequest{
		SessionId: env.session.ID, Table: &queravuev1.TableRef{Table: "people"},
		Options: &queravuev1.ExportOptions{Format: queravuev1.TransferFormat_TRANSFER_FORMAT_PARQUET},
	}, rec)
	assertNoTemporaryFiles(t, env)
}

func nestedParquet(t *testing.T) []byte {
	return parquetOf(t, "SELECT 1 AS id, [1,2,3] AS tags, 123.45::DECIMAL(10,2) AS price, DATE '2024-03-01' AS day, 18446744073709551615::UBIGINT AS big")
}

func parquetOf(t *testing.T, query string) []byte {
	t.Helper()
	dir := t.TempDir()
	connector, err := duckdbdriver.NewConnector("", nil)
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = connector.Close() }()
	conn, err := connector.Connect(context.Background())
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = conn.Close() }()
	path := filepath.Join(dir, "nested.parquet")
	if _, err := conn.(driver.ExecerContext).ExecContext(context.Background(),
		"COPY ("+query+") TO '"+path+"' (FORMAT parquet)", nil); err != nil {
		t.Fatal(err)
	}
	data, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	return data
}

func TestParquetImportRejectsNestedColumnsAndMapsFlatTypes(t *testing.T) {
	file := nestedParquet(t)
	dst := &xferConn{table: engine.TableDetails{Columns: []engine.ColumnDef{{Name: "id", Kind: engine.VInt}}}}
	env := newXferEnv(t, dst, false)
	hdr := &queravuev1.ImportHeader{Target: existingTable("t"), Format: queravuev1.TransferFormat_TRANSFER_FORMAT_PARQUET}
	res := env.runImport(t, hdr, string(file), 1<<10)
	if res.err.GetKind() != queravuev1.TransferErrorKind_TRANSFER_ERROR_KIND_UNSUPPORTED || !strings.Contains(res.err.GetMessage(), `"tags"`) {
		t.Errorf("err = %v", res.err)
	}
	if len(dst.committedRows()) != 0 {
		t.Error("rows were loaded")
	}
	assertNoTemporaryFiles(t, env)
}

func TestInferImportReadsAWholeParquetFile(t *testing.T) {
	env := newXferEnv(t, peopleConn(0), false)
	file := parquetExportOf(t, newXferEnv(t, parquetFixtureConn(), false))
	resp := env.infer(t, &queravuev1.InferImportHeader{Filename: "people.parquet"}, string(file))
	if resp.GetError() != nil || resp.GetFormat() != queravuev1.TransferFormat_TRANSFER_FORMAT_PARQUET || len(resp.GetColumns()) != 6 {
		t.Fatalf("response = %v", resp)
	}
	kinds := map[string]queravuev1.ValueKind{}
	for _, c := range resp.GetColumns() {
		kinds[c.GetName()] = c.GetInferredKind()
	}
	if kinds["id"] != queravuev1.ValueKind_VALUE_KIND_INT || kinds["joined"] != queravuev1.ValueKind_VALUE_KIND_TIMESTAMPTZ || kinds["ok"] != queravuev1.ValueKind_VALUE_KIND_BOOL {
		t.Errorf("kinds = %v", kinds)
	}
	if len(resp.GetPreviewRows().GetRows()) != 20 {
		t.Errorf("preview rows = %d", len(resp.GetPreviewRows().GetRows()))
	}

	cut := env.infer(t, &queravuev1.InferImportHeader{Filename: "people.parquet"}, string(file[:len(file)/2]))
	if cut.GetError() != nil || len(cut.GetColumns()) != 0 || len(cut.GetWarnings()) == 0 {
		t.Errorf("a cut-off file: %v", cut)
	}
}

func TestListFormatsIncludesParquetWithDuckDB(t *testing.T) {
	env := newXferEnv(t, peopleConn(0), false)
	resp, _ := env.svc.ListFormats(context.Background(), &queravuev1.ListFormatsRequest{})
	for _, list := range [][]queravuev1.TransferFormat{resp.GetImportFormats(), resp.GetExportFormats()} {
		found := false
		for _, f := range list {
			found = found || f == queravuev1.TransferFormat_TRANSFER_FORMAT_PARQUET
		}
		if !found {
			t.Errorf("formats = %v", list)
		}
	}
}

func TestParquetImportConvertsDecimalsDatesAndWideIntegers(t *testing.T) {
	file := parquetOf(t, "SELECT 1::SMALLINT AS id, 123.45::DECIMAL(10,2) AS price, DATE '2024-03-01' AS day, TIMESTAMP '2024-03-01 10:11:12' AS at, 18446744073709551615::UBIGINT AS big, uuid '123e4567-e89b-12d3-a456-426614174000' AS u, 'x'::VARCHAR AS s")
	dst := &xferConn{}
	env := newXferEnv(t, dst, false)
	hdr := &queravuev1.ImportHeader{
		Target: existingTable("t"), Format: queravuev1.TransferFormat_TRANSFER_FORMAT_PARQUET,
		Mappings: []*queravuev1.ColumnMapping{
			{SourceIndex: 0, TargetColumn: "id"}, {SourceIndex: 1, TargetColumn: "price"}, {SourceIndex: 2, TargetColumn: "day"},
			{SourceIndex: 3, TargetColumn: "at"}, {SourceIndex: 4, TargetColumn: "big"}, {SourceIndex: 5, TargetColumn: "u"}, {SourceIndex: 6, TargetColumn: "s"},
		},
	}
	res := env.runImport(t, hdr, string(file), 1<<10)
	if res.err != nil || res.summary.GetRowsCommitted() != 1 {
		t.Fatalf("err = %v, summary = %v", res.err, res.summary)
	}
	row := dst.committedRows()[0]
	day := time.Date(2024, 3, 1, 0, 0, 0, 0, time.UTC)
	at := time.Date(2024, 3, 1, 10, 11, 12, 0, time.UTC)
	checks := []engine.Value{engine.Int(1), engine.Decimal("123.45"), engine.Timestamptz(day), engine.Timestamptz(at), engine.Decimal("18446744073709551615"), engine.UUID("123e4567-e89b-12d3-a456-426614174000"), engine.Text("x")}
	for i, want := range checks {
		if row[i].Kind == engine.VTimestamptz {
			row[i].Time = row[i].Time.UTC()
		}
		if !same(row[i], want) {
			t.Errorf("column %d = %+v, want %+v", i, row[i], want)
		}
	}
}
