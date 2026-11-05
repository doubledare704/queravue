package main

import (
	"bytes"
	"context"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"syscall"
	"testing"
	"time"

	"google.golang.org/grpc"
	"google.golang.org/grpc/credentials/insecure"
	"google.golang.org/grpc/metadata"

	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

func env(m map[string]string) func(string) string { return func(k string) string { return m[k] } }

func TestRunRequiresSocketAndToken(t *testing.T) {
	tests := []struct {
		name string
		args []string
		env  map[string]string
	}{
		{"nothing", nil, nil},
		{"socket only", []string{"--socket", "/tmp/x.sock"}, nil},
		{"token only", nil, map[string]string{"QUERAVUE_TOKEN": "t"}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			err := run(tt.args, env(tt.env), strings.NewReader(""), io.Discard)
			if err == nil || !strings.Contains(err.Error(), "required") {
				t.Fatalf("err = %v, want 'required' error", err)
			}
		})
	}
}

func TestRunExitsOnStdinEOF(t *testing.T) {
	dir, err := os.MkdirTemp("", "qv")
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = os.RemoveAll(dir) }()
	sock := filepath.Join(dir, "core.sock")

	stdinR, stdinW := io.Pipe()
	done := make(chan error, 1)
	go func() {
		done <- run([]string{"--exit-on-stdin-eof"}, env(map[string]string{
			"QUERAVUE_SOCKET": sock, "QUERAVUE_TOKEN": "tok",
		}), stdinR, io.Discard)
	}()
	waitForSocket(t, sock)
	_ = stdinW.Close()
	select {
	case err := <-done:
		if err != nil {
			t.Fatalf("run: %v", err)
		}
	case <-time.After(10 * time.Second):
		t.Fatal("run did not exit after stdin EOF")
	}
}

// TestBinarySIGTERM builds the real binary and checks graceful shutdown on
// SIGTERM, that the token never reaches the logs, and Hello works end to end.
func TestBinarySIGTERM(t *testing.T) {
	if testing.Short() {
		t.Skip("builds the binary")
	}
	dir, err := os.MkdirTemp("", "qv")
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = os.RemoveAll(dir) }()
	bin := filepath.Join(dir, "queravued")
	if out, err := exec.Command("go", "build", "-o", bin, ".").CombinedOutput(); err != nil {
		t.Fatalf("build: %v\n%s", err, out)
	}
	sock := filepath.Join(dir, "core.sock")
	const token = "never-log-me-123"

	var logs bytes.Buffer
	cmd := exec.Command(bin, "--socket", sock, "--log-level", "debug")
	cmd.Env = append(os.Environ(), "QUERAVUE_TOKEN="+token)
	cmd.Stderr = &logs
	if err := cmd.Start(); err != nil {
		t.Fatal(err)
	}
	waitForSocket(t, sock)

	conn, err := grpc.NewClient("unix://"+sock, grpc.WithTransportCredentials(insecure.NewCredentials()))
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithTimeout(metadata.AppendToOutgoingContext(context.Background(), "authorization", "Bearer "+token), 5*time.Second)
	defer cancel()
	if _, err := queravuev1.NewCoreServiceClient(conn).Hello(ctx, &queravuev1.HelloRequest{}); err != nil {
		t.Fatalf("Hello: %v", err)
	}
	_ = conn.Close()

	if err := cmd.Process.Signal(syscall.SIGTERM); err != nil {
		t.Fatal(err)
	}
	waitErr := make(chan error, 1)
	go func() { waitErr <- cmd.Wait() }()
	select {
	case err := <-waitErr:
		if err != nil {
			t.Fatalf("exit: %v\nlogs:\n%s", err, logs.String())
		}
	case <-time.After(10 * time.Second):
		_ = cmd.Process.Kill()
		t.Fatal("core did not exit on SIGTERM")
	}
	if _, err := os.Stat(sock); !os.IsNotExist(err) {
		t.Errorf("socket not removed on shutdown")
	}
	if strings.Contains(logs.String(), token) {
		t.Errorf("token leaked into logs")
	}
	if !strings.Contains(logs.String(), `"msg":"stopped"`) {
		t.Errorf("missing 'stopped' log line:\n%s", logs.String())
	}
}

func waitForSocket(t *testing.T, path string) {
	t.Helper()
	deadline := time.Now().Add(10 * time.Second)
	for time.Now().Before(deadline) {
		if fi, err := os.Stat(path); err == nil && fi.Mode()&os.ModeSocket != 0 {
			return
		}
		time.Sleep(20 * time.Millisecond)
	}
	t.Fatalf("socket %s never appeared", path)
}
