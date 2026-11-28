package api

import (
	"context"
	"errors"
	"fmt"
	"log/slog"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/doubledare704/queravue/core/internal/connections"
	"github.com/doubledare704/queravue/core/internal/dataformat"
	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/results"
	"github.com/doubledare704/queravue/core/internal/session"
	"github.com/doubledare704/queravue/core/internal/sqlbuilder"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
	"github.com/doubledare704/queravue/core/internal/transfer"
)

// ParquetMemoryLimit caps the DuckDB buffers of one Parquet transfer.
const ParquetMemoryLimit = "24MiB"

// TransferService implements queravuev1.TransferServiceServer.
type TransferService struct {
	queravuev1.UnimplementedTransferServiceServer

	sessions    *session.Manager
	results     *results.Manager
	connections *connections.Service
	log         *slog.Logger
}

// NewTransferService returns a TransferService backed by s, r and c. connections may be
// nil, in which case no connection counts as production.
func NewTransferService(s *session.Manager, r *results.Manager, c *connections.Service, log *slog.Logger) *TransferService {
	if log == nil {
		log = slog.Default()
	}
	return &TransferService{sessions: s, results: r, connections: c, log: log}
}

func (t *TransferService) session(id string) (*session.Session, error) {
	sess, err := t.sessions.Get(id)
	if err != nil {
		return nil, status.Error(codes.NotFound, "session not found")
	}
	return sess, nil
}

func (t *TransferService) parquetConfig() transfer.ParquetConfig {
	return transfer.ParquetConfig{Dir: t.results.Dir(), MemoryLimit: ParquetMemoryLimit}
}

func beginTransfer(ctx context.Context, sess *session.Session) (context.Context, func(), error) {
	runCtx, finish, err := sess.Begin(ctx)
	switch {
	case errors.Is(err, session.ErrBusy):
		return nil, nil, status.Error(codes.FailedPrecondition, "session is busy running another statement")
	case err != nil:
		return nil, nil, status.Error(codes.NotFound, "session not found")
	}
	return runCtx, finish, nil
}

// ListFormats implements the RPC.
func (t *TransferService) ListFormats(context.Context, *queravuev1.ListFormatsRequest) (*queravuev1.ListFormatsResponse, error) {
	imports, exports := transfer.Formats()
	out := &queravuev1.ListFormatsResponse{}
	for _, f := range imports {
		out.ImportFormats = append(out.ImportFormats, formatToProto(f))
	}
	for _, f := range exports {
		out.ExportFormats = append(out.ExportFormats, formatToProto(f))
	}
	return out, nil
}

type exportJob struct {
	format   transfer.Format
	filename string
	write    func(ctx context.Context, run *transfer.ExportRun) error
}

func (t *TransferService) export(ctx context.Context, send func(*queravuev1.ExportEvent) error, job exportJob) error {
	if err := send(&queravuev1.ExportEvent{Event: &queravuev1.ExportEvent_Header{Header: &queravuev1.ExportHeader{
		Format: formatToProto(job.format), SuggestedFilename: job.filename,
	}}}); err != nil {
		return fmt.Errorf("transfer: send header: %w", err)
	}
	var sendErr error
	guard := func(ev *queravuev1.ExportEvent) error {
		if err := send(ev); err != nil {
			sendErr = err
			return err
		}
		return nil
	}
	run := transfer.NewExportRun(
		func(chunk []byte) error {
			return guard(&queravuev1.ExportEvent{Event: &queravuev1.ExportEvent_Chunk{Chunk: chunk}})
		},
		func(rows, bytes uint64) error {
			return guard(&queravuev1.ExportEvent{Event: &queravuev1.ExportEvent_Progress{Progress: &queravuev1.ExportProgress{Rows: rows, Bytes: bytes}}})
		},
	)
	err := job.write(ctx, run)
	var rows, bytes uint64
	if err == nil {
		rows, bytes, err = run.Finish()
	}
	switch {
	case sendErr != nil:
		return fmt.Errorf("transfer: send: %w", sendErr)
	case ctx.Err() != nil:
		return status.FromContextError(ctx.Err()).Err()
	case err != nil:
		t.log.Warn("export failed", "kind", transfer.Classify(err).Kind, "cause", fmt.Sprintf("%T", errors.Unwrap(err)))
		return send(&queravuev1.ExportEvent{Event: &queravuev1.ExportEvent_Error{Error: transferErrorToProto(err)}})
	}
	return send(&queravuev1.ExportEvent{Event: &queravuev1.ExportEvent_Summary{Summary: &queravuev1.ExportSummary{Rows: rows, Bytes: bytes}}})
}

