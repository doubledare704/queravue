package api

import (
	"context"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"strings"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/doubledare704/queravue/core/internal/connections"
	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/session"
)

const (
	defaultGridFSListMaxTimeMS = 30_000
	gridfsDownloadChunkBytes   = 1 << 20
)

// GridFsService implements queravuev1.GridFsServiceServer.
type GridFsService struct {
	queravuev1.UnimplementedGridFsServiceServer

	sessions    *session.Manager
	connections *connections.Service
	log         *slog.Logger
}

// NewGridFsService returns a GridFsService backed by s and c. connections may
// be nil, in which case no connection counts as production.
func NewGridFsService(s *session.Manager, c *connections.Service, log *slog.Logger) *GridFsService {
	if log == nil {
		log = slog.Default()
	}
	return &GridFsService{sessions: s, connections: c, log: log}
}

func (g *GridFsService) store(sessionID string) (*session.Session, engine.GridFS, error) {
	sess, err := g.sessions.Get(sessionID)
	if err != nil {
		return nil, nil, status.Error(codes.NotFound, "session not found")
	}
	fs, ok := engine.As[engine.GridFS](sess.Conn)
	if !ok {
		return nil, nil, status.Error(codes.FailedPrecondition, "connection does not support GridFS")
	}
	sess.Touch()
	return sess, fs, nil
}

func (g *GridFsService) production(ctx context.Context, sess *session.Session) bool {
	if g.connections == nil || sess.ConnectionID == "" {
		return false
	}
	c, err := g.connections.Get(ctx, sess.ConnectionID)
	return err == nil && c.Production
}

func gridFsConfirmationError(action string) *queravuev1.GridFsError {
	return &queravuev1.GridFsError{
		Kind:    queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_CONFIRMATION_REQUIRED,
		Message: "This connection is flagged as production. Confirmation is required to " + action + ".",
	}
}

func toGridFsError(err error) *queravuev1.GridFsError {
	var e *engine.Error
	if errors.As(err, &e) {
		return &queravuev1.GridFsError{Kind: gridFsErrorKind(e.Kind), Message: e.Msg}
	}
	switch {
	case errors.Is(err, context.Canceled):
		return &queravuev1.GridFsError{Kind: queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_CANCELED, Message: "operation canceled"}
	case errors.Is(err, context.DeadlineExceeded):
		return &queravuev1.GridFsError{Kind: queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_TIMEOUT, Message: "operation timed out"}
	default:
		return &queravuev1.GridFsError{Kind: queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_SERVER, Message: "operation failed"}
	}
}

func gridFsErrorKind(k engine.Kind) queravuev1.GridFsErrorKind {
	switch k {
	case engine.KindParse, engine.KindInvalidConfig:
		return queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_PARSE
	case engine.KindNotFound:
		return queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_NOT_FOUND
	case engine.KindConfirmationRequired:
		return queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_CONFIRMATION_REQUIRED
	case engine.KindAuth:
		return queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_AUTH
	case engine.KindNetwork, engine.KindTLS, engine.KindConnectionLost, engine.KindTunnelLost:
		return queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_NETWORK
	case engine.KindTimeout:
		return queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_TIMEOUT
	case engine.KindCanceled:
		return queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_CANCELED
	case engine.KindUnsupported:
		return queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_UNSUPPORTED
	case engine.KindCorrupt:
		return queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_CORRUPT
	default:
		return queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_SERVER
	}
}

func gridFsBucketToWire(b engine.GridFSBucket) *queravuev1.GridFsBucket {
	out := &queravuev1.GridFsBucket{
		Name:              b.Name,
		FileCountEstimate: b.FileCountEstimate,
	}
	if b.TotalBytes != nil {
		v := *b.TotalBytes
		out.TotalBytes = &v
	}
	return out
}

