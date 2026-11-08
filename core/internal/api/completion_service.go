package api

import (
	"context"
	"errors"
	"fmt"
	"strings"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/doubledare704/queravue/core/internal/completion"
	"github.com/doubledare704/queravue/core/internal/format"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/session"
	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

// CompletionService implements queravuev1.CompletionServiceServer.
type CompletionService struct {
	queravuev1.UnimplementedCompletionServiceServer

	sessions *session.Manager
	catalogs *completion.Manager
}

// NewCompletionService returns a CompletionService handler.
func NewCompletionService(s *session.Manager, catalogs *completion.Manager) *CompletionService {
	return &CompletionService{sessions: s, catalogs: catalogs}
}

func adminErr(kind queravuev1.AdminErrorKind, msg string) *queravuev1.AdminError {
	return &queravuev1.AdminError{Kind: kind, Message: msg}
}

func unsupported(msg string) *queravuev1.AdminError {
	return adminErr(queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_UNSUPPORTED, msg)
}

// Complete implements the RPC.
func (c *CompletionService) Complete(ctx context.Context, req *queravuev1.CompleteRequest) (*queravuev1.CompleteResponse, error) {
	sess, err := c.sessions.Get(req.GetSessionId())
	if err != nil {
		return nil, status.Error(codes.NotFound, "session not found")
	}
	switch req.GetKind() {
	case queravuev1.CompletionContextKind_COMPLETION_CONTEXT_KIND_SQL:
	case queravuev1.CompletionContextKind_COMPLETION_CONTEXT_KIND_SHELL,
		queravuev1.CompletionContextKind_COMPLETION_CONTEXT_KIND_MONGO_QUERY:
		return &queravuev1.CompleteResponse{Error: unsupported("completion for this context is not available yet")}, nil
	default:
		return &queravuev1.CompleteResponse{Error: adminErr(queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_INVALID, "completion context kind is required")}, nil
	}
	if sess.Dialect == nil {
		return &queravuev1.CompleteResponse{Error: unsupported("this connection does not speak SQL")}, nil
	}

	snap := c.catalogs.Snapshot(sess.ID, req.GetDatabase())
	if snap.State() == completion.StateCold {
		c.catalogs.Start(sess, req.GetDatabase())
	}
	res, err := completion.Complete(ctx, completion.Request{
		Dialect:  sess.Dialect.Lexer(),
		Text:     req.GetText(),
		Cursor:   int(req.GetCursorOffset()),
		MaxItems: int(req.GetMaxItems()),
		Schema:   req.GetSchema(),
		Snapshot: snap,
		Recency:  c.catalogs.Recency(sess.ID),
	})
	if err != nil {
		return &queravuev1.CompleteResponse{Error: adminErr(queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_CANCELED, "completion was cancelled")}, nil
	}
	out := &queravuev1.CompleteResponse{IsIncomplete: res.Incomplete, CatalogState: catalogState(res.State)}
	out.Items = make([]*queravuev1.CompletionItem, len(res.Items))
	for i, it := range res.Items {
		out.Items[i] = &queravuev1.CompletionItem{
			Label: it.Label, Kind: itemKind(it.Kind), Detail: it.Detail, InsertText: it.InsertText, SortKey: it.SortKey,
			Replace: &queravuev1.TextRange{Start: uint32(it.ReplaceStart), End: uint32(it.ReplaceEnd)}, //nolint:gosec // offsets are non-negative
		}
	}
	return out, nil
}

// WarmCatalog implements the RPC.
func (c *CompletionService) WarmCatalog(req *queravuev1.WarmCatalogRequest, stream queravuev1.CompletionService_WarmCatalogServer) error {
	sess, err := c.sessions.Get(req.GetSessionId())
	if err != nil {
		return status.Error(codes.NotFound, "session not found")
	}
	send := func(p completion.Progress) error {
		msg := &queravuev1.WarmCatalogResponse{
			SchemasTotal: uint32(p.SchemasTotal), SchemasDone: uint32(p.SchemasDone), //nolint:gosec // counters are non-negative
			TablesLoaded: uint32(p.TablesLoaded), ColumnsLoaded: uint32(p.ColumnsLoaded), //nolint:gosec // counters are non-negative
			Done: p.Done,
		}
		if p.Err != nil {
			msg.Error = warmError(p.Err)
		}
		if err := stream.Send(msg); err != nil {
			return fmt.Errorf("completion: send progress: %w", err)
		}
		return nil
	}
	if sess.Dialect == nil {
		return send(completion.Progress{Done: true, Err: completion.ErrNotSupported})
	}
	err = c.catalogs.Watch(stream.Context(), sess, req.GetDatabase(), send)
	if errors.Is(err, context.Canceled) && stream.Context().Err() != nil {
		return status.FromContextError(stream.Context().Err()).Err()
	}
	return err
}

func warmError(err error) *queravuev1.AdminError {
	switch {
	case errors.Is(err, completion.ErrNotSupported):
		return unsupported("this connection cannot list columns in bulk")
	case errors.Is(err, context.Canceled):
		return adminErr(queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_CANCELED, "loading the catalog was cancelled")
	}
	return toAdminError(err)
}

func catalogState(s completion.State) queravuev1.CatalogState {
	switch s {
	case completion.StateWarming:
		return queravuev1.CatalogState_CATALOG_STATE_WARMING
	case completion.StateReady:
		return queravuev1.CatalogState_CATALOG_STATE_READY
	}
	return queravuev1.CatalogState_CATALOG_STATE_COLD
}

func itemKind(k completion.Kind) queravuev1.CompletionItemKind {
	switch k {
	case completion.KindKeyword:
		return queravuev1.CompletionItemKind_COMPLETION_ITEM_KIND_KEYWORD
	case completion.KindFunction:
		return queravuev1.CompletionItemKind_COMPLETION_ITEM_KIND_FUNCTION
	case completion.KindTable:
		return queravuev1.CompletionItemKind_COMPLETION_ITEM_KIND_TABLE
	case completion.KindView:
		return queravuev1.CompletionItemKind_COMPLETION_ITEM_KIND_VIEW
	case completion.KindColumn:
		return queravuev1.CompletionItemKind_COMPLETION_ITEM_KIND_COLUMN
	case completion.KindSchema:
		return queravuev1.CompletionItemKind_COMPLETION_ITEM_KIND_SCHEMA
	case completion.KindAlias:
		return queravuev1.CompletionItemKind_COMPLETION_ITEM_KIND_ALIAS
	}
	return queravuev1.CompletionItemKind_COMPLETION_ITEM_KIND_UNSPECIFIED
}

// FormatSQL implements the RPC.
func (c *CompletionService) FormatSQL(_ context.Context, req *queravuev1.FormatSQLRequest) (*queravuev1.FormatSQLResponse, error) {
	lexer, errResp, err := c.formatDialect(req)
	if err != nil || errResp != nil {
		return errResp, err
	}
	text := req.GetText()
	offsets := sqlsplit.NewOffsetMap(text)
	whole := &queravuev1.TextRange{End: utf16Offset(offsets, len(text))}
	replaced := whole
	start, end := 0, len(text)
	if r := req.GetRange(); r != nil {
		if r.GetStart() > r.GetEnd() || r.GetEnd() > whole.GetEnd() {
			return &queravuev1.FormatSQLResponse{Error: adminErr(queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_INVALID, "range is outside the text")}, nil
		}
		replaced = r
		start, end = offsets.ToByte(int(r.GetStart())), offsets.ToByte(int(r.GetEnd()))
	}
	formatted, err := format.Format(lexer, text[start:end], formatOptions(req.GetOptions()))
	var syntaxErr *format.SyntaxError
	if errors.As(err, &syntaxErr) {
		pos := utf16Offset(offsets, start+syntaxErr.Offset)
		return &queravuev1.FormatSQLResponse{Error: &queravuev1.AdminError{
			Kind: queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_INVALID, Message: syntaxErr.Message, Position: &pos,
		}}, nil
	}
	if err != nil {
		return nil, status.Error(codes.Internal, "formatting failed")
	}
	return &queravuev1.FormatSQLResponse{FormattedText: formatted, ReplacedRange: replaced}, nil
}

func (c *CompletionService) formatDialect(req *queravuev1.FormatSQLRequest) (sqlsplit.Dialect, *queravuev1.FormatSQLResponse, error) {
	if id := req.GetSessionId(); id != "" {
		sess, err := c.sessions.Get(id)
		if err != nil {
			return 0, nil, status.Error(codes.NotFound, "session not found")
		}
		if sess.Dialect == nil {
			return 0, &queravuev1.FormatSQLResponse{Error: unsupported("this connection does not speak SQL")}, nil
		}
		return sess.Dialect.Lexer(), nil, nil
	}
	lexer, ok := lexerByName(req.GetDialect())
	if !ok {
		return 0, &queravuev1.FormatSQLResponse{Error: adminErr(queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_INVALID, fmt.Sprintf("unknown dialect %q", req.GetDialect()))}, nil
	}
	return lexer, nil, nil
}

func lexerByName(name string) (sqlsplit.Dialect, bool) {
	switch strings.ToLower(name) {
	case "postgres", "postgresql", "cockroachdb", "cockroach":
		return sqlsplit.Postgres, true
	case "mysql", "mariadb", "tidb":
		return sqlsplit.MySQL, true
	case "mssql", "sqlserver":
		return sqlsplit.MSSQL, true
	case "sqlite":
		return sqlsplit.SQLite, true
	}
	return 0, false
}

func utf16Offset(m sqlsplit.OffsetMap, byteOffset int) uint32 {
	return uint32(m.ToUTF16(byteOffset)) //nolint:gosec // offsets are non-negative and bounded by the request size
}

func formatOptions(o *queravuev1.FormatOptions) format.Options {
	opts := format.Options{IndentWidth: int(o.GetIndentWidth()), MaxLineWidth: int(o.GetMaxLineWidth())}
	switch o.GetKeywordCase() {
	case queravuev1.KeywordCase_KEYWORD_CASE_LOWER:
		opts.KeywordCase = format.CaseLower
	case queravuev1.KeywordCase_KEYWORD_CASE_PRESERVE:
		opts.KeywordCase = format.CasePreserve
	}
	if o.GetCommaStyle() == queravuev1.CommaStyle_COMMA_STYLE_LEADING {
		opts.CommaStyle = format.CommaLeading
	}
	return opts
}
