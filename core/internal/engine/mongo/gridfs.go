package mongo

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"math"
	"sort"
	"strings"
	"sync"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"

	"github.com/doubledare704/queravue/core/internal/engine"
)

var _ engine.GridFS = (*Conn)(nil)

const (
	// Strictly below MongoDB's 16 MiB BSON limit and the driver's 16 MiB upload buffer.
	maxGridFSChunkSize   = (16 << 20) - 4096
	maxCheapBucketCount  = 10_000
	gridfsCleanupTimeout = 10 * time.Second
	gridfsUploadCopyBuf  = 256 << 10
)

var errNoMoreRangeChunks = errors.New("no more range chunks")

func (c *Conn) gridfsDB(op, database string) (*mongo.Database, error) {
	cl, err := c.live(op)
	if err != nil {
		return nil, err
	}
	if database == "" {
		database = c.defaultDB
	}
	if database == "" {
		return nil, engine.Errorf(engine.KindInvalidConfig, c.id, op, "database is required")
	}
	return cl.Database(database), nil
}

func (c *Conn) gridfsBucket(op, database, bucket string) (*mongo.GridFSBucket, error) {
	db, err := c.gridfsDB(op, database)
	if err != nil {
		return nil, err
	}
	if bucket == "" {
		return nil, engine.Errorf(engine.KindInvalidConfig, c.id, op, "bucket is required")
	}
	return db.GridFSBucket(options.GridFSBucket().SetName(bucket)), nil
}

func detectBuckets(specs []mongo.CollectionSpecification) []string {
	files := map[string]bool{}
	chunks := map[string]bool{}
	for _, s := range specs {
		if s.Type == "view" || strings.HasPrefix(s.Name, "system.") {
			continue
		}
		if prefix, ok := strings.CutSuffix(s.Name, ".files"); ok && prefix != "" {
			files[prefix] = true
		}
		if prefix, ok := strings.CutSuffix(s.Name, ".chunks"); ok && prefix != "" {
			chunks[prefix] = true
		}
	}
	var names []string
	for name := range files {
		if chunks[name] {
			names = append(names, name)
		}
	}
	sort.Strings(names)
	return names
}

func rawIDFilter(field string, id bson.RawValue) bson.D {
	return bson.D{{Key: field, Value: bson.D{{Key: "$eq", Value: id}}}}
}

func bsonUint64(v bson.RawValue) (uint64, bool) {
	switch v.Type {
	case bson.TypeInt64:
		n := v.Int64()
		if n < 0 {
			return 0, false
		}
		return uint64(n), true
	case bson.TypeInt32:
		n := v.Int32()
		if n < 0 {
			return 0, false
		}
		return uint64(n), true
	case bson.TypeDouble:
		d := v.Double()
		if math.IsNaN(d) || math.IsInf(d, 0) || d < 0 || d >= math.Exp2(64) || math.Trunc(d) != d {
			return 0, false
		}
		return uint64(d), true
	default:
		return 0, false
	}
}

func bsonUint32(v bson.RawValue) (uint32, bool) {
	n, ok := bsonUint64(v)
	if !ok || n > math.MaxUint32 {
		return 0, false
	}
	return uint32(n), true
}

func gridFSContentType(raw bson.Raw) string {
	if meta, ok := raw.Lookup("metadata").DocumentOK(); ok {
		if ct, ok := meta.Lookup("contentType").StringValueOK(); ok && ct != "" {
			return ct
		}
	}
	if ct, ok := raw.Lookup("contentType").StringValueOK(); ok {
		return ct
	}
	return ""
}

