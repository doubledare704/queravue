package api

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"strings"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/doubledare704/queravue/core/internal/completion"
	"github.com/doubledare704/queravue/core/internal/connections"
	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/history"
	"github.com/doubledare704/queravue/core/internal/session"
)

// Default server-side limits.
const (
	defaultFindTimeout  = 30 * time.Second
	defaultCountTimeout = 10 * time.Second
	maxBatchSize        = 5000
)

// DocumentService implements queravuev1.DocumentServiceServer. Handlers stay
// thin: parsing, concurrency checks and driver calls live in the engine.
type DocumentService struct {
	queravuev1.UnimplementedDocumentServiceServer

	sessions    *session.Manager
	connections *connections.Service
	log         *slog.Logger
	history     *history.Store
	mongo       *completion.MongoCatalog
}

// SetMongoCatalog shares the field path cache with completion.
func (d *DocumentService) SetMongoCatalog(c *completion.MongoCatalog) { d.mongo = c }

// SetHistory records document operations in the query history.
func (d *DocumentService) SetHistory(h *history.Store) { d.history = h }

// record appends an operation to the query history. Document bodies are not
// logged for writes, only a summary (they may hold row data).
func (d *DocumentService) record(sess *session.Session, text string, start time.Time, n uint64, err error) {
	if d.history == nil {
		return
	}
	e := history.Entry{ConnectionID: sess.ConnectionID, QueryText: text, StartedAt: start, Duration: time.Since(start), RowsAffected: n}
	if err != nil {
		e.Error = "failed"
		var ee *engine.Error
		if errors.As(err, &ee) {
			e.Error = ee.Msg
		}
	}
	_, _ = d.history.Append(context.Background(), e)
}

func findText(r *queravuev1.FindRequest) string {
	q := "db." + r.GetCollection() + ".find(" + orEmptyDoc(r.GetFilter())
	if p := r.GetProjection(); p != "" {
		q += ", " + p
	}
	q += ")"
	if s := r.GetSort(); s != "" {
		q += ".sort(" + s + ")"
	}
	if r.GetSkip() > 0 {
		q += fmt.Sprintf(".skip(%d)", r.GetSkip())
	}
	if r.GetLimit() > 0 {
		q += fmt.Sprintf(".limit(%d)", r.GetLimit())
	}
	return "// " + r.GetDatabase() + "\n" + q
}

func orEmptyDoc(s string) string {
	if strings.TrimSpace(s) == "" {
		return "{}"
	}
	return s
}

// NewDocumentService returns a DocumentService handler. connections may be
// nil, in which case no connection counts as production.
func NewDocumentService(s *session.Manager, c *connections.Service, log *slog.Logger) *DocumentService {
	if log == nil {
		log = slog.Default()
	}
	return &DocumentService{sessions: s, connections: c, log: log, mongo: completion.NewMongoCatalog()}
}

func (d *DocumentService) store(sessionID string) (*session.Session, engine.DocumentStore, error) {
	sess, err := d.sessions.Get(sessionID)
	if err != nil {
		return nil, nil, status.Error(codes.NotFound, "session not found")
	}
	ds, ok := engine.As[engine.DocumentStore](sess.Conn)
	if !ok {
		return nil, nil, status.Error(codes.FailedPrecondition, "connection does not support documents")
	}
	return sess, ds, nil
}

func (d *DocumentService) production(ctx context.Context, sess *session.Session) bool {
	if d.connections == nil || sess.ConnectionID == "" {
		return false
	}
	c, err := d.connections.Get(ctx, sess.ConnectionID)
	return err == nil && c.Production
}

