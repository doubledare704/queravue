package netpath

import (
	"context"
	"errors"
	"net"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"testing"
	"time"

	"go.uber.org/goleak"
	"golang.org/x/crypto/ssh"
	"golang.org/x/crypto/ssh/knownhosts"
)

func TestMain(m *testing.M) { goleak.VerifyTestMain(m) }

func echoServer(t *testing.T) string {
	t.Helper()
	l, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = l.Close() })
	go func() {
		for {
			c, err := l.Accept()
			if err != nil {
				return
			}
			go func() {
				defer c.Close()
				buf := make([]byte, 64)
				for {
					n, err := c.Read(buf)
					if err != nil {
						return
					}
					_, _ = c.Write(buf[:n])
				}
			}()
		}
	}()
	return l.Addr().String()
}

type rig struct {
	server *testSSHServer
	keys   *HostKeys
	cfg    SSHConfig
	own    string
}

func newRig(t *testing.T) *rig {
	t.Helper()
	host := newSigner(t)
	srv := startSSHServer(t, host, nil)
	ip, port := srv.Addr()
	own := filepath.Join(t.TempDir(), "known_hosts")
	return &rig{
		server: srv, own: own, keys: NewHostKeys("", own),
		cfg: SSHConfig{Host: ip, Port: port, User: "tester", Auth: SSHAuthPassword, Password: testPassword, KeepAlive: 100 * time.Millisecond},
	}
}

func (r *rig) trust(t *testing.T) {
	t.Helper()
	_, err := OpenTunnel(context.Background(), r.cfg, r.keys)
	var unknown *HostKeyUnknownError
	if !errors.As(err, &unknown) {
		t.Fatalf("want unknown host key, got %v", err)
	}
	if err := r.keys.Trust(r.cfg.Host, r.cfg.Port, unknown.Fingerprint); err != nil {
		t.Fatal(err)
	}
}

func TestHostKeyStates(t *testing.T) {
	r := newRig(t)

	_, err := OpenTunnel(context.Background(), r.cfg, r.keys)
	var unknown *HostKeyUnknownError
	if !errors.As(err, &unknown) {
		t.Fatalf("unknown host: got %v", err)
	}
	if want := ssh.FingerprintSHA256(r.server.hostKey.PublicKey()); unknown.Fingerprint != want {
		t.Fatalf("fingerprint = %s, want %s", unknown.Fingerprint, want)
	}

	if err := r.keys.Trust(r.cfg.Host, r.cfg.Port, "SHA256:wrong"); err == nil {
		t.Fatal("Trust accepted a fingerprint the failure did not carry")
	}
	if err := r.keys.Trust(r.cfg.Host, r.cfg.Port, unknown.Fingerprint); err != nil {
		t.Fatal(err)
	}
	tun, err := OpenTunnel(context.Background(), r.cfg, r.keys)
	if err != nil {
		t.Fatalf("known host: %v", err)
	}
	_ = tun.Close()
	if st, err := os.Stat(r.own); err != nil || st.Mode().Perm() != 0o600 {
		t.Fatalf("known_hosts file: %v %v", st, err)
	}

	other := startSSHServer(t, newSigner(t), nil)
	ip, port := other.Addr()
	cfg := r.cfg
	cfg.Host, cfg.Port = ip, port
	swapped := knownhosts.Line([]string{knownhosts.Normalize(net.JoinHostPort(ip, strconv.Itoa(port)))}, r.server.hostKey.PublicKey()) + "\n"
	if err := os.WriteFile(r.own, []byte(swapped), 0o600); err != nil {
		t.Fatal(err)
	}
	_, err = OpenTunnel(context.Background(), cfg, r.keys)
	var changed *HostKeyChangedError
	if !errors.As(err, &changed) {
		t.Fatalf("changed key: got %v", err)
	}
	if changed.Fingerprint == changed.TrustedFingerprint || changed.TrustedFingerprint == "" {
		t.Fatalf("changed error lacks both fingerprints: %+v", changed)
	}
	if err := r.keys.Trust(ip, port, changed.Fingerprint); err == nil {
		t.Fatal("a changed key must have no trust path")
	}
}

func TestUserKnownHostsIsHonoured(t *testing.T) {
	r := newRig(t)
	r.trust(t)
	b, _ := os.ReadFile(r.own)
	user := filepath.Join(t.TempDir(), "user_known_hosts")
	if err := os.WriteFile(user, b, 0o600); err != nil {
		t.Fatal(err)
	}
	keys := NewHostKeys(user, filepath.Join(t.TempDir(), "own"))
	tun, err := OpenTunnel(context.Background(), r.cfg, keys)
	if err != nil {
		t.Fatalf("host in user known_hosts: %v", err)
	}
	_ = tun.Close()
}

func TestAuthErrors(t *testing.T) {
	r := newRig(t)
	r.trust(t)

	bad := r.cfg
	bad.Password = "nope"
	if _, err := OpenTunnel(context.Background(), bad, r.keys); !isAuthErr(err) {
		t.Fatalf("wrong password: got %v", err)
	}

	keyPath, pub := writeOpenSSHKey(t, "")
	r.server.userKey = pub
	keyCfg := r.cfg
	keyCfg.Auth, keyCfg.KeyFile = SSHAuthKeyFile, keyPath
	tun, err := OpenTunnel(context.Background(), keyCfg, r.keys)
	if err != nil {
		t.Fatalf("key auth: %v", err)
	}
	_ = tun.Close()

	otherKey, _ := writeOpenSSHKey(t, "")
	keyCfg.KeyFile = otherKey
	if _, err := OpenTunnel(context.Background(), keyCfg, r.keys); !isAuthErr(err) {
		t.Fatalf("unauthorised key: got %v", err)
	}

	encPath, encPub := writeOpenSSHKey(t, "pp")
	r.server.userKey = encPub
	keyCfg.KeyFile = encPath
	if _, err := OpenTunnel(context.Background(), keyCfg, r.keys); !isAuthErr(err) {
		t.Fatalf("missing passphrase: got %v", err)
	}
	keyCfg.KeyPassphrase = "wrong"
	if _, err := OpenTunnel(context.Background(), keyCfg, r.keys); !isAuthErr(err) {
		t.Fatalf("wrong passphrase: got %v", err)
	}
	keyCfg.KeyPassphrase = "pp"
	tun, err = OpenTunnel(context.Background(), keyCfg, r.keys)
	if err != nil {
		t.Fatalf("encrypted key: %v", err)
	}
	_ = tun.Close()
}