func decodeGridFSFile(raw bson.Raw) (engine.GridFSFile, error) {
	idVal, err := raw.LookupErr("_id")
	if err != nil {
		return engine.GridFSFile{}, fmt.Errorf("mongo: decode gridfs file _id: %w", err)
	}
	idJSON, err := valueToEJSON(idVal)
	if err != nil {
		return engine.GridFSFile{}, err
	}
	f := engine.GridFSFile{
		ID:          idJSON,
		ContentType: gridFSContentType(raw),
	}
	if name, ok := raw.Lookup("filename").StringValueOK(); ok {
		f.Filename = name
	}
	if n, ok := bsonUint64(raw.Lookup("length")); ok {
		f.Length = n
	}
	if cs, ok := bsonUint32(raw.Lookup("chunkSize")); ok {
		f.ChunkSize = cs
	}
	if ms, ok := raw.Lookup("uploadDate").DateTimeOK(); ok {
		f.UploadDate = time.UnixMilli(ms).UTC()
	}
	if meta, ok := raw.Lookup("metadata").DocumentOK(); ok {
		mJSON, err := toEJSON(meta)
		if err != nil {
			return engine.GridFSFile{}, err
		}
		f.Metadata = mJSON
	}
	return f, nil
}

func buildUploadMetadata(metaEJSON, contentType string) (bson.D, error) {
	var doc bson.D
	if strings.TrimSpace(metaEJSON) != "" {
		raw, err := parseDocument(metaEJSON, false, engine.InputDocument)
		if err != nil {
			return nil, err
		}
		if err := bson.Unmarshal(raw, &doc); err != nil {
			return nil, &engine.Error{Kind: engine.KindParse, Engine: ID, Op: "parse", Input: engine.InputDocument,
				Msg: err.Error(), Err: err}
		}
	}
	if contentType != "" {
		replaced := false
		for i := range doc {
			if doc[i].Key == "contentType" {
				doc[i].Value = contentType
				replaced = true
				break
			}
		}
		if !replaced {
			doc = append(doc, bson.E{Key: "contentType", Value: contentType})
		}
	}
	if len(doc) == 0 {
		return nil, nil
	}
	return doc, nil
}

// ListBuckets implements engine.GridFS.
func (c *Conn) ListBuckets(ctx context.Context, database string) ([]engine.GridFSBucket, error) {
	db, err := c.gridfsDB("list buckets", database)
	if err != nil {
		return nil, err
	}
	specs, err := db.ListCollectionSpecifications(ctx, bson.D{})
	if err != nil {
		return nil, c.fail("list buckets", err)
	}
	names := detectBuckets(specs)
	out := make([]engine.GridFSBucket, len(names))
	for i, name := range names {
		out[i] = engine.GridFSBucket{Name: name}
	}

	sem := make(chan struct{}, 8)
	var wg sync.WaitGroup
	for i := range out {
		wg.Add(1)
		sem <- struct{}{}
		go func(b *engine.GridFSBucket) {
			defer wg.Done()
			defer func() { <-sem }()
			defer func() { _ = recover() }()
			cctx, cancel := context.WithTimeout(ctx, 2*time.Second)
			defer cancel()
			files := db.Collection(b.Name + ".files")
			n, err := files.EstimatedDocumentCount(cctx)
			if err != nil || n < 0 {
				return
			}
			b.FileCountEstimate = uint64(n)
			if b.FileCountEstimate > maxCheapBucketCount {
				return
			}
			cur, err := files.Aggregate(cctx, mongo.Pipeline{{{Key: "$group", Value: bson.D{
				{Key: "_id", Value: nil},
				{Key: "total", Value: bson.D{{Key: "$sum", Value: "$length"}}},
			}}}})
			if err != nil {
				return
			}
			defer closeCursor(cur)
			if cur.Next(cctx) {
				if total, ok := bsonUint64(cur.Current.Lookup("total")); ok {
					b.TotalBytes = &total
				}
				return
			}
			if cur.Err() == nil {
				var zero uint64
				b.TotalBytes = &zero
			}
		}(&out[i])
	}
	wg.Wait()
	return out, nil
}

