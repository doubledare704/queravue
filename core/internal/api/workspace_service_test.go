package api_test

import (
	"context"
	"os"
	"path/filepath"
	"testing"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/doubledare704/queravue/core/internal/api"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/workspace"
)

func newWorkspaceHandler(t *testing.T) (*api.WorkspaceService, string) {
	t.Helper()
	dir := t.TempDir()
	root := filepath.Join(dir, "ws")
	ws := workspace.NewService(workspace.Options{ConfigDir: filepath.Join(dir, "cfg"), DefaultRoot: root, DebounceInterval: 20 * time.Millisecond})
	return api.NewWorkspaceService(ws), root
}

type searchStream struct {
	grpc.ServerStream
	ctx  context.Context
	hits []*queravuev1.SearchResponse
}

func (s *searchStream) Context() context.Context { return s.ctx }
func (s *searchStream) Send(m *queravuev1.SearchResponse) error {
	s.hits = append(s.hits, m)
	return nil
}

type watchStream struct {
	grpc.ServerStream
	ctx context.Context
	ch  chan *queravuev1.WatchResponse
}

func (s *watchStream) Context() context.Context { return s.ctx }
func (s *watchStream) Send(m *queravuev1.WatchResponse) error {
	s.ch <- m
	return nil
}

func TestWorkspaceServiceFileLifecycle(t *testing.T) {
	h, _ := newWorkspaceHandler(t)
	ctx := context.Background()
	roots, err := h.GetRoots(ctx, &queravuev1.GetRootsRequest{})
	if err != nil || len(roots.GetRoots()) != 1 {
		t.Fatalf("roots = %v, %v", roots, err)
	}
	id := roots.GetRoots()[0].GetId()

	created, err := h.Create(ctx, &queravuev1.CreateRequest{RootId: id, Path: "q/users.sql", Content: "-- title: Users\n-- connection: main\nSELECT 1;\n"})
	if err != nil || created.GetError() != nil || created.GetHash() == "" {
		t.Fatalf("create = %v, %v", created, err)
	}
	read, err := h.Read(ctx, &queravuev1.ReadRequest{RootId: id, Path: "q/users.sql"})
	if err != nil || read.GetFile().GetMeta().GetTitle() != "Users" || read.GetFile().GetMeta().GetConnection() != "main" ||
		read.GetFile().GetKind() != queravuev1.FileKind_FILE_KIND_SQL {
		t.Fatalf("read = %v, %v", read, err)
	}
	tree, err := h.ListTree(ctx, &queravuev1.ListTreeRequest{RootId: id, Path: "q"})
	if err != nil || len(tree.GetEntries()) != 1 || tree.GetEntries()[0].GetMeta().GetTitle() != "Users" {
		t.Fatalf("tree = %v, %v", tree, err)
	}
	w, err := h.Write(ctx, &queravuev1.WriteRequest{RootId: id, Path: "q/users.sql", Content: "SELECT 2;", ExpectedHash: created.GetHash()})
	if err != nil || w.GetError() != nil || w.GetHash() == created.GetHash() {
		t.Fatalf("write = %v, %v", w, err)
	}
	if r, err := h.Rename(ctx, &queravuev1.RenameRequest{RootId: id, FromPath: "q/users.sql", ToPath: "q/people.sql"}); err != nil || r.GetError() != nil {
		t.Fatalf("rename = %v, %v", r, err)
	}
	if d, err := h.Delete(ctx, &queravuev1.DeleteRequest{RootId: id, Path: "q"}); err != nil || d.GetError() != nil {
		t.Fatalf("delete = %v, %v", d, err)
	}
}

func TestWorkspaceServiceConflictIsInBand(t *testing.T) {
	h, root := newWorkspaceHandler(t)
	ctx := context.Background()
	created, err := h.Create(ctx, &queravuev1.CreateRequest{RootId: workspace.DefaultRootID, Path: "a.sql", Content: "v1"})
	if err != nil {
		t.Fatal(err)
	}
	if err := os.WriteFile(filepath.Join(root, "a.sql"), []byte("external"), 0o644); err != nil {
		t.Fatal(err)
	}
	w, err := h.Write(ctx, &queravuev1.WriteRequest{RootId: workspace.DefaultRootID, Path: "a.sql", Content: "mine", ExpectedHash: created.GetHash()})
	if err != nil {
		t.Fatal(err)
	}
	e := w.GetError()
	if e.GetKind() != queravuev1.WorkspaceErrorKind_WORKSPACE_ERROR_KIND_CONFLICT || e.GetCurrent().GetContent() != "external" || e.GetCurrent().GetHash() == "" {
		t.Fatalf("error = %v", e)
	}
	forced, err := h.Write(ctx, &queravuev1.WriteRequest{RootId: workspace.DefaultRootID, Path: "a.sql", Content: "mine", ExpectedHash: created.GetHash(), Force: true})
	if err != nil || forced.GetError() != nil {
		t.Fatalf("forced = %v, %v", forced, err)
	}
}

