package api

import (
	"context"
	"fmt"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/session"
)

// CompletionService implements queravuev1.CompletionServiceServer.
type CompletionService struct {
	queravuev1.UnimplementedCompletionServiceServer

	sessions *session.Manager
}

// NewCompletionService returns a CompletionService handler.
func NewCompletionService(s *session.Manager) *CompletionService {
	return &CompletionService{sessions: s}
}

func notImplementedYet() *queravuev1.AdminError {
	return &queravuev1.AdminError{
		Kind:    queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_UNSUPPORTED,
		Message: "completion is not available yet",
	}
}

// Complete implements the RPC.
func (c *CompletionService) Complete(_ context.Context, req *queravuev1.CompleteRequest) (*queravuev1.CompleteResponse, error) {
	if _, err := c.sessions.Get(req.GetSessionId()); err != nil {
		return nil, status.Error(codes.NotFound, "session not found")
	}
	return &queravuev1.CompleteResponse{Error: notImplementedYet()}, nil
}

// WarmCatalog implements the RPC.
func (c *CompletionService) WarmCatalog(req *queravuev1.WarmCatalogRequest, stream queravuev1.CompletionService_WarmCatalogServer) error {
	if _, err := c.sessions.Get(req.GetSessionId()); err != nil {
		return status.Error(codes.NotFound, "session not found")
	}
	if err := stream.Send(&queravuev1.WarmCatalogResponse{Done: true, Error: notImplementedYet()}); err != nil {
		return fmt.Errorf("completion: send: %w", err)
	}
	return nil
}

// FormatSQL implements the RPC.
func (c *CompletionService) FormatSQL(_ context.Context, req *queravuev1.FormatSQLRequest) (*queravuev1.FormatSQLResponse, error) {
	if id := req.GetSessionId(); id != "" {
		if _, err := c.sessions.Get(id); err != nil {
			return nil, status.Error(codes.NotFound, "session not found")
		}
	}
	return &queravuev1.FormatSQLResponse{Error: notImplementedYet()}, nil
}