// ListFiles implements engine.GridFS.
func (c *Conn) ListFiles(ctx context.Context, opt engine.GridFSListOptions, sink engine.GridFSFileSink) error {
	b, err := c.gridfsBucket("list files", opt.Database, opt.Bucket)
	if err != nil {
		return err
	}
	filter, err := optionalDoc(opt.Filter, engine.InputFilter)
	if err != nil {
		return c.parseErr(err)
	}
	if filter == nil {
		filter = bson.Raw{5, 0, 0, 0, 0}
	}
	sortDoc, err := optionalDoc(opt.Sort, engine.InputSort)
	if err != nil {
		return c.parseErr(err)
	}
	batch := int(opt.BatchSize)
	if batch <= 0 {
		batch = engine.MaxDocBatch
	}
	batch = min(batch, 5000)

	ctx, cancel := withTimeout(ctx, opt.MaxTimeMS)
	defer cancel()

	cur, err := openGridFSFilesCursor(ctx, b, filter, sortDoc, opt.Skip, opt.Limit, batch)
	if err != nil {
		return c.fail("list files", err)
	}
	defer closeCursor(cur)

	files := make([]engine.GridFSFile, 0, batch)
	size := 0
	flush := func() error {
		if len(files) == 0 {
			return nil
		}
		err := sink.Batch(files)
		files, size = files[:0], 0
		return err
	}
	for cur.Next(ctx) {
		f, err := decodeGridFSFile(cur.Current)
		if err != nil {
			return relabel(&engine.Error{Kind: engine.KindServer, Op: "list files", Msg: err.Error(), Err: err}, c.id)
		}
		files = append(files, f)
		size += len(f.ID) + len(f.Filename) + len(f.ContentType) + len(f.Metadata) + 64
		if len(files) >= batch || size >= engine.MaxDocBatchBytes {
			if err := flush(); err != nil {
				if errors.Is(err, engine.ErrStopDocs) {
					return nil
				}
				return err
			}
		}
	}
	if err := cur.Err(); err != nil {
		return c.fail("list files", err)
	}
	if err := flush(); err != nil && !errors.Is(err, engine.ErrStopDocs) {
		return err
	}
	return nil
}

func openGridFSFilesCursor(ctx context.Context, b *mongo.GridFSBucket, filter, sortDoc bson.Raw, skip, limit uint64, batch int) (*mongo.Cursor, error) {
	if skip <= math.MaxInt32 && limit <= math.MaxInt32 {
		fo := options.GridFSFind().SetBatchSize(int32(batch)) //nolint:gosec // batch <= 5000
		if sortDoc != nil {
			fo.SetSort(sortDoc)
		}
		if skip > 0 {
			fo.SetSkip(int32(skip))
		}
		if limit > 0 {
			fo.SetLimit(int32(limit))
		}
		cur, err := b.Find(ctx, filter, fo)
		if err != nil {
			return nil, fmt.Errorf("mongo: list gridfs files: %w", err)
		}
		return cur, nil
	}
	fo := options.Find().SetBatchSize(int32(batch)) //nolint:gosec // batch <= 5000
	if sortDoc != nil {
		fo.SetSort(sortDoc)
	}
	if skip > 0 {
		fo.SetSkip(int64(skip)) //nolint:gosec // bounded by server int64 range
	}
	if limit > 0 {
		fo.SetLimit(int64(limit)) //nolint:gosec // bounded by server int64 range
	}
	cur, err := b.GetFilesCollection().Find(ctx, filter, fo)
	if err != nil {
		return nil, fmt.Errorf("mongo: list gridfs files: %w", err)
	}
	return cur, nil
}

// OpenDownload implements engine.GridFS.
func (c *Conn) OpenDownload(ctx context.Context, database, bucket string, id engine.Document, offset uint64) (engine.GridFSFile, io.ReadCloser, error) {
	b, err := c.gridfsBucket("download", database, bucket)
	if err != nil {
		return engine.GridFSFile{}, nil, err
	}
	idv, err := parseValue(id, engine.InputDocument)
	if err != nil {
		return engine.GridFSFile{}, nil, c.parseErr(err)
	}
	raw, err := b.GetFilesCollection().FindOne(ctx, rawIDFilter("_id", idv)).Raw()
	if err != nil {
		if errors.Is(err, mongo.ErrNoDocuments) {
			return engine.GridFSFile{}, nil, engine.Errorf(engine.KindNotFound, c.id, "download", "file not found")
		}
		return engine.GridFSFile{}, nil, c.fail("download", err)
	}
	if lv, lerr := raw.LookupErr("length"); lerr == nil {
		if _, ok := bsonUint64(lv); !ok {
			return engine.GridFSFile{}, nil, engine.Errorf(engine.KindCorrupt, c.id, "download", "invalid file length")
		}
	}
	file, err := decodeGridFSFile(raw)
	if err != nil {
		return engine.GridFSFile{}, nil, c.fail("download", err)
	}
	if file.Length > 0 && (file.ChunkSize == 0 || file.ChunkSize > maxGridFSChunkSize) {
		return engine.GridFSFile{}, nil, engine.Errorf(engine.KindCorrupt, c.id, "download", "invalid chunk size %d", file.ChunkSize)
	}
	if file.Length == 0 || offset >= file.Length {
		return file, io.NopCloser(bytes.NewReader(nil)), nil
	}
	if offset == 0 {
		ds, err := b.OpenDownloadStream(ctx, idv)
		if err != nil {
			return engine.GridFSFile{}, nil, c.fail("download", err)
		}
		return file, &downloadStreamReader{conn: c, ds: ds}, nil
	}
	return c.openRangedDownload(ctx, b, idv, file, offset)
}

