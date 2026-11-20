package api_test

import (
	"bytes"
	"context"
	"errors"
	"io"
	"sync"
	"testing"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/doubledare704/queravue/core/internal/api"
	"github.com/doubledare704/queravue/core/internal/connections"
	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/mongo"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/secrets"
	"github.com/doubledare704/queravue/core/internal/session"
)

type fakeGridFSConn struct {
	buckets      []engine.GridFSBucket
	listBucketsE error
	files        []engine.GridFSFile
	listFilesE   error
	listOpt      engine.GridFSListOptions

	dlFile   engine.GridFSFile
	dlReader func(offset uint64) (io.ReadCloser, error)
	dlOpenE  error
	dlOffset uint64

	uploadFn     func(ctx context.Context, u engine.GridFSUpload, r io.Reader) (engine.GridFSFile, error)
	uploadCalls  int
	lastUpload   engine.GridFSUpload
	uploadedData []byte

	deleteCalls int
	deleteErr   error
	renameCalls int
	renameErr   error
}

func (*fakeGridFSConn) Ping(context.Context) error { return nil }
func (*fakeGridFSConn) ServerInfo(context.Context) (engine.ServerInfo, error) {
	return engine.ServerInfo{}, nil
}
func (*fakeGridFSConn) Close() error { return nil }

func (f *fakeGridFSConn) ListBuckets(context.Context, string) ([]engine.GridFSBucket, error) {
	return f.buckets, f.listBucketsE
}

func (f *fakeGridFSConn) ListFiles(_ context.Context, opt engine.GridFSListOptions, sink engine.GridFSFileSink) error {
	f.listOpt = opt
	if f.listFilesE != nil {
		return f.listFilesE
	}
	for i := 0; i < len(f.files); i += 2 {
		if err := sink.Batch(f.files[i:min(i+2, len(f.files))]); err != nil {
			return err
		}
	}
	return nil
}

func (f *fakeGridFSConn) OpenDownload(_ context.Context, _, _ string, _ engine.Document, offset uint64) (engine.GridFSFile, io.ReadCloser, error) {
	f.dlOffset = offset
	if f.dlOpenE != nil {
		return engine.GridFSFile{}, nil, f.dlOpenE
	}
	rc, err := f.dlReader(offset)
	if err != nil {
		return engine.GridFSFile{}, nil, err
	}
	return f.dlFile, rc, nil
}

func (f *fakeGridFSConn) Upload(ctx context.Context, u engine.GridFSUpload, r io.Reader) (engine.GridFSFile, error) {
	f.uploadCalls++
	f.lastUpload = u
	if f.uploadFn != nil {
		return f.uploadFn(ctx, u, r)
	}
	data, err := io.ReadAll(r)
	if err != nil {
		return engine.GridFSFile{}, err
	}
	f.uploadedData = data
	return engine.GridFSFile{
		ID:          `{"$oid":"650000000000000000000001"}`,
		Filename:    u.Filename,
		Length:      uint64(len(data)),
		ChunkSize:   261120,
		UploadDate:  time.UnixMilli(1700000000000).UTC(),
		ContentType: u.ContentType,
		Metadata:    u.Metadata,
	}, nil
}

func (f *fakeGridFSConn) DeleteFile(context.Context, string, string, engine.Document) error {
	f.deleteCalls++
	return f.deleteErr
}

func (f *fakeGridFSConn) RenameFile(context.Context, string, string, engine.Document, string) error {
	f.renameCalls++
	return f.renameErr
}

type gridfsOpener struct{ conn engine.Conn }

func (o gridfsOpener) Open(context.Context, string) (engine.Conn, engine.Descriptor, error) {
	return o.conn, engine.Descriptor{ID: mongo.ID, Capabilities: []engine.Capability{engine.CapConnect, engine.CapGridFS}}, nil
}

