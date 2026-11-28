package api

import (
	"bytes"
	"context"
	"errors"
	"fmt"
	"io"
	"maps"
	"path/filepath"
	"slices"
	"strings"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/doubledare704/queravue/core/internal/completion"
	"github.com/doubledare704/queravue/core/internal/dataformat"
	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/results"
	"github.com/doubledare704/queravue/core/internal/session"
	"github.com/doubledare704/queravue/core/internal/sqldialect"
	"github.com/doubledare704/queravue/core/internal/transfer"
)

const maxParquetInferBytes = 512 << 20

// InferImport implements the RPC.
func (t *TransferService) InferImport(stream queravuev1.TransferService_InferImportServer) error {
	first, err := stream.Recv()
	if err != nil {
		return status.Error(codes.InvalidArgument, "the first message must be the header")
	}
	hdr := first.GetHeader()
	if hdr == nil {
		return status.Error(codes.InvalidArgument, "the first message must be the header")
	}
	sess, err := t.session(hdr.GetSessionId())
	if err != nil {
		return err
	}
	chunks := transfer.NewChunkReader(func() ([]byte, error) {
		msg, err := stream.Recv()
		if err != nil {
			return nil, err //nolint:wrapcheck // io.EOF ends the sample
		}
		return msg.GetChunk(), nil
	})
	sample := make([]byte, 0, 64<<10)
	buf := make([]byte, 64<<10)
	for len(sample) < transfer.MaxSampleBytes {
		n, err := chunks.Read(buf)
		sample = append(sample, buf[:n]...)
		if err != nil {
			if !errors.Is(err, io.EOF) && stream.Context().Err() == nil {
				return status.Error(codes.InvalidArgument, "the upload ended unexpectedly")
			}
			break
		}
	}
	_, hasDocs := engine.As[engine.DocumentLoader](sess.Conn)
	req := transfer.InferRequest{
		Filename: hdr.GetFilename(), Options: optionsFromProto(hdr.GetFormatOptions()),
		Documents: hasDocs, Truncated: len(sample) >= transfer.MaxSampleBytes,
	}
	req.Format, _ = formatFromProto(hdr.GetFormat())
	inferred, inferErr := t.infer(stream.Context(), sample, req, io.MultiReader(chunks))
	if inferErr != nil {
		return sendInferResponse(stream, &queravuev1.InferImportResponse{Error: transferErrorToProto(inferErr)})
	}
	return sendInferResponse(stream, inferResponse(inferred, sess.Dialect))
}

func (t *TransferService) infer(ctx context.Context, sample []byte, req transfer.InferRequest, rest io.Reader) (transfer.Inferred, *transfer.Error) {
	format := req.Format
	if format == 0 && len(sample) >= len("PAR1") && string(sample[:4]) == "PAR1" {
		format = transfer.Parquet
	}
	if format == transfer.Parquet || (format == 0 && strings.EqualFold(filepath.Ext(req.Filename), ".parquet")) {
		return transfer.InferParquet(ctx, io.MultiReader(bytes.NewReader(sample), io.LimitReader(rest, maxParquetInferBytes)), t.parquetConfig())
	}
	return transfer.Infer(ctx, sample, req)
}

func inferResponse(in transfer.Inferred, dialect sqldialect.Dialect) *queravuev1.InferImportResponse {
	out := &queravuev1.InferImportResponse{
		Format: formatToProto(in.Format), FormatOptions: optionsToProto(in.Options),
		PreviewDocumentsEjson: in.PreviewDocs, Warnings: in.Warnings,
	}
	for _, c := range in.Columns {
		col := &queravuev1.ImportColumn{Name: c.Name, InferredKind: results.KindToProto(c.Kind), Nullable: c.Nullable}
		if dialect != nil {
			col.SuggestedTypeName = sqldialect.ImportColumnType(dialect, c.Kind)
		}
		out.Columns = append(out.Columns, col)
	}
	if len(in.Preview) > 0 {
		out.PreviewRows = &queravuev1.RowBatch{Rows: results.RowsToProto(in.Preview)}
	}
	return out
}

type importRun struct {
	svc    *TransferService
	stream queravuev1.TransferService_ImportServer
	sess   *session.Session
	hdr    *queravuev1.ImportHeader
	format transfer.Format
	opts   transfer.Options
	chunks *transfer.ChunkReader
	ddl    string
}

