// Package server runs the core's gRPC server on a Unix domain socket.
package server

import (
	"context"
	"errors"
	"fmt"
	"log/slog"
	"net"
	"os"
	"path/filepath"
	"time"

	"google.golang.org/grpc"

	"github.com/doubledare704/queravue/core/internal/api"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

// Config configures Serve.
type Config struct {
	// SocketPath is the Unix socket to listen on. Its parent directory must exist.
	SocketPath string
	// Token is the per-launch auth token every request must present.
	Token string
	// ShutdownTimeout bounds graceful shutdown before connections are cut.
	ShutdownTimeout time.Duration
	// Logger receives structured logs. Defaults to slog.Default().
	Logger *slog.Logger
	// OnListening, if set, is called once the socket accepts connections.
	OnListening func()
}

// Serve listens on cfg.SocketPath and serves until ctx is cancelled, then
// shuts down gracefully and removes the socket file.
func Serve(ctx context.Context, cfg Config) error {
	if cfg.SocketPath == "" {
		return errors.New("server: socket path is required")
	}
	if cfg.Token == "" {
		return errors.New("server: token is required")
	}
	log := cfg.Logger
	if log == nil {
		log = slog.Default()
	}
	if cfg.ShutdownTimeout <= 0 {
		cfg.ShutdownTimeout = 5 * time.Second
	}

	lis, err := listenUnix(cfg.SocketPath)
	if err != nil {
		return err
	}
	// Close also unlinks the socket file for listeners created by net.Listen.
	defer func() { _ = lis.Close() }()

	token := []byte(cfg.Token)
	srv := grpc.NewServer(
		grpc.ChainUnaryInterceptor(logUnary(log), recoverUnary(log), authUnary(token)),
		grpc.ChainStreamInterceptor(logStream(log), recoverStream(log), authStream(token)),
	)
	draining := make(chan struct{})
	queravuev1.RegisterCoreServiceServer(srv, api.NewCoreService(draining))

	serveErr := make(chan error, 1)
	go func() { serveErr <- srv.Serve(lis) }()
	log.Info("listening", "socket", cfg.SocketPath)
	if cfg.OnListening != nil {
		cfg.OnListening()
	}

	select {
	case err := <-serveErr:
		return fmt.Errorf("server: serve: %w", err)
	case <-ctx.Done():
	}

	log.Info("shutting down")
	close(draining)
	stopped := make(chan struct{})
	go func() {
		srv.GracefulStop()
		close(stopped)
	}()
	select {
	case <-stopped:
	case <-time.After(cfg.ShutdownTimeout):
		log.Warn("graceful shutdown timed out; forcing stop")
		srv.Stop()
	}
	return nil
}

// listenUnix removes a stale socket at path, listens, and restricts the
// socket to the current user.
func listenUnix(path string) (net.Listener, error) {
	if fi, err := os.Lstat(path); err == nil {
		if fi.Mode()&os.ModeSocket == 0 {
			return nil, fmt.Errorf("server: %s exists and is not a socket", path)
		}
		if err := os.Remove(path); err != nil {
			return nil, fmt.Errorf("server: remove stale socket: %w", err)
		}
	}
	if err := os.MkdirAll(filepath.Dir(path), 0o700); err != nil {
		return nil, fmt.Errorf("server: create socket dir: %w", err)
	}
	lis, err := net.Listen("unix", path)
	if err != nil {
		return nil, fmt.Errorf("server: listen: %w", err)
	}
	if err := os.Chmod(path, 0o600); err != nil {
		_ = lis.Close()
		return nil, fmt.Errorf("server: chmod socket: %w", err)
	}
	return lis, nil
}