// Find implements the RPC.
func (d *DocumentService) Find(req *queravuev1.FindRequest, stream queravuev1.DocumentService_FindServer) error {
	sess, ds, err := d.store(req.GetSessionId())
	if err != nil {
		return err
	}
	started := time.Now()
	opt := engine.FindOptions{
		Database: req.GetDatabase(), Collection: req.GetCollection(),
		Filter: req.GetFilter(), Sort: req.GetSort(), Projection: req.GetProjection(),
		Skip: req.GetSkip(), Limit: req.GetLimit(),
		BatchSize: int(min(req.GetBatchSize(), maxBatchSize)),
		MaxTimeMS: req.GetMaxTimeMs(),
	}
	if opt.MaxTimeMS == 0 {
		opt.MaxTimeMS = uint32(defaultFindTimeout / time.Millisecond)
	}
	sink := &findSink{stream: stream}
	err = ds.Find(stream.Context(), opt, sink)
	d.record(sess, findText(req), started, sink.offset, err)
	if err != nil {
		if stream.Context().Err() != nil {
			return status.FromContextError(stream.Context().Err()).Err()
		}
		if sink.sendErr != nil {
			return fmt.Errorf("document: send: %w", sink.sendErr)
		}
		return sendFind(stream, &queravuev1.FindResponse{Event: &queravuev1.FindResponse_Error{Error: toDocumentError(err)}})
	}
	return sendFind(stream, &queravuev1.FindResponse{Event: &queravuev1.FindResponse_Batch{
		Batch: &queravuev1.DocumentBatch{Offset: sink.offset, Done: true},
	}})
}

func sendFind(stream queravuev1.DocumentService_FindServer, m *queravuev1.FindResponse) error {
	if err := stream.Send(m); err != nil {
		return fmt.Errorf("document: send: %w", err)
	}
	return nil
}

type findSink struct {
	stream  queravuev1.DocumentService_FindServer
	offset  uint64
	sendErr error
}

func (s *findSink) Batch(docs []engine.Document) error {
	b := &queravuev1.DocumentBatch{Offset: s.offset, Documents: append([]string(nil), docs...)}
	if err := s.stream.Send(&queravuev1.FindResponse{Event: &queravuev1.FindResponse_Batch{Batch: b}}); err != nil {
		s.sendErr = err
		return fmt.Errorf("document: send batch: %w", err)
	}
	s.offset += uint64(len(docs))
	return nil
}

// Count implements the RPC.
func (d *DocumentService) Count(ctx context.Context, req *queravuev1.CountRequest) (*queravuev1.CountResponse, error) {
	_, ds, err := d.store(req.GetSessionId())
	if err != nil {
		return nil, err
	}
	ms := req.GetMaxTimeMs()
	if ms == 0 {
		ms = uint32(defaultCountTimeout / time.Millisecond)
	}
	c, err := ds.Count(ctx, req.GetDatabase(), req.GetCollection(), req.GetFilter(), ms)
	if err != nil {
		return &queravuev1.CountResponse{Error: toDocumentError(err)}, nil
	}
	return &queravuev1.CountResponse{Count: c.N, Exact: c.Exact}, nil
}

// InsertDocuments implements the RPC.
func (d *DocumentService) InsertDocuments(ctx context.Context, req *queravuev1.InsertDocumentsRequest) (*queravuev1.InsertDocumentsResponse, error) {
	sess, ds, err := d.store(req.GetSessionId())
	if err != nil {
		return nil, err
	}
	started := time.Now()
	ids, err := ds.Insert(ctx, req.GetDatabase(), req.GetCollection(), req.GetDocuments(), engine.WriteOptions{})
	d.record(sess, "// "+req.GetDatabase()+"\ndb."+req.GetCollection()+".insertMany(…)", started, uint64(len(ids)), err)
	resp := &queravuev1.InsertDocumentsResponse{InsertedIds: ids}
	if err != nil {
		resp.Error = toDocumentError(err)
	}
	return resp, nil
}

func writeOptions(expected *string) engine.WriteOptions {
	return engine.WriteOptions{Expected: expected}
}

// ReplaceDocument implements the RPC.
func (d *DocumentService) ReplaceDocument(ctx context.Context, req *queravuev1.ReplaceDocumentRequest) (*queravuev1.ReplaceDocumentResponse, error) {
	sess, ds, err := d.store(req.GetSessionId())
	if err != nil {
		return nil, err
	}
	started := time.Now()
	doc, err := ds.Replace(ctx, req.GetDatabase(), req.GetCollection(), req.GetId(), req.GetDocument(), writeOptions(req.ExpectedDocument))
	d.record(sess, "// "+req.GetDatabase()+"\ndb."+req.GetCollection()+".replaceOne({_id: "+req.GetId()+"}, …)", started, 1, err)
	if err != nil {
		return &queravuev1.ReplaceDocumentResponse{Error: toDocumentError(err)}, nil
	}
	return &queravuev1.ReplaceDocumentResponse{Document: doc}, nil
}