func newGridFSService(t *testing.T, conn engine.Conn, production bool) (*api.GridFsService, string) {
	t.Helper()
	mgr := session.NewManager(gridfsOpener{conn: conn})
	t.Cleanup(mgr.Shutdown)
	sess, err := mgr.Open(context.Background(), "c")
	if err != nil {
		t.Fatal(err)
	}
	reg, err := engine.NewRegistry(mongo.New(mongo.VariantMongoDB))
	if err != nil {
		t.Fatal(err)
	}
	store := connections.NewFileStore(t.TempDir())
	if err := store.Save([]connections.Connection{{ID: sess.ConnectionID, Name: "M", EngineID: mongo.ID, Production: production}}); err != nil {
		t.Fatal(err)
	}
	return api.NewGridFsService(mgr, connections.NewService(reg, store, secrets.NewMemory()), nil), sess.ID
}

type listFilesStream struct {
	grpc.ServerStream
	ctx  context.Context
	msgs []*queravuev1.ListFilesResponse
}

func (s *listFilesStream) Context() context.Context { return s.ctx }
func (s *listFilesStream) Send(m *queravuev1.ListFilesResponse) error {
	s.msgs = append(s.msgs, m)
	return nil
}

type downloadStream struct {
	grpc.ServerStream
	ctx  context.Context
	msgs []*queravuev1.DownloadResponse
}

func (s *downloadStream) Context() context.Context { return s.ctx }
func (s *downloadStream) Send(m *queravuev1.DownloadResponse) error {
	s.msgs = append(s.msgs, m)
	return nil
}

type uploadStream struct {
	grpc.ServerStream
	ctx      context.Context
	reqs     []*queravuev1.UploadRequest
	idx      int
	recvErr  error
	resp     *queravuev1.UploadResponse
	sentOnce sync.Once
}

func (s *uploadStream) Context() context.Context { return s.ctx }
func (s *uploadStream) Recv() (*queravuev1.UploadRequest, error) {
	if s.idx >= len(s.reqs) {
		if s.recvErr != nil {
			return nil, s.recvErr
		}
		return nil, io.EOF
	}
	m := s.reqs[s.idx]
	s.idx++
	return m, nil
}
func (s *uploadStream) SendAndClose(r *queravuev1.UploadResponse) error {
	s.sentOnce.Do(func() { s.resp = r })
	return nil
}

func TestGridFsServiceSessionAndCapabilityErrors(t *testing.T) {
	svc, nonGridFSSid := newGridFSService(t, &fakeDocConn{}, false)
	ctx := context.Background()

	cases := []struct {
		name string
		sid  string
		want codes.Code
	}{
		{"unknown session", "missing", codes.NotFound},
		{"no capability", nonGridFSSid, codes.FailedPrecondition},
	}

	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			if _, err := svc.ListBuckets(ctx, &queravuev1.ListBucketsRequest{SessionId: tc.sid}); status.Code(err) != tc.want {
				t.Errorf("ListBuckets code = %v, want %v", status.Code(err), tc.want)
			}
			if err := svc.ListFiles(&queravuev1.ListFilesRequest{SessionId: tc.sid}, &listFilesStream{ctx: ctx}); status.Code(err) != tc.want {
				t.Errorf("ListFiles code = %v, want %v", status.Code(err), tc.want)
			}
			if err := svc.Download(&queravuev1.DownloadRequest{SessionId: tc.sid}, &downloadStream{ctx: ctx}); status.Code(err) != tc.want {
				t.Errorf("Download code = %v, want %v", status.Code(err), tc.want)
			}
			up := &uploadStream{
				ctx:  ctx,
				reqs: []*queravuev1.UploadRequest{{Part: &queravuev1.UploadRequest_Header{Header: &queravuev1.UploadHeader{SessionId: tc.sid}}}},
			}
			if err := svc.Upload(up); status.Code(err) != tc.want {
				t.Errorf("Upload code = %v, want %v", status.Code(err), tc.want)
			}
			if _, err := svc.DeleteFile(ctx, &queravuev1.DeleteFileRequest{SessionId: tc.sid}); status.Code(err) != tc.want {
				t.Errorf("DeleteFile code = %v, want %v", status.Code(err), tc.want)
			}
			if _, err := svc.RenameFile(ctx, &queravuev1.RenameFileRequest{SessionId: tc.sid}); status.Code(err) != tc.want {
				t.Errorf("RenameFile code = %v, want %v", status.Code(err), tc.want)
			}
		})
	}
}

