package postgres

import (
	"context"
	"errors"
	"io"
	"math"
	"strings"
	"testing"
	"testing/iotest"
	"time"

	"github.com/jackc/pgx/v5/pgconn"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func TestAppendCopyField(t *testing.T) {
	tests := []struct {
		name string
		in   engine.Value
		want string
	}{
		{"null", engine.Null(), `\N`},
		{"true", engine.Bool(true), "t"},
		{"false", engine.Bool(false), "f"},
		{"int", engine.Int(-42), "-42"},
		{"float", engine.Float(0.30000000000000004), "0.30000000000000004"},
		{"nan", engine.Float(math.NaN()), "NaN"},
		{"decimal", engine.Decimal("1.50"), "1.50"},
		{"text escapes", engine.Text("a\tb\nc\rd\\e"), `a\tb\nc\rd\\e`},
		{"literal backslash N", engine.Text(`\N`), `\\N`},
		{"bytes", engine.Bytes([]byte{0, 0xff}), `\\x00ff`},
		{"timestamp", engine.Timestamptz(time.Date(2024, 2, 29, 1, 2, 3, 456789000, time.FixedZone("x", 3600))), "2024-02-29T00:02:03.456789Z"},
		{"array", engine.Array([]engine.Value{engine.Int(1), engine.Null(), engine.Text(`a"b\c`)}), `{"1",NULL,"a\\"b\\\\c"}`},
		{"nested array", engine.Array([]engine.Value{engine.Array([]engine.Value{engine.Bool(true)})}), `{{"t"}}`},
		{"empty array", engine.Array(nil), "{}"},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := appendCopyField(nil, tt.in, false)
			if err != nil || string(got) != tt.want {
				t.Fatalf("got %q, %v; want %q", got, err, tt.want)
			}
		})
	}
}

func TestAppendCopyFieldOctalBytea(t *testing.T) {
	got, err := appendCopyField(nil, engine.Bytes([]byte{0, 'a', '\\', '\n', 0xff, ' '}), true)
	if err != nil || string(got) != `\000a\\\012\377 ` {
		t.Fatalf("got %q, %v", got, err)
	}
}

func TestAppendCopyFieldRejectsUnknownKind(t *testing.T) {
	if _, err := appendCopyField(nil, engine.Value{Kind: engine.ValueKind(99)}, false); err == nil {
		t.Fatal("want an error")
	}
}

func TestCopyTextReaderStreamsRowsAcrossSmallReads(t *testing.T) {
	rows := [][]engine.Value{{engine.Int(1), engine.Text("a")}, {engine.Int(2), engine.Null()}}
	r := &copyTextReader{rows: rows}
	got, err := io.ReadAll(iotest.OneByteReader(r))
	if err != nil || string(got) != "1\ta\n2\t\\N\n" {
		t.Fatalf("got %q, %v", got, err)
	}
}

func TestCopyTextReaderReportsEncodingErrorWithoutValue(t *testing.T) {
	rows := [][]engine.Value{{engine.Int(1)}, {{Kind: engine.ValueKind(99)}}}
	r := &copyTextReader{rows: rows}
	_, err := io.ReadAll(r)
	if err == nil || r.err == nil {
		t.Fatal("want an error")
	}
}

func TestLoadErrorKinds(t *testing.T) {
	c := &Conn{id: IDPostgres}
	tests := []struct {
		code string
		msg  string
		want engine.Kind
	}{
		{"23505", `duplicate key value violates unique constraint "t_pkey"`, engine.KindConstraint},
		{"23502", `null value in column "x" violates not-null constraint`, engine.KindConstraint},
		{"23503", "fk", engine.KindConstraint},
		{"42P01", `relation "t" does not exist`, engine.KindNotFound},
		{"42501", "permission denied", engine.KindAuth},
		{"22P02", `invalid input syntax for type integer: "secret-value"`, engine.KindSQL},
		{"42703", `column "x" does not exist`, engine.KindSQL},
		{"0A000", `could not parse "secret-value" as type int[]`, engine.KindSQL},
	}
	for _, tt := range tests {
		t.Run(tt.code, func(t *testing.T) {
			err := c.loadError(t.Context(), &pgconn.PgError{Code: tt.code, Message: tt.msg})
			if engine.KindOf(err) != tt.want {
				t.Fatalf("kind = %v, want %v", engine.KindOf(err), tt.want)
			}
			if containsSecret(err) {
				t.Errorf("message quotes the value: %v", err)
			}
		})
	}
}

func TestLoadErrorWhenContextCancelled(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	err := (&Conn{id: IDPostgres}).loadError(ctx, errors.New("whatever"))
	if engine.KindOf(err) != engine.KindCanceled {
		t.Fatalf("kind = %v", engine.KindOf(err))
	}
}

func containsSecret(err error) bool { return strings.Contains(err.Error(), "secret-value") }
