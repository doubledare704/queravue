// Package dataformat streams file records between transfer sources and engine values.
package dataformat

import (
	"errors"
	"fmt"
	"strings"
	"unicode/utf8"
)

// MaxBatchBytes is the decoded batch target; larger records travel alone.
const MaxBatchBytes = 1 << 20

const defaultMaxRecordBytes = 64 << 20
const valueBudget = 96

// Format selects a wire representation for rows or documents.
type Format uint8

// Supported file representations.
const (
	CSV Format = iota
	TSV
	JSON
	NDJSON
	SQL
)

// Options configures UTF-8 records, with separate batch and single-record byte limits.
type Options struct {
	Format         Format
	Delimiter      rune
	Quote          rune
	NullText       string
	Header         bool
	BOM            bool
	Encoding       string
	MaxBytes       int
	MaxRecordBytes int
}

func (o *Options) normalize() error {
	if o.Encoding != "" && !strings.EqualFold(o.Encoding, "UTF-8") && !strings.EqualFold(o.Encoding, "UTF8") {
		return &ParseError{Line: 1, Column: 1, Err: errEncoding}
	}
	if o.MaxBytes < 0 || o.MaxBytes > MaxBatchBytes {
		return fmt.Errorf("dataformat: byte limit must be between 0 and %d", MaxBatchBytes)
	}
	if o.MaxBytes == 0 {
		o.MaxBytes = MaxBatchBytes
	}
	if o.MaxRecordBytes < 0 {
		return errors.New("dataformat: negative record byte limit")
	}
	if o.MaxRecordBytes == 0 {
		o.MaxRecordBytes = defaultMaxRecordBytes
	}
	if o.Format > SQL {
		return fmt.Errorf("dataformat: unknown format %d", o.Format)
	}
	if o.Format != CSV && o.Format != TSV {
		return nil
	}
	if o.Delimiter == 0 {
		o.Delimiter = ','
		if o.Format == TSV {
			o.Delimiter = '\t'
		}
	}
	if o.Quote == 0 {
		o.Quote = '"'
	}
	if !validSeparator(o.Delimiter) || !validSeparator(o.Quote) || o.Delimiter == o.Quote {
		return errors.New("dataformat: invalid delimiter or quote")
	}
	if strings.HasPrefix(o.NullText, "\ufeff") || !utf8.ValidString(o.NullText) || strings.ContainsAny(o.NullText, string(o.Delimiter)+string(o.Quote)+"\r\n\x00") {
		return errors.New("dataformat: null text must be a valid unquoted field")
	}
	return nil
}

func validSeparator(r rune) bool {
	return utf8.ValidRune(r) && !strings.ContainsRune("\x00\r\n\ufeff", r)
}

var errEncoding = errors.New("unsupported encoding or invalid UTF-8")
var errRecordSize = errors.New("record exceeds byte limit")

// ParseError identifies the 1-based line and byte column and the 0-based file offset.
type ParseError struct {
	Line   int64
	Column int64
	Offset int64
	Err    error
}

func (e *ParseError) Error() string {
	return fmt.Sprintf("dataformat: line %d, column %d (byte offset %d): %v", e.Line, e.Column, e.Offset, e.Err)
}

func (e *ParseError) Unwrap() error { return e.Err }
