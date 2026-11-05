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
	"syscall"
	"time"

	"github.com/doubledare704/queravue/core/internal/server"
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

	ctx, stop := signal.NotifyContext(context.Background(), syscall.SIGTERM, syscall.SIGINT)
	defer stop()
	if *stdinEOF {
		ctx = watchStdin(ctx, stdin, log)
	}

	err := server.Serve(ctx, server.Config{
		SocketPath:      *socket,
		Token:           *token,
		ShutdownTimeout: 5 * time.Second,
		Logger:          log,
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

func envOr(getenv func(string) string, key, def string) string {
	if v := getenv(key); v != "" {
		return v
	}
	return def
}
