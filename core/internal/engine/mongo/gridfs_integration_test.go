//go:build integration

package mongo

import (
	"bytes"
	"context"
	"crypto/sha256"
	"errors"
	"fmt"
	"hash"
	"io"
	"os"
	"os/exec"
	"runtime"
	"runtime/metrics"
	"runtime/pprof"
	"strconv"
	"strings"
	"testing"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func scratchBucket(t *testing.T, c *Conn) string {
	t.Helper()
	name := fmt.Sprintf("gfs_%d", time.Now().UnixNano())
	client := c.client
	t.Cleanup(func() {
		dctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
		defer cancel()
		_ = client.Database("queravue").Collection(name + ".files").Drop(dctx)
		_ = client.Database("queravue").Collection(name + ".chunks").Drop(dctx)
	})
	return name
}

type fileCollector struct {
	files   []engine.GridFSFile
	batches int
	offsets []uint64
}

func (f *fileCollector) Batch(files []engine.GridFSFile) error {
	f.batches++
	f.offsets = append(f.offsets, uint64(len(f.files)))
	f.files = append(f.files, files...)
	return nil
}

func readAllGridFS(ctx context.Context, t *testing.T, c *Conn, db, bucket, id string, offset uint64) (engine.GridFSFile, []byte) {
	t.Helper()
	file, rc, err := c.OpenDownload(ctx, db, bucket, id, offset)
	if err != nil {
		t.Fatalf("OpenDownload(offset=%d): %v", offset, err)
	}
	defer func() { _ = rc.Close() }()
	data, err := io.ReadAll(rc)
	if err != nil {
		t.Fatalf("ReadAll(offset=%d): %v", offset, err)
	}
	return file, data
}

func TestIntegrationGridFSBucketDiscoveryAndCRUD(t *testing.T) {
	c := connect(t)
	ctx := context.Background()
	bucketA := scratchBucket(t, c)
	bucketB := scratchBucket(t, c)
	orphan := fmt.Sprintf("orphan_%d.files", time.Now().UnixNano())
	if err := c.client.Database("queravue").CreateCollection(ctx, orphan); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = c.client.Database("queravue").Collection(orphan).Drop(context.Background()) })

	payload1 := []byte("hello gridfs world")
	payload2 := bytes.Repeat([]byte{0x42}, 512)
	f1, err := c.Upload(ctx, engine.GridFSUpload{
		Database:    "queravue",
		Bucket:      bucketA,
		Filename:    "alpha.txt",
		ContentType: "text/plain",
		Metadata:    `{"tag":"first","n":1}`,
	}, bytes.NewReader(payload1))
	if err != nil {
		t.Fatalf("Upload 1: %v", err)
	}
	if f1.Filename != "alpha.txt" || f1.Length != uint64(len(payload1)) || f1.ContentType != "text/plain" || !strings.Contains(f1.Metadata, `"tag":"first"`) {
		t.Fatalf("f1 = %+v", f1)
	}

	f2, err := c.Upload(ctx, engine.GridFSUpload{
		Database:    "queravue",
		Bucket:      bucketA,
		Filename:    "beta.bin",
		ContentType: "application/octet-stream",
	}, bytes.NewReader(payload2))
	if err != nil {
		t.Fatalf("Upload 2: %v", err)
	}

	if _, err := c.Upload(ctx, engine.GridFSUpload{
		Database: "queravue",
		Bucket:   bucketB,
		Filename: "other.txt",
	}, bytes.NewReader([]byte("other"))); err != nil {
		t.Fatalf("Upload bucketB: %v", err)
	}

	// Bucket discovery: finds both pairs, ignores unpaired .files collection.
	buckets, err := c.ListBuckets(ctx, "queravue")
	if err != nil {
		t.Fatal(err)
	}
	byName := map[string]engine.GridFSBucket{}
	for _, b := range buckets {
		byName[b.Name] = b
	}
	orphanPrefix := strings.TrimSuffix(orphan, ".files")
	if _, has := byName[orphanPrefix]; has {
		t.Errorf("unpaired collection %q reported as bucket", orphanPrefix)
	}
	bA, okA := byName[bucketA]
	bB, okB := byName[bucketB]
	if !okA || !okB {
		t.Fatalf("missing buckets in %+v", buckets)
	}
	if bA.FileCountEstimate != 2 || bA.TotalBytes == nil || *bA.TotalBytes != uint64(len(payload1)+len(payload2)) {
		t.Errorf("bucketA = %+v", bA)
	}
	if bB.FileCountEstimate != 1 || bB.TotalBytes == nil || *bB.TotalBytes != 5 {
		t.Errorf("bucketB = %+v", bB)
	}

	// ListFiles: filter, sort, skip, limit, batching.
	var all fileCollector
	if err := c.ListFiles(ctx, engine.GridFSListOptions{
		Database:  "queravue",
		Bucket:    bucketA,
		Sort:      `{"length":-1}`,
		BatchSize: 1,
	}, &all); err != nil {
		t.Fatal(err)
	}
	if all.batches != 2 || len(all.files) != 2 || all.files[0].ID != f2.ID || all.files[1].ID != f1.ID {
		t.Errorf("sorted list = %+v", all)
	}

	var filtered fileCollector
	if err := c.ListFiles(ctx, engine.GridFSListOptions{
		Database: "queravue",
		Bucket:   bucketA,
		Filter:   `{"metadata.n": 1}`,
	}, &filtered); err != nil {
		t.Fatal(err)
	}
	if len(filtered.files) != 1 || filtered.files[0].ID != f1.ID {
		t.Errorf("filtered = %+v", filtered.files)
	}

	// Download full.
	_, got1 := readAllGridFS(ctx, t, c, "queravue", bucketA, f1.ID, 0)
	if !bytes.Equal(got1, payload1) {
		t.Errorf("downloaded = %q, want %q", got1, payload1)
	}

	// RenameFile.
	if err := c.RenameFile(ctx, "queravue", bucketA, f1.ID, "alpha-renamed.txt"); err != nil {
		t.Fatal(err)
	}
	gotMeta, _ := readAllGridFS(ctx, t, c, "queravue", bucketA, f1.ID, 0)
	if gotMeta.Filename != "alpha-renamed.txt" {
		t.Errorf("renamed filename = %q", gotMeta.Filename)
	}

	// Replace upload removes previous file + chunks.
	payload3 := []byte("replacement bytes")
	f3, err := c.Upload(ctx, engine.GridFSUpload{
		Database:  "queravue",
		Bucket:    bucketA,
		Filename:  "gamma.txt",
		ReplaceID: f1.ID,
	}, bytes.NewReader(payload3))
	if err != nil {
		t.Fatal(err)
	}
	if _, _, err := c.OpenDownload(ctx, "queravue", bucketA, f1.ID, 0); engine.KindOf(err) != engine.KindNotFound {
		t.Errorf("replaced file download err = %v, want KindNotFound", err)
	}
	_, got3 := readAllGridFS(ctx, t, c, "queravue", bucketA, f3.ID, 0)
	if !bytes.Equal(got3, payload3) {
		t.Errorf("replacement data = %q", got3)
	}

	// DeleteFile + not found + parse errors.
	if err := c.DeleteFile(ctx, "queravue", bucketA, f3.ID); err != nil {
		t.Fatal(err)
	}
	if err := c.DeleteFile(ctx, "queravue", bucketA, f2.ID); err != nil {
		t.Fatal(err)
	}
	if err := c.DeleteFile(ctx, "queravue", bucketA, f2.ID); engine.KindOf(err) != engine.KindNotFound {
		t.Errorf("double delete err = %v, want KindNotFound", err)
	}
	if err := c.ListFiles(ctx, engine.GridFSListOptions{Database: "queravue", Bucket: bucketA, Filter: `{`}, &fileCollector{}); engine.KindOf(err) != engine.KindParse {
		t.Errorf("bad filter err = %v, want KindParse", err)
	}
	if _, _, err := c.OpenDownload(ctx, "queravue", bucketA, `{`, 0); engine.KindOf(err) != engine.KindParse {
		t.Errorf("bad id err = %v, want KindParse", err)
	}
}