func TestGridFsServiceErrorMapping(t *testing.T) {
	tests := []struct {
		name    string
		err     error
		want    queravuev1.GridFsErrorKind
		wantMsg string
	}{
		{"parse", engine.Errorf(engine.KindParse, "mongo", "op", "bad ejson"), queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_PARSE, "bad ejson"},
		{"invalid config", engine.Errorf(engine.KindInvalidConfig, "mongo", "op", "bad bucket"), queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_PARSE, "bad bucket"},
		{"not found", engine.Errorf(engine.KindNotFound, "mongo", "op", "missing"), queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_NOT_FOUND, "missing"},
		{"confirmation", engine.Errorf(engine.KindConfirmationRequired, "mongo", "op", "confirm"), queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_CONFIRMATION_REQUIRED, "confirm"},
		{"auth", engine.Errorf(engine.KindAuth, "mongo", "op", "denied"), queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_AUTH, "denied"},
		{"network", engine.Errorf(engine.KindNetwork, "mongo", "op", "dial"), queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_NETWORK, "dial"},
		{"tls", engine.Errorf(engine.KindTLS, "mongo", "op", "cert"), queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_NETWORK, "cert"},
		{"conn lost", engine.Errorf(engine.KindConnectionLost, "mongo", "op", "closed"), queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_NETWORK, "closed"},
		{"tunnel lost", engine.Errorf(engine.KindTunnelLost, "mongo", "op", "ssh"), queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_NETWORK, "ssh"},
		{"timeout", engine.Errorf(engine.KindTimeout, "mongo", "op", "slow"), queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_TIMEOUT, "slow"},
		{"canceled", engine.Errorf(engine.KindCanceled, "mongo", "op", "canceled"), queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_CANCELED, "canceled"},
		{"unsupported", engine.Errorf(engine.KindUnsupported, "mongo", "op", "nope"), queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_UNSUPPORTED, "nope"},
		{"corrupt", engine.Errorf(engine.KindCorrupt, "mongo", "op", "short chunk"), queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_CORRUPT, "short chunk"},
		{"server", engine.Errorf(engine.KindServer, "mongo", "op", "rejected"), queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_SERVER, "rejected"},
		{"unknown kind", engine.Errorf(engine.KindUnknown, "mongo", "op", "other"), queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_SERVER, "other"},
		{"untyped redacted", errors.New("secret-pw-leak"), queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_SERVER, "operation failed"},
		{"raw context canceled", context.Canceled, queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_CANCELED, "operation canceled"},
		{"raw deadline", context.DeadlineExceeded, queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_TIMEOUT, "operation timed out"},
	}

	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			svc, sid := newGridFSService(t, &fakeGridFSConn{listBucketsE: tc.err}, false)
			resp, err := svc.ListBuckets(context.Background(), &queravuev1.ListBucketsRequest{SessionId: sid, Database: "db"})
			if err != nil {
				t.Fatal(err)
			}
			got := resp.GetError()
			if got.GetKind() != tc.want || got.GetMessage() != tc.wantMsg {
				t.Errorf("error = %+v, want kind=%v msg=%q", got, tc.want, tc.wantMsg)
			}
		})
	}
}

