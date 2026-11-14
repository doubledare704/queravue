//go:build integration

package netcells

import (
	"context"
	"errors"
	"net"
	"os"
	"path/filepath"
	"strconv"
	"testing"
	"time"

	"go.uber.org/goleak"
	"golang.org/x/crypto/ssh"
	"golang.org/x/crypto/ssh/agent"

	"github.com/doubledare704/queravue/core/internal/connections"
	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/engines"
	"github.com/doubledare704/queravue/core/internal/netpath"
	"github.com/doubledare704/queravue/core/internal/secrets"
)

const (
	bastionAddr  = "127.0.0.1:2222"
	bastionUser  = "queravue"
	bastionPass  = "queravue"
	devPassphase = "dev-passphrase"
)

var tlsDir = filepath.Join("..", "..", "..", "dev", "tls", "out")

func str(s string) *string { return &s }

func reachable(t *testing.T, addr string) {
	t.Helper()
	c, err := net.DialTimeout("tcp", addr, 700*time.Millisecond)
	if err != nil {
		t.Skipf("%s is not up: %v", addr, err)
	}
	_ = c.Close()
}

func newService(t *testing.T) *connections.Service {
	t.Helper()
	reg, err := engines.Registry()
	if err != nil {
		t.Fatal(err)
	}
	dir := t.TempDir()
	return connections.NewService(reg, connections.NewFileStore(dir), secrets.NewMemory(),
		connections.WithKnownHosts("", filepath.Join(dir, "known_hosts")))
}

func bastion(auth netpath.SSHAuth) *connections.SSHTunnel {
	host, port, _ := net.SplitHostPort(bastionAddr)
	p, _ := strconv.Atoi(port)
	return &connections.SSHTunnel{Host: host, Port: p, User: bastionUser, Auth: auth, KeepAliveSeconds: 5}
}

func tlsFiles(mode netpath.TLSMode) *connections.TLSSettings {
	return &connections.TLSSettings{Mode: mode, CAFile: filepath.Join(tlsDir, "ca.pem")}
}

// testTrusting runs a connection test, accepting the unknown host key once.
func testTrusting(t *testing.T, svc *connections.Service, req connections.TestRequest) connections.TestResult {
	t.Helper()
	for range 3 {
		res, err := svc.Test(context.Background(), req)
		if err != nil {
			t.Fatal(err)
		}
		var unknown *netpath.HostKeyUnknownError
		if res.Err == nil || !errors.As(res.Err, &unknown) {
			return res
		}
		host, port, _ := net.SplitHostPort(unknown.Host)
		p, _ := strconv.Atoi(port)
		if err := svc.TrustHostKey(host, p, unknown.Fingerprint); err != nil {
			t.Fatal(err)
		}
	}
	t.Fatal("host key still unknown after trusting")
	return connections.TestResult{}
}

type cell struct {
	name   string
	engine string
	params map[string]string
	pw     string
	probe  string
	tls    *connections.TLSSettings
	ssh    *connections.SSHTunnel
	sec    connections.Secrets
	want   netpath.TLSMode
}

func (c cell) run(t *testing.T) {
	t.Helper()
	reachable(t, c.probe)
	if c.ssh != nil {
		reachable(t, bastionAddr)
	}
	svc := newService(t)
	d := connections.Connection{Name: c.name, EngineID: c.engine, Params: c.params, SSH: c.ssh, TLS: c.tls}
	sec := c.sec
	sec.Password = str(c.pw)
	res := testTrusting(t, svc, connections.TestRequest{Draft: &d, Secrets: sec, Password: str(c.pw), Timeout: 30 * time.Second})
	if res.Err != nil {
		t.Fatalf("%s: %v (steps %+v)", c.name, res.Err, res.Steps)
	}
	if res.Server.Product == "" {
		t.Fatalf("%s: no server info", c.name)
	}
	var sawSSH, sawTLS bool
	for _, s := range res.Steps {
		sawSSH = sawSSH || s.Stage == connections.StageSSH
		sawTLS = sawTLS || s.Stage == connections.StageTLS
	}
	if sawSSH != (c.ssh != nil) {
		t.Fatalf("%s: SSH step present = %v", c.name, sawSSH)
	}
	if sawTLS != (c.tls != nil && c.tls.Mode > netpath.TLSDisable) {
		t.Fatalf("%s: TLS step present = %v", c.name, sawTLS)
	}
}