// Import implements the RPC.
func (t *TransferService) Import(stream queravuev1.TransferService_ImportServer) error {
	first, err := stream.Recv()
	if err != nil || first.GetHeader() == nil {
		return status.Error(codes.InvalidArgument, "the first message must be the header")
	}
	hdr := first.GetHeader()
	sess, err := t.session(hdr.GetSessionId())
	if err != nil {
		return err
	}
	format, ok := formatFromProto(hdr.GetFormat())
	if !ok {
		return status.Error(codes.InvalidArgument, "a file format is required")
	}
	r := &importRun{svc: t, stream: stream, sess: sess, hdr: hdr, format: format, opts: optionsFromProto(hdr.GetFormatOptions())}
	r.chunks = transfer.NewChunkReader(r.nextChunk)
	if err := r.checkCapabilities(); err != nil {
		return err
	}
	if rejected := r.checkRequest(); rejected != nil {
		return r.sendError(rejected)
	}
	if isProduction(stream.Context(), t.connections, sess) && !hdr.GetConfirmed() {
		return r.sendError(&transfer.Error{Kind: transfer.KindConfirmationRequired, Message: "This connection is flagged as production. Confirmation is required to import."})
	}
	ctx, finish, err := beginTransfer(stream.Context(), sess)
	if err != nil {
		return err
	}
	defer finish()
	return r.run(ctx)
}

func (r *importRun) nextChunk() ([]byte, error) {
	msg, err := r.stream.Recv()
	if err != nil {
		return nil, err //nolint:wrapcheck // io.EOF ends the file
	}
	if msg.GetHeader() != nil {
		return nil, &transfer.Error{Kind: transfer.KindParse, Message: "the header was sent twice"}
	}
	return msg.GetChunk(), nil
}

func (r *importRun) checkCapabilities() error {
	conn := r.sess.Conn
	_, canExec := engine.As[engine.Executor](conn)
	_, canRows := engine.As[engine.RowLoader](conn)
	_, canDocs := engine.As[engine.DocumentLoader](conn)
	switch {
	case r.format == transfer.SQL:
		if !canExec || r.sess.Dialect == nil {
			return status.Error(codes.FailedPrecondition, "connection cannot run SQL scripts")
		}
	case r.hdr.GetCollection() != nil:
		if !canDocs {
			return status.Error(codes.FailedPrecondition, "connection does not support document loading")
		}
	case r.hdr.GetExistingTable() != nil || r.hdr.GetNewTable() != nil:
		if !canRows {
			return status.Error(codes.FailedPrecondition, "connection does not support bulk row loading")
		}
		if r.hdr.GetNewTable() != nil && (!canExec || r.sess.Dialect == nil) {
			return status.Error(codes.FailedPrecondition, "connection cannot create tables")
		}
	default:
		return status.Error(codes.InvalidArgument, "an import target is required")
	}
	return nil
}

func (r *importRun) checkRequest() *transfer.Error {
	switch {
	case r.hdr.GetSingleTransaction():
		return &transfer.Error{Kind: transfer.KindUnsupported, Message: "single_transaction is not supported by the bulk loaders yet; rows commit per batch"}
	case r.format == transfer.Parquet && !transfer.ParquetAvailable:
		return &transfer.Error{Kind: transfer.KindUnsupported, Message: "Parquet needs a core built with DuckDB"}
	}
	return nil
}

func (r *importRun) sendError(err *transfer.Error) error {
	return r.send(&queravuev1.ImportResponse{Event: &queravuev1.ImportResponse_Error{Error: transferErrorToProto(err)}})
}

func (r *importRun) send(msg *queravuev1.ImportResponse) error {
	if err := r.stream.Send(msg); err != nil {
		return fmt.Errorf("transfer: send: %w", err)
	}
	return nil
}

func (r *importRun) progress(committed, bytesRead uint64) error {
	return r.send(&queravuev1.ImportResponse{Event: &queravuev1.ImportResponse_Progress{
		Progress: &queravuev1.ImportProgress{RowsCommitted: committed, BytesRead: bytesRead},
	}})
}

