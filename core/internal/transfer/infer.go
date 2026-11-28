package transfer

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"path/filepath"
	"strings"

	"github.com/doubledare704/queravue/core/internal/dataformat"
	"github.com/doubledare704/queravue/core/internal/engine"
)

// MaxSampleBytes is how much of a file InferImport reads.
const MaxSampleBytes = 4 << 20

const (
	inferSampleRows  = 1000
	previewRows      = 20
	previewDocuments = 10
	parquetMagic     = "PAR1"
)

// InferRequest is what InferImport knows before it looks at the bytes.
type InferRequest struct {
	Filename string
	Format   Format
	Options  Options
	// Documents asks for JSON and NDJSON to be read as documents, for a document target.
	Documents bool
	// Truncated says the sample ends before the file does.
	Truncated bool
}

// Inferred describes a file.
type Inferred struct {
	Format      Format
	Options     Options
	Columns     []dataformat.InferredColumn
	Preview     [][]engine.Value
	PreviewDocs []string
	Warnings    []string
}

// Infer detects the format, columns, types and a preview of a file from its first bytes.
func Infer(ctx context.Context, sample []byte, req InferRequest) (Inferred, *Error) {
	sample = bytes.TrimPrefix(sample, []byte(utf8BOM))
	if len(bytes.TrimSpace(sample)) == 0 {
		return Inferred{}, newError(KindParse, "the file is empty")
	}
	out := Inferred{Format: req.Format, Options: req.Options}
	if out.Format == 0 {
		out.Format, out.Options = detect(sample, req.Filename, req.Options)
	}
	if req.Truncated {
		sample = cutAtLastLine(sample)
		out.Warnings = append(out.Warnings, "only the start of the file was read, so types may change further down")
	}
	switch out.Format {
	case SQL, Parquet:
		return out, nil
	case JSON, NDJSON:
		if req.Documents {
			return inferDocuments(ctx, sample, out)
		}
	}
	return inferRows(ctx, sample, out, req.Truncated)
}

func inferRows(ctx context.Context, sample []byte, out Inferred, truncated bool) (Inferred, *Error) {
	opts, err := out.Options.DataformatOptions(out.Format)
	if err != nil {
		return out, Classify(err)
	}
	if out.Format.delimited() && !out.Options.Header {
		out.Options.Header = looksLikeHeader(ctx, sample, opts)
	}
	opts.Header = out.Options.Header
	rd, err := dataformat.NewReader(ctx, bytes.NewReader(sample), opts, nil)
	if err != nil {
		return out, Classify(err)
	}
	columns, skipped, err := rd.InferLenient(ctx, inferSampleRows)
	if err != nil {
		return out, Classify(err)
	}
	out.Columns = columns
	if skipped > 0 && !truncated {
		out.Warnings = append(out.Warnings, fmt.Sprintf("%d records in the sample could not be read", skipped))
	}
	for _, c := range columns {
		if c.Warning != "" {
			out.Warnings = append(out.Warnings, fmt.Sprintf("column %q: %s", c.Name, c.Warning))
		}
	}
	out.Preview = previewOf(ctx, sample, opts, columns)
	return out, nil
}

func previewOf(ctx context.Context, sample []byte, opts dataformat.Options, columns []dataformat.InferredColumn) [][]engine.Value {
	rd, err := dataformat.NewReader(ctx, bytes.NewReader(sample), opts, nil)
	if err != nil {
		return nil
	}
	rows, err := rd.Next(ctx)
	if err != nil && len(rows) == 0 {
		return nil
	}
	rows = rows[:min(len(rows), previewRows)]
	for _, row := range rows {
		for i := range row {
			if typed, err := Coerce(row[i], columns[i].Kind); err == nil {
				row[i] = typed
			}
		}
	}
	return rows
}