func TestDirectTLSAndSSHCells(t *testing.T) {
	pg := map[string]string{"host": "localhost", "port": "5432", "database": "queravue", "user": "queravue"}
	pgTLS := map[string]string{"host": "localhost", "port": "5443", "database": "queravue", "user": "queravue"}
	pgSSH := map[string]string{"host": "postgres", "port": "5432", "database": "queravue", "user": "queravue"}
	my := map[string]string{"host": "localhost", "port": "3306", "database": "queravue", "user": "queravue"}
	myTLS := map[string]string{"host": "localhost", "port": "3316", "database": "queravue", "user": "queravue"}
	mySSH := map[string]string{"host": "mysql", "port": "3306", "database": "queravue", "user": "queravue"}
	ch := map[string]string{"host": "localhost", "port": "9000", "database": "queravue", "user": "queravue"}
	chTLS := map[string]string{"host": "localhost", "port": "9441", "database": "queravue", "user": "queravue", "tls": "verify"}
	chSSH := map[string]string{"host": "clickhouse", "port": "9000", "database": "queravue", "user": "queravue"}
	mssqlSSH := map[string]string{"host": "mssql", "port": "1433", "user": "sa"}
	oraSSH := map[string]string{"host": "oracle", "port": "1521", "service_name": "FREEPDB1", "user": "queravue"}
	pass := connections.Secrets{SSH: connections.SSHSecrets{Password: str(bastionPass)}}

	cells := []cell{
		{name: "postgres direct", engine: "postgres", params: pg, pw: "queravue", probe: "127.0.0.1:5432"},
		{name: "postgres tls verify-full", engine: "postgres", params: pgTLS, pw: "queravue", probe: "127.0.0.1:5443", tls: tlsFiles(netpath.TLSVerifyFull)},
		{name: "postgres tls verify-ca", engine: "postgres", params: pgTLS, pw: "queravue", probe: "127.0.0.1:5443", tls: tlsFiles(netpath.TLSVerifyCA)},
		{name: "postgres tls require", engine: "postgres", params: pgTLS, pw: "queravue", probe: "127.0.0.1:5443", tls: &connections.TLSSettings{Mode: netpath.TLSRequire}},
		{name: "postgres ssh password", engine: "postgres", params: pgSSH, pw: "queravue", probe: "127.0.0.1:5432", ssh: bastion(netpath.SSHAuthPassword), sec: pass},
		{name: "postgres ssh key file", engine: "postgres", params: pgSSH, pw: "queravue", probe: "127.0.0.1:5432", ssh: func() *connections.SSHTunnel {
			b := bastion(netpath.SSHAuthKeyFile)
			b.KeyFile = filepath.Join(tlsDir, "ssh", "id_ed25519")
			return b
		}()},
		{name: "postgres ssh encrypted key", engine: "postgres", params: pgSSH, pw: "queravue", probe: "127.0.0.1:5432", ssh: func() *connections.SSHTunnel {
			b := bastion(netpath.SSHAuthKeyFile)
			b.KeyFile = filepath.Join(tlsDir, "ssh", "id_ed25519_encrypted")
			return b
		}(), sec: connections.Secrets{SSH: connections.SSHSecrets{KeyPassphrase: str(devPassphase)}}},
		{name: "postgres ssh jump host", engine: "postgres", params: pgSSH, pw: "queravue", probe: "127.0.0.1:5432", ssh: func() *connections.SSHTunnel {
			b := bastion(netpath.SSHAuthPassword)
			b.Host, b.Port = "ssh-bastion", 2222
			b.Jump = bastion(netpath.SSHAuthPassword)
			return b
		}(), sec: connections.Secrets{SSH: connections.SSHSecrets{Password: str(bastionPass), JumpPassword: str(bastionPass)}}},
		{name: "postgres ssh over tls", engine: "postgres", params: map[string]string{"host": "postgres-tls", "port": "5432", "database": "queravue", "user": "queravue"},
			pw: "queravue", probe: "127.0.0.1:5443", ssh: bastion(netpath.SSHAuthPassword), sec: pass, tls: tlsFiles(netpath.TLSVerifyFull)},
		{name: "mysql direct", engine: "mysql", params: my, pw: "queravue", probe: "127.0.0.1:3306"},
		{name: "mysql tls verify-full", engine: "mysql", params: myTLS, pw: "queravue", probe: "127.0.0.1:3316", tls: tlsFiles(netpath.TLSVerifyFull)},
		{name: "mysql ssh", engine: "mysql", params: mySSH, pw: "queravue", probe: "127.0.0.1:3306", ssh: bastion(netpath.SSHAuthPassword), sec: pass},
		{name: "mongodb direct", engine: "mongodb", params: map[string]string{"hosts": "localhost:27017", "replica_set": "rs0"}, probe: "127.0.0.1:27017"},
		{name: "mongodb tls", engine: "mongodb", params: map[string]string{"hosts": "localhost:27018", "direct_connection": "true"}, probe: "127.0.0.1:27018", tls: tlsFiles(netpath.TLSVerifyFull)},
		{name: "mongodb ssh direct_connection", engine: "mongodb", params: map[string]string{"hosts": "mongo:27017", "direct_connection": "true"}, probe: "127.0.0.1:27017", ssh: bastion(netpath.SSHAuthPassword), sec: pass},
		{name: "mongodb ssh over tls replica set", engine: "mongodb", params: map[string]string{"hosts": "mongo-tls:27017", "replica_set": "rs0"}, probe: "127.0.0.1:27018", ssh: bastion(netpath.SSHAuthPassword), sec: pass, tls: tlsFiles(netpath.TLSVerifyFull)},
		{name: "clickhouse direct", engine: "clickhouse", params: ch, pw: "queravue", probe: "127.0.0.1:9000"},
		{name: "clickhouse tls", engine: "clickhouse", params: chTLS, pw: "queravue", probe: "127.0.0.1:9441", tls: tlsFiles(netpath.TLSVerifyFull)},
		{name: "clickhouse ssh", engine: "clickhouse", params: chSSH, pw: "queravue", probe: "127.0.0.1:9000", ssh: bastion(netpath.SSHAuthPassword), sec: pass},
		{name: "mssql ssh", engine: "mssql", params: mssqlSSH, pw: "Queravue_dev1", probe: "127.0.0.1:1433", ssh: bastion(netpath.SSHAuthPassword), sec: pass, tls: &connections.TLSSettings{Mode: netpath.TLSRequire}},
		{name: "oracle ssh", engine: "oracle", params: oraSSH, pw: "queravue", probe: "127.0.0.1:1521", ssh: bastion(netpath.SSHAuthPassword), sec: pass},
	}
	for _, c := range cells {
		t.Run(c.name, c.run)
	}
}

