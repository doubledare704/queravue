package transfer

import (
	"fmt"
	"strings"
	"unicode/utf8"

	"github.com/doubledare704/queravue/core/internal/dataformat"
)

// Format is a file format.
type Format uint8

// File formats.
const (
	CSV Format = iota + 1
	TSV
	JSON
	NDJSON
	SQL
	Parquet
)

// Extension is the file extension of f, without the dot.
func (f Format) Extension() string {
	switch f {
	case CSV:
		return "csv"
	case TSV:
		return "tsv"
	case JSON:
		return "json"
	case NDJSON:
		return "ndjson"
	case SQL:
		return "sql"
	case Parquet:
		return "parquet"
	}
	return "bin"
}

func (f Format) delimited() bool { return f == CSV || f == TSV }

func (f Format) dataformat() dataformat.Format {
	switch f {
	case TSV:
		return dataformat.TSV
	case JSON:
		return dataformat.JSON
	case NDJSON:
		return dataformat.NDJSON
	case SQL:
		return dataformat.SQL
	}
	return dataformat.CSV
}

// Formats lists what this build imports and exports.
func Formats() (imports, exports []Format) {
	all := []Format{CSV, TSV, JSON, NDJSON, SQL}
	if ParquetAvailable {
		all = append(all, Parquet)
	}
	return all, all
}

// Options tunes a format; fields that do not apply to it are ignored.
type Options struct {
	Delimiter     string
	Quote         string
	Header        bool
	NullText      string
	CanonicalJSON bool
	SQLIncludeDDL bool
	SQLTable      string
}

// DataformatOptions are the reader and writer options for f.
func (o Options) DataformatOptions(f Format) (dataformat.Options, error) {
	out := dataformat.Options{Format: f.dataformat(), Header: o.Header, NullText: o.NullText}
	var err error
	if out.Delimiter, err = singleRune("delimiter", o.Delimiter); err != nil {
		return out, err
	}
	out.Quote, err = singleRune("quote", o.Quote)
	return out, err
}

func singleRune(name, s string) (rune, error) {
	switch {
	case s == "":
		return 0, nil
	case s == `\t`:
		return '\t', nil
	case utf8.RuneCountInString(s) != 1:
		return 0, newError(KindParse, "%s must be a single character", name)
	}
	r, _ := utf8.DecodeRuneInString(s)
	return r, nil
}

func fileStem(name string) string {
	name = strings.TrimSpace(name)
	if name == "" {
		return "export"
	}
	return strings.Map(func(r rune) rune {
		if strings.ContainsRune(`/\:*?"<>|`, r) || r < ' ' {
			return '_'
		}
		return r
	}, name)
}

// SuggestedFilename is the name a save dialog proposes.
func SuggestedFilename(stem string, f Format) string {
	return fmt.Sprintf("%s.%s", fileStem(stem), f.Extension())
}
