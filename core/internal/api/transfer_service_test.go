package api_test

import (
	"bytes"
	"context"
	"fmt"
	"strings"
	"testing"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

func peopleTable() engine.TableDetails {
	return engine.TableDetails{Schema: "public", Table: "people", Columns: []engine.ColumnDef{
		{Name: "id", TypeName: "int8", Kind: engine.VInt, IsPrimaryKey: true, PrimaryKeyOrder: 1},
		{Name: "name", TypeName: "text", Kind: engine.VText, Nullable: true},
		{Name: "joined", TypeName: "timestamptz", Kind: engine.VTimestamptz, Nullable: true},
		{Name: "score", TypeName: "float8", Kind: engine.VFloat, Nullable: true},
	}}
}

func peopleConn(rows int) *xferConn {
	c := &xferConn{table: peopleTable(), selectCols: []engine.Column{
		{Name: "id", TypeName: "int8", Kind: engine.VInt}, {Name: "name", TypeName: "text", Kind: engine.VText},
	}}
	for i := 1; i <= rows; i++ {
		c.selectRows = append(c.selectRows, []engine.Value{engine.Int(int64(i)), engine.Text(fmt.Sprintf("person %d", i))})
	}
	return c
}

func csvOptions(header bool) *queravuev1.TransferFormatOptions {
	return &queravuev1.TransferFormatOptions{Header: header}
}

func TestListFormatsOmitsParquetWithoutDuckDB(t *testing.T) {
	env := newXferEnv(t, peopleConn(0), false)
	resp, err := env.svc.ListFormats(context.Background(), &queravuev1.ListFormatsRequest{})
	if err != nil {
		t.Fatal(err)
	}
	for _, list := range [][]queravuev1.TransferFormat{resp.GetImportFormats(), resp.GetExportFormats()} {
		if len(list) < 5 {
			t.Errorf("formats = %v, want at least CSV, TSV, JSON, NDJSON and SQL", list)
		}
	}
}

func TestExportTableCSVWithHeaderAndColumnSubset(t *testing.T) {
	env := newXferEnv(t, peopleConn(3), false)
	out := env.exportTable(t, &queravuev1.ExportTableRequest{
		Table:   &queravuev1.TableRef{Schema: "public", Table: "people"},
		Columns: []string{"name"},
		Options: &queravuev1.ExportOptions{Format: queravuev1.TransferFormat_TRANSFER_FORMAT_CSV, FormatOptions: csvOptions(true)},
	})
	if out.err != nil {
		t.Fatalf("error: %v", out.err)
	}
	if want := "name\r\nperson 1\r\nperson 2\r\nperson 3\r\n"; string(out.body) != want {
		t.Errorf("body = %q, want %q", out.body, want)
	}
	if out.header.GetSuggestedFilename() != "people.csv" || out.summary.GetRows() != 3 || out.summary.GetBytes() != uint64(len(out.body)) {
		t.Errorf("header = %v, summary = %v", out.header, out.summary)
	}
}

func TestExportTableUnknownColumnIsAMappingError(t *testing.T) {
	env := newXferEnv(t, peopleConn(1), false)
	out := env.exportTable(t, &queravuev1.ExportTableRequest{
		Table: &queravuev1.TableRef{Table: "people"}, Columns: []string{"nope"},
		Options: &queravuev1.ExportOptions{Format: queravuev1.TransferFormat_TRANSFER_FORMAT_NDJSON},
	})
	if out.err.GetKind() != queravuev1.TransferErrorKind_TRANSFER_ERROR_KIND_MAPPING || out.summary != nil {
		t.Errorf("err = %v, summary = %v", out.err, out.summary)
	}
}

func TestExportTableSQLDumpIncludesCreateTable(t *testing.T) {
	env := newXferEnv(t, peopleConn(2), false)
	out := env.exportTable(t, &queravuev1.ExportTableRequest{
		Table: &queravuev1.TableRef{Schema: "public", Table: "people"},
		Options: &queravuev1.ExportOptions{
			Format:        queravuev1.TransferFormat_TRANSFER_FORMAT_SQL,
			FormatOptions: &queravuev1.TransferFormatOptions{SqlIncludeDdl: true},
		},
	})
	body := string(out.body)
	for _, want := range []string{`CREATE TABLE "public"."people"`, `INSERT INTO "public"."people" ("id", "name")`, `'person 2'`} {
		if !strings.Contains(body, want) {
			t.Errorf("dump lacks %s:\n%s", want, body)
		}
	}
}

func TestExportTableSplitsOutputIntoChunksOfAtMostOneMiB(t *testing.T) {
	env := newXferEnv(t, peopleConn(40_000), false)
	out := env.exportTable(t, &queravuev1.ExportTableRequest{
		Table:   &queravuev1.TableRef{Table: "people"},
		Options: &queravuev1.ExportOptions{Format: queravuev1.TransferFormat_TRANSFER_FORMAT_NDJSON},
	})
	if out.err != nil || out.summary.GetRows() != 40_000 {
		t.Fatalf("err = %v, summary = %v", out.err, out.summary)
	}
	if out.chunks < 2 || out.maxSize > 1<<20 {
		t.Errorf("%d chunks, largest %d bytes", out.chunks, out.maxSize)
	}
	if n := bytes.Count(out.body, []byte("\n")); n != 40_000 {
		t.Errorf("%d lines", n)
	}
}

func TestExportTableCancelStopsTheStream(t *testing.T) {
	env := newXferEnv(t, peopleConn(40_000), false)
	ctx, cancel := context.WithCancel(context.Background())
	rec := &exportRecorder[*queravuev1.ExportTableResponse]{ctx: ctx, onSend: func(n int) {
		if n == 3 {
			cancel()
		}
	}}
	err := env.svc.ExportTable(&queravuev1.ExportTableRequest{
		SessionId: env.session.ID, Table: &queravuev1.TableRef{Table: "people"},
		Options: &queravuev1.ExportOptions{Format: queravuev1.TransferFormat_TRANSFER_FORMAT_NDJSON},
	}, rec)
	if status.Code(err) != codes.Canceled {
		t.Fatalf("err = %v, want Canceled", err)
	}
	if got := collectExport(rec.events); got.summary != nil {
		t.Error("a cancelled export sent a summary")
	}
}

func TestExportRejectsMissingFormatAndUnknownSession(t *testing.T) {
	env := newXferEnv(t, peopleConn(1), false)
	rec := &exportRecorder[*queravuev1.ExportTableResponse]{}
	err := env.svc.ExportTable(&queravuev1.ExportTableRequest{SessionId: env.session.ID, Table: &queravuev1.TableRef{Table: "people"}}, rec)
	if status.Code(err) != codes.InvalidArgument {
		t.Errorf("no format: %v", err)
	}
	err = env.svc.ExportTable(&queravuev1.ExportTableRequest{
		SessionId: "gone", Options: &queravuev1.ExportOptions{Format: queravuev1.TransferFormat_TRANSFER_FORMAT_CSV},
	}, rec)
	if status.Code(err) != codes.NotFound {
		t.Errorf("unknown session: %v", err)
	}
	err = env.svc.ExportResult(&queravuev1.ExportResultRequest{
		ResultId: "gone", Options: &queravuev1.ExportOptions{Format: queravuev1.TransferFormat_TRANSFER_FORMAT_CSV},
	}, &exportRecorder[*queravuev1.ExportResultResponse]{})
	if status.Code(err) != codes.NotFound {
		t.Errorf("unknown result: %v", err)
	}
}

func TestExportResultReadsTheSpool(t *testing.T) {
	env := newXferEnv(t, peopleConn(0), false)
	id, spool, err := env.results.Create(env.session.ID)
	if err != nil {
		t.Fatal(err)
	}
	spool.SetColumns([]*queravuev1.Column{
		{Name: "id", TypeName: "int8", Kind: queravuev1.ValueKind_VALUE_KIND_INT},
		{Name: "name", TypeName: "text", Kind: queravuev1.ValueKind_VALUE_KIND_TEXT},
		{Name: "joined", TypeName: "timestamptz", Kind: queravuev1.ValueKind_VALUE_KIND_TIMESTAMPTZ},
	})
	stamp := time.Date(2024, 2, 29, 12, 0, 0, 0, time.UTC)
	rows := []engine.Value{engine.Int(7), engine.Text("Ada, \"the\" first"), engine.Timestamptz(stamp)}
	if err := spool.Append(rowsOf([][]engine.Value{rows})); err != nil {
		t.Fatal(err)
	}
	if err := spool.Finish(); err != nil {
		t.Fatal(err)
	}
	rec := &exportRecorder[*queravuev1.ExportResultResponse]{}
	err = env.svc.ExportResult(&queravuev1.ExportResultRequest{
		ResultId: id, ColumnIndices: []uint32{1, 0},
		Options: &queravuev1.ExportOptions{Format: queravuev1.TransferFormat_TRANSFER_FORMAT_CSV, FormatOptions: csvOptions(true)},
	}, rec)
	if err != nil {
		t.Fatal(err)
	}
	out := collectExport(rec.events)
	if want := "name,id\r\n\"Ada, \"\"the\"\" first\",7\r\n"; string(out.body) != want {
		t.Errorf("body = %q, want %q", out.body, want)
	}
	rec = &exportRecorder[*queravuev1.ExportResultResponse]{}
	_ = env.svc.ExportResult(&queravuev1.ExportResultRequest{
		ResultId: id, Options: &queravuev1.ExportOptions{Format: queravuev1.TransferFormat_TRANSFER_FORMAT_SQL, FormatOptions: &queravuev1.TransferFormatOptions{SqlIncludeDdl: true, SqlTargetTable: "copy"}},
	}, rec)
	dump := string(collectExport(rec.events).body)
	if !strings.Contains(dump, `CREATE TABLE "copy"`) || !strings.Contains(dump, `INSERT INTO "copy"`) || !strings.Contains(dump, "2024-02-29") {
		t.Errorf("dump = %s", dump)
	}
}

func TestExportCollectionFormats(t *testing.T) {
	docs := []string{
		`{"_id":{"$oid":"650000000000000000000001"},"name":"Ada","n":{"$numberInt":"3"},"profile":{"city":"London"},"tags":["a","b"],"at":{"$date":{"$numberLong":"1709208000000"}}}`,
		`{"_id":{"$oid":"650000000000000000000002"},"name":"Bob"}`,
	}
	env := newXferEnv(t, &fakeDocConn{docs: docs}, false)
	export := func(req *queravuev1.ExportCollectionRequest) exported {
		req.SessionId = env.session.ID
		req.Collection = &queravuev1.CollectionRef{Database: "app", Collection: "people"}
		rec := &exportRecorder[*queravuev1.ExportCollectionResponse]{}
		if err := env.svc.ExportCollection(req, rec); err != nil {
			t.Fatal(err)
		}
		return collectExport(rec.events)
	}

	nd := export(&queravuev1.ExportCollectionRequest{Options: &queravuev1.ExportOptions{Format: queravuev1.TransferFormat_TRANSFER_FORMAT_NDJSON}})
	lines := strings.Split(strings.TrimSpace(string(nd.body)), "\n")
	if len(lines) != 2 || !strings.Contains(lines[0], `"n":3`) || nd.summary.GetRows() != 2 {
		t.Errorf("relaxed ndjson = %q", nd.body)
	}
	canonical := export(&queravuev1.ExportCollectionRequest{Options: &queravuev1.ExportOptions{
		Format: queravuev1.TransferFormat_TRANSFER_FORMAT_NDJSON, FormatOptions: &queravuev1.TransferFormatOptions{JsonFlavor: queravuev1.JsonFlavor_JSON_FLAVOR_CANONICAL},
	}})
	if !strings.Contains(string(canonical.body), `"$numberInt":"3"`) {
		t.Errorf("canonical ndjson = %q", canonical.body)
	}

	csv := export(&queravuev1.ExportCollectionRequest{
		FieldPaths: []string{"name", "profile.city", "tags", "n", "missing"},
		Options:    &queravuev1.ExportOptions{Format: queravuev1.TransferFormat_TRANSFER_FORMAT_CSV, FormatOptions: csvOptions(true)},
	})
	want := "name,profile.city,tags,n,missing\r\nAda,London,\"[\"\"a\"\",\"\"b\"\"]\",3,\r\nBob,,,,\r\n"
	if string(csv.body) != want {
		t.Errorf("csv = %q, want %q", csv.body, want)
	}

	noPaths := export(&queravuev1.ExportCollectionRequest{Options: &queravuev1.ExportOptions{Format: queravuev1.TransferFormat_TRANSFER_FORMAT_CSV}})
	if noPaths.err.GetKind() != queravuev1.TransferErrorKind_TRANSFER_ERROR_KIND_MAPPING {
		t.Errorf("csv without paths: %v", noPaths.err)
	}
	sql := export(&queravuev1.ExportCollectionRequest{Options: &queravuev1.ExportOptions{Format: queravuev1.TransferFormat_TRANSFER_FORMAT_SQL}})
	if sql.err.GetKind() != queravuev1.TransferErrorKind_TRANSFER_ERROR_KIND_UNSUPPORTED {
		t.Errorf("sql: %v", sql.err)
	}
}