func TestIntegrationGridFSChunkBoundaries(t *testing.T) {
	c := connect(t)
	ctx := context.Background()
	bucket := scratchBucket(t, c)
	const chunkSize = 4096
	for _, size := range []int{0, chunkSize, 3*chunkSize + 1} {
		t.Run(strconv.Itoa(size), func(t *testing.T) {
			data := bytes.Repeat([]byte{0x65}, size)
			file, err := c.Upload(ctx, engine.GridFSUpload{Database: "queravue", Bucket: bucket, Filename: "boundary", ChunkSizeBytes: chunkSize}, bytes.NewReader(data))
			if err != nil {
				t.Fatal(err)
			}
			if file.Length != uint64(size) {
				t.Fatalf("length = %d, want %d", file.Length, size)
			}
			_, got := readAllGridFS(ctx, t, c, "queravue", bucket, file.ID, 0)
			if !bytes.Equal(got, data) {
				t.Fatal("round-trip mismatch")
			}
			id, err := parseValue(file.ID, engine.InputDocument)
			if err != nil {
				t.Fatal(err)
			}
			count, err := c.client.Database("queravue").Collection(bucket+".chunks").CountDocuments(ctx, rawIDFilter("files_id", id))
			if err != nil {
				t.Fatal(err)
			}
			if want := int64((size + chunkSize - 1) / chunkSize); count != want {
				t.Fatalf("chunks = %d, want %d", count, want)
			}
		})
	}
}

