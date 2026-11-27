package dataformat

import (
	"errors"
	"fmt"
	"io"
	"reflect"
	"strings"
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func TestSkipBadRecord(t *testing.T) {
	for _, tc := range []struct {
		name                 string
		opts                 Options
		data                 string
		line, column, offset int64
		want                 string
	}{
		{"csv", Options{Format: CSV, Header: true}, "a\r\ngood\r\nno\"pe\r\nlast\r\n", 3, 3, 11, "last"},
		{"csv-later-quoted-field", Options{Format: CSV}, "good\n\"bad\"x,\"hello\nworld\"\nlast", 2, 6, 10, "last"},
		{"csv-bare-cr", Options{Format: CSV}, "good\nbad\rfield\nlast", 2, 4, 8, "last"},
		{"csv-field-count", Options{Format: CSV}, "good\nx,y\nlast", 2, 1, 5, "last"},
		{"csv-utf8", Options{Format: CSV}, "\ufeffgood\n\xff\nlast", 2, 1, 8, "last"},
		{"csv-wide", Options{Format: CSV, MaxRecordBytes: 110}, "good\n\"" + strings.Repeat("x", 40) + "\ncontinued\"\nlast", 2, 15, 19, "last"},
		{"ndjson", Options{Format: NDJSON}, "{\"a\":\"good\"}\n{\"a\":!}\n{\"a\":\"last\"}", 2, 6, 18, "last"},
		{"ndjson-utf8", Options{Format: NDJSON}, "{\"a\":\"good\"}\n{\"a\":\"\xff\"}\n{\"a\":\"last\"}", 2, 7, 19, "last"},
		{"json-array", Options{Format: JSON}, "[{\"a\":\"good\"},\n{\"a\":!},\n{\"a\":\"last\"}]", 2, 6, 20, "last"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			r, err := NewReader(t.Context(), strings.NewReader(tc.data), tc.opts, nil)
			if err != nil {
				t.Fatal(err)
			}
			if rows, err := r.Next(t.Context()); err != nil || len(rows) != 1 || rows[0][0].Str != "good" {
				t.Fatalf("first batch: %v, %v", rows, err)
			}
			rows, err := r.Next(t.Context())
			var parse *ParseError
			if len(rows) != 0 || !errors.As(err, &parse) || parse.Line != tc.line || parse.Column != tc.column || parse.Offset != tc.offset {
				t.Fatalf("expected error at %d:%d (%d), got %v, %v", tc.line, tc.column, tc.offset, rows, err)
			}
			if rows, err := r.Next(t.Context()); err != nil || len(rows) != 1 || rows[0][0].Str != tc.want {
				t.Fatalf("after skip: %v, %v", rows, err)
			}
			if _, err := r.Next(t.Context()); !errors.Is(err, io.EOF) {
				t.Fatalf("expected EOF, got %v", err)
			}
		})
	}
}

func TestEncoding(t *testing.T) {
	for _, tc := range []struct {
		opts Options
		data string
	}{
		{Options{Encoding: "latin1"}, "abc"},
		{Options{}, "\xff\xfea\x00"},
		{Options{}, "\xfe\xff\x00a"},
		{Options{}, "\x00\x00\xfe\xff"},
	} {
		t.Run(fmt.Sprintf("%s/%x", tc.opts.Encoding, tc.data), func(t *testing.T) {
			_, err := NewReader(t.Context(), strings.NewReader(tc.data), tc.opts, nil)
			var parse *ParseError
			if !errors.As(err, &parse) || !errors.Is(err, errEncoding) || parse.Offset != 0 {
				t.Fatalf("expected encoding error at offset zero, got %v", err)
			}
		})
	}
}

func TestInference(t *testing.T) {
	data := "bool,int,float,decimal,ts,uuid,json,text,mixed,nullable,all_null\n" +
		"true,42,1e2,12345678901234567890.1,2026-01-02T03:04:05Z,00000000-0000-0000-0000-000000000000,[],001,3,,\n" +
		"false,-2,2,-1,2026-01-02T03:04:05Z,00000000-0000-0000-0000-000000000000,{},abc,string,3,\n" +
		"null,null,null,null,null,null,null,null,null,null,null\n"
	r, err := NewReader(t.Context(), strings.NewReader(data), Options{Header: true}, nil)
	if err != nil {
		t.Fatal(err)
	}
	got, err := r.Infer(t.Context(), 2)
	if err != nil {
		t.Fatal(err)
	}
	var kinds []engine.ValueKind
	var nullable, warnings []string
	for _, col := range got {
		kinds = append(kinds, col.Kind)
		if col.Nullable {
			nullable = append(nullable, col.Name)
		}
		if col.Warning != "" {
			warnings = append(warnings, col.Name)
		}
	}
	want := []engine.ValueKind{engine.VBool, engine.VInt, engine.VFloat, engine.VDecimal, engine.VTimestamptz, engine.VUUID, engine.VJSON, engine.VText, engine.VText, engine.VInt, engine.VText}
	if !reflect.DeepEqual(kinds, want) || !reflect.DeepEqual(nullable, []string{"nullable", "all_null"}) || !reflect.DeepEqual(warnings, []string{"mixed"}) {
		t.Fatalf("inferred %+v", got)
	}
	if rows, err := r.Next(t.Context()); err != nil || len(rows) != 1 || rows[0][0].Str != "null" {
		t.Fatalf("remaining sample: %v, %v", rows, err)
	}
}

