package server

import (
	"context"
	"io"
	"log/slog"
	"os"
	"path/filepath"
	"testing"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/codes"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/metadata"
	"google.golang.org/grpc/status"

	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

const testToken = "s3cret-token"

// shortSocketPath avoids t.TempDir(): macOS caps Unix socket paths at 104 bytes.
func shortSocketPath(t *testing.T) string {
	t.Helper()
	dir, err := os.MkdirTemp("", "qv")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = os.RemoveAll(dir) })
	return filepath.Join(dir, "core.sock")
}

// startServer runs Serve in the background and returns a client plus a stop func.
func startServer(t *testing.T) (queravuev1.CoreServiceClient, string, func() error) {
	t.Helper()
	sock := shortSocketPath(t)
	ctx, cancel := context.WithCancel(context.Background())
	ready := make(chan struct{})
	done := make(chan error, 1)
	go func() {
		done <- Serve(ctx, Config{
			SocketPath:  sock,
			Token:       testToken,
			Logger:      slog.New(slog.NewTextHandler(io.Discard, nil)),
			OnListening: func() { close(ready) },
		})
	}()
	select {
	case <-ready:
	case err := <-done:
		t.Fatalf("Serve exited early: %v", err)
	case <-time.After(5 * time.Second):
		t.Fatal("server did not start")
	}

	conn, err := grpc.NewClient("unix://"+sock, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		t.Fatal(err)
	}
	stopped := false
	stop := func() error {
		if stopped {
			return nil
		}
		stopped = true
		cancel()
		return <-done
	}
	t.Cleanup(func() {
		_ = stop()
		_ = conn.Close()
	})
	return queravuev1.NewCoreServiceClient(conn), sock, stop
}

func withToken(ctx context.Context, token string) context.Context {
	return metadata.AppendToOutgoingContext(ctx, "authorization", "Bearer "+token)
}

func TestAuth(t *testing.T) {
	client, _, _ := startServer(t)
	tests := []struct {
		name string
		ctx  context.Context
		want codes.Code
	}{
		{"no token", context.Background(), codes.Unauthenticated},
		{"wrong token", withToken(context.Background(), "nope"), codes.Unauthenticated},
		{"no bearer prefix", metadata.AppendToOutgoingContext(context.Background(), "authorization", testToken), codes.Unauthenticated},
		{"valid token", withToken(context.Background(), testToken), codes.OK},
	}
	for _, tt := range tests {
		t.Run(tt.name+"/unary", func(t *testing.T) {
			ctx, cancel := context.WithTimeout(tt.ctx, 5*time.Second)
			defer cancel()
			_, err := client.Hello(ctx, &queravuev1.HelloRequest{})
			if got := status.Code(err); got != tt.want {
				t.Fatalf("Hello code = %v, want %v (err %v)", got, tt.want, err)
			}
		})
		t.Run(tt.name+"/stream", func(t *testing.T) {
			ctx, cancel := context.WithTimeout(tt.ctx, 5*time.Second)
			defer cancel()
			stream, err := client.Health(ctx, &queravuev1.HealthRequest{})
			if err == nil {
				_, err = stream.Recv()
			}
			if got := status.Code(err); got != tt.want {
				t.Fatalf("Health code = %v, want %v (err %v)", got, tt.want, err)
			}
		})
	}
}

func TestSocketPermissionsAndCleanup(t *testing.T) {
	_, sock, stop := startServer(t)
	fi, err := os.Stat(sock)
	if err != nil {
		t.Fatal(err)
	}
	if perm := fi.Mode().Perm(); perm != 0o600 {
		t.Errorf("socket perm = %o, want 600", perm)
	}
	if err := stop(); err != nil {
		t.Fatalf("Serve: %v", err)
	}
	if _, err := os.Stat(sock); !os.IsNotExist(err) {
		t.Errorf("socket still exists after shutdown (err %v)", err)
	}
}

func TestGracefulShutdownEndsHealthStream(t *testing.T) {
	client, _, stop := startServer(t)
	stream, err := client.Health(withToken(context.Background(), testToken), &queravuev1.HealthRequest{IntervalMs: 10_000})
	if err != nil {
		t.Fatal(err)
	}
	if _, err := stream.Recv(); err != nil {
		t.Fatalf("first beat: %v", err)
	}
	stopErr := make(chan error, 1)
	go func() { stopErr <- stop() }()

	beat, err := stream.Recv()
	if err != nil {
		t.Fatalf("draining beat: %v", err)
	}
	if beat.GetStatus() != queravuev1.HealthStatus_HEALTH_STATUS_DRAINING {
		t.Fatalf("status = %v, want DRAINING", beat.GetStatus())
	}
	if err := <-stopErr; err != nil {
		t.Fatalf("Serve: %v", err)
	}
}

func TestStaleSocketIsReplaced(t *testing.T) {
	sock := shortSocketPath(t)
	lis, err := listenUnix(sock)
	if err != nil {
		t.Fatal(err)
	}
	// Simulate a crashed core: the file stays behind without a listener.
	if ul, ok := lis.(interface{ SetUnlinkOnClose(bool) }); ok {
		ul.SetUnlinkOnClose(false)
	}
	_ = lis.Close()
	if _, err := os.Stat(sock); err != nil {
		t.Fatalf("expected stale socket file: %v", err)
	}
	lis2, err := listenUnix(sock)
	if err != nil {
		t.Fatalf("listen over stale socket: %v", err)
	}
	_ = lis2.Close()
}

func TestRefusesNonSocketPath(t *testing.T) {
	sock := shortSocketPath(t)
	if err := os.WriteFile(sock, []byte("x"), 0o600); err != nil {
		t.Fatal(err)
	}
	if _, err := listenUnix(sock); err == nil {
		t.Fatal("expected error for regular file at socket path")
	}
}

func TestRecoverTurnsPanicIntoInternal(t *testing.T) {
	log := slog.New(slog.NewTextHandler(io.Discard, nil))
	_, err := recoverUnary(log)(context.Background(), nil, &grpc.UnaryServerInfo{FullMethod: "/x"},
		func(context.Context, any) (any, error) { panic("boom") })
	if status.Code(err) != codes.Internal {
		t.Fatalf("code = %v, want Internal", status.Code(err))
	}
	err = recoverStream(log)(nil, nil, &grpc.StreamServerInfo{FullMethod: "/x"},
		func(any, grpc.ServerStream) error { panic("boom") })
	if status.Code(err) != codes.Internal {
		t.Fatalf("stream code = %v, want Internal", status.Code(err))
	}
}
