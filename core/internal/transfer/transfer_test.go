package transfer_test

import (
	"bytes"
	"context"
	"errors"
	"io"
	"reflect"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/dataformat"
	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/transfer"
)

func TestCoerce(t *testing.T) {
	stamp := time.Date(2024, 2, 29, 12, 0, 0, 0, time.UTC)
	cases := []struct {
		name string
		in   engine.Value
		kind engine.ValueKind
		want engine.Value
		fail bool
	}{
		{"null stays null", engine.Null(), engine.VInt, engine.Null(), false},
		{"text to int", engine.Text(" 42 "), engine.VInt, engine.Int(42), false},
		{"integral float text to int", engine.Text("3.0"), engine.VInt, engine.Int(3), false},
		{"fraction to int fails", engine.Text("3.5"), engine.VInt, engine.Value{}, true},
		{"text to bool", engine.Text("Yes"), engine.VBool, engine.Bool(true), false},
		{"int to bool", engine.Int(0), engine.VBool, engine.Bool(false), false},
		{"bad bool", engine.Text("maybe"), engine.VBool, engine.Value{}, true},
		{"text to float", engine.Text("1e3"), engine.VFloat, engine.Float(1000), false},
		{"text to decimal keeps digits", engine.Text("12345678901234567890.123456789"), engine.VDecimal, engine.Decimal("12345678901234567890.123456789"), false},
		{"hex is not a decimal", engine.Text("0x10"), engine.VDecimal, engine.Value{}, true},
		{"rfc3339", engine.Text("2024-02-29T12:00:00Z"), engine.VTimestamptz, engine.Timestamptz(stamp), false},
		{"naive timestamp is UTC", engine.Text("2024-02-29 12:00:00"), engine.VTimestamptz, engine.Timestamptz(stamp), false},
		{"date only", engine.Text("2024-02-29"), engine.VTimestamptz, engine.Timestamptz(stamp.Add(-12 * time.Hour)), false},
		{"bad timestamp", engine.Text("tomorrow"), engine.VTimestamptz, engine.Value{}, true},
		{"uuid is normalised", engine.Text("123E4567-E89B-12D3-A456-426614174000"), engine.VUUID, engine.UUID("123e4567-e89b-12d3-a456-426614174000"), false},
		{"bytes from hex", engine.Text(`\x6869`), engine.VBytes, engine.Bytes([]byte("hi")), false},
		{"valid json", engine.Text(`{"a":1}`), engine.VJSON, engine.JSON(`{"a":1}`), false},
		{"invalid json", engine.Text(`{a`), engine.VJSON, engine.Value{}, true},
		{"int to text", engine.Int(7), engine.VText, engine.Text("7"), false},
		{"unknown target kind passes through", engine.Text("x"), engine.VNull, engine.Text("x"), false},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got, err := transfer.Coerce(tc.in, tc.kind)
			if (err != nil) != tc.fail {
				t.Fatalf("error = %v, want failure %v", err, tc.fail)
			}
			if !tc.fail && !reflect.DeepEqual(got, tc.want) {
				t.Errorf("got %+v, want %+v", got, tc.want)
			}
		})
	}
}

func TestPathExtractor(t *testing.T) {
	doc := `{"_id":{"$oid":"650000000000000000000001"},"n":{"$numberLong":"9"},"f":{"$numberDouble":"1.5"},"d":{"$numberDecimal":"1.10"},` +
		`"at":{"$date":{"$numberLong":"1709208000000"}},"a":{"b":{"c":true}},"items":[{"sku":"x"},{"sku":"y"},{"other":1}],"nil":null}`
	paths := []string{"_id", "n", "f", "d", "at", "a.b.c", "a", "items.[].sku", "items.1.sku", "items.9", "missing", "nil"}
	for _, canonical := range []bool{true, false} {
		row, err := transfer.NewPathExtractor(paths, canonical).Row(doc)
		if err != nil {
			t.Fatal(err)
		}
		want := []engine.Value{
			engine.Text("650000000000000000000001"), engine.Int(9), engine.Float(1.5), engine.Decimal("1.10"),
			engine.Timestamptz(time.UnixMilli(1709208000000).UTC()), engine.Bool(true), {}, {}, engine.Text("y"), {}, {}, {},
		}
		for i := range want {
			got := row[i]
			if got.Kind == engine.VTimestamptz {
				got.Time = got.Time.UTC()
			}
			if i == 6 || i == 7 {
				if got.Kind != engine.VJSON {
					t.Errorf("canonical=%v path %q = %+v, want JSON", canonical, paths[i], got)
				}
				continue
			}
			if !reflect.DeepEqual(got, want[i]) {
				t.Errorf("canonical=%v path %q = %+v, want %+v", canonical, paths[i], got, want[i])
			}
		}
	}
}

