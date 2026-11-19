package api

import (
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/session"
)

// GridFsService implements queravuev1.GridFsServiceServer. Its RPCs return
// UNIMPLEMENTED until iteration 12 PR 5.
type GridFsService struct {
	queravuev1.UnimplementedGridFsServiceServer

	sessions *session.Manager
}

// NewGridFsService returns a GridFsService backed by s.
func NewGridFsService(s *session.Manager) *GridFsService {
	return &GridFsService{sessions: s}
}