func startAgent(t *testing.T) {
	t.Helper()
	keyBytes, err := os.ReadFile(filepath.Join(tlsDir, "ssh", "id_ed25519"))
	if err != nil {
		t.Skipf("dev ssh key missing: %v", err)
	}
	key, err := ssh.ParseRawPrivateKey(keyBytes)
	if err != nil {
		t.Fatal(err)
	}
	keyring := agent.NewKeyring()
	if err := keyring.Add(agent.AddedKey{PrivateKey: key}); err != nil {
		t.Fatal(err)
	}
	sock := filepath.Join(t.TempDir(), "agent.sock")
	l, err := net.Listen("unix", sock)
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
				_ = agent.ServeAgent(keyring, c)
			}()
		}
	}()
	t.Setenv("SSH_AUTH_SOCK", sock)
}

func TestSSHAgentAuth(t *testing.T) {
	startAgent(t)
	cell{
		name: "postgres ssh agent", engine: "postgres", pw: "queravue", probe: "127.0.0.1:5432",
		params: map[string]string{"host": "postgres", "port": "5432", "database": "queravue", "user": "queravue"},
		ssh:    bastion(netpath.SSHAuthAgent),
	}.run(t)
}

func TestTLSFailuresAreTyped(t *testing.T) {
	reachable(t, "127.0.0.1:5443")
	svc := newService(t)
	base := map[string]string{"host": "localhost", "port": "5443", "database": "queravue", "user": "queravue"}
	cases := []struct {
		name string
		tls  *connections.TLSSettings
	}{
		{"verify-full without the dev CA", &connections.TLSSettings{Mode: netpath.TLSVerifyFull}},
		{"verify-full with the wrong server name", &connections.TLSSettings{Mode: netpath.TLSVerifyFull, CAFile: filepath.Join(tlsDir, "ca.pem"), ServerName: "other.example"}},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			d := connections.Connection{Name: "n", EngineID: "postgres", Params: base, TLS: tc.tls}
			res, err := svc.Test(context.Background(), connections.TestRequest{Draft: &d, Password: str("queravue")})
			if err != nil {
				t.Fatal(err)
			}
			if res.Err == nil || res.Err.Kind != engine.KindTLS {
				t.Fatalf("want a TLS failure, got %+v", res.Err)
			}
			if n := len(res.Steps); n == 0 || res.Steps[n-1].Stage != connections.StageTLS || res.Steps[n-1].OK {
				t.Fatalf("steps = %+v", res.Steps)
			}
		})
	}
}