func TestIntegrationGridFSUploadCreatesIndexes(t *testing.T) {
	c := connect(t)
	ctx := context.Background()
	bucket := scratchBucket(t, c)
	_, err := c.Upload(ctx, engine.GridFSUpload{Database: "queravue", Bucket: bucket, Filename: "empty"}, bytes.NewReader(nil))
	if err != nil {
		t.Fatal(err)
	}
	for _, tc := range []struct {
		collection string
		name       string
		unique     bool
	}{
		{bucket + ".files", "filename_1_uploadDate_1", false},
		{bucket + ".chunks", "files_id_1_n_1", true},
	} {
		cursor, err := c.client.Database("queravue").Collection(tc.collection).Indexes().List(ctx)
		if err != nil {
			t.Fatal(err)
		}
		found := false
		for cursor.Next(ctx) {
			if cursor.Current.Lookup("name").StringValue() == tc.name {
				found = true
				if tc.unique && !cursor.Current.Lookup("unique").Boolean() {
					t.Fatalf("index %s is not unique", tc.name)
				}
			}
		}
		if err := cursor.Err(); err != nil {
			t.Fatal(err)
		}
		_ = cursor.Close(ctx)
		if !found {
			t.Fatalf("index %s not found", tc.name)
		}
	}
}

func TestIntegrationGridFSRangedDownload(t *testing.T) {
	c := connect(t)
	ctx := context.Background()
	bucket := scratchBucket(t, c)

	const size = 1 << 20 // 1 MiB
	const chunk = 64 << 10
	payload := make([]byte, size)
	for i := range payload {
		payload[i] = byte(i*31 + (i >> 8))
	}
	file, err := c.Upload(ctx, engine.GridFSUpload{
		Database:       "queravue",
		Bucket:         bucket,
		Filename:       "ranged.bin",
		ChunkSizeBytes: chunk,
	}, bytes.NewReader(payload))
	if err != nil {
		t.Fatal(err)
	}

	offsets := []uint64{0, 1234, chunk, chunk + 500, size - 17, size, size + 500}
	for _, off := range offsets {
		_, got := readAllGridFS(ctx, t, c, "queravue", bucket, file.ID, off)
		var want []byte
		if off < uint64(len(payload)) {
			want = payload[off:]
		}
		if !bytes.Equal(got, want) {
			t.Errorf("offset=%d: got %d bytes, want %d bytes", off, len(got), len(want))
		}
	}
}

func TestIntegrationGridFSCorruptDetection(t *testing.T) {
	c := connect(t)
	ctx := context.Background()
	bucket := scratchBucket(t, c)
	chunksColl := c.client.Database("queravue").Collection(bucket + ".chunks")

	payload := bytes.Repeat([]byte{0x7e}, 200<<10) // 4 chunks of 64 KiB (last = 8 KiB)
	upload := func(name string) engine.GridFSFile {
		f, err := c.Upload(ctx, engine.GridFSUpload{
			Database:       "queravue",
			Bucket:         bucket,
			Filename:       name,
			ChunkSizeBytes: 64 << 10,
		}, bytes.NewReader(payload))
		if err != nil {
			t.Fatal(err)
		}
		return f
	}
	rawID := func(idJSON string) bson.RawValue {
		v, err := parseValue(idJSON, engine.InputDocument)
		if err != nil {
			t.Fatal(err)
		}
		return v
	}
	expectCorrupt := func(idJSON string, off uint64) {
		t.Helper()
		_, rc, err := c.OpenDownload(ctx, "queravue", bucket, idJSON, off)
		if err != nil {
			if engine.KindOf(err) != engine.KindCorrupt {
				t.Fatalf("OpenDownload(%d) err = %v, want KindCorrupt", off, err)
			}
			return
		}
		defer func() { _ = rc.Close() }()
		if _, err := io.ReadAll(rc); engine.KindOf(err) != engine.KindCorrupt {
			t.Fatalf("ReadAll(%d) err = %v, want KindCorrupt", off, err)
		}
	}

	// Missing middle chunk.
	f1 := upload("missing-middle.bin")
	if _, err := chunksColl.DeleteOne(ctx, bson.D{{Key: "files_id", Value: rawID(f1.ID)}, {Key: "n", Value: int32(1)}}); err != nil {
		t.Fatal(err)
	}
	expectCorrupt(f1.ID, 0)
	expectCorrupt(f1.ID, 70_000)

	// Short intermediate chunk.
	f2 := upload("short-chunk.bin")
	if _, err := chunksColl.UpdateOne(ctx,
		bson.D{{Key: "files_id", Value: rawID(f2.ID)}, {Key: "n", Value: int32(1)}},
		bson.D{{Key: "$set", Value: bson.D{{Key: "data", Value: bson.Binary{Subtype: 0, Data: []byte{1, 2, 3}}}}}},
	); err != nil {
		t.Fatal(err)
	}
	expectCorrupt(f2.ID, 0)
	expectCorrupt(f2.ID, 64<<10)

	// Missing trailing chunk.
	f3 := upload("missing-end.bin")
	if _, err := chunksColl.DeleteOne(ctx, bson.D{{Key: "files_id", Value: rawID(f3.ID)}, {Key: "n", Value: int32(3)}}); err != nil {
		t.Fatal(err)
	}
	expectCorrupt(f3.ID, 0)
	expectCorrupt(f3.ID, 192<<10)
}

