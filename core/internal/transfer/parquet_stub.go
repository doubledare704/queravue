//go:build !duckdb

package transfer

import (
	"context"
	"io"

	"github.com/doubledare704/queravue/core/internal/dataformat"
)

// ParquetAvailable reports whether this build links DuckDB for Parquet.
const ParquetAvailable = false

// ParquetConfig bounds the private DuckDB instance of one transfer.
type ParquetConfig struct {
	Dir         string
	MemoryLimit string
}

var errParquetUnavailable = &Error{Kind: KindUnsupported, Message: "Parquet needs a core built with DuckDB"}

// NewParquetWriter is not available in this build.
func NewParquetWriter(io.Writer, ParquetConfig) (dataformat.Writer, error) {
	return nil, errParquetUnavailable
}

// ParquetRows reads the rows of an uploaded Parquet file and removes its temporary files on Close.
type ParquetRows interface {
	RowReader
	Close()
}

// OpenParquetReader is not available in this build.
func OpenParquetReader(context.Context, io.Reader, ParquetConfig) (ParquetRows, error) {
	return nil, errParquetUnavailable
}

// InferParquet is not available in this build.
func InferParquet(context.Context, io.Reader, ParquetConfig) (Inferred, *Error) {
	return Inferred{}, errParquetUnavailable
}
