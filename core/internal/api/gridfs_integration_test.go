//go:build integration

package api_test

import (
	"bytes"
	"context"
	"fmt"
	"io"
	"os"
	"testing"
	"time"

	"go.mongodb.org/mongo-driver/v2/bson"
	mongodrv "go.mongodb.org/mongo-driver/v2/mongo"
	"go.mongodb.org/mongo-driver/v2/mongo/options"
	"google.golang.org/grpc"

	"github.com/doubledare704/queravue/core/internal/api"
	"github.com/doubledare704/queravue/core/internal/connections"
	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/mongo"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/secrets"
	"github.com/doubledare704/queravue/core/internal/session"
)

type mongoTestOpener struct{}

func mongoHostPort() string {
	host := os.Getenv("MONGO_HOST")
	if host == "" {
		host = "127.0.0.1"
	}
	port := os.Getenv("MONGO_PORT")
	if port == "" {
		port = "27017"
	}
	return host + ":" + port
}

func (mongoTestOpener) Open(ctx context.Context, _ string) (engine.Conn, engine.Descriptor, error) {
	e := mongo.New(mongo.VariantMongoDB)
	c, err := e.Connect(ctx, engine.Config{EngineID: mongo.ID, Params: map[string]string{
		mongo.ParamHosts:      mongoHostPort(),
		mongo.ParamReplicaSet: "rs0",
		mongo.ParamDirect:     "false",
	}}, engine.Secret{})
	return c, e.Descriptor(), err
}

func newMongoGridFS(t *testing.T, production bool) (*api.GridFsService, string, *mongodrv.Database) {
	t.Helper()
	mgr := session.NewManager(mongoTestOpener{})
	t.Cleanup(mgr.Shutdown)
	sess, err := mgr.Open(context.Background(), "c")
	if err != nil {
		t.Fatalf("open: %v (docker compose -f dev/docker-compose.yml up -d --wait mongo)", err)
	}
	reg, _ := engine.NewRegistry(mongo.New(mongo.VariantMongoDB))
	store := connections.NewFileStore(t.TempDir())
	_ = store.Save([]connections.Connection{{ID: sess.ConnectionID, Name: "M", EngineID: mongo.ID, Production: production}})

	cl, err := mongodrv.Connect(options.Client().ApplyURI("mongodb://" + mongoHostPort() + "/?replicaSet=rs0"))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = cl.Disconnect(context.Background()) })

	return api.NewGridFsService(mgr, connections.NewService(reg, store, secrets.NewMemory()), nil), sess.ID, cl.Database("queravue")
}