func (c *Conn) openRangedDownload(ctx context.Context, b *mongo.GridFSBucket, idv bson.RawValue, file engine.GridFSFile, offset uint64) (engine.GridFSFile, io.ReadCloser, error) {
	chunkSize := uint64(file.ChunkSize)
	startChunk := offset / chunkSize
	skipInFirst := int(offset % chunkSize) //nolint:gosec // modulo by chunkSize <= maxGridFSChunkSize
	numChunks := (file.Length + chunkSize - 1) / chunkSize

	var startVal any
	if startChunk <= math.MaxInt32 {
		startVal = int32(startChunk)
	} else {
		startVal = int64(startChunk) //nolint:gosec // bounded by file length / chunk size
	}
	filter := bson.D{
		{Key: "files_id", Value: bson.D{{Key: "$eq", Value: idv}}},
		{Key: "n", Value: bson.D{{Key: "$gte", Value: startVal}}},
	}
	cur, err := b.GetChunksCollection().Find(ctx, filter, options.Find().SetSort(bson.D{{Key: "n", Value: 1}}))
	if err != nil {
		return engine.GridFSFile{}, nil, c.fail("download", err)
	}
	return file, &rangeDownloadReader{
		conn:          c,
		ctx:           ctx,
		cur:           cur,
		buf:           make([]byte, file.ChunkSize),
		chunkSize:     file.ChunkSize,
		fileLen:       file.Length,
		numChunks:     numChunks,
		expectedChunk: startChunk,
		skipInFirst:   skipInFirst,
	}, nil
}

func (c *Conn) classifyDownloadErr(err error) error {
	if strings.Contains(err.Error(), "element not found") {
		return &engine.Error{Kind: engine.KindCorrupt, Engine: c.id, Op: "download", Msg: err.Error(), Err: err}
	}
	return c.fail("download", err)
}

type downloadStreamReader struct {
	conn      *Conn
	ds        *mongo.GridFSDownloadStream
	closeOnce sync.Once
	closeErr  error
}

func (r *downloadStreamReader) Read(p []byte) (int, error) {
	n, err := r.ds.Read(p)
	if err != nil && !errors.Is(err, io.EOF) {
		return n, r.conn.classifyDownloadErr(err)
	}
	return n, err //nolint:wrapcheck // io.Reader contract requires raw io.EOF
}

func (r *downloadStreamReader) Close() error {
	r.closeOnce.Do(func() {
		if err := r.ds.Close(); err != nil && !errors.Is(err, mongo.ErrStreamClosed) {
			r.closeErr = r.conn.fail("download", err)
		}
	})
	return r.closeErr
}

type rangeDownloadReader struct {
	conn          *Conn
	ctx           context.Context
	cur           *mongo.Cursor
	buf           []byte
	bufStart      int
	bufEnd        int
	chunkSize     uint32
	fileLen       uint64
	numChunks     uint64
	expectedChunk uint64
	skipInFirst   int
	done          bool
	closed        bool
	closeOnce     sync.Once
}

