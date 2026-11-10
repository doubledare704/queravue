package api

import (
	"context"
	"fmt"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/session"
)

// DiagramService implements queravuev1.DiagramServiceServer.
type DiagramService struct {
	queravuev1.UnimplementedDiagramServiceServer

	sessions *session.Manager
}

// NewDiagramService returns a DiagramService handler.
func NewDiagramService(s *session.Manager) *DiagramService {
	return &DiagramService{sessions: s}
}

func diagramsNotImplementedYet() *queravuev1.AdminError {
	return &queravuev1.AdminError{
		Kind:    queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_UNSUPPORTED,
		Message: "schema diagrams are not available yet",
	}
}

func (d *DiagramService) requireSession(id string) error {
	if _, err := d.sessions.Get(id); err != nil {
		return status.Error(codes.NotFound, "session not found")
	}
	return nil
}

// GetSchemaGraph implements the RPC.
func (d *DiagramService) GetSchemaGraph(req *queravuev1.GetSchemaGraphRequest, stream queravuev1.DiagramService_GetSchemaGraphServer) error {
	if err := d.requireSession(req.GetSessionId()); err != nil {
		return err
	}
	if err := stream.Send(&queravuev1.GetSchemaGraphResponse{Done: true, Error: diagramsNotImplementedYet()}); err != nil {
		return fmt.Errorf("diagram: send: %w", err)
	}
	return nil
}

// PreviewDiagramDDL implements the RPC.
func (d *DiagramService) PreviewDiagramDDL(_ context.Context, req *queravuev1.PreviewDiagramDDLRequest) (*queravuev1.PreviewDiagramDDLResponse, error) {
	if err := d.requireSession(req.GetSessionId()); err != nil {
		return nil, err
	}
	return &queravuev1.PreviewDiagramDDLResponse{Error: diagramsNotImplementedYet()}, nil
}

// ApplyDiagramDDL implements the RPC.
func (d *DiagramService) ApplyDiagramDDL(_ context.Context, req *queravuev1.ApplyDiagramDDLRequest) (*queravuev1.ApplyDiagramDDLResponse, error) {
	if err := d.requireSession(req.GetSessionId()); err != nil {
		return nil, err
	}
	return &queravuev1.ApplyDiagramDDLResponse{Error: diagramsNotImplementedYet()}, nil
}
