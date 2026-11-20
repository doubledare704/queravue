package engine

import (
	"context"
	"io"
	"time"
)

// GridFSBucket is one bucket: a <Name>.files and <Name>.chunks collection pair.
type GridFSBucket struct {
	Name              string
	FileCountEstimate uint64
	TotalBytes        *uint64
}

// GridFSFile is one entry of a bucket's files collection.
type GridFSFile struct {
	ID          Document
	Filename    string
	Length      uint64
	ChunkSize   uint32
	UploadDate  time.Time
	ContentType string
	// Metadata is canonical EJSON, or empty when the file has none.
	Metadata Document
}

// GridFSListOptions selects files. Filter and Sort are Extended JSON text.
type GridFSListOptions struct {
	Database, Bucket string
	Filter, Sort     string
	Skip, Limit      uint64
	BatchSize        uint32
	MaxTimeMS        uint32
}

// GridFSFileSink receives listed files in batches; returning an error stops
// the listing.
type GridFSFileSink interface {
	Batch(files []GridFSFile) error
}

// GridFSUpload describes a file to store. A non-empty ReplaceID removes that
// file once the new one is stored.
type GridFSUpload struct {
	Database, Bucket string
	Filename         string
	ContentType      string
	Metadata         Document
	ChunkSizeBytes   uint32
	ReplaceID        Document
}

// GridFS is implemented by Conns with CapGridFS (ADR 0023). File bytes are
// streamed through readers and writers; no method holds a whole file.
type GridFS interface {
	ListBuckets(ctx context.Context, database string) ([]GridFSBucket, error)
	ListFiles(ctx context.Context, opt GridFSListOptions, sink GridFSFileSink) error
	// OpenDownload returns the file and a reader positioned at offset.
	OpenDownload(ctx context.Context, database, bucket string, id Document, offset uint64) (GridFSFile, io.ReadCloser, error)
	// Upload reads r to EOF; when ctx is cancelled or r fails, the chunks
	// written so far are removed.
	Upload(ctx context.Context, u GridFSUpload, r io.Reader) (GridFSFile, error)
	DeleteFile(ctx context.Context, database, bucket string, id Document) error
	RenameFile(ctx context.Context, database, bucket string, id Document, filename string) error
}