func TestBatchLimits(t *testing.T) {
	for _, tc := range []struct {
		name string
		opts Options
		row  string
		want int
	}{
		{"row cap", Options{}, "x\n", engine.MaxBatchRows},
		{"byte cap", Options{MaxBytes: 240}, strings.Repeat("x", 20) + "\n", 2},
	} {
		t.Run(tc.name, func(t *testing.T) {
			r, err := NewReader(t.Context(), strings.NewReader(strings.Repeat(tc.row, 1001)), tc.opts, nil)
			if err != nil {
				t.Fatal(err)
			}
			total := 0
			for {
				rows, err := r.Next(t.Context())
				if errors.Is(err, io.EOF) {
					break
				}
				if err != nil || len(rows) != min(tc.want, 1001-total) {
					t.Fatalf("invalid batch of %d rows after %d: %v", len(rows), total, err)
				}
				total += len(rows)
			}
			if total != 1001 {
				t.Fatalf("read %d rows", total)
			}
		})
	}
}

func FuzzCSVReader(f *testing.F) {
	f.Add("name,age\r\n\"first\nlast\",21\r\n")
	f.Add("abc\nunterminated\"\n")
	f.Fuzz(func(t *testing.T, data string) {
		fuzzReader(t, CSV, data)
	})
}

func FuzzNDJSONReader(f *testing.F) {
	f.Add("{\"n\":1}\n{\n{\"n\":null}\n")
	f.Add("{\"n\":[{},[]]}\n")
	f.Fuzz(func(t *testing.T, data string) {
		fuzzReader(t, NDJSON, data)
	})
}

func fuzzReader(t *testing.T, format Format, data string) {
	t.Helper()
	const limit = 2048
	r, err := NewReader(t.Context(), strings.NewReader(data), Options{Format: format, MaxBytes: limit, MaxRecordBytes: limit}, nil)
	if err != nil {
		var parse *ParseError
		if !errors.As(err, &parse) {
			t.Fatal(err)
		}
		return
	}
	for range len(data) + 2 {
		rows, err := r.Next(t.Context())
		if errors.Is(err, io.EOF) {
			return
		}
		if err != nil {
			var parse *ParseError
			if len(rows) != 0 || !errors.As(err, &parse) || parse.Line < 1 || parse.Column < 1 || parse.Offset > int64(len(data)) {
				t.Fatalf("unexpected read error: %v", err)
			}
			continue
		}
		if len(rows) == 0 || len(rows) > engine.MaxBatchRows {
			t.Fatalf("invalid row count %d", len(rows))
		}
		size := 0
		for _, row := range rows {
			size += len(row)*valueBudget + 1
			for _, v := range row {
				size += len(v.Str)
			}
		}
		if size > limit {
			t.Fatalf("batch size %d exceeds %d", size, limit)
		}
	}
	t.Fatal("reader failed to make progress")
}

func TestJSONArrayStructure(t *testing.T) {
	for _, tc := range []struct {
		data           string
		rows, failures int
	}{
		{`[]`, 0, 0},
		{`[{"a":1},]`, 1, 1},
		{`[{"a":1}] extra`, 1, 1},
		{`[{"a":1}, {"a":2, "a":3}, {"a":4}]`, 2, 1},
		{`[{"a":1}, {"b":2}, {}]`, 2, 1},
		{`[{"a":1}, {"a":`, 1, 1},
	} {
		t.Run(tc.data, func(t *testing.T) {
			ctx := t.Context()
			r, err := NewReader(ctx, strings.NewReader(tc.data), Options{Format: JSON}, nil)
			if err != nil {
				t.Fatal(err)
			}
			rows, failures := 0, 0
			for {
				batch, err := r.Next(ctx)
				if errors.Is(err, io.EOF) {
					break
				}
				if err != nil {
					var parse *ParseError
					if !errors.As(err, &parse) {
						t.Fatal(err)
					}
					failures++
				}
				rows += len(batch)
				if rows > tc.rows || failures > tc.failures {
					t.Fatalf("unexpected additional rows or failure: %v, %v", batch, err)
				}
			}
			if rows != tc.rows || failures != tc.failures {
				t.Fatalf("got %d rows and %d failures, want %d and %d", rows, failures, tc.rows, tc.failures)
			}
		})
	}
}

func FuzzJSONArrayReader(f *testing.F) {
	f.Add(`[{"n":1},{"n":{"t":"[],\""}},{"n":null}]`)
	f.Add(`[{}, {},]`)
	f.Fuzz(func(t *testing.T, data string) {
		fuzzReader(t, JSON, data)
	})
}