func TestGridFsServiceListBucketsAndFiles(t *testing.T) {
	total := uint64(4096)
	ts := time.Date(2026, 11, 19, 10, 0, 0, 0, time.UTC)
	conn := &fakeGridFSConn{
		buckets: []engine.GridFSBucket{
			{Name: "fs", FileCountEstimate: 3, TotalBytes: &total},
			{Name: "large", FileCountEstimate: 50000},
		},
		files: []engine.GridFSFile{
			{ID: `"a"`, Filename: "a.txt", Length: 10, ChunkSize: 261120, UploadDate: ts, ContentType: "text/plain", Metadata: `{"contentType":"text/plain"}`},
			{ID: `"b"`, Filename: "b.bin", Length: 20, ChunkSize: 261120},
			{ID: `"c"`, Filename: "c.png", Length: 30, ChunkSize: 261120, UploadDate: ts},
		},
	}
	svc, sid := newGridFSService(t, conn, false)

	bResp, err := svc.ListBuckets(context.Background(), &queravuev1.ListBucketsRequest{SessionId: sid, Database: "db"})
	if err != nil || bResp.GetError() != nil || len(bResp.GetBuckets()) != 2 {
		t.Fatalf("ListBuckets = %+v, %v", bResp, err)
	}
	if bResp.GetBuckets()[0].GetTotalBytes() != 4096 || bResp.GetBuckets()[1].TotalBytes != nil {
		t.Errorf("buckets = %+v", bResp.GetBuckets())
	}

	st := &listFilesStream{ctx: context.Background()}
	if err := svc.ListFiles(&queravuev1.ListFilesRequest{SessionId: sid, Database: "db", Bucket: "fs", Filter: `{"length":{"$gt":0}}`}, st); err != nil {
		t.Fatal(err)
	}
	if conn.listOpt.MaxTimeMS != 30_000 {
		t.Errorf("MaxTimeMS = %d, want 30000", conn.listOpt.MaxTimeMS)
	}
	if len(st.msgs) != 3 {
		t.Fatalf("got %d messages, want 3", len(st.msgs))
	}
	b0 := st.msgs[0].GetBatch()
	if b0.GetOffset() != 0 || len(b0.GetFiles()) != 2 || b0.GetFiles()[0].GetUploadDateMs() != ts.UnixMilli() {
		t.Errorf("batch 0 = %+v", b0)
	}
	if b0.GetFiles()[1].GetUploadDateMs() != 0 {
		t.Errorf("zero uploadDate should map to 0, got %d", b0.GetFiles()[1].GetUploadDateMs())
	}
	if last := st.msgs[2].GetBatch(); !last.GetDone() || last.GetOffset() != 3 {
		t.Errorf("last batch = %+v", last)
	}
}

type trackingReadCloser struct {
	r      io.Reader
	closed bool
}

func (t *trackingReadCloser) Read(p []byte) (int, error) { return t.r.Read(p) }
func (t *trackingReadCloser) Close() error               { t.closed = true; return nil }

type errAfterReader struct {
	first []byte
	sent  bool
	err   error
}

func (e *errAfterReader) Read(p []byte) (int, error) {
	if !e.sent {
		e.sent = true
		n := copy(p, e.first)
		return n, nil
	}
	return 0, e.err
}
func (*errAfterReader) Close() error { return nil }

