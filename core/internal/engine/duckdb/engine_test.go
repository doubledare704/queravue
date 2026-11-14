//go:build duckdb

package duckdb

import (
	"bufio"
	"context"
	"errors"
	"io"
	"os"
	"os/exec"
	"path/filepath"
	"strings"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func connectErr(params map[string]string) (engine.Conn, error) {
	return New().Connect(context.Background(), engine.Config{EngineID: ID, Params: params}, engine.Secret{})
}

func TestConnectMemoryByDefault(t *testing.T) {
	c, err := connectErr(nil)
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = c.Close() }()
	query(t, c, "CREATE TABLE t (a INTEGER)")
	info, err := c.ServerInfo(context.Background())
	if err != nil || info.Product != "DuckDB" || info.Version == "" || strings.HasPrefix(info.Version, "v") {
		t.Errorf("ServerInfo = %+v, %v", info, err)
	}
}

func TestMissingFileIsNotCreatedUnlessAsked(t *testing.T) {
	path := filepath.Join(t.TempDir(), "new.duckdb")
	_, err := connectErr(map[string]string{ParamPath: path})
	if engine.KindOf(err) != engine.KindNotFound {
		t.Fatalf("err = %v, want not_found", err)
	}
	if _, statErr := os.Stat(path); statErr == nil {
		t.Fatal("a failed connect created the file")
	}
	c, err := connectErr(map[string]string{ParamPath: path, ParamCreateIfMissing: "true"})
	if err != nil {
		t.Fatal(err)
	}
	_ = c.Close()
	if _, statErr := os.Stat(path); statErr != nil {
		t.Errorf("file was not created: %v", statErr)
	}
}

func TestReadOnlyOpensReadsAndRefusesWrites(t *testing.T) {
	path, seed := seededFile(t)
	_ = seed.Close()
	c, err := connectErr(map[string]string{ParamPath: path, ParamReadOnly: "true"})
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = c.Close() }()
	if got, _ := query(t, c, "SELECT count(*) FROM customers"); got.rows[0][0].Int != 3 {
		t.Errorf("customers = %+v", got.rows)
	}
	ex, _ := engine.As[engine.Executor](c)
	_, err = ex.Execute(context.Background(), engine.Statement{SQL: "DELETE FROM customers"}, &collector{})
	if engine.KindOf(err) != engine.KindAuth {
		t.Fatalf("write on a read-only file: %v (kind %v), want auth", err, engine.KindOf(err))
	}
}

func TestReadOnlyMissingFile(t *testing.T) {
	_, err := connectErr(map[string]string{ParamPath: filepath.Join(t.TempDir(), "none.duckdb"), ParamReadOnly: "true", ParamCreateIfMissing: "true"})
	if engine.KindOf(err) != engine.KindNotFound {
		t.Fatalf("err = %v, want not_found", err)
	}
}

func TestNotADatabaseFile(t *testing.T) {
	path := filepath.Join(t.TempDir(), "junk.duckdb")
	if err := os.WriteFile(path, []byte(strings.Repeat("not a database ", 40)), 0o600); err != nil {
		t.Fatal(err)
	}
	_, err := connectErr(map[string]string{ParamPath: path})
	if engine.KindOf(err) != engine.KindInvalidConfig {
		t.Fatalf("err = %v, want invalid_config", err)
	}
}

func TestSameFileWithOtherAccessModeInOneProcess(t *testing.T) {
	path, seed := seededFile(t)
	defer func() { _ = seed.Close() }()
	_, err := connectErr(map[string]string{ParamPath: path, ParamReadOnly: "true"})
	if engine.KindOf(err) != engine.KindInvalidConfig {
		t.Fatalf("err = %v, want invalid_config", err)
	}
}

func TestExecuteAfterCloseIsConnectionLost(t *testing.T) {
	c, _ := connectErr(nil)
	if err := c.Close(); err != nil {
		t.Fatal(err)
	}
	if err := c.Close(); err != nil {
		t.Errorf("second Close: %v", err)
	}
	ex, _ := engine.As[engine.Executor](c)
	_, err := ex.Execute(context.Background(), engine.Statement{SQL: "SELECT 1"}, &collector{})
	if engine.KindOf(err) != engine.KindConnectionLost {
		t.Errorf("err = %v, want connection_lost", err)
	}
}

const holdLockEnv = "QV_DUCKDB_HOLD_LOCK"

// TestHoldLock is the child process of TestFileLockedByAnotherProcess.
func TestHoldLock(t *testing.T) {
	path := os.Getenv(holdLockEnv)
	if path == "" {
		t.Skip("helper process of TestFileLockedByAnotherProcess")
	}
	c := connectTo(t, map[string]string{ParamPath: path, ParamCreateIfMissing: "true"})
	query(t, c, "CREATE TABLE IF NOT EXISTS held (a INTEGER)")
	_, _ = os.Stdout.WriteString("locked\n")
	_, _ = io.Copy(io.Discard, os.Stdin)
}

func TestFileLockedByAnotherProcess(t *testing.T) {
	path := filepath.Join(t.TempDir(), "held.duckdb")
	cmd := exec.Command(os.Args[0], "-test.run=^TestHoldLock$")
	cmd.Env = append(os.Environ(), holdLockEnv+"="+path)
	stdin, _ := cmd.StdinPipe()
	stdout, _ := cmd.StdoutPipe()
	if err := cmd.Start(); err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = stdin.Close(); _ = cmd.Wait() })
	ready := make(chan string, 1)
	go func() {
		line, _ := bufio.NewReader(stdout).ReadString('\n')
		ready <- strings.TrimSpace(line)
	}()
	select {
	case line := <-ready:
		if line != "locked" {
			t.Fatalf("helper said %q", line)
		}
	case <-time.After(30 * time.Second):
		t.Fatal("helper process did not take the lock")
	}

	for name, params := range map[string]map[string]string{
		"read-write": {ParamPath: path},
		"read-only":  {ParamPath: path, ParamReadOnly: "true"},
	} {
		t.Run(name, func(t *testing.T) {
			_, err := connectErr(params)
			if !errors.Is(err, ErrFileLocked) || engine.KindOf(err) != engine.KindTimeout {
				t.Fatalf("err = %v (kind %v), want ErrFileLocked as timeout", err, engine.KindOf(err))
			}
			t.Logf("message: %v", err)
		})
	}
	_ = stdin.Close()
	_ = cmd.Wait()
	c, err := connectErr(map[string]string{ParamPath: path})
	if err != nil {
		t.Fatalf("after the other process exited: %v", err)
	}
	_ = c.Close()
}
