package api_test

import (
	"context"
	"database/sql"
	"path/filepath"
	"testing"
	"time"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	_ "modernc.org/sqlite"

	"github.com/doubledare704/queravue/core/internal/api"
	"github.com/doubledare704/queravue/core/internal/completion"
	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/sqlite"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/session"
)

type sqliteFileOpener struct{ path string }

func (o sqliteFileOpener) Open(ctx context.Context, _ string) (engine.Conn, engine.Descriptor, error) {
	e := sqlite.New()
	c, err := e.Connect(ctx, engine.Config{EngineID: sqlite.ID, Params: map[string]string{sqlite.ParamPath: o.path}}, engine.Secret{})
	return c, e.Descriptor(), err
}

func completionEnv(t *testing.T) (*api.CompletionService, *session.Session, *completion.Manager) {
	t.Helper()
	path := filepath.Join(t.TempDir(), "c.db")
	db, err := sql.Open("sqlite", path)
	if err != nil {
		t.Fatal(err)
	}
	if _, err := db.Exec("CREATE TABLE customers (id INTEGER PRIMARY KEY, name TEXT, email TEXT)"); err != nil {
		t.Fatal(err)
	}
	_ = db.Close()
	mgr := session.NewManager(sqliteFileOpener{path})
	t.Cleanup(mgr.Shutdown)
	catalogs := completion.NewManager()
	t.Cleanup(catalogs.Shutdown)
	sess, err := mgr.Open(context.Background(), "c")
	if err != nil {
		t.Fatal(err)
	}
	return api.NewCompletionService(mgr, catalogs), sess, catalogs
}

func waitReady(t *testing.T, catalogs *completion.Manager, sess *session.Session) {
	t.Helper()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	if err := catalogs.Watch(ctx, sess, "", func(completion.Progress) error { return nil }); err != nil {
		t.Fatal(err)
	}
}

func TestCompleteReturnsColumnsOnceTheCatalogIsWarm(t *testing.T) {
	svc, sess, catalogs := completionEnv(t)
	waitReady(t, catalogs, sess)
	text := "SELECT c.na FROM customers c"
	resp, err := svc.Complete(context.Background(), &queravuev1.CompleteRequest{
		SessionId: sess.ID, Kind: queravuev1.CompletionContextKind_COMPLETION_CONTEXT_KIND_SQL, Text: text, CursorOffset: 11,
	})
	if err != nil || resp.GetError() != nil {
		t.Fatalf("Complete = %v, %v", resp, err)
	}
	first := resp.GetItems()[0]
	if first.GetLabel() != "name" || first.GetKind() != queravuev1.CompletionItemKind_COMPLETION_ITEM_KIND_COLUMN ||
		first.GetReplace().GetStart() != 9 || first.GetReplace().GetEnd() != 11 || first.GetDetail() != "TEXT · c" {
		t.Errorf("first item = %v", first)
	}
	if resp.GetCatalogState() != queravuev1.CatalogState_CATALOG_STATE_READY {
		t.Errorf("catalog state = %v", resp.GetCatalogState())
	}
}

func TestCompleteRejectsUnavailableContexts(t *testing.T) {
	svc, sess, _ := completionEnv(t)
	tests := []struct {
		kind queravuev1.CompletionContextKind
		want queravuev1.AdminErrorKind
	}{
		{queravuev1.CompletionContextKind_COMPLETION_CONTEXT_KIND_UNSPECIFIED, queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_INVALID},
		{queravuev1.CompletionContextKind_COMPLETION_CONTEXT_KIND_SHELL, queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_UNSUPPORTED},
		{queravuev1.CompletionContextKind_COMPLETION_CONTEXT_KIND_MONGO_QUERY, queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_UNSUPPORTED},
	}
	for _, tc := range tests {
		resp, err := svc.Complete(context.Background(), &queravuev1.CompleteRequest{SessionId: sess.ID, Kind: tc.kind})
		if err != nil || resp.GetError().GetKind() != tc.want {
			t.Errorf("kind %v: %v, %v; want in-band %v", tc.kind, resp, err, tc.want)
		}
	}
}

func TestCompleteOnNonSQLConnectionIsUnsupported(t *testing.T) {
	mgr := session.NewManager(fakeOpener{conn: &fakeValidatingConn{}})
	t.Cleanup(mgr.Shutdown)
	sess, err := mgr.Open(context.Background(), "test-conn")
	if err != nil {
		t.Fatal(err)
	}
	svc := api.NewCompletionService(mgr, completion.NewManager())
	resp, err := svc.Complete(context.Background(), &queravuev1.CompleteRequest{
		SessionId: sess.ID, Kind: queravuev1.CompletionContextKind_COMPLETION_CONTEXT_KIND_SQL,
	})
	if err != nil || resp.GetError().GetKind() != queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_UNSUPPORTED {
		t.Errorf("Complete = %v, %v", resp, err)
	}
	if _, err := svc.Complete(context.Background(), &queravuev1.CompleteRequest{SessionId: "missing"}); status.Code(err) != codes.NotFound {
		t.Errorf("unknown session code = %v, want NotFound", status.Code(err))
	}
}

func TestFormatSQLFormatsWithTheSessionDialect(t *testing.T) {
	svc, sess, _ := completionEnv(t)
	resp, err := svc.FormatSQL(context.Background(), &queravuev1.FormatSQLRequest{SessionId: sess.ID, Text: "select a,b from t"})
	if err != nil || resp.GetError() != nil {
		t.Fatalf("FormatSQL = %v, %v", resp, err)
	}
	if resp.GetFormattedText() != "SELECT a, b\nFROM t" || resp.GetReplacedRange().GetStart() != 0 || resp.GetReplacedRange().GetEnd() != 17 {
		t.Errorf("FormatSQL = %v", resp)
	}
}

