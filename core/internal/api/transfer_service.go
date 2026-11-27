package api

import (
	"log/slog"

	"github.com/doubledare704/queravue/core/internal/connections"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/session"
)

// TransferService implements queravuev1.TransferServiceServer.
type TransferService struct {
	queravuev1.UnimplementedTransferServiceServer

	sessions    *session.Manager
	connections *connections.Service
	log         *slog.Logger
}

// NewTransferService returns a TransferService backed by s and c. connections may be
// nil, in which case no connection counts as production.
func NewTransferService(s *session.Manager, c *connections.Service, log *slog.Logger) *TransferService {
	if log == nil {
		log = slog.Default()
	}
	return &TransferService{sessions: s, connections: c, log: log}
}
