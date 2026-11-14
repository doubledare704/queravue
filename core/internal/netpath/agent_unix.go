//go:build !windows

package netpath

import (
	"context"
	"net"
	"os"
)

func dialAgent(ctx context.Context) (net.Conn, error) {
	sock := os.Getenv("SSH_AUTH_SOCK")
	if sock == "" {
		return nil, &ConfigError{Msg: "SSH_AUTH_SOCK is not set; no ssh-agent is running"}
	}
	var d net.Dialer
	return d.DialContext(ctx, "unix", sock)
}
