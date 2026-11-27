package api

import (
	"bytes"
	"flag"
	"math"
	"os"
	"path/filepath"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/results"
)

var updateCopyGolden = flag.Bool("update-copy-golden", false, "update CopyRange goldens")

func TestCopyRangeGolden(t *testing.T) {
	f := newFixture(t)
	id, spool, err := f.res.Create(f.sess.ID)
	if err != nil {
		t.Fatal(err)
	}
	var cols []engine.Column
	for _, name := range []string{"unicode, \"雪\"", "null", "bool", "int", "float", "decimal", "bytes", "time", "json", "uuid", "array", "empty"} {
		cols = append(cols, engine.Column{Name: name})
	}
	spool.SetColumns(results.ColumnsToProto(cols))
	rows := [][]engine.Value{{
		engine.Text("a\t, \"雪\"\r\nb"), engine.Null(), engine.Bool(true), engine.Int(-7),
		engine.Float(math.Inf(1)), engine.Decimal("1000000000000000000.1234"), engine.Bytes([]byte{0x00, 0xff}),
		engine.Timestamptz(time.Date(2026, 2, 3, 4, 5, 6, 7000, time.FixedZone("local", 7200))),
		engine.JSON("{\n  \"key\": true\n}"), engine.UUID("00000000-0000-0000-0000-000000000000"),
		engine.Array([]engine.Value{engine.Int(1), engine.Text("<>&"), engine.Null()}), engine.Text(""),
	}, {
		engine.Text("last"), engine.Text(""), engine.Bool(false), engine.Int(0),
		engine.Float(1.25), engine.Decimal("NaN"), engine.Bytes(nil), engine.Null(),
		engine.JSON("invalid json"), engine.Null(), engine.Array(nil), engine.Null(),
	}, {engine.Text("short row")}}
	if err := spool.Append(results.RowsToProto(rows)); err != nil {
		t.Fatal(err)
	}
	for _, tc := range []struct {
		name   string
		format queravuev1.CopyFormat
	}{
		{"copy.csv", queravuev1.CopyFormat_COPY_FORMAT_CSV},
		{"copy.tsv", queravuev1.CopyFormat_COPY_FORMAT_TSV},
		{"copy.json", queravuev1.CopyFormat_COPY_FORMAT_JSON},
	} {
		t.Run(tc.name, func(t *testing.T) {
			s := &copyStream{ctx: t.Context()}
			err := f.q.CopyRange(&queravuev1.CopyRangeRequest{
				ResultId: id, Format: tc.format, IncludeHeader: true,
				ColumnIndices: []uint32{11, 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 99, 0},
			}, s)
			if err != nil {
				t.Fatal(err)
			}
			path := filepath.Join("testdata", tc.name)
			if *updateCopyGolden {
				if err := os.WriteFile(path, []byte(s.text.String()), 0o644); err != nil {
					t.Fatal(err)
				}
			}
			want, err := os.ReadFile(path)
			if err != nil {
				t.Fatal(err)
			}
			if !bytes.Equal([]byte(s.text.String()), want) {
				t.Errorf("CopyRange = %q, want %q", []byte(s.text.String()), want)
			}
		})
	}
}
