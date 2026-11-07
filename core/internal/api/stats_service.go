package api

import (
	"context"

	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/status"

	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/session"
)

// StatsService implements queravuev1.StatsServiceServer.
type StatsService struct {
	queravuev1.UnimplementedStatsServiceServer

	sessions *session.Manager
}

// NewStatsService returns a StatsService handler.
func NewStatsService(s *session.Manager) *StatsService {
	return &StatsService{sessions: s}
}

// GetStats implements the RPC.
func (s *StatsService) GetStats(ctx context.Context, req *queravuev1.GetStatsRequest) (*queravuev1.GetStatsResponse, error) {
	sess, err := s.sessions.Get(req.GetSessionId())
	if err != nil {
		return nil, status.Error(codes.NotFound, "session not found")
	}
	ref := req.GetTableRef()
	if ref.GetTable() == "" {
		return nil, status.Error(codes.InvalidArgument, "table reference is required")
	}
	sp, ok := engine.As[engine.StatsProvider](sess.Conn)
	if !ok {
		return nil, status.Error(codes.FailedPrecondition, "connection cannot report statistics")
	}
	st, err := sp.TableStats(ctx, ref.GetDatabase(), ref.GetSchema(), ref.GetTable())
	if err != nil {
		return &queravuev1.GetStatsResponse{Error: toAdminError(err)}, nil
	}
	out := &queravuev1.TableStats{
		EstimatedRows: st.EstimatedRows, DataBytes: st.DataBytes, IndexBytes: st.IndexBytes, TotalBytes: st.TotalBytes,
	}
	for _, e := range st.Extras {
		out.Extras = append(out.Extras, &queravuev1.StatEntry{Key: e.Key, Label: e.Label, Value: e.Value})
	}
	return &queravuev1.GetStatsResponse{Stats: out}, nil
}
