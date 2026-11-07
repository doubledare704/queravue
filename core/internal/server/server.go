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
	"github.com/doubledare704/queravue/core/internal/connections"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/history"
	"github.com/doubledare704/queravue/core/internal/results"
	"github.com/doubledare704/queravue/core/internal/schema"
	"github.com/doubledare704/queravue/core/internal/session"
	"github.com/doubledare704/queravue/core/internal/workspace"
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
	// Connections backs ConnectionService. Nil leaves the service unregistered.
	Connections *connections.Service
	// Workspace backs WorkspaceService. Nil leaves the service unregistered.
	Workspace *workspace.Service
	// Shells backs ShellService. If nil, a handler is created when Sessions
	// and Results are set; pass one to close shells when sessions close.
	Shells *api.ShellService
	// Sessions and Results back SessionService and QueryService. Both must be
	// set to register them.
	Sessions    *session.Manager
	Results     *results.Manager
	History     *history.Store
	SchemaCache *schema.Cache
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
		// Documents can be up to 16 MiB of BSON, more as Extended JSON (ADR 0009).
		grpc.MaxRecvMsgSize(48<<20), grpc.MaxSendMsgSize(48<<20),
		grpc.ChainUnaryInterceptor(logUnary(log), recoverUnary(log), authUnary(token)),
		grpc.ChainStreamInterceptor(logStream(log), recoverStream(log), authStream(token)),
	)
	draining := make(chan struct{})
	queravuev1.RegisterCoreServiceServer(srv, api.NewCoreService(draining))
	if cfg.Connections != nil {
		queravuev1.RegisterConnectionServiceServer(srv, api.NewConnectionService(cfg.Connections))
	}
	if cfg.Sessions != nil && cfg.Results != nil {
		queravuev1.RegisterSessionServiceServer(srv, api.NewSessionService(cfg.Sessions))
		querySvc := api.NewQueryService(cfg.Sessions, cfg.Results, log)
		if cfg.History != nil {
			querySvc.SetHistory(cfg.History)
		}
		queravuev1.RegisterQueryServiceServer(srv, querySvc)
		schemaCache := cfg.SchemaCache
		if schemaCache == nil {
			schemaCache = schema.NewCache()
		}
		queravuev1.RegisterSchemaServiceServer(srv, api.NewSchemaService(cfg.Sessions, schemaCache))
		docSvc := api.NewDocumentService(cfg.Sessions, cfg.Connections, log)
		if cfg.History != nil {
			docSvc.SetHistory(cfg.History)
		}
		queravuev1.RegisterDocumentServiceServer(srv, docSvc)
		shellSvc := cfg.Shells
		if shellSvc == nil {
			shellSvc = api.NewShellService(cfg.Sessions, cfg.Connections, log)
			if cfg.History != nil {
				shellSvc.SetHistory(cfg.History)
			}
		}
		defer shellSvc.Shutdown()
		queravuev1.RegisterShellServiceServer(srv, shellSvc)
		queravuev1.RegisterTableServiceServer(srv, api.NewTableService(cfg.Sessions, cfg.Results, cfg.Connections, cfg.History, log))
		queravuev1.RegisterIndexServiceServer(srv, api.NewIndexService(cfg.Sessions, cfg.Connections, cfg.History, schemaCache, log))
		queravuev1.RegisterStatsServiceServer(srv, api.NewStatsService(cfg.Sessions))
	}
	if cfg.Workspace != nil {
		queravuev1.RegisterWorkspaceServiceServer(srv, api.NewWorkspaceService(cfg.Workspace))
	}
	if cfg.History != nil {
		queravuev1.RegisterHistoryServiceServer(srv, api.NewHistoryService(cfg.History))
	}

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