func TestChunkWriterNeverEmitsMoreThanOneMiB(t *testing.T) {
	var sizes []int
	w := transfer.NewChunkWriter(func(b []byte) error {
		sizes = append(sizes, len(b))
		return nil
	})
	payload := bytes.Repeat([]byte("x"), 2_500_000)
	if _, err := w.Write(payload); err != nil {
		t.Fatal(err)
	}
	if err := w.Flush(); err != nil {
		t.Fatal(err)
	}
	if !reflect.DeepEqual(sizes, []int{1 << 20, 1 << 20, 2_500_000 - 2<<20}) || w.Bytes() != 2_500_000 {
		t.Errorf("sizes = %v, bytes = %d", sizes, w.Bytes())
	}
	failing := transfer.NewChunkWriter(func([]byte) error { return errors.New("client gone") })
	if _, err := failing.Write(payload); err == nil {
		t.Error("a failing emit was ignored")
	}
}

func TestChunkReaderReassemblesAnyChunking(t *testing.T) {
	chunks := [][]byte{[]byte("ab"), nil, []byte("cde"), []byte("f")}
	next := 0
	r := transfer.NewChunkReader(func() ([]byte, error) {
		if next == len(chunks) {
			return nil, io.EOF
		}
		next++
		return chunks[next-1], nil
	})
	got, err := io.ReadAll(r)
	if err != nil || string(got) != "abcdef" || r.Bytes() != 6 {
		t.Errorf("got %q, %v, %d bytes", got, err, r.Bytes())
	}
	tooBig := transfer.NewChunkReader(func() ([]byte, error) { return make([]byte, 1<<20+1), nil })
	if _, err := tooBig.Read(make([]byte, 8)); err == nil {
		t.Error("an oversized chunk was accepted")
	}
}

func TestBuildMapper(t *testing.T) {
	target := []engine.ColumnDef{{Name: "id", Kind: engine.VInt}, {Name: "Name", Kind: engine.VText}, {Name: "n", Kind: engine.VInt}}
	t.Run("by position", func(t *testing.T) {
		m, err := transfer.BuildMapper([]string{"a", "b"}, nil, target, false)
		if err != nil || !reflect.DeepEqual(m.Columns(), []string{"id", "Name"}) {
			t.Fatalf("columns = %v, err = %v", m, err)
		}
	})
	t.Run("by name", func(t *testing.T) {
		m, err := transfer.BuildMapper([]string{"n", "ID"}, nil, target, true)
		if err != nil || !reflect.DeepEqual(m.Columns(), []string{"n", "id"}) {
			t.Fatalf("columns = %v, err = %v", m, err)
		}
		if _, err := transfer.BuildMapper([]string{"unknown"}, nil, target, true); err == nil || err.Kind != transfer.KindMapping {
			t.Errorf("unknown name: %v", err)
		}
	})
	t.Run("too many file columns", func(t *testing.T) {
		if _, err := transfer.BuildMapper([]string{"a", "b", "c", "d"}, nil, target, false); err == nil || err.Kind != transfer.KindMapping {
			t.Errorf("err = %v", err)
		}
	})
	t.Run("case-insensitive target and canonical name", func(t *testing.T) {
		m, err := transfer.BuildMapper([]string{"a", "b"}, []transfer.Mapping{{SourceIndex: 1, Target: "name"}}, target, false)
		if err != nil || m.Columns()[0] != "Name" {
			t.Errorf("columns = %v, err = %v", m, err)
		}
	})
	for name, mappings := range map[string][]transfer.Mapping{
		"unknown target":  {{SourceIndex: 0, Target: "nope"}},
		"source too high": {{SourceIndex: 5, Target: "id"}},
		"mapped twice":    {{SourceIndex: 0, Target: "id"}, {SourceIndex: 1, Target: "ID"}},
	} {
		t.Run(name, func(t *testing.T) {
			if _, err := transfer.BuildMapper([]string{"a", "b"}, mappings, target, false); err == nil || err.Kind != transfer.KindMapping {
				t.Errorf("err = %v", err)
			}
		})
	}
	t.Run("unknown target needs mappings", func(t *testing.T) {
		if _, err := transfer.BuildMapper([]string{"a"}, nil, nil, false); err == nil {
			t.Error("no error")
		}
	})
}