func TestIntegrationGridFSDownloadDetectsCorruptionAfterFirstBatch(t *testing.T) {
	c := connect(t)
	ctx := context.Background()
	bucket := scratchBucket(t, c)
	payload := bytes.Repeat([]byte{0x7e}, 5<<20)
	file, err := c.Upload(ctx, engine.GridFSUpload{
		Database: "queravue", Bucket: bucket, Filename: "corrupt-later.bin", ChunkSizeBytes: 64 << 10,
	}, bytes.NewReader(payload))
	if err != nil {
		t.Fatal(err)
	}
	id, err := parseValue(file.ID, engine.InputDocument)
	if err != nil {
		t.Fatal(err)
	}
	chunks := c.client.Database("queravue").Collection(bucket + ".chunks")
	if _, err := chunks.DeleteOne(ctx, bson.D{{Key: "files_id", Value: id}, {Key: "n", Value: int32(65)}}); err != nil {
		t.Fatal(err)
	}
	_, reader, err := c.OpenDownload(ctx, "queravue", bucket, file.ID, 0)
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = reader.Close() }()
	if _, err := io.Copy(io.Discard, reader); engine.KindOf(err) != engine.KindCorrupt {
		t.Fatalf("download error = %v, want corrupt", err)
	}
}

// gatedChunkReader emits >16 MiB so the driver flushes at least one chunk
// batch to MongoDB, waits until chunks appear in the collection, and then
// triggers fn().
type gatedChunkReader struct {
	remaining int64
	chunks    *mongo.Collection
	baseCount int64
	triggered bool
	onTrigger func() error
}

func (r *gatedChunkReader) Read(p []byte) (int, error) {
	if !r.triggered {
		n, err := r.chunks.CountDocuments(context.Background(), bson.D{})
		if err == nil && n > r.baseCount {
			r.triggered = true
			if err := r.onTrigger(); err != nil {
				return 0, err
			}
		}
	}
	if r.remaining <= 0 {
		return 0, io.EOF
	}
	n := int64(len(p))
	if n > r.remaining {
		n = r.remaining
	}
	clear(p[:n])
	r.remaining -= n
	return int(n), nil
}

