package api

import (
	"os"
	"path/filepath"
	"strings"
	"testing"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/doubledare704/queravue/core/internal/connections"
	"github.com/doubledare704/queravue/core/internal/engine/engines"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/secrets"
)

func newConnHandler(t *testing.T) (*ConnectionService, string) {
	t.Helper()
	reg, err := engines.Registry()
	if err != nil {
		t.Fatal(err)
	}
	dir := t.TempDir()
	return NewConnectionService(connections.NewService(reg, connections.NewFileStore(dir), secrets.NewMemory())), dir
}

func TestListEngines(t *testing.T) {
	h, _ := newConnHandler(t)
	resp, err := h.ListEngines(t.Context(), &queravuev1.ListEnginesRequest{})
	if err != nil {
		t.Fatal(err)
	}
	byID := map[string]*queravuev1.EngineInfo{}
	for _, e := range resp.GetEngines() {
		byID[e.GetId()] = e
	}
	pg := byID["postgres"]
	if pg == nil || pg.GetDisplayName() != "PostgreSQL" || !pg.GetSupportsUri() || len(pg.GetFields()) == 0 {
		t.Fatalf("postgres = %v", pg)
	}
	var sawPassword bool
	for _, f := range pg.GetFields() {
		if f.GetKind() == queravuev1.FieldKind_FIELD_KIND_PASSWORD {
			sawPassword = true
		}
	}
	if !sawPassword {
		t.Error("postgres has no password field")
	}
	if byID["cockroachdb"].GetFamily() != "postgres" {
		t.Error("cockroach family")
	}
	if f := byID["sqlite"].GetFields()[0]; f.GetKind() != queravuev1.FieldKind_FIELD_KIND_FILE {
		t.Errorf("sqlite first field = %v", f)
	}
}

func TestConnectionCRUDAndTest(t *testing.T) {
	h, dir := newConnHandler(t)
	ctx := t.Context()
	dbPath := filepath.Join(t.TempDir(), "x.db")

	pw := "pg-secret"
	created, err := h.CreateConnection(ctx, &queravuev1.CreateConnectionRequest{
		Connection: &queravuev1.Connection{
			Name: "PG", EngineId: "postgres", Folder: "Work", Color: queravuev1.ColorTag_COLOR_TAG_RED, Production: true,
			Params: map[string]string{"host": "localhost", "user": "u"},
		},
		Password: &pw,
	})
	if err != nil {
		t.Fatal(err)
	}
	c := created.GetConnection()
	if c.GetId() == "" || !c.GetHasPassword() || c.GetColor() != queravuev1.ColorTag_COLOR_TAG_RED || !c.GetProduction() {
		t.Errorf("created = %v", c)
	}
	if c.GetParams()["port"] != "" {
		t.Error("defaults must not be persisted as params")
	}

	raw, _ := os.ReadFile(filepath.Join(dir, connections.FileName))
	if strings.Contains(string(raw), pw) {
		t.Fatal("password on disk")
	}

	sq, err := h.CreateConnection(ctx, &queravuev1.CreateConnectionRequest{Connection: &queravuev1.Connection{
		Name: "Local file", EngineId: "sqlite", Params: map[string]string{"path": dbPath},
	}})
	if err != nil {
		t.Fatal(err)
	}

	list, _ := h.ListConnections(ctx, &queravuev1.ListConnectionsRequest{})
	if len(list.GetConnections()) != 2 {
		t.Fatalf("list = %v", list)
	}

	res, err := h.TestConnection(ctx, &queravuev1.TestConnectionRequest{Id: sq.GetConnection().GetId()})
	if err != nil {
		t.Fatal(err)
	}
	if res.GetOk() || res.GetError().GetKind() != queravuev1.ErrorKind_ERROR_KIND_NOT_FOUND {
		t.Errorf("missing sqlite file = %v", res)
	}

	draft := sq.GetConnection()
	draft.Params = map[string]string{"path": dbPath, "create_if_missing": "true"}
	res, _ = h.TestConnection(ctx, &queravuev1.TestConnectionRequest{Draft: draft})
	if !res.GetOk() || res.GetServer().GetProduct() != "SQLite" || res.GetError() != nil {
		t.Errorf("sqlite test = %v", res)
	}

	if _, err := h.DeleteConnection(ctx, &queravuev1.DeleteConnectionRequest{Id: c.GetId()}); err != nil {
		t.Fatal(err)
	}
	_, err = h.GetConnection(ctx, &queravuev1.GetConnectionRequest{Id: c.GetId()})
	if status.Code(err) != codes.NotFound {
		t.Errorf("get deleted = %v", err)
	}
}

func TestConnectionErrorsCodes(t *testing.T) {
	h, _ := newConnHandler(t)
	ctx := t.Context()
	_, err := h.CreateConnection(ctx, &queravuev1.CreateConnectionRequest{Connection: &queravuev1.Connection{Name: "x", EngineId: "nope"}})
	if status.Code(err) != codes.InvalidArgument {
		t.Errorf("unknown engine = %v", err)
	}
	_, err = h.UpdateConnection(ctx, &queravuev1.UpdateConnectionRequest{Connection: &queravuev1.Connection{
		Id: "missing", Name: "x", EngineId: "sqlite", Params: map[string]string{"path": "/x"},
	}})
	if status.Code(err) != codes.NotFound {
		t.Errorf("update missing = %v", err)
	}
	_, err = h.ParseConnectionString(ctx, &queravuev1.ParseConnectionStringRequest{EngineId: "postgres", ConnectionString: "mysql://x"})
	if status.Code(err) != codes.InvalidArgument {
		t.Errorf("bad uri = %v", err)
	}
}

func TestParseConnectionString(t *testing.T) {
	h, _ := newConnHandler(t)
	resp, err := h.ParseConnectionString(t.Context(), &queravuev1.ParseConnectionStringRequest{
		EngineId: "postgres", ConnectionString: "postgres://u:p%40ss@h:5433/db",
	})
	if err != nil {
		t.Fatal(err)
	}
	if resp.GetParams()["host"] != "h" || resp.GetParams()["port"] != "5433" || resp.GetPassword() != "p@ss" {
		t.Errorf("resp = %v", resp)
	}
	if _, ok := resp.GetParams()["password"]; ok {
		t.Error("password in params")
	}
	resp, _ = h.ParseConnectionString(t.Context(), &queravuev1.ParseConnectionStringRequest{EngineId: "sqlite", ConnectionString: "/tmp/a.db"})
	if resp.Password != nil {
		t.Error("sqlite password must be unset")
	}
}