func isAuthErr(err error) bool {
	var a *AuthError
	return errors.As(err, &a)
}

func TestAuthErrorsNeverLeakSecrets(t *testing.T) {
	r := newRig(t)
	r.trust(t)
	bad := r.cfg
	bad.Password = "super-secret-wrong"
	_, err := OpenTunnel(context.Background(), bad, r.keys)
	if err == nil || strings.Contains(err.Error(), "super-secret-wrong") {
		t.Fatalf("error leaks the password: %v", err)
	}
}

func TestTunnelCarriesTraffic(t *testing.T) {
	r := newRig(t)
	r.trust(t)
	tun, err := OpenTunnel(context.Background(), r.cfg, r.keys)
	if err != nil {
		t.Fatal(err)
	}
	defer tun.Close()
	c, err := tun.DialContext(context.Background(), "tcp", echoServer(t))
	if err != nil {
		t.Fatal(err)
	}
	defer c.Close()
	_, _ = c.Write([]byte("ping"))
	buf := make([]byte, 4)
	if _, err := c.Read(buf); err != nil || string(buf) != "ping" {
		t.Fatalf("echo = %q, %v", buf, err)
	}
}

func TestJumpHost(t *testing.T) {
	jump := newRig(t)
	jump.trust(t)
	final := newRig(t)
	final.keys = jump.keys
	final.trust(t)

	cfg := final.cfg
	cfg.Jump = &jump.cfg
	tun, err := OpenTunnel(context.Background(), cfg, jump.keys)
	if err != nil {
		t.Fatalf("via jump host: %v", err)
	}
	c, err := tun.DialContext(context.Background(), "tcp", echoServer(t))
	if err != nil {
		t.Fatal(err)
	}
	_ = c.Close()
	if err := tun.Close(); err != nil {
		t.Fatal(err)
	}
}

func TestTunnelLossIsTypedAndLeaksNothing(t *testing.T) {
	r := newRig(t)
	r.trust(t)
	tun, err := OpenTunnel(context.Background(), r.cfg, r.keys)
	if err != nil {
		t.Fatal(err)
	}
	c, err := tun.DialContext(context.Background(), "tcp", echoServer(t))
	if err != nil {
		t.Fatal(err)
	}
	readErr := make(chan error, 1)
	go func() {
		_, err := c.Read(make([]byte, 1))
		readErr <- err
	}()
	time.Sleep(50 * time.Millisecond)
	r.server.DropConnections()

	select {
	case err := <-readErr:
		var lost *TunnelLostError
		if !errors.As(err, &lost) {
			t.Fatalf("in-flight read: want TunnelLostError, got %v", err)
		}
	case <-time.After(5 * time.Second):
		t.Fatal("read did not fail after the tunnel dropped")
	}
	select {
	case <-tun.Lost():
	case <-time.After(time.Second):
		t.Fatal("Lost() not closed")
	}
	_, err = tun.DialContext(context.Background(), "tcp", "127.0.0.1:1")
	var lost *TunnelLostError
	if !errors.As(err, &lost) {
		t.Fatalf("dial after loss: got %v", err)
	}
	_ = c.Close()
	_ = tun.Close()
}

func TestCancelledOpenLeaksNothing(t *testing.T) {
	l, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer l.Close()
	go func() {
		for {
			c, err := l.Accept()
			if err != nil {
				return
			}
			defer c.Close()
		}
	}()
	host, portStr, _ := net.SplitHostPort(l.Addr().String())
	port, _ := strconv.Atoi(portStr)
	cfg := SSHConfig{Host: host, Port: port, User: "u", Password: "p"}
	ctx, cancel := context.WithTimeout(context.Background(), 150*time.Millisecond)
	defer cancel()
	start := time.Now()
	_, err = OpenTunnel(ctx, cfg, NewHostKeys("", filepath.Join(t.TempDir(), "kh")))
	if err == nil {
		t.Fatal("handshake against a mute server succeeded")
	}
	if time.Since(start) > 3*time.Second {
		t.Fatalf("cancel took %s", time.Since(start))
	}
}

func TestCancelledDialLeaksNothing(t *testing.T) {
	r := newRig(t)
	r.trust(t)
	tun, err := OpenTunnel(context.Background(), r.cfg, r.keys)
	if err != nil {
		t.Fatal(err)
	}
	defer tun.Close()
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	if _, err := tun.DialContext(ctx, "tcp", echoServer(t)); !errors.Is(err, context.Canceled) {
		t.Fatalf("got %v", err)
	}
}

func TestAgentWithoutSocketIsConfigError(t *testing.T) {
	t.Setenv("SSH_AUTH_SOCK", "")
	r := newRig(t)
	cfg := r.cfg
	cfg.Auth = SSHAuthAgent
	_, err := OpenTunnel(context.Background(), cfg, r.keys)
	var ce *ConfigError
	if !errors.As(err, &ce) {
		t.Fatalf("got %v", err)
	}
}
