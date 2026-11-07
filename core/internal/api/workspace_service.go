package api

import (
	"context"
	"errors"
	"fmt"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"
	"google.golang.org/protobuf/types/known/timestamppb"

	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/workspace"
)

// WorkspaceService implements queravuev1.WorkspaceServiceServer on top of
// internal/workspace.
type WorkspaceService struct {
	queravuev1.UnimplementedWorkspaceServiceServer

	ws *workspace.Service
}

// NewWorkspaceService returns a handler backed by ws.
func NewWorkspaceService(ws *workspace.Service) *WorkspaceService { return &WorkspaceService{ws: ws} }

// workspaceFailure converts err into the in-band error, or a gRPC status for
// failures the UI cannot act on.
func workspaceFailure(err error) (*queravuev1.WorkspaceError, error) {
	var e *workspace.Error
	if !errors.As(err, &e) {
		return nil, status.Error(codes.Internal, err.Error())
	}
	out := &queravuev1.WorkspaceError{Kind: workspaceErrorKind(e.Kind), Message: e.Msg}
	if e.Current != nil {
		out.Current = fileContent(e.Current)
	}
	return out, nil
}

func workspaceErrorKind(k workspace.ErrorKind) queravuev1.WorkspaceErrorKind {
	switch k {
	case workspace.KindPathEscapesRoot:
		return queravuev1.WorkspaceErrorKind_WORKSPACE_ERROR_KIND_PATH_ESCAPES_ROOT
	case workspace.KindNotFound:
		return queravuev1.WorkspaceErrorKind_WORKSPACE_ERROR_KIND_NOT_FOUND
	case workspace.KindAlreadyExists:
		return queravuev1.WorkspaceErrorKind_WORKSPACE_ERROR_KIND_ALREADY_EXISTS
	case workspace.KindConflict:
		return queravuev1.WorkspaceErrorKind_WORKSPACE_ERROR_KIND_CONFLICT
	case workspace.KindTooLarge:
		return queravuev1.WorkspaceErrorKind_WORKSPACE_ERROR_KIND_TOO_LARGE
	}
	return queravuev1.WorkspaceErrorKind_WORKSPACE_ERROR_KIND_IO
}

func fileKind(k workspace.Kind) queravuev1.FileKind {
	switch k {
	case workspace.KindSQL:
		return queravuev1.FileKind_FILE_KIND_SQL
	case workspace.KindMongo:
		return queravuev1.FileKind_FILE_KIND_MONGO
	}
	return queravuev1.FileKind_FILE_KIND_UNSPECIFIED
}

func fileMeta(m workspace.Meta) *queravuev1.FileMeta {
	if m.IsZero() {
		return nil
	}
	return &queravuev1.FileMeta{Title: m.Title, Description: m.Description, Connection: m.Connection, Tags: m.Tags}
}

func fileContent(f *workspace.File) *queravuev1.FileContent {
	return &queravuev1.FileContent{
		Content: f.Content, Mtime: timestamppb.New(f.ModTime), Hash: f.Hash, Meta: fileMeta(f.Meta), Kind: fileKind(f.Kind),
	}
}

func protoRoots(roots []workspace.Root) []*queravuev1.WorkspaceRoot {
	out := make([]*queravuev1.WorkspaceRoot, 0, len(roots))
	for _, r := range roots {
		out = append(out, &queravuev1.WorkspaceRoot{Id: r.ID, Name: r.Name, Path: r.Path})
	}
	return out
}

// GetRoots implements the RPC.
func (s *WorkspaceService) GetRoots(context.Context, *queravuev1.GetRootsRequest) (*queravuev1.GetRootsResponse, error) {
	roots, err := s.ws.Roots()
	if err != nil {
		return nil, status.Error(codes.Internal, err.Error())
	}
	return &queravuev1.GetRootsResponse{Roots: protoRoots(roots)}, nil
}

// SetRoots implements the RPC.
func (s *WorkspaceService) SetRoots(_ context.Context, req *queravuev1.SetRootsRequest) (*queravuev1.SetRootsResponse, error) {
	in := make([]workspace.Root, 0, len(req.GetRoots()))
	for _, r := range req.GetRoots() {
		in = append(in, workspace.Root{ID: r.GetId(), Name: r.GetName(), Path: r.GetPath()})
	}
	roots, err := s.ws.SetRoots(in)
	if err != nil {
		we, gerr := workspaceFailure(err)
		return &queravuev1.SetRootsResponse{Error: we}, gerr
	}
	return &queravuev1.SetRootsResponse{Roots: protoRoots(roots)}, nil
}

// ListTree implements the RPC.
func (s *WorkspaceService) ListTree(_ context.Context, req *queravuev1.ListTreeRequest) (*queravuev1.ListTreeResponse, error) {
	entries, err := s.ws.ListTree(req.GetRootId(), req.GetPath())
	if err != nil {
		we, gerr := workspaceFailure(err)
		return &queravuev1.ListTreeResponse{Error: we}, gerr
	}
	out := make([]*queravuev1.TreeEntry, 0, len(entries))
	for _, e := range entries {
		out = append(out, &queravuev1.TreeEntry{
			Name: e.Name, IsDir: e.IsDir, Kind: fileKind(e.Kind), Size: uint64(max(e.Size, 0)),
			Mtime: timestamppb.New(e.ModTime), Meta: fileMeta(e.Meta),
		})
	}
	return &queravuev1.ListTreeResponse{Entries: out}, nil
}