func (r *rangeDownloadReader) Read(p []byte) (int, error) {
	if r.closed {
		return 0, r.conn.fail("download", mongo.ErrStreamClosed)
	}
	if r.done {
		return 0, io.EOF
	}
	bytesCopied := 0
	for bytesCopied < len(p) {
		if r.bufStart >= r.bufEnd {
			if err := r.fillBuffer(); err != nil {
				if errors.Is(err, errNoMoreRangeChunks) {
					if bytesCopied == 0 {
						r.done = true
						return 0, io.EOF
					}
					return bytesCopied, nil
				}
				return bytesCopied, err
			}
		}
		n := copy(p[bytesCopied:], r.buf[r.bufStart:r.bufEnd])
		bytesCopied += n
		r.bufStart += n
	}
	return bytesCopied, nil
}

func (r *rangeDownloadReader) fillBuffer() error {
	if !r.cur.Next(r.ctx) {
		r.done = true
		if err := r.cur.Err(); err != nil {
			closeCursor(r.cur)
			return r.conn.fail("download", err)
		}
		if r.expectedChunk != r.numChunks {
			return engine.Errorf(engine.KindCorrupt, r.conn.id, "download", "missing chunk %d of %d", r.expectedChunk, r.numChunks)
		}
		return errNoMoreRangeChunks
	}
	nVal, err := r.cur.Current.LookupErr("n")
	if err != nil {
		return engine.Errorf(engine.KindCorrupt, r.conn.id, "download", "chunk missing n field")
	}
	idx, ok := bsonUint64(nVal)
	if !ok {
		return engine.Errorf(engine.KindCorrupt, r.conn.id, "download", "chunk has invalid n field")
	}
	if idx != r.expectedChunk {
		return engine.Errorf(engine.KindCorrupt, r.conn.id, "download", "missing chunk %d (got %d)", r.expectedChunk, idx)
	}
	dataVal, err := r.cur.Current.LookupErr("data")
	if err != nil {
		return engine.Errorf(engine.KindCorrupt, r.conn.id, "download", "chunk %d missing data field", idx)
	}
	_, dataBytes, ok := dataVal.BinaryOK()
	if !ok {
		return engine.Errorf(engine.KindCorrupt, r.conn.id, "download", "chunk %d data is not binary", idx)
	}

	expectedLen := uint64(r.chunkSize)
	if r.expectedChunk+1 == r.numChunks {
		expectedLen = r.fileLen - r.expectedChunk*uint64(r.chunkSize)
	}
	if uint64(len(dataBytes)) != expectedLen {
		return engine.Errorf(engine.KindCorrupt, r.conn.id, "download", "chunk %d length %d does not match expected %d", idx, len(dataBytes), expectedLen)
	}

	copied := copy(r.buf, dataBytes)
	start := 0
	if r.skipInFirst > 0 {
		if r.skipInFirst >= copied {
			return engine.Errorf(engine.KindCorrupt, r.conn.id, "download", "chunk %d shorter than offset", idx)
		}
		start = r.skipInFirst
		r.skipInFirst = 0
	}
	r.bufStart = start
	r.bufEnd = copied
	r.expectedChunk++
	return nil
}

func (r *rangeDownloadReader) Close() error {
	r.closeOnce.Do(func() {
		r.closed = true
		if r.cur != nil {
			closeCursor(r.cur)
		}
	})
	return nil
}

