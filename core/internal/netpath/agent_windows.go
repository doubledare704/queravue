//go:build windows

package netpath

import (
	"context"
	"net"
	"os"
)

const openSSHAgentPipe = `\\.\pipe\openssh-ssh-agent`

type pipeConn struct{ *os.File }

func (pipeConn) LocalAddr() net.Addr  { return pipeAddr{} }
func (pipeConn) RemoteAddr() net.Addr { return pipeAddr{} }

type pipeAddr struct{}

func (pipeAddr) Network() string { return "pipe" }
func (pipeAddr) String() string  { return openSSHAgentPipe }

func dialAgent(_ context.Context) (net.Conn, error) {
	f, err := os.OpenFile(openSSHAgentPipe, os.O_RDWR, 0)
	if err != nil {
		return nil, &ConfigError{Msg: "the OpenSSH agent is not running (named pipe " + openSSHAgentPipe + ")"}
	}
	return pipeConn{f}, nil
}