func gridFsFileToWire(f engine.GridFSFile) *queravuev1.GridFsFile {
	var uploadDateMs int64
	if !f.UploadDate.IsZero() {
		uploadDateMs = f.UploadDate.UnixMilli()
	}
	return &queravuev1.GridFsFile{
		IdEjson:       f.ID,
		Filename:      f.Filename,
		Length:        f.Length,
		ChunkSize:     f.ChunkSize,
		UploadDateMs:  uploadDateMs,
		ContentType:   f.ContentType,
		MetadataEjson: f.Metadata,
	}
}

// ListBuckets implements the RPC.
func (g *GridFsService) ListBuckets(ctx context.Context, req *queravuev1.ListBucketsRequest) (*queravuev1.ListBucketsResponse, error) {
	_, fs, err := g.store(req.GetSessionId())
	if err != nil {
		return nil, err
	}
	buckets, err := fs.ListBuckets(ctx, req.GetDatabase())
	if err != nil {
		return &queravuev1.ListBucketsResponse{Error: toGridFsError(err)}, nil
	}
	resp := &queravuev1.ListBucketsResponse{Buckets: make([]*queravuev1.GridFsBucket, len(buckets))}
	for i, b := range buckets {
		resp.Buckets[i] = gridFsBucketToWire(b)
	}
	return resp, nil
}

// ListFiles implements the RPC.
func (g *GridFsService) ListFiles(req *queravuev1.ListFilesRequest, stream queravuev1.GridFsService_ListFilesServer) error {
	sess, fs, err := g.store(req.GetSessionId())
	if err != nil {
		return err
	}
	defer sess.Hold()()

	opt := engine.GridFSListOptions{
		Database:  req.GetDatabase(),
		Bucket:    req.GetBucket(),
		Filter:    req.GetFilter(),
		Sort:      req.GetSort(),
		Skip:      req.GetSkip(),
		Limit:     req.GetLimit(),
		MaxTimeMS: req.GetMaxTimeMs(),
	}
	if opt.MaxTimeMS == 0 {
		opt.MaxTimeMS = defaultGridFSListMaxTimeMS
	}
	sink := &gridFsFileSink{stream: stream}
	err = fs.ListFiles(stream.Context(), opt, sink)
	if err != nil {
		if stream.Context().Err() != nil {
			return status.FromContextError(stream.Context().Err()).Err()
		}
		if sink.sendErr != nil {
			return fmt.Errorf("gridfs: send: %w", sink.sendErr)
		}
		return sendListFiles(stream, &queravuev1.ListFilesResponse{Event: &queravuev1.ListFilesResponse_Error{Error: toGridFsError(err)}})
	}
	return sendListFiles(stream, &queravuev1.ListFilesResponse{Event: &queravuev1.ListFilesResponse_Batch{
		Batch: &queravuev1.GridFsFileBatch{Offset: sink.offset, Done: true},
	}})
}

func sendListFiles(stream queravuev1.GridFsService_ListFilesServer, m *queravuev1.ListFilesResponse) error {
	if err := stream.Send(m); err != nil {
		return fmt.Errorf("gridfs: send: %w", err)
	}
	return nil
}

type gridFsFileSink struct {
	stream  queravuev1.GridFsService_ListFilesServer
	offset  uint64
	sendErr error
}

func (s *gridFsFileSink) Batch(files []engine.GridFSFile) error {
	wire := make([]*queravuev1.GridFsFile, len(files))
	for i, f := range files {
		wire[i] = gridFsFileToWire(f)
	}
	b := &queravuev1.GridFsFileBatch{Offset: s.offset, Files: wire}
	if err := s.stream.Send(&queravuev1.ListFilesResponse{Event: &queravuev1.ListFilesResponse_Batch{Batch: b}}); err != nil {
		s.sendErr = err
		return fmt.Errorf("gridfs: send batch: %w", err)
	}
	s.offset += uint64(len(files))
	return nil
}

