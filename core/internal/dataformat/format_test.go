package dataformat

import (
	"bytes"
	"errors"
	"flag"
	"io"
	"os"
	"path/filepath"
	"reflect"
	"strings"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

var update = flag.Bool("update", false, "update format goldens")

func golden(t *testing.T, name string, got []byte) {
	t.Helper()
	path := filepath.Join("testdata", name)
	if *update {
		if err := os.WriteFile(path, got, 0o644); err != nil {
			t.Fatal(err)
		}
	}
	want, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	if !bytes.Equal(got, want) {
		t.Fatalf("%s differs from golden (%d bytes vs %d)", name, len(got), len(want))
	}
}

func fixture() ([]engine.Column, [][]engine.Value) {
	names := []string{"id", "bool", "int", "float", "decimal", "text, \"名\"", "bytes", "time", "json", "uuid", "array", "null", "empty", "wide"}
	columns := make([]engine.Column, len(names))
	for i, name := range names {
		columns[i].Name = name
	}
	return columns, [][]engine.Value{{
		engine.Int(1), engine.Bool(true), engine.Int(-17), engine.Float(0.00000000123),
		engine.Decimal("12345678901234567890.0123456789"), engine.Text("雪; a\tb, \"quote\"\r\nsecond\nthird 'line'"),
		engine.Bytes([]byte{0, 0xff, 0xab}), engine.Timestamptz(time.Date(2026, 1, 2, 3, 4, 5, 123000, time.UTC)),
		engine.JSON("{\n  \"key\": [1,true]\n}"), engine.UUID("c1f1d680-5349-4018-8790-7a5ec93c4377"),
		engine.Array([]engine.Value{engine.Int(42), engine.Null()}), engine.Null(), engine.Text(""), engine.Text(strings.Repeat("界", 700)),
	}, {
		engine.Int(2), engine.Bool(false), engine.Int(0), engine.Float(-1.5),
		engine.Decimal("-0.5"), engine.Text("NULL"), engine.Bytes(nil),
		engine.Timestamptz(time.Unix(0, 0).UTC()), engine.JSON("[]"), engine.UUID("00000000-0000-0000-0000-000000000000"),
		engine.Array(nil), engine.Null(), engine.Text(""), engine.Text("literal \\n"),
	}}
}

func TestRowGoldens(t *testing.T) {
	columns, rows := fixture()
	for _, tc := range []struct {
		name string
		opts Options
	}{
		{"rows.csv", Options{Format: CSV, Header: true, BOM: true, NullText: "NULL"}},
		{"rows.tsv", Options{Format: TSV}},
		{"custom.csv", Options{Format: CSV, Delimiter: '§', Quote: '«', Header: true, NullText: "NULL"}},
		{"rows.json", Options{Format: JSON}},
		{"rows.ndjson", Options{Format: NDJSON}},
	} {
		t.Run(tc.name, func(t *testing.T) {
			var out bytes.Buffer
			w, err := NewWriter(&out, tc.opts)
			if err != nil {
				t.Fatal(err)
			}
			if err := w.Columns(t.Context(), columns); err != nil {
				t.Fatal(err)
			}
			for _, row := range rows {
				if err := w.Batch(t.Context(), [][]engine.Value{row}); err != nil {
					t.Fatal(err)
				}
			}
			if err := w.Close(t.Context()); err != nil {
				t.Fatal(err)
			}
			golden(t, tc.name, out.Bytes())

			names := make([]string, len(columns))
			for i, col := range columns {
				names[i] = col.Name
			}
			r, err := NewReader(t.Context(), &out, tc.opts, names)
			if err != nil {
				t.Fatal(err)
			}
			got, err := r.Next(t.Context())
			if err != nil || len(got) != 2 {
				t.Fatalf("read %d rows: %v", len(got), err)
			}
			for i, row := range got {
				if row[11].Kind != engine.VNull || row[12].Kind != engine.VText || row[12].Str != "" {
					t.Fatalf("null and empty collapsed in row %d", i+1)
				}
				if row[5].Str != rows[i][5].Str || row[13].Str != rows[i][13].Str {
					t.Fatalf("text failed round trip in row %d", i+1)
				}
			}
			if _, err := r.Next(t.Context()); !errors.Is(err, io.EOF) {
				t.Fatalf("expected EOF, got %v", err)
			}
		})
	}
}

func TestDocumentGoldens(t *testing.T) {
	docs := []engine.Document{
		`{"_id":{"$oid":"507f1f77bcf86cd799439011"},"count":{"$numberLong":"9007199254740993"},"date":{"$date":{"$numberLong":"0"}},"price":{"$numberDecimal":"12.30"},"a":[null,"雪\n\""],"empty":"","bin":{"$binary":{"base64":"AAE=","subType":"00"}}}`,
		`{"nested":{"n":{"$numberInt":"1"}},"nullable":null}`,
	}
	for _, tc := range []struct {
		name      string
		format    Format
		canonical bool
	}{
		{"canonical.json", JSON, true}, {"relaxed.json", JSON, false},
		{"canonical.ndjson", NDJSON, true}, {"relaxed.ndjson", NDJSON, false},
	} {
		t.Run(tc.name, func(t *testing.T) {
			var out bytes.Buffer
			opts := Options{Format: tc.format}
			w, err := NewDocumentWriter(&out, opts, tc.canonical)
			if err != nil {
				t.Fatal(err)
			}
			if err := w.Batch(t.Context(), docs); err != nil {
				t.Fatal(err)
			}
			if err := w.Close(t.Context()); err != nil {
				t.Fatal(err)
			}
			golden(t, tc.name, out.Bytes())
			r, err := NewDocumentReader(t.Context(), &out, opts, tc.canonical)
			if err != nil {
				t.Fatal(err)
			}
			got, err := r.Next(t.Context())
			if err != nil || !reflect.DeepEqual(got, docs) {
				t.Fatalf("round trip: %v, %v", got, err)
			}
		})
	}
}

func TestSQLGolden(t *testing.T) {
	columns, rows := fixture()
	design := sqldialect.TableDesign{}
	types := []string{"bigint", "boolean", "bigint", "double precision", "numeric", "text", "bytea", "timestamptz", "jsonb", "uuid", "integer[]", "text", "text", "text"}
	for i, col := range columns {
		design.Columns = append(design.Columns, sqldialect.ColumnSpec{Name: col.Name, TypeName: types[i], Nullable: true})
	}
	var out bytes.Buffer
	w, err := NewSQLWriter(&out, SQLDumpOptions{Dialect: sqldialect.Postgres, Target: sqldialect.Target{Schema: "public", Table: "select"}, Create: &design})
	if err != nil {
		t.Fatal(err)
	}
	if err := w.Columns(t.Context(), columns); err != nil {
		t.Fatal(err)
	}
	if err := w.Batch(t.Context(), rows); err != nil {
		t.Fatal(err)
	}
	if err := w.Close(t.Context()); err != nil {
		t.Fatal(err)
	}
	golden(t, "rows.sql", out.Bytes())
}

func TestSQLStatementBounds(t *testing.T) {
	for _, tc := range []struct {
		name    string
		dialect sqldialect.Dialect
		want    int
	}{
		{"multi", sqldialect.SQLite, 2},
		{"single", sqldialect.Oracle, 3},
	} {
		t.Run(tc.name, func(t *testing.T) {
			var out strings.Builder
			const capBytes = 75
			w, err := NewSQLWriter(&out, SQLDumpOptions{Dialect: tc.dialect, MaxBytes: capBytes})
			if err != nil {
				t.Fatal(err)
			}
			ctx := t.Context()
			if err := w.Columns(ctx, []engine.Column{{Name: "name"}}); err != nil {
				t.Fatal(err)
			}
			for range 3 {
				if err := w.Batch(ctx, [][]engine.Value{{engine.Text("123456789")}}); err != nil {
					t.Fatal(err)
				}
			}
			if err := w.Close(ctx); err != nil {
				t.Fatal(err)
			}
			statements := sqlsplit.Split(tc.dialect.Lexer(), out.String())
			if len(statements) != tc.want {
				t.Fatalf("got %d statements, want %d:\n%s", len(statements), tc.want, out.String())
			}
			for _, s := range statements {
				if s.End-s.Start > capBytes {
					t.Fatalf("statement exceeds %d bytes: %+v", capBytes, s)
				}
			}
		})
	}
}
