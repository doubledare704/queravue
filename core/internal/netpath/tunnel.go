package netpath

import (
	"context"
	"errors"
	"fmt"
	"net"
	"strconv"
	"strings"
	"sync"
	"time"

	"golang.org/x/crypto/ssh"
	"golang.org/x/crypto/ssh/agent"
)

// SSHAuth selects how the tunnel authenticates.
type SSHAuth int

// SSH authentication methods.
const (
	SSHAuthPassword SSHAuth = iota
	SSHAuthKeyFile
	SSHAuthAgent
)

// Defaults for zero settings.
const (
	DefaultSSHPort        = 22
	DefaultKeepAlive      = 30 * time.Second
	DefaultConnectTimeout = 10 * time.Second

	// lostGrace is how long a failed read waits for the keep-alive loop to
	// confirm that the tunnel itself is gone, not just the database peer.
	lostGrace = 300 * time.Millisecond
)

// SSHConfig describes a bastion. Secrets are plain strings here: the caller
// reads them from the keychain right before opening.
type SSHConfig struct {
	Host           string
	Port           int
	User           string
	Auth           SSHAuth
	Password       string
	KeyFile        string
	KeyPassphrase  string
	KeepAlive      time.Duration
	ConnectTimeout time.Duration
	Jump           *SSHConfig
}

// Addr returns host:port with the default port applied.
func (c SSHConfig) Addr() string {
	port := c.Port
	if port == 0 {
		port = DefaultSSHPort
	}
	return net.JoinHostPort(c.Host, strconv.Itoa(port))
}

func (c SSHConfig) methodName() string {
	switch c.Auth {
	case SSHAuthKeyFile:
		return "key file"
	case SSHAuthAgent:
		return "agent"
	default:
		return "password"
	}
}

// DialFunc opens a connection to addr, from the far end of the tunnel when
// there is one.
type DialFunc func(ctx context.Context, network, addr string) (net.Conn, error)

// DialContext lets a DialFunc satisfy the context-dialer interfaces of the drivers.
func (f DialFunc) DialContext(ctx context.Context, network, addr string) (net.Conn, error) {
	return f(ctx, network, addr)
}

// Direct dials without a tunnel.
func Direct(timeout time.Duration) DialFunc {
	d := &net.Dialer{Timeout: timeout}
	return d.DialContext
}

// Tunnel is one SSH client shared by every connection of a session.
type Tunnel struct {
	host string
	jump *Tunnel

	client  *ssh.Client
	closers []func()

	mu      sync.Mutex
	lostErr error
	closed  bool
	lost    chan struct{}
	done    chan struct{}
	wg      sync.WaitGroup
}

// OpenTunnel connects to the bastion (through its jump host, if any) and
// authenticates. ctx bounds the whole open and cancels a dial in flight.
func OpenTunnel(ctx context.Context, cfg SSHConfig, keys *HostKeys) (*Tunnel, error) {
	if cfg.Host == "" {
		return nil, &ConfigError{Msg: "SSH host is required"}
	}
	if cfg.User == "" {
		return nil, &ConfigError{Msg: "SSH user is required"}
	}
	timeout := cfg.ConnectTimeout
	if timeout <= 0 {
		timeout = DefaultConnectTimeout
	}
	ctx, cancel := context.WithTimeout(ctx, timeout)
	defer cancel()

	t := &Tunnel{host: cfg.Addr(), lost: make(chan struct{}), done: make(chan struct{})}
	rawDial := Direct(timeout)
	if cfg.Jump != nil {
		jump, err := OpenTunnel(ctx, *cfg.Jump, keys)
		if err != nil {
			return nil, err
		}
		t.jump, rawDial = jump, jump.DialContext
	}
	auth, closers, err := authMethods(ctx, cfg)
	if err != nil {
		t.releaseJump()
		return nil, err
	}
	t.closers = closers

	conn, err := rawDial(ctx, "tcp", cfg.Addr())
	if err != nil {
		t.abandon()
		return nil, fmt.Errorf("netpath: dial %s: %w", cfg.Addr(), err)
	}
	stop := context.AfterFunc(ctx, func() { _ = conn.Close() })
	sshConn, chans, reqs, err := ssh.NewClientConn(conn, cfg.Addr(), &ssh.ClientConfig{
		User: cfg.User, Auth: auth, HostKeyCallback: keys.Callback(), Timeout: timeout,
		ClientVersion: "SSH-2.0-Queravue",
	})
	stop()
	if err != nil {
		_ = conn.Close()
		t.abandon()
		return nil, classifyHandshake(ctx, cfg, err)
	}
	t.client = ssh.NewClient(sshConn, chans, reqs)
	keepAlive := cfg.KeepAlive
	if keepAlive <= 0 {
		keepAlive = DefaultKeepAlive
	}
	t.wg.Add(2)
	go t.watchClient()
	go t.keepAlive(keepAlive)
	return t, nil
}

func classifyHandshake(ctx context.Context, cfg SSHConfig, err error) error {
	var unknown *HostKeyUnknownError
	var changed *HostKeyChangedError
	var cfgErr *ConfigError
	switch {
	case errors.As(err, &unknown):
		return unknown
	case errors.As(err, &changed):
		return changed
	case errors.As(err, &cfgErr):
		return cfgErr
	case ctx.Err() != nil:
		return fmt.Errorf("netpath: ssh handshake with %s: %w", cfg.Addr(), ctx.Err())
	// A wrong password that falls through to keyboard-interactive ends with a bare failure message.
	case strings.Contains(err.Error(), "unable to authenticate"), strings.Contains(err.Error(), "no supported methods remain"),
		strings.Contains(err.Error(), "unexpected message type 51"):
		return &AuthError{Host: cfg.Addr(), Method: cfg.methodName(), Err: err}
	}
	return fmt.Errorf("netpath: ssh handshake with %s: %w", cfg.Addr(), err)
}

