package api

import (
	"context"
	"errors"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/doubledare704/queravue/core/internal/connections"
	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/session"
)

// CapabilityQuery means SessionService and QueryService are available.
const CapabilityQuery = "query"

// SessionService implements queravuev1.SessionServiceServer.
type SessionService struct {
	queravuev1.UnimplementedSessionServiceServer

	sessions *session.Manager
}

// NewSessionService returns a handler backed by m.
func NewSessionService(m *session.Manager) *SessionService { return &SessionService{sessions: m} }

// Open implements the RPC. Connection failures are reported in-band.
func (h *SessionService) Open(ctx context.Context, req *queravuev1.OpenRequest) (*queravuev1.OpenResponse, error) {
	s, err := h.sessions.Open(ctx, req.GetConnectionId())
	if err != nil {
		var ee *engine.Error
		if errors.As(err, &ee) {
			return &queravuev1.OpenResponse{Error: errorToProto(ee)}, nil
		}
		if errors.Is(err, connections.ErrNotFound) {
			return nil, status.Error(codes.NotFound, "connection not found")
		}
		return nil, grpcError(err)
	}
	resp := &queravuev1.OpenResponse{SessionId: s.ID}
	// ServerInfo is best effort: a failure here must not hide a good session.
	if info, err := s.Conn.ServerInfo(ctx); err == nil {
		resp.ServerInfo = &queravuev1.ServerInfo{Product: info.Product, Version: info.Version, Banner: info.Banner}
	}
	for _, c := range s.Desc.Capabilities {
		resp.Capabilities = append(resp.Capabilities, string(c))
	}
	return resp, nil
}

// Close implements the RPC.
func (h *SessionService) Close(_ context.Context, req *queravuev1.CloseRequest) (*queravuev1.CloseResponse, error) {
	h.sessions.Close(req.GetSessionId())
	return &queravuev1.CloseResponse{}, nil
}