// Download implements the RPC.
func (g *GridFsService) Download(req *queravuev1.DownloadRequest, stream queravuev1.GridFsService_DownloadServer) error {
	sess, fs, err := g.store(req.GetSessionId())
	if err != nil {
		return err
	}
	defer sess.Hold()()

	file, rc, err := fs.OpenDownload(stream.Context(), req.GetDatabase(), req.GetBucket(), req.GetIdEjson(), req.GetOffset())
	if err != nil {
		if stream.Context().Err() != nil {
			return status.FromContextError(stream.Context().Err()).Err()
		}
		return sendDownload(stream, &queravuev1.DownloadResponse{Event: &queravuev1.DownloadResponse_Error{Error: toGridFsError(err)}})
	}
	defer func() { _ = rc.Close() }()

	if err := sendDownload(stream, &queravuev1.DownloadResponse{Event: &queravuev1.DownloadResponse_File{File: gridFsFileToWire(file)}}); err != nil {
		return err
	}

	var limited bool
	var remaining uint64
	if req.Length != nil {
		limited = true
		remaining = *req.Length
		if remaining == 0 {
			return nil
		}
	}

	bufSize := gridfsDownloadChunkBytes
	if limited && remaining < uint64(bufSize) {
		bufSize = int(remaining)
	}
	buf := make([]byte, bufSize)
	for {
		if cerr := stream.Context().Err(); cerr != nil {
			return status.FromContextError(cerr).Err()
		}
		readSlice := buf
		if limited && remaining < uint64(len(readSlice)) {
			readSlice = buf[:remaining]
		}
		n, rerr := rc.Read(readSlice)
		if n > 0 {
			chunk := make([]byte, n)
			copy(chunk, readSlice[:n])
			if serr := sendDownload(stream, &queravuev1.DownloadResponse{Event: &queravuev1.DownloadResponse_Chunk{Chunk: chunk}}); serr != nil {
				return serr
			}
			if limited {
				remaining -= uint64(n)
				if remaining == 0 {
					return nil
				}
			}
		}
		if errors.Is(rerr, io.EOF) {
			return nil
		}
		if rerr != nil {
			if cerr := stream.Context().Err(); cerr != nil {
				return status.FromContextError(cerr).Err()
			}
			return sendDownload(stream, &queravuev1.DownloadResponse{Event: &queravuev1.DownloadResponse_Error{Error: toGridFsError(rerr)}})
		}
	}
}

func sendDownload(stream queravuev1.GridFsService_DownloadServer, m *queravuev1.DownloadResponse) error {
	if err := stream.Send(m); err != nil {
		return fmt.Errorf("gridfs: send: %w", err)
	}
	return nil
}

// Upload implements the RPC. Production connections need confirmed=true when
// replacing a file.
func (g *GridFsService) Upload(stream queravuev1.GridFsService_UploadServer) error {
	first, err := stream.Recv()
	if err != nil {
		if cerr := stream.Context().Err(); cerr != nil {
			return status.FromContextError(cerr).Err()
		}
		if errors.Is(err, io.EOF) {
			return sendUploadResult(stream, &queravuev1.UploadResponse{Error: &queravuev1.GridFsError{
				Kind:    queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_PARSE,
				Message: "upload stream missing header",
			}})
		}
		return fmt.Errorf("gridfs: recv header: %w", err)
	}
	hdr := first.GetHeader()
	if hdr == nil {
		return sendUploadResult(stream, &queravuev1.UploadResponse{Error: &queravuev1.GridFsError{
			Kind:    queravuev1.GridFsErrorKind_GRID_FS_ERROR_KIND_PARSE,
			Message: "first upload message must be a header",
		}})
	}
	sess, fs, err := g.store(hdr.GetSessionId())
	if err != nil {
		return err
	}
	defer sess.Hold()()

	if strings.TrimSpace(hdr.GetReplaceIdEjson()) != "" && !hdr.GetConfirmed() && g.production(stream.Context(), sess) {
		return sendUploadResult(stream, &queravuev1.UploadResponse{Error: gridFsConfirmationError("replace file")})
	}

	u := engine.GridFSUpload{
		Database:       hdr.GetDatabase(),
		Bucket:         hdr.GetBucket(),
		Filename:       hdr.GetFilename(),
		ContentType:    hdr.GetContentType(),
		Metadata:       hdr.GetMetadataEjson(),
		ChunkSizeBytes: hdr.GetChunkSizeBytes(),
		ReplaceID:      hdr.GetReplaceIdEjson(),
	}
	file, err := fs.Upload(stream.Context(), u, &uploadStreamReader{stream: stream})
	if err != nil {
		if cerr := stream.Context().Err(); cerr != nil {
			return status.FromContextError(cerr).Err()
		}
		return sendUploadResult(stream, &queravuev1.UploadResponse{Error: toGridFsError(err)})
	}
	return sendUploadResult(stream, &queravuev1.UploadResponse{File: gridFsFileToWire(file)})
}