func inferDocuments(ctx context.Context, sample []byte, out Inferred) (Inferred, *Error) {
	opts, err := out.Options.DataformatOptions(out.Format)
	if err != nil {
		return out, Classify(err)
	}
	rd, err := dataformat.NewDocumentReader(ctx, bytes.NewReader(sample), opts, false)
	if err != nil {
		return out, Classify(err)
	}
	docs, err := rd.Next(ctx)
	if err != nil && len(docs) == 0 && !errors.Is(err, io.EOF) {
		return out, Classify(err)
	}
	out.PreviewDocs = append(out.PreviewDocs, docs[:min(len(docs), previewDocuments)]...)
	return out, nil
}

func cutAtLastLine(sample []byte) []byte {
	if i := bytes.LastIndexByte(sample, '\n'); i > 0 {
		return sample[:i+1]
	}
	return sample
}

func detect(sample []byte, filename string, given Options) (Format, Options) {
	opts := given
	trimmed := bytes.TrimSpace(sample)
	switch ext := strings.ToLower(strings.TrimPrefix(filepath.Ext(filename), ".")); {
	case bytes.HasPrefix(sample, []byte(parquetMagic)) || ext == "parquet":
		return Parquet, opts
	case ext == "sql":
		return SQL, opts
	case trimmed[0] == '[':
		return JSON, opts
	case trimmed[0] == '{':
		return NDJSON, opts
	case ext == "tsv" || ext == "tab":
		return TSV, opts
	case ext == "csv":
		return CSV, withDelimiter(opts, sniffDelimiter(sample, ','))
	case looksLikeSQL(trimmed):
		return SQL, opts
	}
	switch d := sniffDelimiter(sample, ','); d {
	case '\t':
		return TSV, opts
	default:
		return CSV, withDelimiter(opts, d)
	}
}

func withDelimiter(opts Options, d rune) Options {
	if d != ',' && opts.Delimiter == "" {
		opts.Delimiter = string(d)
	}
	return opts
}

func looksLikeSQL(trimmed []byte) bool {
	head := strings.ToUpper(string(trimmed[:min(len(trimmed), 16)]))
	for _, prefix := range []string{"INSERT ", "CREATE ", "DROP ", "BEGIN", "START TRANS", "SET ", "USE ", "COPY ", "--", "/*", "PRAGMA ", "PRAGMA\t"} {
		if strings.HasPrefix(head, prefix) {
			return true
		}
	}
	return false
}

// sniffDelimiter picks the candidate that appears the same number of times on the most leading lines.
func sniffDelimiter(sample []byte, fallback rune) rune {
	lines := strings.SplitN(string(sample), "\n", 12)
	best, bestScore := fallback, 0
	for _, candidate := range []rune{',', '\t', ';', '|'} {
		counts := map[int]int{}
		for _, line := range lines[:min(len(lines), 10)] {
			if n := strings.Count(line, string(candidate)); n > 0 {
				counts[n]++
			}
		}
		for n, lineCount := range counts {
			if score := lineCount * n; lineCount >= 1 && n >= 1 && score > bestScore {
				best, bestScore = candidate, score
			}
		}
	}
	return best
}

// looksLikeHeader is true when the first record is all distinct words that no
// column would hold as data (no numbers, booleans, timestamps or UUIDs).
func looksLikeHeader(ctx context.Context, sample []byte, opts dataformat.Options) bool {
	opts.Header = false
	rd, err := dataformat.NewReader(ctx, bytes.NewReader(sample), opts, nil)
	if err != nil {
		return false
	}
	rows, err := rd.Next(ctx)
	if err != nil || len(rows) == 0 {
		return false
	}
	seen := map[string]bool{}
	for _, v := range rows[0] {
		if v.Kind != engine.VText || v.Str == "" || seen[v.Str] || len(v.Str) > 128 {
			return false
		}
		seen[v.Str] = true
		if dataformat.SniffKind(v.Str) != engine.VText {
			return false
		}
	}
	return true
}