func TestGridFsServiceDownloadChunkingRangeAndCorrupt(t *testing.T) {
	payload := bytes.Repeat([]byte{0x5a, 0xa5, 0x11, 0x22}, (2<<20+512<<10)/4) // 2.5 MiB
	var tracker *trackingReadCloser
	conn := &fakeGridFSConn{
		dlFile: engine.GridFSFile{ID: `"id1"`, Filename: "big.bin", Length: uint64(len(payload)), ChunkSize: 261120},
		dlReader: func(offset uint64) (io.ReadCloser, error) {
			tracker = &trackingReadCloser{r: bytes.NewReader(payload[offset:])}
			return tracker, nil
		},
	}
	svc, sid := newGridFSService(t, conn, false)

	// Full download: chunks <= 1 MiB.
	st := &downloadStream{ctx: context.Background()}
	if err := svc.Download(&queravuev1.DownloadRequest{SessionId: sid, Database: "db", Bucket: "fs", IdEjson: `"id1"`}, st); err != nil {
		t.Fatal(err)
	}
	if !tracker.closed {
		t.Error("download reader not closed")
	}
	if st.msgs[0].GetFile().GetFilename() != "big.bin" {
		t.Fatalf("first event = %+v, want file header", st.msgs[0])
	}
	var got bytes.Buffer
	for _, m := range st.msgs[1:] {
		chunk := m.GetChunk()
		if len(chunk) == 0 || len(chunk) > 1<<20 {
			t.Fatalf("invalid chunk size %d", len(chunk))
		}
		got.Write(chunk)
	}
	if !bytes.Equal(got.Bytes(), payload) {
		t.Fatalf("downloaded %d bytes, want %d", got.Len(), len(payload))
	}

	// Ranged download with offset + length.
	reqLen := uint64(1500)
	stRange := &downloadStream{ctx: context.Background()}
	if err := svc.Download(&queravuev1.DownloadRequest{SessionId: sid, Database: "db", Bucket: "fs", IdEjson: `"id1"`, Offset: 100, Length: &reqLen}, stRange); err != nil {
		t.Fatal(err)
	}
	if conn.dlOffset != 100 {
		t.Errorf("offset = %d, want 100", conn.dlOffset)
	}
	var ranged bytes.Buffer
	for _, m := range stRange.msgs[1:] {
		ranged.Write(m.GetChunk())
	}
	if !bytes.Equal(ranged.Bytes(), payload[100:1600]) {
		t.Errorf("ranged bytes mismatch: got %d", ranged.Len())
	}

	// Zero length returns only header.
	zero := uint64(0)
	stZero := &downloadStream{ctx: context.Background()}
	if err := svc.Download(&queravuev1.DownloadRequest{SessionId: sid, Database: "db", Bucket: "fs", IdEjson: `"id1"`, Length: &zero}, stZero); err != nil {
		t.Fatal(err)
	}
	if len(stZero.msgs) != 1 || stZero.msgs[0].GetFile() == nil {
		t.Errorf("zero length msgs = %+v", stZero.msgs)
	}

	// Mid-stream corrupt error mapped in-band.
	conn.dlReader = func(uint64) (io.ReadCloser, error) {
		return &errAfterReader{first: []byte("abc"), err: engine.Errorf(engine.KindCorrupt, "mongo", "download", "missing chunk")}, nil
	}
	stCorrupt := &downloadStream{ctx: context.Background()}
	if err := svc.Download(&queravuev1.DownloadRequest{SessionId: sid, Database: "db", Bucket: "fs", IdEjson: `"id1"`}, stCorrupt); err != nil {
		t.Fatal(err)
	}
	last := stCorrupt.msgs[len(stCorrupt.msgs)-1]
	if last.GetError().GetKind() != queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_CORRUPT {
		t.Errorf("last event = %+v, want CORRUPT", last)
	}

	// Context cancellation returns gRPC Canceled.
	cctx, cancel := context.WithCancel(context.Background())
	cancel()
	conn.dlReader = func(uint64) (io.ReadCloser, error) {
		return io.NopCloser(bytes.NewReader([]byte("x"))), nil
	}
	if err := svc.Download(&queravuev1.DownloadRequest{SessionId: sid, Database: "db", Bucket: "fs", IdEjson: `"id1"`}, &downloadStream{ctx: cctx}); status.Code(err) != codes.Canceled {
		t.Errorf("canceled download code = %v, want Canceled", status.Code(err))
	}
}

