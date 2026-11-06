package api

import (
	"context"

	"google.golang.org/protobuf/types/known/durationpb"
	"google.golang.org/protobuf/types/known/timestamppb"

	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/history"
)

// HistoryService implements queravuev1.HistoryServiceServer.
type HistoryService struct {
	queravuev1.UnimplementedHistoryServiceServer

	store *history.Store
}

// NewHistoryService returns a HistoryService handler.
func NewHistoryService(s *history.Store) *HistoryService {
	return &HistoryService{store: s}
}

// ListHistory implements the RPC.
func (h *HistoryService) ListHistory(ctx context.Context, req *queravuev1.ListHistoryRequest) (*queravuev1.ListHistoryResponse, error) {
	if h.store == nil {
		return &queravuev1.ListHistoryResponse{}, nil
	}

	entries, total, err := h.store.List(ctx, req.GetConnectionId(), req.GetSearchQuery(), int(req.GetLimit()), int(req.GetOffset()))
	if err != nil {
		return nil, err
	}

	protoEntries := make([]*queravuev1.HistoryEntry, len(entries))
	for i, e := range entries {
		protoEntries[i] = &queravuev1.HistoryEntry{
			Id:           e.ID,
			ConnectionId: e.ConnectionID,
			QueryText:    e.QueryText,
			StartedAt:    timestamppb.New(e.StartedAt),
			Duration:     durationpb.New(e.Duration),
			RowsAffected: e.RowsAffected,
			Error:        e.Error,
		}
	}

	return &queravuev1.ListHistoryResponse{
		Entries:    protoEntries,
		TotalCount: uint64(total), //nolint:gosec // count is non-negative
	}, nil
}

// ClearHistory implements the RPC.
func (h *HistoryService) ClearHistory(ctx context.Context, req *queravuev1.ClearHistoryRequest) (*queravuev1.ClearHistoryResponse, error) {
	if h.store != nil {
		if err := h.store.Clear(ctx, req.GetConnectionId()); err != nil {
			return nil, err
		}
	}
	return &queravuev1.ClearHistoryResponse{}, nil
}