// Read implements the RPC.
func (s *WorkspaceService) Read(_ context.Context, req *queravuev1.ReadRequest) (*queravuev1.ReadResponse, error) {
	f, err := s.ws.Read(req.GetRootId(), req.GetPath())
	if err != nil {
		we, gerr := workspaceFailure(err)
		return &queravuev1.ReadResponse{Error: we}, gerr
	}
	return &queravuev1.ReadResponse{File: fileContent(f)}, nil
}

// Write implements the RPC.
func (s *WorkspaceService) Write(_ context.Context, req *queravuev1.WriteRequest) (*queravuev1.WriteResponse, error) {
	check := workspace.WriteCheck{ExpectedHash: req.GetExpectedHash(), Force: req.GetForce()}
	if t := req.GetExpectedMtime(); t != nil {
		check.ExpectedMtime = t.AsTime()
	}
	f, err := s.ws.Write(req.GetRootId(), req.GetPath(), req.GetContent(), check)
	if err != nil {
		we, gerr := workspaceFailure(err)
		return &queravuev1.WriteResponse{Error: we}, gerr
	}
	return &queravuev1.WriteResponse{Mtime: timestamppb.New(f.ModTime), Hash: f.Hash}, nil
}

// Create implements the RPC.
func (s *WorkspaceService) Create(_ context.Context, req *queravuev1.CreateRequest) (*queravuev1.CreateResponse, error) {
	f, err := s.ws.Create(req.GetRootId(), req.GetPath(), req.GetIsDir(), req.GetContent())
	if err != nil {
		we, gerr := workspaceFailure(err)
		return &queravuev1.CreateResponse{Error: we}, gerr
	}
	if f == nil {
		return &queravuev1.CreateResponse{}, nil
	}
	return &queravuev1.CreateResponse{Mtime: timestamppb.New(f.ModTime), Hash: f.Hash}, nil
}

// Rename implements the RPC.
func (s *WorkspaceService) Rename(_ context.Context, req *queravuev1.RenameRequest) (*queravuev1.RenameResponse, error) {
	if err := s.ws.Rename(req.GetRootId(), req.GetFromPath(), req.GetToPath()); err != nil {
		we, gerr := workspaceFailure(err)
		return &queravuev1.RenameResponse{Error: we}, gerr
	}
	return &queravuev1.RenameResponse{}, nil
}

// Delete implements the RPC.
func (s *WorkspaceService) Delete(_ context.Context, req *queravuev1.DeleteRequest) (*queravuev1.DeleteResponse, error) {
	if err := s.ws.Delete(req.GetRootId(), req.GetPath()); err != nil {
		we, gerr := workspaceFailure(err)
		return &queravuev1.DeleteResponse{Error: we}, gerr
	}
	return &queravuev1.DeleteResponse{}, nil
}

// Search implements the RPC.
func (s *WorkspaceService) Search(req *queravuev1.SearchRequest, stream queravuev1.WorkspaceService_SearchServer) error {
	q := workspace.SearchQuery{Text: req.GetText(), Tags: req.GetTags(), RootID: req.GetRootId(), Limit: int(req.GetLimit())}
	err := s.ws.Search(stream.Context(), q, func(h workspace.Hit) error {
		if err := stream.Send(&queravuev1.SearchResponse{
			RootId: h.RootID, Path: h.Path, Kind: fileKind(h.Kind), Meta: fileMeta(h.Meta), Snippet: h.Snippet, Line: uint32(h.Line), //nolint:gosec // line numbers are small
		}); err != nil {
			return fmt.Errorf("workspace: send hit: %w", err)
		}
		return nil
	})
	return streamResult(stream.Context(), err)
}

// Watch implements the RPC.
func (s *WorkspaceService) Watch(req *queravuev1.WatchRequest, stream queravuev1.WorkspaceService_WatchServer) error {
	err := s.ws.Watch(stream.Context(), req.GetRootIds(), func(c workspace.Change) error {
		m := &queravuev1.WatchResponse{RootId: c.RootID, Path: c.Path, Kind: changeKind(c.Kind), OldPath: c.OldPath}
		if !c.ModTime.IsZero() {
			m.Mtime = timestamppb.New(c.ModTime)
		}
		if err := stream.Send(m); err != nil {
			return fmt.Errorf("workspace: send change: %w", err)
		}
		return nil
	})
	return streamResult(stream.Context(), err)
}

func streamResult(ctx context.Context, err error) error {
	if ctx.Err() != nil {
		return status.FromContextError(ctx.Err()).Err()
	}
	if err == nil {
		return nil
	}
	var we *workspace.Error
	if errors.As(err, &we) && we.Kind == workspace.KindNotFound {
		return status.Error(codes.NotFound, we.Msg)
	}
	return status.Error(codes.Internal, err.Error())
}

func changeKind(k workspace.ChangeKind) queravuev1.ChangeKind {
	switch k {
	case workspace.ChangeCreated:
		return queravuev1.ChangeKind_CHANGE_KIND_CREATED
	case workspace.ChangeModified:
		return queravuev1.ChangeKind_CHANGE_KIND_MODIFIED
	case workspace.ChangeDeleted:
		return queravuev1.ChangeKind_CHANGE_KIND_DELETED
	case workspace.ChangeRenamed:
		return queravuev1.ChangeKind_CHANGE_KIND_RENAMED
	}
	return queravuev1.ChangeKind_CHANGE_KIND_UNSPECIFIED
}