func TestClassifyMapsEngineAndFormatErrors(t *testing.T) {
	cases := []struct {
		err  error
		want transfer.ErrorKind
	}{
		{&engine.Error{Kind: engine.KindConstraint, Msg: "dup"}, transfer.KindConstraint},
		{&engine.Error{Kind: engine.KindAuth}, transfer.KindAuth},
		{&engine.Error{Kind: engine.KindConnectionLost}, transfer.KindNetwork},
		{&engine.Error{Kind: engine.KindTimeout}, transfer.KindTimeout},
		{&engine.Error{Kind: engine.KindUnsupported}, transfer.KindUnsupported},
		{&engine.Error{Kind: engine.KindSQL, Msg: "syntax"}, transfer.KindServer},
		{&dataformat.ParseError{Line: 3, Column: 1, Err: errors.New("bad")}, transfer.KindParse},
		{context.Canceled, transfer.KindCanceled},
		{context.DeadlineExceeded, transfer.KindTimeout},
		{errors.New("boom with a secret"), transfer.KindServer},
	}
	for _, tc := range cases {
		got := transfer.Classify(tc.err)
		if got.Kind != tc.want {
			t.Errorf("Classify(%v) = %v, want %v", tc.err, got.Kind, tc.want)
		}
	}
	if msg := transfer.Classify(errors.New("password=hunter2")).Message; msg != "operation failed" {
		t.Errorf("unknown errors must not leak: %q", msg)
	}
}

func TestInferDetectsFormats(t *testing.T) {
	cases := []struct {
		name, file, data string
		format           transfer.Format
		delimiter        string
		header           bool
	}{
		{"csv header", "a.csv", "id,name\n1,x\n2,y\n", transfer.CSV, "", true},
		{"csv no header", "", "1,x\n2,y\n", transfer.CSV, "", false},
		{"pipe", "", "a|b\n1|2\n3|4\n", transfer.CSV, "|", true},
		{"tsv by content", "", "a\tb\n1\t2\n", transfer.TSV, "", true},
		{"json array", "", " [{\"a\":1}]", transfer.JSON, "", false},
		{"ndjson", "", "{\"a\":1}\n{\"a\":2}\n", transfer.NDJSON, "", false},
		{"sql by content", "", "CREATE TABLE t (a int);", transfer.SQL, "", false},
		{"sql by extension", "dump.sql", "SELECT 1;", transfer.SQL, "", false},
		{"parquet magic", "", "PAR1....", transfer.Parquet, "", false},
		{"bom csv", "", "\xef\xbb\xbfa,b\nx,y\n", transfer.CSV, "", true},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			got, err := transfer.Infer(context.Background(), []byte(tc.data), transfer.InferRequest{Filename: tc.file})
			if err != nil {
				t.Fatal(err)
			}
			if got.Format != tc.format || got.Options.Delimiter != tc.delimiter || got.Options.Header != tc.header {
				t.Errorf("format = %v, options = %+v", got.Format, got.Options)
			}
		})
	}
}

func TestInferWarnsAboutMixedColumnsAndTruncation(t *testing.T) {
	got, err := transfer.Infer(context.Background(), []byte("a,b\n1,x\nzz,y\n3,partial"), transfer.InferRequest{Truncated: true})
	if err != nil {
		t.Fatal(err)
	}
	if len(got.Warnings) < 2 {
		t.Errorf("warnings = %v", got.Warnings)
	}
	if got.Columns[0].Kind != engine.VText || got.Columns[0].Name != "a" {
		t.Errorf("columns = %+v", got.Columns)
	}
}