func TestIntegrationGridFSUploadCancelAndReaderErrorLeavesNoOrphans(t *testing.T) {
	c := connect(t)
	ctx := context.Background()
	bucket := scratchBucket(t, c)
	filesColl := c.client.Database("queravue").Collection(bucket + ".files")
	chunksColl := c.client.Database("queravue").Collection(bucket + ".chunks")

	// Cancel after chunks have been flushed to MongoDB.
	cancelCtx, cancel := context.WithCancel(ctx)
	defer cancel()
	r1 := &gatedChunkReader{
		remaining: 20 << 20,
		chunks:    chunksColl,
		onTrigger: func() error { cancel(); return nil },
	}
	_, err := c.Upload(cancelCtx, engine.GridFSUpload{
		Database: "queravue",
		Bucket:   bucket,
		Filename: "cancelled.bin",
	}, r1)
	if engine.KindOf(err) != engine.KindCanceled || !r1.triggered {
		t.Fatalf("cancel upload: err=%v triggered=%v, want KindCanceled and flushed chunks", err, r1.triggered)
	}
	fc, _ := filesColl.CountDocuments(ctx, bson.D{})
	cc, _ := chunksColl.CountDocuments(ctx, bson.D{})
	if fc != 0 || cc != 0 {
		t.Fatalf("orphans after cancel: files=%d chunks=%d", fc, cc)
	}

	// Reader failure mid-upload after chunks flushed.
	readBoom := io.ErrUnexpectedEOF
	r2 := &gatedChunkReader{
		remaining: 20 << 20,
		chunks:    chunksColl,
		onTrigger: func() error { return readBoom },
	}
	_, err = c.Upload(ctx, engine.GridFSUpload{
		Database: "queravue",
		Bucket:   bucket,
		Filename: "failed.bin",
	}, r2)
	if err == nil || !r2.triggered {
		t.Fatalf("reader fail upload: err=%v triggered=%v", err, r2.triggered)
	}
	fc, _ = filesColl.CountDocuments(ctx, bson.D{})
	cc, _ = chunksColl.CountDocuments(ctx, bson.D{})
	if fc != 0 || cc != 0 {
		t.Fatalf("orphans after reader error: files=%d chunks=%d", fc, cc)
	}

	// Cancelled replacing upload leaves original file and chunks intact.
	origPayload := []byte("keep me intact")
	orig, err := c.Upload(ctx, engine.GridFSUpload{
		Database: "queravue",
		Bucket:   bucket,
		Filename: "orig.txt",
	}, bytes.NewReader(origPayload))
	if err != nil {
		t.Fatal(err)
	}
	origChunks, err := chunksColl.CountDocuments(ctx, bson.D{})
	if err != nil || origChunks != 1 {
		t.Fatalf("origChunks = %d, %v", origChunks, err)
	}
	repCtx, repCancel := context.WithCancel(ctx)
	defer repCancel()
	r3 := &gatedChunkReader{
		remaining: 20 << 20,
		chunks:    chunksColl,
		baseCount: origChunks,
		onTrigger: func() error { repCancel(); return nil },
	}
	_, err = c.Upload(repCtx, engine.GridFSUpload{
		Database:  "queravue",
		Bucket:    bucket,
		Filename:  "orig.txt",
		ReplaceID: orig.ID,
	}, r3)
	if engine.KindOf(err) != engine.KindCanceled || !r3.triggered {
		t.Fatalf("cancelled replace: err=%v triggered=%v", err, r3.triggered)
	}
	cc, _ = chunksColl.CountDocuments(ctx, bson.D{})
	if cc != origChunks {
		t.Fatalf("chunks after cancelled replace = %d, want %d", cc, origChunks)
	}
	_, back := readAllGridFS(ctx, t, c, "queravue", bucket, orig.ID, 0)
	if !bytes.Equal(back, origPayload) {
		t.Errorf("original modified: %q", back)
	}
}

func TestIntegrationGridFSInteropExternalClient(t *testing.T) {
	c := connect(t)
	ctx := context.Background()
	bucketName := scratchBucket(t, c)

	ext, err := mongo.Connect(options.Client().ApplyURI("mongodb://" + hostPort() + "/?replicaSet=rs0"))
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = ext.Disconnect(context.Background()) }()
	db := ext.Database("queravue")
	extBucket := db.GridFSBucket(options.GridFSBucket().SetName(bucketName))

	// File 1 written by external client with custom string _id and metadata.contentType.
	extData := []byte("written by external mongo client")
	err = extBucket.UploadFromStreamWithID(ctx, "ext-id-1", "ext.txt", bytes.NewReader(extData),
		options.GridFSUpload().SetMetadata(bson.D{{Key: "contentType", Value: "text/plain"}, {Key: "client", Value: "go-driver"}}))
	if err != nil {
		t.Fatal(err)
	}

	// File 2 shaped like legacy mongofiles (top-level contentType, no metadata).
	legacyData := []byte("legacy jpeg bytes")
	legacyID := bson.NewObjectID()
	if _, err := db.Collection(bucketName+".chunks").InsertOne(ctx, bson.D{
		{Key: "_id", Value: bson.NewObjectID()},
		{Key: "files_id", Value: legacyID},
		{Key: "n", Value: int32(0)},
		{Key: "data", Value: bson.Binary{Subtype: 0, Data: legacyData}},
	}); err != nil {
		t.Fatal(err)
	}
	if _, err := db.Collection(bucketName+".files").InsertOne(ctx, bson.D{
		{Key: "_id", Value: legacyID},
		{Key: "filename", Value: "legacy.jpg"},
		{Key: "length", Value: int64(len(legacyData))},
		{Key: "chunkSize", Value: int32(261120)},
		{Key: "uploadDate", Value: bson.NewDateTimeFromTime(time.Now().UTC())},
		{Key: "contentType", Value: "image/jpeg"},
	}); err != nil {
		t.Fatal(err)
	}

	var listed fileCollector
	if err := c.ListFiles(ctx, engine.GridFSListOptions{Database: "queravue", Bucket: bucketName, Sort: `{"filename":1}`}, &listed); err != nil {
		t.Fatal(err)
	}
	if len(listed.files) != 2 {
		t.Fatalf("listed = %+v", listed.files)
	}
	if listed.files[0].ID != `"ext-id-1"` || listed.files[0].ContentType != "text/plain" {
		t.Errorf("ext file = %+v", listed.files[0])
	}
	if listed.files[1].Filename != "legacy.jpg" || listed.files[1].ContentType != "image/jpeg" || listed.files[1].Metadata != "" {
		t.Errorf("legacy file = %+v", listed.files[1])
	}

	_, gotExt := readAllGridFS(ctx, t, c, "queravue", bucketName, `"ext-id-1"`, 0)
	if !bytes.Equal(gotExt, extData) {
		t.Errorf("ext download = %q", gotExt)
	}
	_, gotLegacy := readAllGridFS(ctx, t, c, "queravue", bucketName, listed.files[1].ID, 0)
	if !bytes.Equal(gotLegacy, legacyData) {
		t.Errorf("legacy download = %q", gotLegacy)
	}

	// File written by Conn is readable by external GridFSBucket.
	connData := []byte("uploaded via queravue Conn")
	upFile, err := c.Upload(ctx, engine.GridFSUpload{
		Database:    "queravue",
		Bucket:      bucketName,
		Filename:    "from-conn.txt",
		ContentType: "text/plain",
		Metadata:    `{"client":"queravue"}`,
	}, bytes.NewReader(connData))
	if err != nil {
		t.Fatal(err)
	}
	idVal, err := parseValue(upFile.ID, engine.InputDocument)
	if err != nil {
		t.Fatal(err)
	}
	stream, err := extBucket.OpenDownloadStream(ctx, idVal)
	if err != nil {
		t.Fatalf("external OpenDownloadStream: %v", err)
	}
	defer func() { _ = stream.Close() }()
	metadata := stream.GetFile().Metadata
	if metadata.Lookup("contentType").StringValue() != "text/plain" || metadata.Lookup("client").StringValue() != "queravue" {
		t.Fatalf("external metadata = %v", metadata)
	}
	got, err := io.ReadAll(stream)
	if err != nil || !bytes.Equal(got, connData) {
		t.Errorf("external read = %q, error = %v", got, err)
	}
}