func TestWorkspaceServiceErrorsAreInBand(t *testing.T) {
	h, _ := newWorkspaceHandler(t)
	ctx := context.Background()
	id := workspace.DefaultRootID
	escape, _ := h.Read(ctx, &queravuev1.ReadRequest{RootId: id, Path: "../x.sql"})
	missing, _ := h.Read(ctx, &queravuev1.ReadRequest{RootId: id, Path: "nope.sql"})
	unknownRoot, _ := h.ListTree(ctx, &queravuev1.ListTreeRequest{RootId: "nope"})
	_, _ = h.Create(ctx, &queravuev1.CreateRequest{RootId: id, Path: "a.sql"})
	exists, _ := h.Create(ctx, &queravuev1.CreateRequest{RootId: id, Path: "a.sql"})

	tests := []struct {
		name string
		got  *queravuev1.WorkspaceError
		want queravuev1.WorkspaceErrorKind
	}{
		{"escape", escape.GetError(), queravuev1.WorkspaceErrorKind_WORKSPACE_ERROR_KIND_PATH_ESCAPES_ROOT},
		{"missing", missing.GetError(), queravuev1.WorkspaceErrorKind_WORKSPACE_ERROR_KIND_NOT_FOUND},
		{"unknown root", unknownRoot.GetError(), queravuev1.WorkspaceErrorKind_WORKSPACE_ERROR_KIND_NOT_FOUND},
		{"exists", exists.GetError(), queravuev1.WorkspaceErrorKind_WORKSPACE_ERROR_KIND_ALREADY_EXISTS},
	}
	for _, tc := range tests {
		if tc.got.GetKind() != tc.want {
			t.Errorf("%s: got %v, want %v", tc.name, tc.got, tc.want)
		}
	}
}

func TestWorkspaceServiceSetRoots(t *testing.T) {
	h, _ := newWorkspaceHandler(t)
	extra := filepath.Join(t.TempDir(), "extra")
	resp, err := h.SetRoots(context.Background(), &queravuev1.SetRootsRequest{Roots: []*queravuev1.WorkspaceRoot{{Path: extra}}})
	if err != nil || len(resp.GetRoots()) != 1 || resp.GetRoots()[0].GetId() == "" {
		t.Fatalf("SetRoots = %v, %v", resp, err)
	}
	bad, err := h.SetRoots(context.Background(), &queravuev1.SetRootsRequest{})
	if err != nil || bad.GetError() == nil {
		t.Fatalf("empty SetRoots = %v, %v", bad, err)
	}
}

func TestWorkspaceServiceSearchStreams(t *testing.T) {
	h, _ := newWorkspaceHandler(t)
	ctx := context.Background()
	for p, c := range map[string]string{"a.sql": "-- tags: x\nSELECT needle", "b.mongo.js": "db.t.find()"} {
		if _, err := h.Create(ctx, &queravuev1.CreateRequest{RootId: workspace.DefaultRootID, Path: p, Content: c}); err != nil {
			t.Fatal(err)
		}
	}
	st := &searchStream{ctx: ctx}
	if err := h.Search(&queravuev1.SearchRequest{Text: "needle", Tags: []string{"x"}}, st); err != nil {
		t.Fatal(err)
	}
	if len(st.hits) != 1 || st.hits[0].GetPath() != "a.sql" || st.hits[0].GetLine() != 2 || st.hits[0].GetKind() != queravuev1.FileKind_FILE_KIND_SQL {
		t.Fatalf("hits = %v", st.hits)
	}
	cctx, cancel := context.WithCancel(ctx)
	cancel()
	if err := h.Search(&queravuev1.SearchRequest{}, &searchStream{ctx: cctx}); status.Code(err) != codes.Canceled {
		t.Fatalf("got %v, want Canceled", err)
	}
}

func TestWorkspaceServiceWatchStreamsExternalChange(t *testing.T) {
	h, root := newWorkspaceHandler(t)
	if _, err := h.GetRoots(context.Background(), &queravuev1.GetRootsRequest{}); err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithCancel(context.Background())
	st := &watchStream{ctx: ctx, ch: make(chan *queravuev1.WatchResponse, 8)}
	done := make(chan error, 1)
	go func() { done <- h.Watch(&queravuev1.WatchRequest{}, st) }()
	time.Sleep(150 * time.Millisecond)
	if err := os.WriteFile(filepath.Join(root, "ext.sql"), []byte("x"), 0o644); err != nil {
		t.Fatal(err)
	}
	select {
	case m := <-st.ch:
		if m.GetPath() != "ext.sql" || m.GetKind() != queravuev1.ChangeKind_CHANGE_KIND_CREATED || m.GetRootId() != workspace.DefaultRootID {
			t.Fatalf("change = %v", m)
		}
	case <-time.After(5 * time.Second):
		t.Fatal("no change event")
	}
	cancel()
	if err := <-done; status.Code(err) != codes.Canceled {
		t.Fatalf("got %v, want Canceled", err)
	}
}
