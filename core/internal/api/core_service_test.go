package api

import (
	"context"
	"slices"
	"testing"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/metadata"

	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/version"
)

func TestHello(t *testing.T) {
	s := NewCoreService(make(chan struct{}))
	resp, err := s.Hello(context.Background(), &queravuev1.HelloRequest{ClientVersion: "test"})
	if err != nil {
		t.Fatalf("Hello: %v", err)
	}
	if resp.GetCoreVersion() != version.Version {
		t.Errorf("core_version = %q, want %q", resp.GetCoreVersion(), version.Version)
	}
	if resp.GetProtocolVersion() != version.ProtocolVersion {
		t.Errorf("protocol_version = %d, want %d", resp.GetProtocolVersion(), version.ProtocolVersion)
	}
	if got := resp.GetCapabilities(); !slices.Equal(got, []string{CapabilityHealth, CapabilityConnections}) {
		t.Errorf("capabilities = %v, want [%s %s]", got, CapabilityHealth, CapabilityConnections)
	}
}

func TestHealthInterval(t *testing.T) {
	tests := []struct {
		name string
		ms   uint32
		want time.Duration
	}{
		{"zero uses default", 0, time.Second},
		{"below min clamps", 10, 250 * time.Millisecond},
		{"in range", 500, 500 * time.Millisecond},
		{"above max clamps", 60_000, 10 * time.Second},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := healthInterval(tt.ms); got != tt.want {
				t.Errorf("healthInterval(%d) = %v, want %v", tt.ms, got, tt.want)
			}
		})
	}
}

// fakeHealthStream records sent heartbeats.
type fakeHealthStream struct {
	grpc.ServerStream
	ctx  context.Context
	sent chan *queravuev1.HealthResponse
}

func (f *fakeHealthStream) Context() context.Context     { return f.ctx }
func (f *fakeHealthStream) SetHeader(metadata.MD) error  { return nil }
func (f *fakeHealthStream) SendHeader(metadata.MD) error { return nil }
func (f *fakeHealthStream) SetTrailer(metadata.MD)       {}
func (f *fakeHealthStream) Send(r *queravuev1.HealthResponse) error {
	f.sent <- r
	return nil
}

func TestHealthStreamsUntilCancelled(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	stream := &fakeHealthStream{ctx: ctx, sent: make(chan *queravuev1.HealthResponse, 16)}
	s := NewCoreService(make(chan struct{}))

	done := make(chan error, 1)
	go func() { done <- s.Health(&queravuev1.HealthRequest{IntervalMs: 250}, stream) }()

	for want := uint64(1); want <= 2; want++ {
		select {
		case beat := <-stream.sent:
			if beat.GetSeq() != want || beat.GetStatus() != queravuev1.HealthStatus_HEALTH_STATUS_SERVING {
				t.Fatalf("beat = seq %d status %v, want seq %d SERVING", beat.GetSeq(), beat.GetStatus(), want)
			}
		case <-time.After(2 * time.Second):
			t.Fatalf("timed out waiting for beat %d", want)
		}
	}
	cancel()
	if err := <-done; err != nil {
		t.Fatalf("Health returned %v after cancel, want nil", err)
	}
}

func TestHealthSendsDrainingOnShutdown(t *testing.T) {
	draining := make(chan struct{})
	stream := &fakeHealthStream{ctx: context.Background(), sent: make(chan *queravuev1.HealthResponse, 16)}
	s := NewCoreService(draining)

	done := make(chan error, 1)
	go func() { done <- s.Health(&queravuev1.HealthRequest{IntervalMs: 10_000}, stream) }()
	<-stream.sent // first beat
	close(draining)
	if err := <-done; err != nil {
		t.Fatalf("Health: %v", err)
	}
	if last := <-stream.sent; last.GetStatus() != queravuev1.HealthStatus_HEALTH_STATUS_DRAINING {
		t.Fatalf("last status = %v, want DRAINING", last.GetStatus())
	}
}