// Upload implements engine.GridFS.
func (c *Conn) Upload(ctx context.Context, u engine.GridFSUpload, r io.Reader) (engine.GridFSFile, error) {
	b, err := c.gridfsBucket("upload", u.Database, u.Bucket)
	if err != nil {
		return engine.GridFSFile{}, err
	}
	if u.Filename == "" {
		return engine.GridFSFile{}, engine.Errorf(engine.KindInvalidConfig, c.id, "upload", "filename is required")
	}
	if u.ChunkSizeBytes > maxGridFSChunkSize {
		return engine.GridFSFile{}, engine.Errorf(engine.KindInvalidConfig, c.id, "upload", "chunk size %d exceeds maximum %d", u.ChunkSizeBytes, maxGridFSChunkSize)
	}
	if r == nil {
		r = bytes.NewReader(nil)
	}

	var replaceID bson.RawValue
	hasReplace := strings.TrimSpace(u.ReplaceID) != ""
	if hasReplace {
		replaceID, err = parseValue(strings.TrimSpace(u.ReplaceID), engine.InputDocument)
		if err != nil {
			return engine.GridFSFile{}, c.parseErr(err)
		}
	}

	meta, err := buildUploadMetadata(u.Metadata, u.ContentType)
	if err != nil {
		return engine.GridFSFile{}, c.parseErr(err)
	}

	uploadOpts := options.GridFSUpload()
	if u.ChunkSizeBytes > 0 {
		uploadOpts.SetChunkSizeBytes(int32(u.ChunkSizeBytes))
	}
	if meta != nil {
		uploadOpts.SetMetadata(meta)
	}

	us, err := b.OpenUploadStream(ctx, u.Filename, uploadOpts)
	if err != nil {
		return engine.GridFSFile{}, c.fail("upload", err)
	}

	abort := func(removeFileDoc bool) {
		// Driver Abort() reuses the upload ctx, which fails if ctx was cancelled; fall back to a fresh ctx.
		if aerr := us.Abort(); aerr != nil || ctx.Err() != nil {
			cleanCtx, cancel := context.WithTimeout(context.Background(), gridfsCleanupTimeout)
			defer cancel()
			_, _ = b.GetChunksCollection().DeleteMany(cleanCtx, bson.D{{Key: "files_id", Value: bson.D{{Key: "$eq", Value: us.FileID}}}})
			if removeFileDoc {
				_, _ = b.GetFilesCollection().DeleteOne(cleanCtx, bson.D{{Key: "_id", Value: bson.D{{Key: "$eq", Value: us.FileID}}}})
			}
		}
	}

	buf := make([]byte, gridfsUploadCopyBuf)
	for {
		if err := ctx.Err(); err != nil {
			abort(false)
			return engine.GridFSFile{}, c.fail("upload", err)
		}
		n, rerr := r.Read(buf)
		if n > 0 {
			if _, werr := us.Write(buf[:n]); werr != nil {
				abort(false)
				return engine.GridFSFile{}, c.fail("upload", werr)
			}
		}
		if errors.Is(rerr, io.EOF) {
			break
		}
		if rerr != nil {
			abort(false)
			if cerr := ctx.Err(); cerr != nil {
				return engine.GridFSFile{}, c.fail("upload", cerr)
			}
			return engine.GridFSFile{}, c.fail("upload", rerr)
		}
	}

	if err := us.Close(); err != nil {
		abort(true)
		return engine.GridFSFile{}, c.fail("upload", err)
	}

	raw, err := b.GetFilesCollection().FindOne(ctx, bson.D{{Key: "_id", Value: bson.D{{Key: "$eq", Value: us.FileID}}}}).Raw()
	if err != nil {
		return engine.GridFSFile{}, c.fail("upload", err)
	}
	file, err := decodeGridFSFile(raw)
	if err != nil {
		return engine.GridFSFile{}, c.fail("upload", err)
	}

	if hasReplace {
		if derr := b.Delete(ctx, replaceID); derr != nil && !errors.Is(derr, mongo.ErrFileNotFound) {
			return file, c.fail("upload", derr)
		}
	}
	return file, nil
}

// DeleteFile implements engine.GridFS.
func (c *Conn) DeleteFile(ctx context.Context, database, bucket string, id engine.Document) error {
	b, err := c.gridfsBucket("delete", database, bucket)
	if err != nil {
		return err
	}
	idv, err := parseValue(id, engine.InputDocument)
	if err != nil {
		return c.parseErr(err)
	}
	if err := b.Delete(ctx, idv); err != nil {
		return c.fail("delete", err)
	}
	return nil
}

// RenameFile implements engine.GridFS.
func (c *Conn) RenameFile(ctx context.Context, database, bucket string, id engine.Document, filename string) error {
	b, err := c.gridfsBucket("rename", database, bucket)
	if err != nil {
		return err
	}
	if filename == "" {
		return engine.Errorf(engine.KindInvalidConfig, c.id, "rename", "filename is required")
	}
	idv, err := parseValue(id, engine.InputDocument)
	if err != nil {
		return c.parseErr(err)
	}
	if err := b.Rename(ctx, idv, filename); err != nil {
		return c.fail("rename", err)
	}
	return nil
}
