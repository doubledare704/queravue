package mongo

import (
	"slices"
	"testing"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
	"go.mongodb.org/mongo-driver/v2/mongo"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func TestDetectBuckets(t *testing.T) {
	specs := []mongo.CollectionSpecification{
		{Name: "uploads.files", Type: "collection"},
		{Name: "uploads.chunks", Type: "collection"},
		{Name: "fs.chunks", Type: "collection"},
		{Name: "fs.files", Type: "collection"},
		{Name: "app.media.files", Type: "collection"},
		{Name: "app.media.chunks", Type: "collection"},
		{Name: "a.files.files", Type: "collection"},
		{Name: "a.files.chunks", Type: "collection"},
		{Name: "orphan_files.files", Type: "collection"},
		{Name: "orphan_chunks.chunks", Type: "collection"},
		{Name: "view_bucket.files", Type: "view"},
		{Name: "view_bucket.chunks", Type: "collection"},
		{Name: "system.buckets.files", Type: "collection"},
		{Name: "system.buckets.chunks", Type: "collection"},
		{Name: ".files", Type: "collection"},
		{Name: ".chunks", Type: "collection"},
		{Name: "regular_collection", Type: "collection"},
	}
	got := detectBuckets(specs)
	want := []string{"a.files", "app.media", "fs", "uploads"}
	if !slices.Equal(got, want) {
		t.Fatalf("detectBuckets = %v, want %v", got, want)
	}
	if empty := detectBuckets(nil); len(empty) != 0 {
		t.Fatalf("detectBuckets(nil) = %v, want empty", empty)
	}
}

func TestDecodeGridFSFileAndContentType(t *testing.T) {
	oid := bson.NewObjectID()
	when := time.Date(2026, 11, 19, 12, 30, 0, 0, time.UTC)

	cases := []struct {
		name            string
		doc             bson.D
		wantID          string
		wantFilename    string
		wantLength      uint64
		wantChunkSize   uint32
		wantContentType string
		wantMeta        string
	}{
		{
			name: "metadata contentType wins over top-level",
			doc: bson.D{
				{Key: "_id", Value: oid},
				{Key: "filename", Value: "photo.png"},
				{Key: "length", Value: int64(4096)},
				{Key: "chunkSize", Value: int32(261120)},
				{Key: "uploadDate", Value: bson.NewDateTimeFromTime(when)},
				{Key: "contentType", Value: "application/octet-stream"},
				{Key: "metadata", Value: bson.D{
					{Key: "contentType", Value: "image/png"},
					{Key: "rev", Value: int32(2)},
				}},
			},
			wantID:          `{"$oid":"` + oid.Hex() + `"}`,
			wantFilename:    "photo.png",
			wantLength:      4096,
			wantChunkSize:   261120,
			wantContentType: "image/png",
			wantMeta:        `{"contentType":"image/png","rev":{"$numberInt":"2"}}`,
		},
		{
			name: "empty metadata contentType falls back to top-level",
			doc: bson.D{
				{Key: "_id", Value: int32(7)},
				{Key: "filename", Value: "legacy.txt"},
				{Key: "length", Value: int32(12)},
				{Key: "chunkSize", Value: int32(1024)},
				{Key: "uploadDate", Value: bson.NewDateTimeFromTime(when)},
				{Key: "contentType", Value: "text/plain"},
				{Key: "metadata", Value: bson.D{{Key: "contentType", Value: ""}, {Key: "source", Value: "mongofiles"}}},
			},
			wantID:          `{"$numberInt":"7"}`,
			wantFilename:    "legacy.txt",
			wantLength:      12,
			wantChunkSize:   1024,
			wantContentType: "text/plain",
			wantMeta:        `{"contentType":"","source":"mongofiles"}`,
		},
		{
			name: "metadata without contentType falls back to top-level",
			doc: bson.D{
				{Key: "_id", Value: "custom-id"},
				{Key: "filename", Value: "doc.pdf"},
				{Key: "length", Value: int64(1)<<55 + 7},
				{Key: "chunkSize", Value: int64(261120)},
				{Key: "uploadDate", Value: bson.NewDateTimeFromTime(when)},
				{Key: "contentType", Value: "application/pdf"},
				{Key: "metadata", Value: bson.D{{Key: "tag", Value: "v1"}}},
			},
			wantID:          `"custom-id"`,
			wantFilename:    "doc.pdf",
			wantLength:      uint64(1)<<55 + 7,
			wantChunkSize:   261120,
			wantContentType: "application/pdf",
			wantMeta:        `{"tag":"v1"}`,
		},
		{
			name: "no metadata falls back to top-level",
			doc: bson.D{
				{Key: "_id", Value: int64(9007199254740993)},
				{Key: "filename", Value: "raw.bin"},
				{Key: "length", Value: float64(512)},
				{Key: "chunkSize", Value: float64(256)},
				{Key: "uploadDate", Value: bson.NewDateTimeFromTime(when)},
				{Key: "contentType", Value: "application/octet-stream"},
			},
			wantID:          `{"$numberLong":"9007199254740993"}`,
			wantFilename:    "raw.bin",
			wantLength:      512,
			wantChunkSize:   256,
			wantContentType: "application/octet-stream",
		},
		{
			name: "neither contentType set",
			doc: bson.D{
				{Key: "_id", Value: oid},
				{Key: "filename", Value: "empty"},
				{Key: "length", Value: int64(0)},
				{Key: "chunkSize", Value: int32(261120)},
				{Key: "uploadDate", Value: bson.NewDateTimeFromTime(when)},
			},
			wantID:        `{"$oid":"` + oid.Hex() + `"}`,
			wantFilename:  "empty",
			wantLength:    0,
			wantChunkSize: 261120,
		},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			raw, err := bson.Marshal(tc.doc)
			if err != nil {
				t.Fatal(err)
			}
			got, err := decodeGridFSFile(raw)
			if err != nil {
				t.Fatalf("decodeGridFSFile: %v", err)
			}
			if got.ID != tc.wantID || got.Filename != tc.wantFilename || got.Length != tc.wantLength ||
				got.ChunkSize != tc.wantChunkSize || !got.UploadDate.Equal(when) ||
				got.ContentType != tc.wantContentType || got.Metadata != tc.wantMeta {
				t.Errorf("got = %+v\nwant id=%s filename=%s len=%d chunk=%d date=%v ct=%q meta=%q",
					got, tc.wantID, tc.wantFilename, tc.wantLength, tc.wantChunkSize, when, tc.wantContentType, tc.wantMeta)
			}
		})
	}
}