func exportFormat(options *queravuev1.ExportOptions) (transfer.Format, transfer.Options, error) {
	format, ok := formatFromProto(options.GetFormat())
	if !ok {
		return 0, transfer.Options{}, status.Error(codes.InvalidArgument, "an export format is required")
	}
	return format, optionsFromProto(options.GetFormatOptions()), nil
}

type spoolRows struct{ spool *results.Spool }

func (s spoolRows) ReadRows(offset uint64, limit int) ([][]engine.Value, error) {
	rows, err := s.spool.ReadRows(offset, limit)
	if err != nil {
		return nil, fmt.Errorf("read spool: %w", err)
	}
	out := make([][]engine.Value, len(rows))
	for i, row := range rows {
		out[i] = make([]engine.Value, len(row.GetValues()))
		for j, v := range row.GetValues() {
			out[i][j] = results.ValueFromProto(v)
		}
	}
	return out, nil
}

func (s spoolRows) State() (uint64, bool) {
	rows, done, _ := s.spool.State()
	return rows, done
}

// ExportResult implements the RPC.
func (t *TransferService) ExportResult(req *queravuev1.ExportResultRequest, stream queravuev1.TransferService_ExportResultServer) error {
	format, opts, err := exportFormat(req.GetOptions())
	if err != nil {
		return err
	}
	spool, err := t.results.Get(req.GetResultId())
	if err != nil {
		return status.Error(codes.NotFound, "result not found")
	}
	var dialect sqldialect.Dialect
	if id, ok := t.results.SessionOf(req.GetResultId()); ok {
		if sess, err := t.sessions.Get(id); err == nil {
			dialect = sess.Dialect
		}
	}
	cols := engineColumnsOfProto(spool.Columns())
	picks := make([]int, len(req.GetColumnIndices()))
	for i, p := range req.GetColumnIndices() {
		picks[i] = int(p)
	}
	job := exportJob{format: format, filename: transfer.SuggestedFilename("result", format)}
	job.write = func(ctx context.Context, run *transfer.ExportRun) error {
		chosen := cols
		if len(picks) > 0 {
			chosen = make([]engine.Column, 0, len(picks))
			for _, p := range picks {
				if p >= 0 && p < len(cols) {
					chosen = append(chosen, cols[p])
				}
			}
		}
		w, err := transfer.NewRowWriter(run.Output(), transfer.RowFormat{
			Format: format, Options: opts, Dialect: dialect, Target: sqldialect.Target{Table: "export"},
			Design: transfer.DesignOfColumns(chosen), Parquet: t.parquetConfig(),
		})
		if err != nil {
			return err
		}
		return transfer.ExportSpool(ctx, spoolRows{spool}, cols, picks, w, run)
	}
	return t.export(stream.Context(), func(ev *queravuev1.ExportEvent) error {
		return stream.Send(&queravuev1.ExportResultResponse{Event: ev})
	}, job)
}