func TestGridFsServiceUploadValidationAndStreaming(t *testing.T) {
	conn := &fakeGridFSConn{}
	svc, sid := newGridFSService(t, conn, false)
	ctx := context.Background()

	// Happy multi-chunk upload.
	up := &uploadStream{
		ctx: ctx,
		reqs: []*queravuev1.UploadRequest{
			{Part: &queravuev1.UploadRequest_Header{Header: &queravuev1.UploadHeader{
				SessionId: sid, Database: "db", Bucket: "media", Filename: "pic.bin",
				ContentType: "application/octet-stream", MetadataEjson: `{"k":"v"}`, ChunkSizeBytes: 65536,
			}}},
			{Part: &queravuev1.UploadRequest_Chunk{Chunk: []byte("hello ")}},
			{Part: &queravuev1.UploadRequest_Chunk{Chunk: nil}},
			{Part: &queravuev1.UploadRequest_Chunk{Chunk: []byte("world")}},
		},
	}
	if err := svc.Upload(up); err != nil {
		t.Fatal(err)
	}
	if up.resp.GetError() != nil || string(conn.uploadedData) != "hello world" ||
		conn.lastUpload.Bucket != "media" || conn.lastUpload.ChunkSizeBytes != 65536 {
		t.Fatalf("upload resp=%+v data=%q opt=%+v", up.resp, conn.uploadedData, conn.lastUpload)
	}

	// Empty stream -> PARSE.
	empty := &uploadStream{ctx: ctx}
	if err := svc.Upload(empty); err != nil || empty.resp.GetError().GetKind() != queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_PARSE {
		t.Errorf("empty upload = %+v, %v", empty.resp, err)
	}

	// Chunk before header -> PARSE.
	noHdr := &uploadStream{ctx: ctx, reqs: []*queravuev1.UploadRequest{{Part: &queravuev1.UploadRequest_Chunk{Chunk: []byte("x")}}}}
	if err := svc.Upload(noHdr); err != nil || noHdr.resp.GetError().GetKind() != queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_PARSE {
		t.Errorf("chunk first = %+v, %v", noHdr.resp, err)
	}

	// Second header mid-stream -> PARSE.
	twoHdr := &uploadStream{
		ctx: ctx,
		reqs: []*queravuev1.UploadRequest{
			{Part: &queravuev1.UploadRequest_Header{Header: &queravuev1.UploadHeader{SessionId: sid, Database: "db", Bucket: "fs", Filename: "a"}}},
			{Part: &queravuev1.UploadRequest_Header{Header: &queravuev1.UploadHeader{SessionId: sid}}},
		},
	}
	if err := svc.Upload(twoHdr); err != nil || twoHdr.resp.GetError().GetKind() != queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_PARSE {
		t.Errorf("second header = %+v, %v", twoHdr.resp, err)
	}

	// Canceled upload stream returns gRPC Canceled.
	cctx, cancel := context.WithCancel(ctx)
	cancel()
	canceledUp := &uploadStream{
		ctx:     cctx,
		recvErr: cctx.Err(),
	}
	if err := svc.Upload(canceledUp); status.Code(err) != codes.Canceled {
		t.Errorf("canceled upload code = %v, want Canceled", status.Code(err))
	}
}