func TestFormatSQLFormatsOnlyTheRequestedRangeInUTF16Units(t *testing.T) {
	svc, _, _ := completionEnv(t)
	text := "-- é😀\nselect a,b from t;\nselect 1"
	resp, err := svc.FormatSQL(context.Background(), &queravuev1.FormatSQLRequest{
		Dialect: "postgres", Text: text, Range: &queravuev1.TextRange{Start: 7, End: 24},
	})
	if err != nil || resp.GetError() != nil {
		t.Fatalf("FormatSQL = %v, %v", resp, err)
	}
	if resp.GetFormattedText() != "SELECT a, b\nFROM t" {
		t.Errorf("formatted = %q", resp.GetFormattedText())
	}
	if r := resp.GetReplacedRange(); r.GetStart() != 7 || r.GetEnd() != 24 {
		t.Errorf("replaced = %v", r)
	}
}

func TestFormatSQLReportsUnterminatedInputWithAUTF16Position(t *testing.T) {
	svc, _, _ := completionEnv(t)
	resp, err := svc.FormatSQL(context.Background(), &queravuev1.FormatSQLRequest{Dialect: "mysql", Text: "select '😀', 'abc"})
	if err != nil {
		t.Fatal(err)
	}
	e := resp.GetError()
	if e.GetKind() != queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_INVALID || e.GetPosition() != 13 {
		t.Errorf("error = %v", e)
	}
}

func TestFormatSQLRejectsUnknownDialectAndBadRange(t *testing.T) {
	svc, _, _ := completionEnv(t)
	for _, req := range []*queravuev1.FormatSQLRequest{
		{Dialect: "cobol", Text: "select 1"},
		{Dialect: "postgres", Text: "select 1", Range: &queravuev1.TextRange{Start: 5, End: 99}},
		{Dialect: "postgres", Text: "select 1", Range: &queravuev1.TextRange{Start: 5, End: 2}},
	} {
		resp, err := svc.FormatSQL(context.Background(), req)
		if err != nil || resp.GetError().GetKind() != queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_INVALID {
			t.Errorf("FormatSQL(%v) = %v, %v", req, resp, err)
		}
	}
}

func TestFormatSQLUnknownSessionIsNotFound(t *testing.T) {
	svc, _, _ := completionEnv(t)
	_, err := svc.FormatSQL(context.Background(), &queravuev1.FormatSQLRequest{SessionId: "nope", Text: "select 1"})
	if status.Code(err) != codes.NotFound {
		t.Errorf("code = %v", status.Code(err))
	}
}

func mongoCompletionEnv(t *testing.T, conn *fakeDocConn) (*api.CompletionService, string) {
	t.Helper()
	mgr := session.NewManager(fakeDocOpener{conn: conn})
	t.Cleanup(mgr.Shutdown)
	sess, err := mgr.Open(context.Background(), "m")
	if err != nil {
		t.Fatal(err)
	}
	catalogs := completion.NewManager()
	t.Cleanup(catalogs.Shutdown)
	return api.NewCompletionService(mgr, catalogs), sess.ID
}

func TestCompleteShellOffersSampledFieldPaths(t *testing.T) {
	conn := &fakeDocConn{}
	svc, sid := mongoCompletionEnv(t, conn)
	text := "db.users.find({ ad"
	resp, err := svc.Complete(context.Background(), &queravuev1.CompleteRequest{
		SessionId: sid, Kind: queravuev1.CompletionContextKind_COMPLETION_CONTEXT_KIND_SHELL, Text: text, CursorOffset: uint32(len(text)), Database: "app",
	})
	if err != nil || resp.GetError() != nil {
		t.Fatalf("Complete = %v, %v", resp, err)
	}
	first := resp.GetItems()[0]
	if first.GetLabel() != "address.city" || first.GetKind() != queravuev1.CompletionItemKind_COMPLETION_ITEM_KIND_FIELD ||
		first.GetInsertText() != `"address.city"` || first.GetReplace().GetStart() != 16 || first.GetReplace().GetEnd() != 18 || first.GetDetail() != "string · 100%" {
		t.Errorf("first item = %v", first)
	}
	if resp.GetCatalogState() != queravuev1.CatalogState_CATALOG_STATE_UNSPECIFIED {
		t.Errorf("catalog state = %v", resp.GetCatalogState())
	}
}

func TestCompleteQueryBarUsesTheRequestCollection(t *testing.T) {
	svc, sid := mongoCompletionEnv(t, &fakeDocConn{})
	resp, err := svc.Complete(context.Background(), &queravuev1.CompleteRequest{
		SessionId: sid, Kind: queravuev1.CompletionContextKind_COMPLETION_CONTEXT_KIND_MONGO_QUERY, Text: `{ "ad`, CursorOffset: 5, Database: "app", Collection: "users",
	})
	if err != nil || resp.GetError() != nil || len(resp.GetItems()) == 0 || resp.GetItems()[0].GetLabel() != "address.city" {
		t.Fatalf("Complete = %v, %v", resp, err)
	}
}

func TestCompleteShellOnASQLSessionIsUnsupported(t *testing.T) {
	svc, sess, _ := completionEnv(t)
	resp, err := svc.Complete(context.Background(), &queravuev1.CompleteRequest{
		SessionId: sess.ID, Kind: queravuev1.CompletionContextKind_COMPLETION_CONTEXT_KIND_SHELL, Text: "db.",
	})
	if err != nil || resp.GetError().GetKind() != queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_UNSUPPORTED {
		t.Errorf("Complete = %v, %v", resp, err)
	}
}
