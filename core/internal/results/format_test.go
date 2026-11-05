package results

import (
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

func fmtRows(t *testing.T, f queravuev1.CopyFormat, idx []uint32, header bool, rows [][]engine.Value) string {
	t.Helper()
	cols := ColumnsToProto([]engine.Column{{Name: "id"}, {Name: "note"}, {Name: "ts"}})
	fm := NewFormatter(f, cols, idx, header)
	fm.Begin()
	for _, r := range RowsToProto(rows) {
		fm.Row(r)
	}
	fm.End()
	return fm.Buffer().String()
}

func TestFormatter(t *testing.T) {
	ts := time.Date(2024, 1, 2, 3, 4, 5, 0, time.UTC)
	rows := [][]engine.Value{
		{engine.Int(1), engine.Text("plain"), engine.Timestamptz(ts)},
		{engine.Int(2), engine.Text("a\tb, \"c\"\nd"), engine.Null()},
	}
	if got, want := fmtRows(t, queravuev1.CopyFormat_COPY_FORMAT_TSV, nil, true, rows),
		"id\tnote\tts\n1\tplain\t2024-01-02T03:04:05Z\n2\t\"a\tb, \"\"c\"\"\nd\"\t\n"; got != want {
		t.Errorf("TSV:\n%q\nwant\n%q", got, want)
	}
	if got, want := fmtRows(t, queravuev1.CopyFormat_COPY_FORMAT_CSV, []uint32{1, 0}, false, rows),
		"plain,1\n\"a\tb, \"\"c\"\"\nd\",2\n"; got != want {
		t.Errorf("CSV:\n%q\nwant\n%q", got, want)
	}
	got := fmtRows(t, queravuev1.CopyFormat_COPY_FORMAT_JSON, []uint32{0, 1, 2}, true, rows)
	want := "[\n  {\"id\": 1, \"note\": \"plain\", \"ts\": \"2024-01-02T03:04:05Z\"},\n  {\"id\": 2, \"note\": \"a\\tb, \\\"c\\\"\\nd\", \"ts\": null}\n]\n"
	if got != want {
		t.Errorf("JSON:\n%q\nwant\n%q", got, want)
	}
	if got := fmtRows(t, queravuev1.CopyFormat_COPY_FORMAT_JSON, nil, false, nil); got != "[]\n" {
		t.Errorf("empty JSON = %q", got)
	}
}

func TestFormatJSONValues(t *testing.T) {
	cols := ColumnsToProto([]engine.Column{{Name: "d"}, {Name: "j"}, {Name: "a"}, {Name: "f"}, {Name: "b"}})
	fm := NewFormatter(queravuev1.CopyFormat_COPY_FORMAT_JSON, cols, nil, false)
	fm.Begin()
	for _, r := range RowsToProto([][]engine.Value{{
		engine.Decimal("12345678901234567890.5"), engine.JSON(`{"x":[1]}`),
		engine.Array([]engine.Value{engine.Int(1), engine.Null(), engine.Text("s")}),
		engine.Float(1.5), engine.Bytes([]byte{0xab}),
	}, {engine.Decimal("NaN"), engine.JSON("not json"), engine.Array(nil), engine.Null(), engine.Null()}}) {
		fm.Row(r)
	}
	fm.End()
	want := "[\n  {\"d\": 12345678901234567890.5, \"j\": {\"x\":[1]}, \"a\": [1,null,\"s\"], \"f\": 1.5, \"b\": \"\\\\xab\"},\n" +
		"  {\"d\": \"NaN\", \"j\": \"not json\", \"a\": [], \"f\": null, \"b\": null}\n]\n"
	if got := fm.Buffer().String(); got != want {
		t.Errorf("got\n%s\nwant\n%s", got, want)
	}
}