func TestIntegrationGridFsServiceRoundTripAndConfirmation(t *testing.T) {
	svc, sid, db := newMongoGridFS(t, true)
	ctx := context.Background()
	bucket := fmt.Sprintf("api_gfs_%d", time.Now().UnixNano())
	t.Cleanup(func() {
		dctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
		defer cancel()
		_ = db.Collection(bucket + ".files").Drop(dctx)
		_ = db.Collection(bucket + ".chunks").Drop(dctx)
	})

	payload := bytes.Repeat([]byte{0x13, 0x37, 0xca, 0xfe}, (1500<<10)/4) // 1.5 MiB
	up := &uploadStream{
		ctx: ctx,
		reqs: []*queravuev1.UploadRequest{
			{Part: &queravuev1.UploadRequest_Header{Header: &queravuev1.UploadHeader{
				SessionId:      sid,
				Database:       "queravue",
				Bucket:         bucket,
				Filename:       "blob.bin",
				ContentType:    "application/octet-stream",
				MetadataEjson:  `{"src":"api-it"}`,
				ChunkSizeBytes: 256 << 10,
			}}},
			{Part: &queravuev1.UploadRequest_Chunk{Chunk: payload[:700<<10]}},
			{Part: &queravuev1.UploadRequest_Chunk{Chunk: payload[700<<10:]}},
		},
	}
	if err := svc.Upload(up); err != nil {
		t.Fatal(err)
	}
	if up.resp.GetError() != nil || up.resp.GetFile().GetLength() != uint64(len(payload)) {
		t.Fatalf("upload resp = %+v", up.resp)
	}
	id := up.resp.GetFile().GetIdEjson()

	// ListBuckets + ListFiles.
	buckets, err := svc.ListBuckets(ctx, &queravuev1.ListBucketsRequest{SessionId: sid, Database: "queravue"})
	if err != nil || buckets.GetError() != nil {
		t.Fatalf("ListBuckets = %+v, %v", buckets, err)
	}
	var found bool
	for _, b := range buckets.GetBuckets() {
		if b.GetName() == bucket && b.GetFileCountEstimate() == 1 {
			found = true
		}
	}
	if !found {
		t.Errorf("bucket %s missing from %+v", bucket, buckets.GetBuckets())
	}

	lst := &listFilesStream{ctx: ctx}
	if err := svc.ListFiles(&queravuev1.ListFilesRequest{SessionId: sid, Database: "queravue", Bucket: bucket}, lst); err != nil {
		t.Fatal(err)
	}
	if len(lst.msgs) < 2 || len(lst.msgs[0].GetBatch().GetFiles()) != 1 || !lst.msgs[len(lst.msgs)-1].GetBatch().GetDone() {
		t.Fatalf("ListFiles = %+v", lst.msgs)
	}

	// Download full -> chunks <= 1 MiB.
	dl := &downloadStream{ctx: ctx}
	if err := svc.Download(&queravuev1.DownloadRequest{SessionId: sid, Database: "queravue", Bucket: bucket, IdEjson: id}, dl); err != nil {
		t.Fatal(err)
	}
	var full bytes.Buffer
	for _, m := range dl.msgs[1:] {
		if len(m.GetChunk()) > 1<<20 {
			t.Fatalf("chunk size %d > 1 MiB", len(m.GetChunk()))
		}
		full.Write(m.GetChunk())
	}
	if !bytes.Equal(full.Bytes(), payload) {
		t.Fatalf("full download mismatch: got %d bytes", full.Len())
	}

	// Ranged download.
	reqLen := uint64(5000)
	dlRange := &downloadStream{ctx: ctx}
	if err := svc.Download(&queravuev1.DownloadRequest{
		SessionId: sid, Database: "queravue", Bucket: bucket, IdEjson: id, Offset: 300_000, Length: &reqLen,
	}, dlRange); err != nil {
		t.Fatal(err)
	}
	var ranged bytes.Buffer
	for _, m := range dlRange.msgs[1:] {
		ranged.Write(m.GetChunk())
	}
	if !bytes.Equal(ranged.Bytes(), payload[300_000:305_000]) {
		t.Fatalf("ranged download mismatch: got %d bytes", ranged.Len())
	}

	// Rename requires no confirmation.
	if ren, err := svc.RenameFile(ctx, &queravuev1.RenameFileRequest{
		SessionId: sid, Database: "queravue", Bucket: bucket, IdEjson: id, NewFilename: "blob2.bin",
	}); err != nil || ren.GetError() != nil {
		t.Fatalf("RenameFile = %+v, %v", ren, err)
	}

	// Production replace requires confirmed=true.
	repUnconf := &uploadStream{
		ctx: ctx,
		reqs: []*queravuev1.UploadRequest{
			{Part: &queravuev1.UploadRequest_Header{Header: &queravuev1.UploadHeader{
				SessionId: sid, Database: "queravue", Bucket: bucket, Filename: "blob3.bin", ReplaceIdEjson: id,
			}}},
		},
	}
	if err := svc.Upload(repUnconf); err != nil || repUnconf.resp.GetError().GetKind() != queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_CONFIRMATION_REQUIRED {
		t.Fatalf("unconfirmed replace = %+v, %v", repUnconf.resp, err)
	}
	repConf := &uploadStream{
		ctx: ctx,
		reqs: []*queravuev1.UploadRequest{
			{Part: &queravuev1.UploadRequest_Header{Header: &queravuev1.UploadHeader{
				SessionId: sid, Database: "queravue", Bucket: bucket, Filename: "blob3.bin", ReplaceIdEjson: id, Confirmed: true,
			}}},
			{Part: &queravuev1.UploadRequest_Chunk{Chunk: []byte("replaced")}},
		},
	}
	if err := svc.Upload(repConf); err != nil || repConf.resp.GetError() != nil {
		t.Fatalf("confirmed replace = %+v, %v", repConf.resp, err)
	}
	newID := repConf.resp.GetFile().GetIdEjson()

	// Production delete requires confirmed=true.
	if del, err := svc.DeleteFile(ctx, &queravuev1.DeleteFileRequest{
		SessionId: sid, Database: "queravue", Bucket: bucket, IdEjson: newID,
	}); err != nil || del.GetError().GetKind() != queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_CONFIRMATION_REQUIRED {
		t.Fatalf("unconfirmed delete = %+v, %v", del, err)
	}
	if del, err := svc.DeleteFile(ctx, &queravuev1.DeleteFileRequest{
		SessionId: sid, Database: "queravue", Bucket: bucket, IdEjson: newID, Confirmed: true,
	}); err != nil || del.GetError() != nil {
		t.Fatalf("confirmed delete = %+v, %v", del, err)
	}
}

