// Package api implements the gRPC services. Handlers stay thin: they adapt
// protobuf messages and delegate real work to other packages.
package api

import (
	"context"
	"time"

	"google.golang.org/protobuf/types/known/timestamppb"

	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/version"
)

const (
	defaultHealthInterval = time.Second
	minHealthInterval     = 250 * time.Millisecond
	maxHealthInterval     = 10 * time.Second
)

// Core-level capability names reported by Hello.
const (
	CapabilityHealth = "health"
	// CapabilityConnections means ConnectionService is available.
	CapabilityConnections = "connections"
)

// CoreService implements queravuev1.CoreServiceServer.
type CoreService struct {
	queravuev1.UnimplementedCoreServiceServer

	// draining is closed when the server starts shutting down, so open Health
	// streams can send a final DRAINING heartbeat and return.
	draining <-chan struct{}
}

// NewCoreService returns a CoreService. Closing draining makes open Health
// streams report HEALTH_STATUS_DRAINING and end.
func NewCoreService(draining <-chan struct{}) *CoreService {
	return &CoreService{draining: draining}
}

// Hello returns the core version and capabilities.
func (s *CoreService) Hello(_ context.Context, _ *queravuev1.HelloRequest) (*queravuev1.HelloResponse, error) {
	return &queravuev1.HelloResponse{
		CoreVersion:     version.Version,
		ProtocolVersion: version.ProtocolVersion,
		Capabilities:    []string{CapabilityHealth, CapabilityConnections},
	}, nil
}

// Health streams heartbeats until the client cancels or the server drains.
func (s *CoreService) Health(req *queravuev1.HealthRequest, stream queravuev1.CoreService_HealthServer) error {
	interval := healthInterval(req.GetIntervalMs())
	ctx := stream.Context()
	ticker := time.NewTicker(interval)
	defer ticker.Stop()

	var seq uint64
	send := func(status queravuev1.HealthStatus) error {
		seq++
		return stream.Send(&queravuev1.HealthResponse{
			Seq:    seq,
			Time:   timestamppb.Now(),
			Status: status,
		})
	}

	// First beat goes out immediately so the client knows the stream is live.
	if err := send(queravuev1.HealthStatus_HEALTH_STATUS_SERVING); err != nil {
		return err
	}
	for {
		select {
		case <-ctx.Done():
			return nil
		case <-s.draining:
			return send(queravuev1.HealthStatus_HEALTH_STATUS_DRAINING)
		case <-ticker.C:
			if err := send(queravuev1.HealthStatus_HEALTH_STATUS_SERVING); err != nil {
				return err
			}
		}
	}
}

func healthInterval(ms uint32) time.Duration {
	if ms == 0 {
		return defaultHealthInterval
	}
	d := time.Duration(ms) * time.Millisecond
	return min(max(d, minHealthInterval), maxHealthInterval)
}