func sendUploadResult(stream queravuev1.GridFsService_UploadServer, resp *queravuev1.UploadResponse) error {
	if err := stream.SendAndClose(resp); err != nil {
		return fmt.Errorf("gridfs: send upload response: %w", err)
	}
	return nil
}

type uploadStreamReader struct {
	stream queravuev1.GridFsService_UploadServer
	buf    []byte
}

func (r *uploadStreamReader) Read(p []byte) (int, error) {
	if len(p) == 0 {
		return 0, nil
	}
	for len(r.buf) == 0 {
		msg, err := r.stream.Recv()
		if err != nil {
			if errors.Is(err, io.EOF) {
				return 0, io.EOF
			}
			return 0, fmt.Errorf("gridfs: recv chunk: %w", err)
		}
		switch part := msg.Part.(type) {
		case *queravuev1.UploadRequest_Chunk:
			r.buf = part.Chunk
		case *queravuev1.UploadRequest_Header:
			return 0, engine.Errorf(engine.KindParse, "gridfs", "upload", "unexpected header after start of upload")
		default:
			return 0, engine.Errorf(engine.KindParse, "gridfs", "upload", "upload message must carry a chunk")
		}
	}
	n := copy(p, r.buf)
	r.buf = r.buf[n:]
	if len(r.buf) == 0 {
		r.buf = nil
	}
	return n, nil
}

// DeleteFile implements the RPC. Production connections need confirmed=true.
func (g *GridFsService) DeleteFile(ctx context.Context, req *queravuev1.DeleteFileRequest) (*queravuev1.DeleteFileResponse, error) {
	sess, fs, err := g.store(req.GetSessionId())
	if err != nil {
		return nil, err
	}
	if !req.GetConfirmed() && g.production(ctx, sess) {
		return &queravuev1.DeleteFileResponse{Error: gridFsConfirmationError("delete file")}, nil
	}
	if err := fs.DeleteFile(ctx, req.GetDatabase(), req.GetBucket(), req.GetIdEjson()); err != nil {
		return &queravuev1.DeleteFileResponse{Error: toGridFsError(err)}, nil
	}
	return &queravuev1.DeleteFileResponse{}, nil
}

// RenameFile implements the RPC.
func (g *GridFsService) RenameFile(ctx context.Context, req *queravuev1.RenameFileRequest) (*queravuev1.RenameFileResponse, error) {
	_, fs, err := g.store(req.GetSessionId())
	if err != nil {
		return nil, err
	}
	if err := fs.RenameFile(ctx, req.GetDatabase(), req.GetBucket(), req.GetIdEjson(), req.GetNewFilename()); err != nil {
		return &queravuev1.RenameFileResponse{Error: toGridFsError(err)}, nil
	}
	return &queravuev1.RenameFileResponse{}, nil
}