type cancellingUploadStream struct {
	grpc.ServerStream
	ctx    context.Context
	cancel context.CancelFunc
	chunks *mongodrv.Collection
	hdr    *queravuev1.UploadHeader
	sent   int
	block  []byte
}

func (s *cancellingUploadStream) Context() context.Context { return s.ctx }
func (s *cancellingUploadStream) Recv() (*queravuev1.UploadRequest, error) {
	if s.sent == 0 {
		s.sent++
		return &queravuev1.UploadRequest{Part: &queravuev1.UploadRequest_Header{Header: s.hdr}}, nil
	}
	n, err := s.chunks.CountDocuments(context.Background(), bson.D{})
	if err == nil && n > 0 {
		s.cancel()
		return nil, io.EOF
	}
	if s.sent > 40 {
		return nil, io.EOF
	}
	s.sent++
	return &queravuev1.UploadRequest{Part: &queravuev1.UploadRequest_Chunk{Chunk: s.block}}, nil
}
func (*cancellingUploadStream) SendAndClose(*queravuev1.UploadResponse) error { return nil }

func TestIntegrationGridFsServiceUploadCancelLeavesNoOrphans(t *testing.T) {
	svc, sid, db := newMongoGridFS(t, false)
	bucket := fmt.Sprintf("api_cancel_%d", time.Now().UnixNano())
	t.Cleanup(func() {
		dctx, cancel := context.WithTimeout(context.Background(), 15*time.Second)
		defer cancel()
		_ = db.Collection(bucket + ".files").Drop(dctx)
		_ = db.Collection(bucket + ".chunks").Drop(dctx)
	})

	ctx, cancel := context.WithCancel(context.Background())
	defer cancel()
	st := &cancellingUploadStream{
		ctx:    ctx,
		cancel: cancel,
		chunks: db.Collection(bucket + ".chunks"),
		hdr:    &queravuev1.UploadHeader{SessionId: sid, Database: "queravue", Bucket: bucket, Filename: "aborted.bin"},
		block:  make([]byte, 1<<20),
	}
	_ = svc.Upload(st)

	fc, err := db.Collection(bucket+".files").CountDocuments(context.Background(), bson.D{})
	if err != nil {
		t.Fatal(err)
	}
	cc, err := db.Collection(bucket+".chunks").CountDocuments(context.Background(), bson.D{})
	if err != nil {
		t.Fatal(err)
	}
	if fc != 0 || cc != 0 {
		t.Fatalf("orphans after API upload cancel: files=%d chunks=%d", fc, cc)
	}
}