func (r *importRun) run(ctx context.Context) error {
	var res transfer.Result
	switch {
	case r.format == transfer.SQL:
		res = r.runScript(ctx)
	case r.hdr.GetCollection() != nil:
		res = r.runCollection(ctx)
	default:
		res = r.runTable(ctx)
	}
	if ctx.Err() != nil && res.Err != nil && res.Err.Kind != transfer.KindCanceled {
		res.Err = &transfer.Error{Kind: transfer.KindCanceled, Message: "the import was cancelled"}
	}
	if res.Err != nil {
		if err := r.sendError(res.Err); err != nil && ctx.Err() == nil {
			return err
		}
	}
	if err := r.sendSummary(res); err != nil && ctx.Err() == nil {
		return err
	}
	return nil
}

func (r *importRun) sendSummary(res transfer.Result) error {
	summary := &queravuev1.ImportSummary{RowsCommitted: res.Committed, RowsSkipped: res.Skipped, Ddl: r.ddl}
	for _, e := range res.RowErrors {
		summary.RowErrors = append(summary.RowErrors, &queravuev1.ImportRowError{Line: e.Line, Column: e.Column, Message: e.Message})
	}
	return r.send(&queravuev1.ImportResponse{Event: &queravuev1.ImportResponse_Summary{Summary: summary}})
}

func (r *importRun) importer() *transfer.Importer {
	policy := transfer.PolicyStop
	if r.hdr.GetErrorPolicy() == queravuev1.ImportErrorPolicy_IMPORT_ERROR_POLICY_SKIP {
		policy = transfer.PolicySkip
	}
	im := &transfer.Importer{Policy: policy, MaxRowErrors: int(r.hdr.GetMaxRowErrors()), BytesRead: r.chunks.Bytes, Progress: r.progress}
	im.RowLoader, _ = engine.As[engine.RowLoader](r.sess.Conn)
	im.DocLoader, _ = engine.As[engine.DocumentLoader](r.sess.Conn)
	return im
}

func (r *importRun) mappings() []transfer.Mapping {
	out := make([]transfer.Mapping, len(r.hdr.GetMappings()))
	for i, m := range r.hdr.GetMappings() {
		out[i] = transfer.Mapping{SourceIndex: int(m.GetSourceIndex()), Target: m.GetTargetColumn()}
	}
	return out
}

func failed(err error) transfer.Result {
	return transfer.Result{Err: transfer.Classify(err)}
}

func (r *importRun) openRows(ctx context.Context) (transfer.RowReader, func(), error) {
	if r.format == transfer.Parquet {
		rd, err := transfer.OpenParquetReader(ctx, r.chunks, r.svc.parquetConfig())
		if err != nil {
			return nil, nil, err
		}
		return rd, rd.Close, nil
	}
	opts, err := r.opts.DataformatOptions(r.format)
	if err != nil {
		return nil, nil, err
	}
	rd, err := dataformat.NewReader(ctx, r.chunks, opts, nil)
	if err != nil {
		return nil, nil, err
	}
	return rd, func() {}, nil
}

func (r *importRun) runTable(ctx context.Context) transfer.Result {
	rd, closeReader, err := r.openRows(ctx)
	if err != nil {
		return failed(err)
	}
	defer closeReader()
	fileColumns, err := rd.Columns(ctx)
	if err != nil {
		return failed(err)
	}
	var ref *queravuev1.TableRef
	var targetColumns []engine.ColumnDef
	switch {
	case r.hdr.GetNewTable() != nil:
		ref = r.hdr.GetNewTable().GetTable()
		targetColumns = columnDefsOfNewTable(r.hdr.GetNewTable())
	default:
		ref = r.hdr.GetExistingTable()
		if si, ok := engine.As[engine.SchemaInspector](r.sess.Conn); ok {
			td, err := si.DescribeTable(ctx, ref.GetDatabase(), ref.GetSchema(), ref.GetTable())
			if err != nil {
				return failed(err)
			}
			targetColumns = td.Columns
		}
	}
	mapper, mapErr := transfer.BuildMapper(fileColumns, r.mappings(), targetColumns, r.format == transfer.JSON || r.format == transfer.NDJSON || r.format == transfer.Parquet)
	if mapErr != nil {
		return transfer.Result{Err: mapErr}
	}
	if r.hdr.GetNewTable() != nil {
		if err := r.createTable(ctx); err != nil {
			return failed(err)
		}
	}
	target := engine.LoadTarget{Database: ref.GetDatabase(), Schema: ref.GetSchema(), Table: ref.GetTable()}
	return r.importer().ImportRows(ctx, rd, mapper, target)
}