// ExportTable implements the RPC.
func (t *TransferService) ExportTable(req *queravuev1.ExportTableRequest, stream queravuev1.TransferService_ExportTableServer) error {
	format, opts, err := exportFormat(req.GetOptions())
	if err != nil {
		return err
	}
	sess, err := t.session(req.GetSessionId())
	if err != nil {
		return err
	}
	ex, ok := engine.As[engine.Executor](sess.Conn)
	if !ok || sess.Dialect == nil {
		return status.Error(codes.FailedPrecondition, "connection cannot execute statements")
	}
	ref := req.GetTable()
	filename := transfer.SuggestedFilename(ref.GetTable(), format)
	send := func(ev *queravuev1.ExportEvent) error {
		return stream.Send(&queravuev1.ExportTableResponse{Event: ev})
	}
	sqlText, params, buildErr := sqlbuilder.BuildSelect(sess.Dialect, ref, req.GetFilter(), req.GetSort(), 0)
	if buildErr != nil {
		return send(&queravuev1.ExportEvent{Event: &queravuev1.ExportEvent_Error{
			Error: transferErrorToProto(&transfer.Error{Kind: transfer.KindParse, Message: "cannot build the query: " + buildErr.Error()}),
		}})
	}
	ctx, finish, err := beginTransfer(stream.Context(), sess)
	if err != nil {
		return err
	}
	defer finish()
	job := exportJob{format: format, filename: filename}
	job.write = func(ctx context.Context, run *transfer.ExportRun) error {
		target := sqldialect.Target{Database: ref.GetDatabase(), Schema: ref.GetSchema(), Table: ref.GetTable()}
		var design *sqldialect.TableDesign
		if format == transfer.SQL && opts.SQLIncludeDDL {
			if si, ok := engine.As[engine.SchemaInspector](sess.Conn); ok {
				if td, err := si.DescribeTable(ctx, target.Database, target.Schema, target.Table); err == nil {
					design = transfer.DesignOfTable(td, req.GetColumns())
				}
			}
		}
		var sink *transfer.RowsToWriter
		defer func() { sink.Abort() }()
		sink = &transfer.RowsToWriter{Ctx: ctx, Run: run, Only: req.GetColumns(), NewFile: func(cols []engine.Column) (dataformat.Writer, error) {
			if design == nil {
				design = transfer.DesignOfColumns(cols)
			}
			return transfer.NewRowWriter(run.Output(), transfer.RowFormat{
				Format: format, Options: opts, Dialect: sess.Dialect, Target: target, Design: design, Parquet: t.parquetConfig(),
			})
		}}
		if _, err := ex.Execute(ctx, engine.Statement{SQL: sqlText, Params: params}, sink); err != nil {
			return err
		}
		return sink.Close()
	}
	return t.export(ctx, send, job)
}

// ExportCollection implements the RPC.
func (t *TransferService) ExportCollection(req *queravuev1.ExportCollectionRequest, stream queravuev1.TransferService_ExportCollectionServer) error {
	format, opts, err := exportFormat(req.GetOptions())
	if err != nil {
		return err
	}
	sess, err := t.session(req.GetSessionId())
	if err != nil {
		return err
	}
	ds, ok := engine.As[engine.DocumentStore](sess.Conn)
	if !ok {
		return status.Error(codes.FailedPrecondition, "connection does not support documents")
	}
	send := func(ev *queravuev1.ExportEvent) error {
		return stream.Send(&queravuev1.ExportCollectionResponse{Event: ev})
	}
	sendError := func(kind transfer.ErrorKind, message string) error {
		return send(&queravuev1.ExportEvent{Event: &queravuev1.ExportEvent_Error{Error: transferErrorToProto(&transfer.Error{Kind: kind, Message: message})}})
	}
	tabular := format != transfer.JSON && format != transfer.NDJSON
	switch {
	case format == transfer.SQL:
		return sendError(transfer.KindUnsupported, "collections cannot be exported as SQL")
	case tabular && len(req.GetFieldPaths()) == 0:
		return sendError(transfer.KindMapping, "choose the field paths that become columns")
	}
	ctx, finish, err := beginTransfer(stream.Context(), sess)
	if err != nil {
		return err
	}
	defer finish()
	ref := req.GetCollection()
	job := exportJob{format: format, filename: transfer.SuggestedFilename(ref.GetCollection(), format)}
	job.write = func(ctx context.Context, run *transfer.ExportRun) error {
		find := engine.FindOptions{
			Database: ref.GetDatabase(), Collection: ref.GetCollection(),
			Filter: req.GetFilterEjson(), Sort: req.GetSortEjson(), Projection: req.GetProjectionEjson(),
		}
		if !tabular {
			w, err := transfer.NewDocumentWriter(run.Output(), format, opts.CanonicalJSON)
			if err != nil {
				return err
			}
			if err := ds.Find(ctx, find, &transfer.DocsToJSON{Ctx: ctx, Run: run, Writer: w}); err != nil {
				return err
			}
			return w.Close(ctx)
		}
		paths := transfer.NewPathExtractor(req.GetFieldPaths(), opts.CanonicalJSON)
		w, err := transfer.NewRowWriter(run.Output(), transfer.RowFormat{Format: format, Options: opts, Parquet: t.parquetConfig()})
		if err != nil {
			return err
		}
		defer transfer.AbortWriter(w)
		if err := w.Columns(ctx, paths.Columns(req.GetFieldPaths())); err != nil {
			return err
		}
		if err := ds.Find(ctx, find, &transfer.DocsToRows{Ctx: ctx, Run: run, Writer: w, Paths: paths}); err != nil {
			return err
		}
		return w.Close(ctx)
	}
	return t.export(ctx, send, job)
}