func TestSSHFailuresAreTyped(t *testing.T) {
	reachable(t, bastionAddr)
	svc := newService(t)
	d := connections.Connection{Name: "n", EngineID: "postgres", SSH: bastion(netpath.SSHAuthPassword),
		Params: map[string]string{"host": "postgres", "port": "5432", "database": "queravue", "user": "queravue"}}

	res := testTrusting(t, svc, connections.TestRequest{Draft: &d, Secrets: connections.Secrets{SSH: connections.SSHSecrets{Password: str("wrong")}}})
	if res.Err == nil || res.Err.Kind != engine.KindSSHAuth {
		t.Fatalf("want ssh auth failure, got %+v", res.Err)
	}

	res, _ = svc.Test(context.Background(), connections.TestRequest{Draft: &d, Secrets: connections.Secrets{SSH: connections.SSHSecrets{Password: str(bastionPass)}}})
	var changed *netpath.HostKeyChangedError
	if errors.As(res.Err, &changed) {
		t.Fatalf("host key reported changed: %+v", changed)
	}
}

func TestSessionOverSSHLeaksNoGoroutines(t *testing.T) {
	reachable(t, bastionAddr)
	reachable(t, "127.0.0.1:5432")
	svc := newService(t)
	d := connections.Connection{Name: "n", EngineID: "postgres", SSH: bastion(netpath.SSHAuthPassword),
		Params: map[string]string{"host": "postgres", "port": "5432", "database": "queravue", "user": "queravue"}}
	sec := connections.Secrets{Password: str("queravue"), SSH: connections.SSHSecrets{Password: str(bastionPass)}}
	testTrusting(t, svc, connections.TestRequest{Draft: &d, Secrets: sec, Password: str("queravue")})
	c, err := svc.CreateWith(context.Background(), d, sec)
	if err != nil {
		t.Fatal(err)
	}

	before := goleak.IgnoreCurrent()
	conn, _, release, err := svc.OpenReleasing(context.Background(), c.ID)
	if err != nil {
		t.Fatal(err)
	}
	if err := conn.Ping(context.Background()); err != nil {
		t.Fatal(err)
	}
	_ = conn.Close()
	release()
	if err := goleak.Find(before, goleak.IgnoreAnyFunction("internal/poll.runtime_pollWait")); err != nil {
		t.Fatalf("goroutines left after closing the session: %v", err)
	}

	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	if _, _, _, err := svc.OpenReleasing(ctx, c.ID); err == nil {
		t.Fatal("cancelled open succeeded")
	}
	if err := goleak.Find(before, goleak.IgnoreAnyFunction("internal/poll.runtime_pollWait")); err != nil {
		t.Fatalf("goroutines left after a cancelled open: %v", err)
	}
}