func TestGridFsServiceProductionConfirmation(t *testing.T) {
	ctx := context.Background()

	// Production connection: DeleteFile and replacing Upload require confirmed=true.
	prodConn := &fakeGridFSConn{}
	prodSvc, prodSid := newGridFSService(t, prodConn, true)

	delResp, err := prodSvc.DeleteFile(ctx, &queravuev1.DeleteFileRequest{SessionId: prodSid, Database: "db", Bucket: "fs", IdEjson: `"1"`})
	if err != nil || delResp.GetError().GetKind() != queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_CONFIRMATION_REQUIRED || prodConn.deleteCalls != 0 {
		t.Fatalf("unconfirmed prod delete = %+v, err=%v, calls=%d", delResp, err, prodConn.deleteCalls)
	}
	delResp, err = prodSvc.DeleteFile(ctx, &queravuev1.DeleteFileRequest{SessionId: prodSid, Database: "db", Bucket: "fs", IdEjson: `"1"`, Confirmed: true})
	if err != nil || delResp.GetError() != nil || prodConn.deleteCalls != 1 {
		t.Fatalf("confirmed prod delete = %+v, err=%v, calls=%d", delResp, err, prodConn.deleteCalls)
	}

	// Rename needs no confirmation even on production.
	renResp, err := prodSvc.RenameFile(ctx, &queravuev1.RenameFileRequest{SessionId: prodSid, Database: "db", Bucket: "fs", IdEjson: `"1"`, NewFilename: "new"})
	if err != nil || renResp.GetError() != nil || prodConn.renameCalls != 1 {
		t.Fatalf("prod rename = %+v, err=%v", renResp, err)
	}

	// Replacing upload without confirmed -> CONFIRMATION_REQUIRED before calling Upload.
	repUnconf := &uploadStream{
		ctx: ctx,
		reqs: []*queravuev1.UploadRequest{
			{Part: &queravuev1.UploadRequest_Header{Header: &queravuev1.UploadHeader{
				SessionId: prodSid, Database: "db", Bucket: "fs", Filename: "f", ReplaceIdEjson: `"old"`,
			}}},
		},
	}
	if err := prodSvc.Upload(repUnconf); err != nil || repUnconf.resp.GetError().GetKind() != queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_CONFIRMATION_REQUIRED || prodConn.uploadCalls != 0 {
		t.Fatalf("unconfirmed prod replace = %+v, err=%v, calls=%d", repUnconf.resp, err, prodConn.uploadCalls)
	}

	// Replacing upload with confirmed -> succeeds.
	repConf := &uploadStream{
		ctx: ctx,
		reqs: []*queravuev1.UploadRequest{
			{Part: &queravuev1.UploadRequest_Header{Header: &queravuev1.UploadHeader{
				SessionId: prodSid, Database: "db", Bucket: "fs", Filename: "f", ReplaceIdEjson: `"old"`, Confirmed: true,
			}}},
		},
	}
	if err := prodSvc.Upload(repConf); err != nil || repConf.resp.GetError() != nil || prodConn.uploadCalls != 1 {
		t.Fatalf("confirmed prod replace = %+v, err=%v", repConf.resp, err)
	}

	// Non-replacing upload on production needs no confirmation.
	newUpload := &uploadStream{
		ctx: ctx,
		reqs: []*queravuev1.UploadRequest{
			{Part: &queravuev1.UploadRequest_Header{Header: &queravuev1.UploadHeader{
				SessionId: prodSid, Database: "db", Bucket: "fs", Filename: "f",
			}}},
		},
	}
	if err := prodSvc.Upload(newUpload); err != nil || newUpload.resp.GetError() != nil || prodConn.uploadCalls != 2 {
		t.Fatalf("new upload on prod = %+v, err=%v", newUpload.resp, err)
	}

	// Non-production connection: DeleteFile and replacing Upload work without confirmed.
	devConn := &fakeGridFSConn{}
	devSvc, devSid := newGridFSService(t, devConn, false)
	if resp, err := devSvc.DeleteFile(ctx, &queravuev1.DeleteFileRequest{SessionId: devSid, Database: "db", Bucket: "fs", IdEjson: `"1"`}); err != nil || resp.GetError() != nil {
		t.Fatalf("dev delete = %+v, %v", resp, err)
	}
	devRep := &uploadStream{
		ctx: ctx,
		reqs: []*queravuev1.UploadRequest{
			{Part: &queravuev1.UploadRequest_Header{Header: &queravuev1.UploadHeader{
				SessionId: devSid, Database: "db", Bucket: "fs", Filename: "f", ReplaceIdEjson: `"old"`,
			}}},
		},
	}
	if err := devSvc.Upload(devRep); err != nil || devRep.resp.GetError() != nil {
		t.Fatalf("dev replace = %+v, %v", devRep.resp, err)
	}
}
