package api

import (
	"log/slog"

	"github.com/doubledare704/queravue/core/internal/connections"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/session"
)

// MockDataService implements queravuev1.MockDataServiceServer.
type MockDataService struct {
	queravuev1.UnimplementedMockDataServiceServer

	sessions    *session.Manager
	connections *connections.Service
	log         *slog.Logger
}

// NewMockDataService returns a MockDataService backed by s and c. connections may be
// nil, in which case no connection counts as production.
func NewMockDataService(s *session.Manager, c *connections.Service, log *slog.Logger) *MockDataService {
	if log == nil {
		log = slog.Default()
	}
	return &MockDataService{sessions: s, connections: c, log: log}
}