func authMethods(ctx context.Context, cfg SSHConfig) ([]ssh.AuthMethod, []func(), error) {
	switch cfg.Auth {
	case SSHAuthKeyFile:
		signer, err := loadSigner(cfg)
		if err != nil {
			return nil, nil, err
		}
		return []ssh.AuthMethod{ssh.PublicKeys(signer)}, nil, nil
	case SSHAuthAgent:
		conn, err := dialAgent(ctx)
		if err != nil {
			var cfgErr *ConfigError
			if errors.As(err, &cfgErr) {
				return nil, nil, err
			}
			return nil, nil, &ConfigError{Msg: "cannot reach the ssh-agent: " + err.Error()}
		}
		return []ssh.AuthMethod{ssh.PublicKeysCallback(agent.NewClient(conn).Signers)}, []func(){func() { _ = conn.Close() }}, nil
	default:
		pw := cfg.Password
		return []ssh.AuthMethod{
			ssh.Password(pw),
			ssh.KeyboardInteractive(func(_, _ string, qs []string, _ []bool) ([]string, error) {
				answers := make([]string, len(qs))
				for i := range answers {
					answers[i] = pw
				}
				return answers, nil
			}),
		}, nil, nil
	}
}

func (t *Tunnel) abandon() {
	for _, c := range t.closers {
		c()
	}
	t.releaseJump()
}

func (t *Tunnel) releaseJump() {
	if t.jump != nil {
		_ = t.jump.Close()
	}
}

func (t *Tunnel) watchClient() {
	defer t.wg.Done()
	t.markLost(t.client.Wait())
}

func (t *Tunnel) keepAlive(every time.Duration) {
	defer t.wg.Done()
	tick := time.NewTicker(every)
	defer tick.Stop()
	for {
		select {
		case <-t.done:
			return
		case <-t.lost:
			return
		case <-tick.C:
			if err := t.probe(every); err != nil {
				t.markLost(err)
				return
			}
		}
	}
}

func (t *Tunnel) probe(timeout time.Duration) error {
	errc := make(chan error, 1)
	go func() {
		_, _, err := t.client.SendRequest("keepalive@openssh.com", true, nil)
		errc <- err
	}()
	select {
	case err := <-errc:
		return err
	case <-time.After(timeout):
		return errors.New("keep-alive timed out")
	case <-t.done:
		return nil
	}
}

func (t *Tunnel) markLost(err error) {
	t.mu.Lock()
	if t.closed || t.lostErr != nil {
		t.mu.Unlock()
		return
	}
	if err == nil {
		err = errors.New("connection closed")
	}
	t.lostErr = err
	close(t.lost)
	t.mu.Unlock()
	_ = t.client.Close()
}

// Lost is closed when the tunnel drops without being closed by the caller.
func (t *Tunnel) Lost() <-chan struct{} { return t.lost }

func (t *Tunnel) lostError() error {
	t.mu.Lock()
	defer t.mu.Unlock()
	if t.lostErr == nil {
		return nil
	}
	return &TunnelLostError{Host: t.host, Err: t.lostErr}
}

func (t *Tunnel) isClosed() bool {
	t.mu.Lock()
	defer t.mu.Unlock()
	return t.closed
}

// DialContext opens a channel to addr on the bastion side. It is the dialer
// every driver gets. A cancelled ctx returns at once and any late channel is
// closed.
func (t *Tunnel) DialContext(ctx context.Context, network, addr string) (net.Conn, error) {
	if err := t.lostError(); err != nil {
		return nil, err
	}
	type result struct {
		conn net.Conn
		err  error
	}
	res := make(chan result, 1)
	go func() {
		c, err := t.client.Dial(network, addr)
		res <- result{c, err}
	}()
	select {
	case r := <-res:
		if r.err != nil {
			if lost := t.lostError(); lost != nil {
				return nil, lost
			}
			return nil, fmt.Errorf("netpath: open channel to %s: %w", addr, r.err)
		}
		return &channelConn{Conn: newDeadlineConn(r.conn), tunnel: t}, nil
	case <-ctx.Done():
		go func() {
			if r := <-res; r.conn != nil {
				_ = r.conn.Close()
			}
		}()
		return nil, fmt.Errorf("netpath: open channel to %s: %w", addr, ctx.Err())
	}
}

// Close closes the SSH client, the agent connection and the jump host.
func (t *Tunnel) Close() error {
	t.mu.Lock()
	if t.closed {
		t.mu.Unlock()
		return nil
	}
	t.closed = true
	close(t.done)
	t.mu.Unlock()
	err := t.client.Close()
	t.wg.Wait()
	for _, c := range t.closers {
		c()
	}
	t.releaseJump()
	if err != nil && !errors.Is(err, net.ErrClosed) {
		return fmt.Errorf("netpath: close tunnel: %w", err)
	}
	return nil
}

// channelConn turns I/O errors into *TunnelLostError when the tunnel, not the
// database peer, went away.
type channelConn struct {
	net.Conn
	tunnel *Tunnel
}

func (c *channelConn) Read(p []byte) (int, error) {
	n, err := c.Conn.Read(p)
	return n, c.classify(err)
}

func (c *channelConn) Write(p []byte) (int, error) {
	n, err := c.Conn.Write(p)
	return n, c.classify(err)
}

func (c *channelConn) classify(err error) error {
	if err == nil || c.tunnel.isClosed() {
		return err
	}
	if lost := c.tunnel.lostError(); lost != nil {
		return lost
	}
	select {
	case <-c.tunnel.lost:
		return c.tunnel.lostError()
	case <-time.After(lostGrace):
		return err
	}
}