func TestBuildUploadMetadata(t *testing.T) {
	if doc, err := buildUploadMetadata("", ""); err != nil || doc != nil {
		t.Fatalf("empty = %v, %v", doc, err)
	}
	doc, err := buildUploadMetadata("", "image/webp")
	if err != nil || len(doc) != 1 || doc[0].Key != "contentType" || doc[0].Value != "image/webp" {
		t.Fatalf("content type only = %v, %v", doc, err)
	}
	doc, err = buildUploadMetadata(`{"author":"ada","rev":2,"contentType":"old/type"}`, "text/plain")
	if err != nil {
		t.Fatal(err)
	}
	raw, err := bson.Marshal(doc)
	if err != nil {
		t.Fatal(err)
	}
	if ct := bson.Raw(raw).Lookup("contentType").StringValue(); ct != "text/plain" {
		t.Errorf("contentType = %q, want text/plain", ct)
	}
	if rev := bson.Raw(raw).Lookup("rev").Int32(); rev != 2 {
		t.Errorf("rev = %d, want 2", rev)
	}
	ctCount := 0
	for _, e := range doc {
		if e.Key == "contentType" {
			ctCount++
		}
	}
	if ctCount != 1 {
		t.Errorf("duplicate contentType keys: %v", doc)
	}

	if _, err := buildUploadMetadata(`{"bad": ]`, ""); engine.KindOf(err) != engine.KindParse {
		t.Errorf("bad metadata = %v, want KindParse", err)
	}
}