func (r *importRun) createTable(ctx context.Context) error {
	nt := r.hdr.GetNewTable()
	ref := nt.GetTable()
	script, err := transfer.CreateTableScript(r.sess.Dialect, sqldialect.Target{Database: ref.GetDatabase(), Schema: ref.GetSchema(), Table: ref.GetTable()}, designOfNewTable(nt))
	if err != nil {
		return err
	}
	ex, _ := engine.As[engine.Executor](r.sess.Conn)
	for _, stmt := range script.Statements {
		if _, err := ex.Execute(ctx, engine.Statement{SQL: stmt.SQL}, discardRows{}); err != nil {
			return fmt.Errorf("create table: %w", err)
		}
		r.ddl += stmt.SQL + "\n"
		r.schemaChanged()
	}
	return nil
}

func (r *importRun) runCollection(ctx context.Context) transfer.Result {
	coll := r.hdr.GetCollection()
	im := r.importer()
	if r.format == transfer.JSON || r.format == transfer.NDJSON {
		opts, err := r.opts.DataformatOptions(r.format)
		if err != nil {
			return failed(err)
		}
		rd, err := dataformat.NewDocumentReader(ctx, r.chunks, opts, false)
		if err != nil {
			return failed(err)
		}
		return im.ImportDocuments(ctx, rd, coll.GetDatabase(), coll.GetCollection())
	}
	rd, closeReader, err := r.openRows(ctx)
	if err != nil {
		return failed(err)
	}
	defer closeReader()
	fileColumns, err := rd.Columns(ctx)
	if err != nil {
		return failed(err)
	}
	mapper, mapErr := transfer.BuildFieldMapper(fileColumns, r.mappings())
	if mapErr != nil {
		return transfer.Result{Err: mapErr}
	}
	return im.ImportRowsAsDocuments(ctx, rd, mapper, coll.GetDatabase(), coll.GetCollection())
}

func (r *importRun) runScript(ctx context.Context) transfer.Result {
	ex, _ := engine.As[engine.Executor](r.sess.Conn)
	lexer := r.sess.Dialect.Lexer()
	runner := &transfer.ScriptRunner{
		Executor: ex, Dialect: lexer, BytesRead: r.chunks.Bytes, Progress: r.progress,
		AfterStatement: func(sql string) {
			if completion.IsSchemaChange(lexer, sql) {
				r.schemaChanged()
			}
		},
	}
	res := runner.Run(ctx, r.chunks)
	out := transfer.Result{Committed: res.Committed, Err: res.Err}
	if res.Err != nil && res.Line > 0 {
		out.RowErrors = []transfer.RowError{{Line: res.Line, Message: res.Err.Message}}
	}
	return out
}

func (r *importRun) schemaChanged() {
	if r.svc.schemaChanged != nil {
		r.svc.schemaChanged(r.sess.ID)
	}
}

type discardRows struct{}

func (discardRows) Columns([]engine.Column) error { return nil }
func (discardRows) Batch([][]engine.Value) error  { return nil }

func columnDefsOfNewTable(nt *queravuev1.NewTable) []engine.ColumnDef {
	out := make([]engine.ColumnDef, len(nt.GetColumns()))
	for i, c := range nt.GetColumns() {
		out[i] = engine.ColumnDef{Name: c.GetName(), TypeName: c.GetTypeName(), Kind: engineKindOfProto(c.GetKind()), Nullable: c.GetNullable()}
	}
	return out
}

func designOfNewTable(nt *queravuev1.NewTable) sqldialect.TableDesign {
	design := sqldialect.TableDesign{}
	keys := map[uint32]string{}
	for _, c := range nt.GetColumns() {
		design.Columns = append(design.Columns, sqldialect.ColumnSpec{
			Name: c.GetName(), TypeName: c.GetTypeName(), Nullable: c.GetNullable(),
			Default: c.DefaultValue, Identity: c.GetIdentity(), Collation: c.Collation,
		})
		if c.GetIsPrimaryKey() {
			keys[c.GetPrimaryKeyOrder()] = c.GetName()
		}
	}
	for _, order := range slices.Sorted(maps.Keys(keys)) {
		design.PrimaryKey = append(design.PrimaryKey, keys[order])
	}
	return design
}

func sendInferResponse(stream queravuev1.TransferService_InferImportServer, resp *queravuev1.InferImportResponse) error {
	if err := stream.SendAndClose(resp); err != nil {
		return fmt.Errorf("transfer: send: %w", err)
	}
	return nil
}