type patternHashReader struct {
	block     []byte
	remaining int64
	pos       int
	hasher    hash.Hash
	totalRead int64
	nextMark  int64
	step      int64
	onMark    func()
}

func (r *patternHashReader) Read(p []byte) (int, error) {
	if r.remaining <= 0 {
		return 0, io.EOF
	}
	want := len(p)
	if int64(want) > r.remaining {
		want = int(r.remaining)
	}
	copied := 0
	for copied < want {
		n := copy(p[copied:want], r.block[r.pos:])
		copied += n
		r.pos += n
		if r.pos == len(r.block) {
			r.pos = 0
		}
	}
	_, _ = r.hasher.Write(p[:copied])
	r.remaining -= int64(copied)
	r.totalRead += int64(copied)
	if r.onMark != nil && r.totalRead >= r.nextMark {
		r.nextMark += r.step
		r.onMark()
	}
	return copied, nil
}

func processRSSBytes() uint64 {
	out, err := exec.Command("ps", "-o", "rss=", "-p", strconv.Itoa(os.Getpid())).Output()
	if err != nil {
		return 0
	}
	kb, err := strconv.ParseUint(strings.TrimSpace(string(out)), 10, 64)
	if err != nil {
		return 0
	}
	return kb << 10
}

func TestIntegrationGridFS1GiBRoundTripMemory(t *testing.T) {
	if testing.Short() || os.Getenv("GRIDFS_MEMORY_PERF") == "" {
		t.Skip("set GRIDFS_MEMORY_PERF=1 to run the 1 GiB memory test")
	}
	c := connect(t)
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
	defer cancel()
	bucket := scratchBucket(t, c)

	const totalBytes = 1 << 30 // 1 GiB
	const markStep = 128 << 20 // 128 MiB

	block := make([]byte, 64<<10)
	for i := range block {
		block[i] = byte(i*131 + (i >> 7))
	}

	runtime.GC()
	runtime.GC()
	var base runtime.MemStats
	runtime.ReadMemStats(&base)
	baseRSS := processRSSBytes()
	logMemory := func(label string) {
		t.Helper()
		samples := []metrics.Sample{{Name: "/memory/classes/heap/free:bytes"}, {Name: "/memory/classes/heap/released:bytes"}, {Name: "/memory/classes/heap/objects:bytes"}, {Name: "/memory/classes/heap/stacks:bytes"}, {Name: "/memory/classes/metadata/mspan/inuse:bytes"}, {Name: "/sched/goroutines:goroutines"}}
		metrics.Read(samples)
		t.Logf("%s: rss=%.1f MiB heap free=%.1f released=%.1f objects=%.1f stacks=%.1f mspan=%.1f MiB goroutines=%d", label, float64(processRSSBytes())/(1<<20), float64(samples[0].Value.Uint64())/(1<<20), float64(samples[1].Value.Uint64())/(1<<20), float64(samples[2].Value.Uint64())/(1<<20), float64(samples[3].Value.Uint64())/(1<<20), float64(samples[4].Value.Uint64())/(1<<20), samples[5].Value.Uint64())
	}
	logMemory("baseline")

	stopRSS := make(chan struct{})
	rssResult := make(chan uint64, 1)
	go func() {
		peak := baseRSS
		ticker := time.NewTicker(25 * time.Millisecond)
		defer ticker.Stop()
		for {
			select {
			case <-ticker.C:
				peak = max(peak, processRSSBytes())
			case <-stopRSS:
				rssResult <- max(peak, processRSSBytes())
				return
			}
		}
	}()

	var upLivePeak, upRawPeak, upRSSPeak uint64
	var upSamples []uint64
	sampleMem := func(livePeak, rawPeak, rssPeak *uint64, samples *[]uint64) {
		var raw runtime.MemStats
		runtime.ReadMemStats(&raw)
		*rawPeak = max(*rawPeak, raw.HeapAlloc)
		runtime.GC()
		runtime.GC()
		var live runtime.MemStats
		runtime.ReadMemStats(&live)
		*livePeak = max(*livePeak, live.HeapAlloc)
		*samples = append(*samples, live.HeapAlloc)
		*rssPeak = max(*rssPeak, processRSSBytes())
	}

	upHash := sha256.New()
	pr := &patternHashReader{
		block:     block,
		remaining: totalBytes,
		hasher:    upHash,
		nextMark:  markStep,
		step:      markStep,
		onMark:    func() { sampleMem(&upLivePeak, &upRawPeak, &upRSSPeak, &upSamples) },
	}

	upStart := time.Now()
	file, err := c.Upload(ctx, engine.GridFSUpload{
		Database:    "queravue",
		Bucket:      bucket,
		Filename:    "one-gib.bin",
		ContentType: "application/octet-stream",
	}, pr)
	upElapsed := time.Since(upStart)
	if err != nil {
		t.Fatalf("Upload 1 GiB: %v", err)
	}
	if file.Length != totalBytes {
		t.Fatalf("uploaded length = %d, want %d", file.Length, totalBytes)
	}
	runtime.GC()
	runtime.GC()
	var postUp runtime.MemStats
	runtime.ReadMemStats(&postUp)
	postUpRSS := processRSSBytes()

	var dlLivePeak, dlRawPeak, dlRSSPeak uint64
	var dlSamples []uint64
	_, rc, err := c.OpenDownload(ctx, "queravue", bucket, file.ID, 0)
	if err != nil {
		t.Fatalf("OpenDownload 1 GiB: %v", err)
	}
	dlHash := sha256.New()
	buf := make([]byte, 256<<10)
	var dlTotal int64
	nextDLMark := int64(markStep)
	dlStart := time.Now()
	for {
		n, rerr := rc.Read(buf)
		if n > 0 {
			_, _ = dlHash.Write(buf[:n])
			dlTotal += int64(n)
			if dlTotal >= nextDLMark {
				nextDLMark += markStep
				sampleMem(&dlLivePeak, &dlRawPeak, &dlRSSPeak, &dlSamples)
			}
		}
		if errors.Is(rerr, io.EOF) {
			break
		}
		if rerr != nil {
			_ = rc.Close()
			t.Fatalf("Download read: %v", rerr)
		}
	}
	_ = rc.Close()
	dlElapsed := time.Since(dlStart)

	runtime.GC()
	runtime.GC()
	var postDL runtime.MemStats
	runtime.ReadMemStats(&postDL)
	postDLRSS := processRSSBytes()
	close(stopRSS)
	peakRSS := <-rssResult
	logMemory("after download")
	if profileDir := os.Getenv("GRIDFS_PROFILE_DIR"); profileDir != "" {
		for _, name := range []string{"heap", "allocs"} {
			f, err := os.Create(profileDir + "/" + name + ".txt")
			if err != nil {
				t.Fatal(err)
			}
			if err := pprof.Lookup(name).WriteTo(f, 1); err != nil {
				t.Fatal(err)
			}
			if err := f.Close(); err != nil {
				t.Fatal(err)
			}
		}
	}
	if err := c.client.Database("queravue").Collection(bucket + ".files").Drop(ctx); err != nil {
		t.Fatal(err)
	}
	if err := c.client.Database("queravue").Collection(bucket + ".chunks").Drop(ctx); err != nil {
		t.Fatal(err)
	}
	if err := c.Close(); err != nil {
		t.Fatal(err)
	}
	time.Sleep(20 * time.Second)
	logMemory("20 seconds after disconnect")
	if peakRSS == 0 || baseRSS == 0 {
		t.Fatal("RSS measurement unavailable")
	}
	// macOS may keep madvised pages resident after a transfer.
	t.Logf("transfer peak RSS: %.1f MiB; baseline: %.1f MiB", float64(peakRSS)/(1<<20), float64(baseRSS)/(1<<20))
	if peakRSS > baseRSS+(60<<20) {
		t.Errorf("peak RSS %.1f MiB exceeds baseline %.1f MiB by more than 60 MiB", float64(peakRSS)/(1<<20), float64(baseRSS)/(1<<20))
	}

	if dlTotal != totalBytes {
		t.Fatalf("downloaded %d bytes, want %d", dlTotal, totalBytes)
	}
	if !bytes.Equal(upHash.Sum(nil), dlHash.Sum(nil)) {
		t.Fatal("SHA-256 mismatch between 1 GiB upload and download")
	}

	formatMiB := func(samples []uint64) string {
		parts := make([]string, len(samples))
		for i, v := range samples {
			parts[i] = fmt.Sprintf("%.1f", float64(v)/(1<<20))
		}
		return "[" + strings.Join(parts, ", ") + "] MiB"
	}
	upMiBs := 1024.0 / upElapsed.Seconds()
	dlMiBs := 1024.0 / dlElapsed.Seconds()
	t.Logf("1 GiB upload:   %v (%.1f MiB/s), baseHeap=%.1f MiB livePeak=%.1f MiB rawPeak=%.1f MiB postHeap=%.1f MiB, checkpoints=%s, baseRSS=%.1f MiB peakRSS=%.1f MiB postRSS=%.1f MiB",
		upElapsed.Round(time.Millisecond), upMiBs,
		float64(base.HeapAlloc)/(1<<20), float64(upLivePeak)/(1<<20), float64(upRawPeak)/(1<<20), float64(postUp.HeapAlloc)/(1<<20),
		formatMiB(upSamples),
		float64(baseRSS)/(1<<20), float64(upRSSPeak)/(1<<20), float64(postUpRSS)/(1<<20))
	t.Logf("1 GiB download: %v (%.1f MiB/s), livePeak=%.1f MiB rawPeak=%.1f MiB postHeap=%.1f MiB, checkpoints=%s, peakRSS=%.1f MiB postRSS=%.1f MiB",
		dlElapsed.Round(time.Millisecond), dlMiBs,
		float64(dlLivePeak)/(1<<20), float64(dlRawPeak)/(1<<20), float64(postDL.HeapAlloc)/(1<<20),
		formatMiB(dlSamples),
		float64(dlRSSPeak)/(1<<20), float64(postDLRSS)/(1<<20))

	const maxGrowth = 64 << 20
	if upLivePeak > base.HeapAlloc+maxGrowth {
		t.Errorf("upload live heap grew from %.1f MiB to %.1f MiB", float64(base.HeapAlloc)/(1<<20), float64(upLivePeak)/(1<<20))
	}
	if dlLivePeak > base.HeapAlloc+maxGrowth {
		t.Errorf("download live heap grew from %.1f MiB to %.1f MiB", float64(base.HeapAlloc)/(1<<20), float64(dlLivePeak)/(1<<20))
	}
	assertFlat := func(label string, samples []uint64) {
		t.Helper()
		if len(samples) < 8 {
			t.Errorf("%s: got %d samples, want 8", label, len(samples))
			return
		}
		var firstHalf, secondHalf uint64
		for _, s := range samples[:4] {
			firstHalf = max(firstHalf, s)
		}
		for _, s := range samples[4:] {
			secondHalf = max(secondHalf, s)
		}
		if secondHalf > firstHalf+(16<<20) {
			t.Errorf("%s live heap grew across halves: first=%s second=%s", label, formatMiB(samples[:4]), formatMiB(samples[4:]))
		}
	}
	assertFlat("upload", upSamples)
	assertFlat("download", dlSamples)
	const maxRetained = 16 << 20
	if postUp.HeapAlloc > base.HeapAlloc+maxRetained {
		t.Errorf("post-upload heap retained %.1f MiB (base %.1f MiB)", float64(postUp.HeapAlloc)/(1<<20), float64(base.HeapAlloc)/(1<<20))
	}
	if postDL.HeapAlloc > base.HeapAlloc+maxRetained {
		t.Errorf("post-download heap retained %.1f MiB (base %.1f MiB)", float64(postDL.HeapAlloc)/(1<<20), float64(base.HeapAlloc)/(1<<20))
	}
}
