// Command queravued is the Queravue core sidecar. The UI launches it with a
// socket path and an auth token, then talks to it over gRPC.
package main

import (
	"context"
	"errors"
	"flag"
	"fmt"
	"io"
	"log/slog"
	"os"
	"os/signal"
	"path/filepath"
	"strconv"
	"syscall"
	"time"

	"github.com/doubledare704/queravue/core/internal/connections"
	"github.com/doubledare704/queravue/core/internal/engine/engines"
	"github.com/doubledare704/queravue/core/internal/history"
	"github.com/doubledare704/queravue/core/internal/results"
	"github.com/doubledare704/queravue/core/internal/secrets"
	"github.com/doubledare704/queravue/core/internal/server"
	"github.com/doubledare704/queravue/core/internal/session"
	"github.com/doubledare704/queravue/core/internal/version"
)

func main() {
	if err := run(os.Args[1:], os.Getenv, os.Stdin, os.Stderr); err != nil {
		fmt.Fprintln(os.Stderr, "queravued:", err)
		os.Exit(1)
	}
}

// run parses configuration and serves until SIGTERM/SIGINT or, with
// --exit-on-stdin-eof, until stdin closes (the parent UI died).
func run(args []string, getenv func(string) string, stdin io.Reader, stderr io.Writer) error {
	fs := flag.NewFlagSet("queravued", flag.ContinueOnError)
	fs.SetOutput(stderr)
	socket := fs.String("socket", getenv("QUERAVUE_SOCKET"), "Unix socket path (env QUERAVUE_SOCKET)")
	token := fs.String("token", "", "auth token; prefer env QUERAVUE_TOKEN so it does not show in ps")
	logLevel := fs.String("log-level", envOr(getenv, "QUERAVUE_LOG_LEVEL", "info"), "debug|info|warn|error (env QUERAVUE_LOG_LEVEL)")
	configDir := fs.String("config-dir", getenv("QUERAVUE_CONFIG_DIR"), "directory for connections.json (env QUERAVUE_CONFIG_DIR; default: OS config dir/Queravue)")
	secretsBackend := fs.String("secrets", envOr(getenv, "QUERAVUE_SECRETS", "keychain"), "keychain|memory (env QUERAVUE_SECRETS); memory is for tests")
	spoolCap := fs.Int64("spool-cap", envInt(getenv, "QUERAVUE_SPOOL_CAP", results.DefaultCap), "max bytes of spooled rows per result (env QUERAVUE_SPOOL_CAP)")
	sessionIdle := fs.Duration("session-idle", session.DefaultIdleTimeout, "close sessions idle for this long")
	stdinEOF := fs.Bool("exit-on-stdin-eof", false, "exit when stdin closes; set by the UI launcher")
	showVersion := fs.Bool("version", false, "print version and exit")
	if err := fs.Parse(args); err != nil {
		return fmt.Errorf("parse flags: %w", err)
	}
	if *showVersion {
		if _, err := fmt.Fprintln(stderr, version.Version); err != nil {
			return fmt.Errorf("print version: %w", err)
		}
		return nil
	}
	if *token == "" {
		*token = getenv("QUERAVUE_TOKEN")
	}
	if *socket == "" || *token == "" {
		return errors.New("--socket and a token (QUERAVUE_TOKEN or --token) are required")
	}

	var level slog.Level
	if err := level.UnmarshalText([]byte(*logLevel)); err != nil {
		return fmt.Errorf("invalid --log-level: %w", err)
	}
	log := slog.New(slog.NewJSONHandler(stderr, &slog.HandlerOptions{Level: level}))
	log.Info("starting", "version", version.Version, "pid", os.Getpid())

	connSvc, err := newConnectionService(*configDir, *secretsBackend, log)
	if err != nil {
		return err
	}

	actualConfigDir := *configDir
	if actualConfigDir == "" {
		base, err := os.UserConfigDir()
		if err != nil {
			return fmt.Errorf("locate config dir: %w", err)
		}
		actualConfigDir = filepath.Join(base, "Queravue")
	}

	histStore, err := history.NewStore(filepath.Join(actualConfigDir, "history.db"), history.DefaultCap, log)
	if err != nil {
		return fmt.Errorf("open history store: %w", err)
	}
	defer func() { _ = histStore.Close() }()

	spools, err := results.NewManager(results.DefaultBaseDir(), *spoolCap, log)
	if err != nil {
		return err
	}
	defer spools.Shutdown()
	sessions := session.NewManager(connSvc, session.WithIdleTimeout(*sessionIdle), session.WithLogger(log),
		session.WithOnClose(spools.CloseSession))
	defer sessions.Shutdown()

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGTERM, syscall.SIGINT)
	defer stop()
	if *stdinEOF {
		ctx = watchStdin(ctx, stdin, log)
	}

	err = server.Serve(ctx, server.Config{
		SocketPath:      *socket,
		Token:           *token,
		ShutdownTimeout: 5 * time.Second,
		Logger:          log,
		Connections:     connSvc,
		Sessions:        sessions,
		Results:         spools,
		History:         histStore,
	})
	if err != nil {
		return err
	}
	log.Info("stopped")
	return nil
}

// watchStdin returns a context cancelled when stdin reaches EOF. The UI keeps
// the pipe open for the core's lifetime, so EOF means the UI is gone.
func watchStdin(parent context.Context, stdin io.Reader, log *slog.Logger) context.Context {
	ctx, cancel := context.WithCancel(parent)
	go func() {
		defer cancel()
		_, _ = io.Copy(io.Discard, stdin)
		log.Info("stdin closed; parent gone")
	}()
	return ctx
}

// newConnectionService builds the connection manager with all engines.
func newConnectionService(configDir, secretsBackend string, log *slog.Logger) (*connections.Service, error) {
	if configDir == "" {
		base, err := os.UserConfigDir()
		if err != nil {
			return nil, fmt.Errorf("locate config dir: %w", err)
		}
		configDir = filepath.Join(base, "Queravue")
	}
	var store secrets.Store
	switch secretsBackend {
	case "keychain":
		store = secrets.Keyring{}
	case "memory":
		store = secrets.NewMemory()
	default:
		return nil, fmt.Errorf("invalid --secrets %q: want keychain or memory", secretsBackend)
	}
	reg, err := engines.Registry()
	if err != nil {
		return nil, err
	}
	log.Info("config", "dir", configDir, "secrets", secretsBackend)
	return connections.NewService(reg, connections.NewFileStore(configDir), store, connections.WithLogger(log)), nil
}

func envInt(getenv func(string) string, key string, def int64) int64 {
	if v, err := strconv.ParseInt(getenv(key), 10, 64); err == nil && v > 0 {
		return v
	}
	return def
}

func envOr(getenv func(string) string, key, def string) string {
	if v := getenv(key); v != "" {
		return v
	}
	return def
}