// UpdateFields implements the RPC.
func (d *DocumentService) UpdateFields(ctx context.Context, req *queravuev1.UpdateFieldsRequest) (*queravuev1.UpdateFieldsResponse, error) {
	sess, ds, err := d.store(req.GetSessionId())
	if err != nil {
		return nil, err
	}
	started := time.Now()
	doc, err := ds.UpdateFields(ctx, req.GetDatabase(), req.GetCollection(), req.GetId(), req.GetSet(), req.GetUnset(), writeOptions(req.ExpectedDocument))
	d.record(sess, "// "+req.GetDatabase()+"\ndb."+req.GetCollection()+".updateOne({_id: "+req.GetId()+"}, …)", started, 1, err)
	if err != nil {
		return &queravuev1.UpdateFieldsResponse{Error: toDocumentError(err)}, nil
	}
	return &queravuev1.UpdateFieldsResponse{Document: doc}, nil
}

// DeleteDocuments implements the RPC. Production connections need
// confirmed=true.
func (d *DocumentService) DeleteDocuments(ctx context.Context, req *queravuev1.DeleteDocumentsRequest) (*queravuev1.DeleteDocumentsResponse, error) {
	sess, ds, err := d.store(req.GetSessionId())
	if err != nil {
		return nil, err
	}
	if !req.GetConfirmed() && d.production(ctx, sess) {
		return &queravuev1.DeleteDocumentsResponse{Error: &queravuev1.DocumentError{
			Kind:    queravuev1.DocumentErrorKind_DOCUMENT_ERROR_KIND_CONFIRMATION_REQUIRED,
			Message: "This connection is flagged as production. Confirmation is required to delete documents.",
		}}, nil
	}
	started := time.Now()
	n, err := ds.Delete(ctx, req.GetDatabase(), req.GetCollection(), req.GetIds(), engine.WriteOptions{})
	d.record(sess, fmt.Sprintf("// %s\ndb.%s.deleteMany({_id: {$in: [… %d ids]}})", req.GetDatabase(), req.GetCollection(), len(req.GetIds())), started, n, err)
	if err != nil {
		return &queravuev1.DeleteDocumentsResponse{Error: toDocumentError(err)}, nil
	}
	return &queravuev1.DeleteDocumentsResponse{DeletedCount: n}, nil
}

// SampleFields implements the RPC.
func (d *DocumentService) SampleFields(ctx context.Context, req *queravuev1.SampleFieldsRequest) (*queravuev1.SampleFieldsResponse, error) {
	_, ds, err := d.store(req.GetSessionId())
	if err != nil {
		return nil, err
	}
	s, err := ds.SampleFields(ctx, req.GetDatabase(), req.GetCollection(), req.GetSampleSize())
	if err != nil {
		return &queravuev1.SampleFieldsResponse{Error: toDocumentError(err)}, nil
	}
	resp := &queravuev1.SampleFieldsResponse{Sampled: s.Sampled, UsedFallback: s.UsedFallback}
	for _, f := range s.Fields {
		fs := &queravuev1.FieldStat{Name: f.Name, Frequency: f.Frequency}
		for _, t := range f.Types {
			fs.Types = append(fs.Types, &queravuev1.TypeCount{Type: t.Type, Count: t.Count})
		}
		resp.Fields = append(resp.Fields, fs)
	}
	return resp, nil
}

// toDocumentError maps an engine error to the wire error. Messages come from
// *engine.Error (already redacted); anything else is reported generically.
func toDocumentError(err error) *queravuev1.DocumentError {
	var e *engine.Error
	if !errors.As(err, &e) {
		return &queravuev1.DocumentError{Kind: queravuev1.DocumentErrorKind_DOCUMENT_ERROR_KIND_SERVER, Message: "operation failed"}
	}
	out := &queravuev1.DocumentError{Kind: documentErrorKind(e.Kind), Message: e.Msg}
	switch e.Kind {
	case engine.KindParse:
		out.Input = documentInput(e.Input)
		if e.Input != engine.InputNone {
			p := uint32(max(e.Position, 0)) //nolint:gosec // clamped to >= 0
			out.Position = &p
		}
		if e.HasIndex {
			i := uint32(max(e.DocumentIndex, 0)) //nolint:gosec // clamped to >= 0
			out.DocumentIndex = &i
		}
	case engine.KindConflict:
		out.CurrentDocument = e.Current
	}
	return out
}

