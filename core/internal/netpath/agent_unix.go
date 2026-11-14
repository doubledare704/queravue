//go:build !windows

package netpath

import (
	"context"
	"fmt"
	"net"
	"os"
)

func dialAgent(ctx context.Context) (net.Conn, error) {
	sock := os.Getenv("SSH_AUTH_SOCK")
	if sock == "" {
		return nil, &ConfigError{Msg: "SSH_AUTH_SOCK is not set; no ssh-agent is running"}
	}
	var d net.Dialer
	conn, err := d.DialContext(ctx, "unix", sock)
	if err != nil {
		return nil, fmt.Errorf("netpath: dial ssh-agent: %w", err)
	}
	return conn, nil
}
