package dataformat

import (
	"bytes"
	"context"
	"errors"
	"io"
	"strings"
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

type failingInput struct {
	err    error
	cancel context.CancelFunc
}

func (f failingInput) Read([]byte) (int, error) {
	if f.cancel != nil {
		f.cancel()
	}
	return 0, f.err
}

func TestReadFailuresAreNotRowErrors(t *testing.T) {
	transport := errors.New("disconnected")
	for _, tc := range []struct {
		name   string
		format Format
		data   string
	}{
		{"prefix", CSV, "x"},
		{"csv", CSV, "good\nbad"},
		{"csv terminator", CSV, "good\nbad\r"},
		{"json", JSON, `[{"a":1},{"a":`},
		{"ndjson", NDJSON, "{\"a\":1}\n{\"a\":"},
	} {
		t.Run(tc.name, func(t *testing.T) {
			for _, want := range []error{transport, io.ErrUnexpectedEOF, context.Canceled} {
				ctx, cancel := context.WithCancel(t.Context())
				src := failingInput{err: want}
				if errors.Is(want, context.Canceled) {
					src.cancel = cancel
				}
				r, err := NewReader(ctx, io.MultiReader(strings.NewReader(tc.data), src), Options{Format: tc.format}, nil)
				if err == nil {
					rows, nextErr := r.Next(ctx)
					if len(rows) != 0 {
						t.Fatalf("returned %d rows before reporting %v", len(rows), want)
					}
					err = nextErr
				}
				cancel()
				var parse *ParseError
				if !errors.Is(err, want) || errors.As(err, &parse) {
					t.Fatalf("expected fatal %v, got %v", want, err)
				}
			}
		})
	}
}

func TestMalformedDelimitedHeaderDoesNotBecomeData(t *testing.T) {
	r, err := NewReader(t.Context(), strings.NewReader("b\"ad\ngood\n"), Options{Header: true}, nil)
	if err != nil {
		t.Fatal(err)
	}
	for range 2 {
		names, err := r.Columns(t.Context())
		var parse *ParseError
		if len(names) != 0 || !errors.As(err, &parse) || parse.Line != 1 {
			t.Fatalf("columns = %v, error = %v", names, err)
		}
	}
	if rows, err := r.Next(t.Context()); len(rows) != 0 || !errors.Is(err, io.EOF) {
		t.Fatalf("expected EOF after malformed header, got %v, %v", rows, err)
	}
}

func TestWideRowsAreSingletonBatches(t *testing.T) {
	text := strings.Repeat("x", MaxBatchBytes+1)
	for _, tc := range []struct {
		name   string
		format Format
	}{{"CSV", CSV}, {"TSV", TSV}, {"JSON", JSON}, {"NDJSON", NDJSON}} {
		t.Run(tc.name, func(t *testing.T) {
			ctx := t.Context()
			var out bytes.Buffer
			opts := Options{Format: tc.format}
			w, err := NewWriter(&out, opts)
			if err != nil {
				t.Fatal(err)
			}
			if err := w.Columns(ctx, []engine.Column{{Name: "value"}}); err != nil {
				t.Fatal(err)
			}
			if err := w.Batch(ctx, [][]engine.Value{{engine.Text("before")}, {engine.Text(text)}, {engine.Text("after")}}); err != nil {
				t.Fatal(err)
			}
			if err := w.Close(ctx); err != nil {
				t.Fatal(err)
			}
			r, err := NewReader(ctx, &out, opts, nil)
			if err != nil {
				t.Fatal(err)
			}
			for _, want := range []string{"before", text, "after"} {
				rows, err := r.Next(ctx)
				if err != nil || len(rows) != 1 || rows[0][0].Str != want {
					t.Fatalf("expected singleton batch for %d-byte value, got %d rows and %v", len(want), len(rows), err)
				}
			}
		})
	}
}

func TestWideDocumentSingleton(t *testing.T) {
	ctx := t.Context()
	wide := `{"s":"` + strings.Repeat("x", MaxBatchBytes+1) + `"}`
	docs := []engine.Document{`{"s":""}`, wide, `{"s":"last"}`}
	var out bytes.Buffer
	opts := Options{Format: NDJSON}
	w, err := NewDocumentWriter(&out, opts, true)
	if err != nil {
		t.Fatal(err)
	}
	if err := w.Batch(ctx, docs); err != nil {
		t.Fatal(err)
	}
	if err := w.Close(ctx); err != nil {
		t.Fatal(err)
	}
	r, err := NewDocumentReader(ctx, &out, opts, true)
	if err != nil {
		t.Fatal(err)
	}
	for _, want := range docs {
		got, err := r.Next(ctx)
		if err != nil || len(got) != 1 || got[0] != want {
			t.Fatalf("expected singleton for %d-byte document, got %d rows and %v", len(want), len(got), err)
		}
	}
}

func TestWideSQLRowUsesOwnStatement(t *testing.T) {
	var out strings.Builder
	ctx := t.Context()
	w, err := NewSQLWriter(&out, SQLDumpOptions{Dialect: sqldialect.Postgres, MaxBytes: 64, MaxRecordBytes: 256})
	if err != nil {
		t.Fatal(err)
	}
	if err := w.Columns(ctx, []engine.Column{{Name: "value"}}); err != nil {
		t.Fatal(err)
	}
	if err := w.Batch(ctx, [][]engine.Value{{engine.Text("a")}, {engine.Text(strings.Repeat("x", 80))}, {engine.Text("b")}}); err != nil {
		t.Fatal(err)
	}
	if err := w.Batch(ctx, [][]engine.Value{{engine.Text(strings.Repeat("x", 256))}}); !errors.Is(err, errRecordSize) {
		t.Fatalf("expected record limit error, got %v", err)
	}
	if err := w.Close(ctx); err != nil {
		t.Fatal(err)
	}
	s := sqlsplit.Split(sqlsplit.Postgres, out.String())
	if len(s) != 3 || s[1].TermEnd-s[1].Start <= 64 {
		t.Fatalf("expected 3 INSERTs with a larger singleton in the middle, got %v", s)
	}
}

func TestJSONProjectionAndInference(t *testing.T) {
	ctx := t.Context()
	data := `[{},{"zip":"12345","n":1.5,"extra":true},{"zip":"01234","n":1e4}]`
	names := []string{"zip", "n"}
	r, err := NewReader(ctx, strings.NewReader(data), Options{Format: JSON}, names)
	if err != nil {
		t.Fatal(err)
	}
	cols, err := r.Infer(ctx, 3)
	if err != nil {
		t.Fatal(err)
	}
	if len(cols) != 2 || cols[0].Kind != engine.VText || cols[1].Kind != engine.VFloat ||
		!cols[0].Nullable || !cols[1].Nullable || cols[0].Warning != "" || cols[1].Warning != "" {
		t.Fatalf("inferred %+v", cols)
	}
	if _, err := NewReader(ctx, strings.NewReader(data), Options{Format: JSON}, []string{"zip", "zip"}); err == nil {
		t.Fatal("duplicate projection was accepted")
	}
	r, err = NewReader(ctx, strings.NewReader(`[{"zip":"12345"}]`), Options{Format: JSON}, []string{})
	if err != nil {
		t.Fatal(err)
	}
	got, err := r.Columns(ctx)
	if err != nil || len(got) != 1 || got[0] != "zip" {
		t.Fatalf("empty projection did not discover columns: %v, %v", got, err)
	}
}

func TestJSONExportDisambiguatesColumnNames(t *testing.T) {
	var out bytes.Buffer
	ctx := t.Context()
	w, err := NewWriter(&out, Options{Format: NDJSON})
	if err != nil {
		t.Fatal(err)
	}
	if err := w.Columns(ctx, []engine.Column{{Name: "id"}, {Name: "id"}, {Name: "id_2"}, {Name: "id"}}); err != nil {
		t.Fatal(err)
	}
	if err := w.Batch(ctx, [][]engine.Value{{engine.Int(1), engine.Int(2), engine.Int(3), engine.Int(4)}}); err != nil {
		t.Fatal(err)
	}
	if err := w.Close(ctx); err != nil {
		t.Fatal(err)
	}
	if want := "{\"id\":1,\"id_3\":2,\"id_2\":3,\"id_4\":4}\n"; out.String() != want {
		t.Fatalf("got %q, want %q", out.String(), want)
	}
}

func TestInvalidCanonicalEJSONOmitsDocumentValue(t *testing.T) {
	const privateNumber = "987654321"
	r, err := NewDocumentReader(t.Context(), strings.NewReader("{\"n\":"+privateNumber+"}\n{\"n\":{\"$numberInt\":\"1\"}}\n"), Options{Format: NDJSON}, true)
	if err != nil {
		t.Fatal(err)
	}
	var parse *ParseError
	if _, err := r.Next(t.Context()); !errors.As(err, &parse) || strings.Contains(err.Error(), privateNumber) {
		t.Fatalf("expected sanitized EJSON error, got %v", err)
	}
	if docs, err := r.Next(t.Context()); err != nil || len(docs) != 1 {
		t.Fatalf("could not resume after invalid document: %d documents, %v", len(docs), err)
	}
}