func documentErrorKind(k engine.Kind) queravuev1.DocumentErrorKind {
	switch k {
	case engine.KindParse, engine.KindInvalidConfig:
		return queravuev1.DocumentErrorKind_DOCUMENT_ERROR_KIND_PARSE
	case engine.KindConflict:
		return queravuev1.DocumentErrorKind_DOCUMENT_ERROR_KIND_CONFLICT
	case engine.KindNotFound:
		return queravuev1.DocumentErrorKind_DOCUMENT_ERROR_KIND_NOT_FOUND
	case engine.KindConfirmationRequired:
		return queravuev1.DocumentErrorKind_DOCUMENT_ERROR_KIND_CONFIRMATION_REQUIRED
	case engine.KindAuth:
		return queravuev1.DocumentErrorKind_DOCUMENT_ERROR_KIND_AUTH
	case engine.KindNetwork, engine.KindTLS, engine.KindConnectionLost:
		return queravuev1.DocumentErrorKind_DOCUMENT_ERROR_KIND_NETWORK
	case engine.KindTimeout:
		return queravuev1.DocumentErrorKind_DOCUMENT_ERROR_KIND_TIMEOUT
	case engine.KindCanceled:
		return queravuev1.DocumentErrorKind_DOCUMENT_ERROR_KIND_CANCELED
	case engine.KindUnsupported:
		return queravuev1.DocumentErrorKind_DOCUMENT_ERROR_KIND_UNSUPPORTED
	default:
		return queravuev1.DocumentErrorKind_DOCUMENT_ERROR_KIND_SERVER
	}
}

func documentInput(in engine.Input) queravuev1.DocumentInput {
	switch in {
	case engine.InputFilter:
		return queravuev1.DocumentInput_DOCUMENT_INPUT_FILTER
	case engine.InputSort:
		return queravuev1.DocumentInput_DOCUMENT_INPUT_SORT
	case engine.InputProjection:
		return queravuev1.DocumentInput_DOCUMENT_INPUT_PROJECTION
	case engine.InputDocument:
		return queravuev1.DocumentInput_DOCUMENT_INPUT_DOCUMENT
	default:
		return queravuev1.DocumentInput_DOCUMENT_INPUT_UNSPECIFIED
	}
}

// SampleFieldPaths implements the RPC.
func (d *DocumentService) SampleFieldPaths(ctx context.Context, req *queravuev1.SampleFieldPathsRequest) (*queravuev1.SampleFieldPathsResponse, error) {
	sess, _, err := d.store(req.GetSessionId())
	if err != nil {
		return nil, err
	}
	sample, err := d.mongo.FieldPaths(ctx, sess, completion.PathsRequest{
		Database: req.GetDatabase(), Collection: req.GetCollection(), Refresh: req.GetRefresh(),
		Options: engine.PathSampleOptions{SampleSize: req.GetSampleSize(), MaxDepth: int(req.GetMaxDepth())},
	})
	if err != nil {
		return &queravuev1.SampleFieldPathsResponse{Error: toDocumentError(err)}, nil
	}
	resp := &queravuev1.SampleFieldPathsResponse{Sampled: sample.Sampled, UsedFallback: sample.UsedFallback, Truncated: sample.Truncated}
	for _, p := range sample.Paths {
		stat := &queravuev1.FieldPathStat{Path: p.Path, Frequency: p.Frequency, Depth: uint32(p.Depth)} //nolint:gosec // depth is small and non-negative
		for _, t := range p.Types {
			stat.Types = append(stat.Types, &queravuev1.TypeCount{Type: t.Type, Count: t.Count})
		}
		resp.Paths = append(resp.Paths, stat)
	}
	return resp, nil
}
