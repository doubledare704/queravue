package connections

import (
	"context"
	"errors"
	"net"
	"os"
	"path/filepath"
	"strings"
	"sync"
	"testing"

	"golang.org/x/crypto/ssh"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/netpath"
	"github.com/doubledare704/queravue/core/internal/netpath/nettest"
	"github.com/doubledare704/queravue/core/internal/secrets"
)

type netEngine struct {
	family string
	mu     sync.Mutex
	got    engine.Config
	target string
}

func (n *netEngine) Descriptor() engine.Descriptor {
	return engine.Descriptor{
		ID: "pg-like", DisplayName: "PG-like", Family: n.family, SupportsSSH: true, SupportsTLS: true,
		Fields: []engine.FieldSpec{
			{Key: "host", Label: "Host", Kind: engine.FieldText},
			{Key: "sslmode", Label: "SSL mode", Kind: engine.FieldSelect, Options: []string{"disable", "allow", "prefer", "require", "verify-ca", "verify-full"}},
			{Key: "password", Label: "Password", Kind: engine.FieldPassword},
		},
		Capabilities: []engine.Capability{engine.CapConnect},
	}
}

func (n *netEngine) ParseURI(string) (engine.Config, engine.Secret, error) {
	return engine.Config{}, engine.Secret{}, errors.New("unused")
}

func (n *netEngine) Connect(ctx context.Context, cfg engine.Config, _ engine.Secret) (engine.Conn, error) {
	n.mu.Lock()
	n.got = cfg
	n.mu.Unlock()
	if cfg.Net.Dial != nil {
		c, err := cfg.Net.Dial(ctx, "tcp", n.target)
		if err != nil {
			return nil, err
		}
		_ = c.Close()
	}
	return fakeConn{}, nil
}

type netEnv struct {
	svc     *Service
	secrets *secrets.Memory
	eng     *netEngine
	server  *nettest.Server
	ssh     *SSHTunnel
	dir     string
}

func newNetEnv(t *testing.T) *netEnv {
	t.Helper()
	echo, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = echo.Close() })
	go func() {
		for {
			c, err := echo.Accept()
			if err != nil {
				return
			}
			_ = c.Close()
		}
	}()
	eng := &netEngine{family: netpath.FamilyPostgres, target: echo.Addr().String()}
	reg, err := engine.NewRegistry(eng)
	if err != nil {
		t.Fatal(err)
	}
	dir := t.TempDir()
	mem := secrets.NewMemory()
	svc := NewService(reg, NewFileStore(dir), mem, WithKnownHosts("", filepath.Join(dir, "known_hosts")))
	srv := nettest.Start(t, nettest.NewSigner(t), nil)
	host, port := srv.Addr()
	return &netEnv{svc: svc, secrets: mem, eng: eng, server: srv, dir: dir,
		ssh: &SSHTunnel{Host: host, Port: port, User: "tester", KeepAliveSeconds: 1}}
}

func (e *netEnv) draft() Connection {
	return Connection{Name: "n", EngineID: "pg-like", Params: map[string]string{"host": "db"}, SSH: e.ssh}
}

func TestLegacyTLSParamsMigrateOnSave(t *testing.T) {
	env := newNetEnv(t)
	c, err := env.svc.Create(context.Background(), Connection{
		Name: "n", EngineID: "pg-like", Params: map[string]string{"host": "db", "sslmode": "verify-full"},
	}, nil)
	if err != nil {
		t.Fatal(err)
	}
	if c.TLS == nil || c.TLS.Mode != netpath.TLSVerifyFull {
		t.Fatalf("TLS = %+v", c.TLS)
	}
	if _, ok := c.Params["sslmode"]; ok {
		t.Fatal("legacy sslmode param kept")
	}
	raw, _ := os.ReadFile(filepath.Join(env.dir, FileName))
	if strings.Contains(string(raw), "sslmode") {
		t.Fatalf("file still has sslmode:\n%s", raw)
	}
}

func TestLegacyTLSParamsMigrateOnRead(t *testing.T) {
	env := newNetEnv(t)
	legacy := []Connection{{ID: "x", Name: "old", EngineID: "pg-like", Params: map[string]string{"host": "db", "sslmode": "require"}}}
	if err := NewFileStore(env.dir).Save(legacy); err != nil {
		t.Fatal(err)
	}
	c, err := env.svc.Get(context.Background(), "x")
	if err != nil {
		t.Fatal(err)
	}
	if c.TLS == nil || c.TLS.Mode != netpath.TLSRequire || c.Params["sslmode"] != "" {
		t.Fatalf("not migrated: %+v params=%v", c.TLS, c.Params)
	}
}

func TestMigrateLegacyTLSTable(t *testing.T) {
	cases := []struct {
		family string
		params map[string]string
		want   netpath.TLSMode
		ok     bool
	}{
		{netpath.FamilyPostgres, map[string]string{"sslmode": "disable"}, netpath.TLSDisable, true},
		{netpath.FamilyPostgres, map[string]string{"sslmode": "allow"}, netpath.TLSPrefer, true},
		{netpath.FamilyPostgres, map[string]string{"sslmode": "verify-ca"}, netpath.TLSVerifyCA, true},
		{netpath.FamilyPostgres, map[string]string{}, 0, false},
		{netpath.FamilyMySQL, map[string]string{"tls": "preferred"}, netpath.TLSPrefer, true},
		{netpath.FamilyMySQL, map[string]string{"tls": "skip-verify"}, netpath.TLSRequire, true},
		{netpath.FamilyMySQL, map[string]string{"tls": "verify"}, netpath.TLSVerifyFull, true},
		{netpath.FamilyClickHouse, map[string]string{"tls": "skip-verify"}, netpath.TLSRequire, true},
		{netpath.FamilyClickHouse, map[string]string{"tls": "verify"}, netpath.TLSVerifyFull, true},
		{netpath.FamilyMSSQL, map[string]string{"encrypt": "disable"}, netpath.TLSDisable, true},
		{netpath.FamilyMSSQL, map[string]string{"encrypt": "optional"}, netpath.TLSPrefer, true},
		{netpath.FamilyMSSQL, map[string]string{"encrypt": "required", "trust_server_certificate": "true"}, netpath.TLSRequire, true},
		{netpath.FamilyMSSQL, map[string]string{"encrypt": "required"}, netpath.TLSVerifyFull, true},
		{netpath.FamilyMSSQL, map[string]string{"encrypt": "strict"}, 0, false},
		{netpath.FamilyMongo, map[string]string{"tls": "false"}, netpath.TLSDisable, true},
		{netpath.FamilyMongo, map[string]string{"tls": "true"}, netpath.TLSVerifyFull, true},
		{netpath.FamilyMongo, map[string]string{"tls": "true", "tls_insecure": "true"}, netpath.TLSRequire, true},
		{netpath.FamilyOracle, map[string]string{"ssl": "false"}, netpath.TLSDisable, true},
		{netpath.FamilyOracle, map[string]string{"ssl": "true", "ssl_verify": "false"}, netpath.TLSRequire, true},
		{netpath.FamilyOracle, map[string]string{"ssl": "true"}, netpath.TLSVerifyFull, true},
	}
	for _, tc := range cases {
		got, rest, ok := netpath.MigrateLegacyTLS(tc.family, tc.params)
		if ok != tc.ok || (ok && got.Mode != tc.want) {
			t.Errorf("%s %v: got mode %d ok %v, want %d %v", tc.family, tc.params, got.Mode, ok, tc.want, tc.ok)
		}
		if ok && len(rest) != 0 {
			t.Errorf("%s %v: consumed keys left over: %v", tc.family, tc.params, rest)
		}
	}
	got, rest, _ := netpath.MigrateLegacyTLS(netpath.FamilyMongo, map[string]string{"tls": "true", "tls_ca_file": "/ca.pem", "tls_cert_key_file": "/c.pem", "hosts": "h"})
	if got.CAFile != "/ca.pem" || got.ClientCert != "/c.pem" || got.ClientKey != "/c.pem" || rest["hosts"] != "h" || len(rest) != 1 {
		t.Fatalf("mongo files: %+v %v", got, rest)
	}
}

func TestNetworkSecretsLiveOnlyInKeychain(t *testing.T) {
	env := newNetEnv(t)
	d := env.draft()
	d.TLS = &TLSSettings{Mode: netpath.TLSVerifyFull, ClientCertFile: "/c.pem", ClientKeyFile: "/k.pem"}
	d.SSH.Jump = &SSHTunnel{Host: "jump", User: "j"}
	c, err := env.svc.CreateWith(context.Background(), d, Secrets{
		Password: ptr("dbpw"),
		SSH:      SSHSecrets{Password: ptr("ssh-pw-1"), JumpPassword: ptr("jump-pw-1"), KeyPassphrase: ptr("kp-1")},
		TLS:      TLSSecrets{ClientKeyPassphrase: ptr("tls-pp-1")},
	})
	if err != nil {
		t.Fatal(err)
	}
	if !c.SSH.HasPassword || !c.SSH.HasKeyPassphrase || !c.SSH.Jump.HasPassword || c.SSH.Jump.HasKeyPassphrase || !c.TLS.HasClientKeyPassphrase {
		t.Fatalf("flags wrong: %+v %+v %+v", c.SSH, c.SSH.Jump, c.TLS)
	}
	raw, _ := os.ReadFile(filepath.Join(env.dir, FileName))
	for _, secret := range []string{"dbpw", "ssh-pw-1", "jump-pw-1", "kp-1", "tls-pp-1"} {
		if strings.Contains(string(raw), secret) {
			t.Fatalf("secret %q reached the config file", secret)
		}
	}
	if v, err := env.secrets.Get(slotRef(c.ID, slotSSHPassword)); err != nil || v != "ssh-pw-1" {
		t.Fatalf("keychain ssh password = %q, %v", v, err)
	}

	upd := c
	upd.SSH = &SSHTunnel{Host: env.ssh.Host, Port: env.ssh.Port, User: "tester"}
	upd.TLS = c.TLS
	u, err := env.svc.UpdateWith(context.Background(), upd, Secrets{SSH: SSHSecrets{Password: ptr("")}})
	if err != nil {
		t.Fatal(err)
	}
	if u.SSH.HasPassword || !u.SSH.HasKeyPassphrase {
		t.Fatalf("flags after update: %+v", u.SSH)
	}
	if _, err := env.secrets.Get(slotRef(c.ID, slotSSHPassword)); !errors.Is(err, secrets.ErrNotFound) {
		t.Fatalf("cleared password still stored: %v", err)
	}
	if _, err := env.secrets.Get(slotRef(c.ID, slotJumpPassword)); !errors.Is(err, secrets.ErrNotFound) {
		t.Fatal("jump password stayed after the jump host was removed")
	}
	if v, _ := env.secrets.Get(slotRef(c.ID, slotSSHPassphrase)); v != "kp-1" {
		t.Fatalf("untouched passphrase = %q", v)
	}

	noTunnel := u
	noTunnel.SSH = nil
	if _, err := env.svc.UpdateWith(context.Background(), noTunnel, Secrets{}); err != nil {
		t.Fatal(err)
	}
	if _, err := env.secrets.Get(slotRef(c.ID, slotSSHPassphrase)); !errors.Is(err, secrets.ErrNotFound) {
		t.Fatal("tunnel secret stayed after the tunnel was removed")
	}

	if err := env.svc.Delete(context.Background(), c.ID); err != nil {
		t.Fatal(err)
	}
	if _, err := env.secrets.Get(slotRef(c.ID, slotTLSKeyPassphrase)); !errors.Is(err, secrets.ErrNotFound) {
		t.Fatal("tls passphrase stayed after delete")
	}
}

func TestSSHNotOfferedByEnginesWithoutSupport(t *testing.T) {
	env := newEnv(t)
	d := Connection{Name: "n", EngineID: "fake", Params: map[string]string{"host": "h"}, SSH: &SSHTunnel{Host: "b", User: "u"}}
	if _, err := env.svc.Create(context.Background(), d, nil); err == nil || engine.KindOf(err) != engine.KindInvalidConfig {
		t.Fatalf("got %v", err)
	}
}

func TestTestOverSSHReportsStepsAndHostKeyFlow(t *testing.T) {
	env := newNetEnv(t)
	ctx := context.Background()
	d := env.draft()
	sec := Secrets{SSH: SSHSecrets{Password: ptr(nettest.Password)}}

	res, err := env.svc.Test(ctx, TestRequest{Draft: &d, Secrets: sec})
	if err != nil {
		t.Fatal(err)
	}
	if res.Err == nil || res.Err.Kind != engine.KindSSHHostKeyUnknown {
		t.Fatalf("first test: %+v", res.Err)
	}
	if len(res.Steps) != 1 || res.Steps[0].Stage != StageSSH || res.Steps[0].OK {
		t.Fatalf("steps = %+v", res.Steps)
	}
	var unknown *netpath.HostKeyUnknownError
	if !errors.As(res.Err, &unknown) || unknown.Fingerprint != ssh.FingerprintSHA256(env.server.HostKey.PublicKey()) {
		t.Fatalf("fingerprint missing: %v", res.Err)
	}

	if err := env.svc.TrustHostKey(env.ssh.Host, env.ssh.Port, "SHA256:other"); err == nil {
		t.Fatal("trusted a fingerprint the failure did not carry")
	}
	if err := env.svc.TrustHostKey(env.ssh.Host, env.ssh.Port, unknown.Fingerprint); err != nil {
		t.Fatal(err)
	}

	res, err = env.svc.Test(ctx, TestRequest{Draft: &d, Secrets: sec})
	if err != nil || res.Err != nil {
		t.Fatalf("second test: %v %+v", err, res.Err)
	}
	var stages []Stage
	for _, s := range res.Steps {
		if !s.OK {
			t.Fatalf("step failed: %+v", s)
		}
		stages = append(stages, s.Stage)
	}
	if want := []Stage{StageSSH, StageAuth, StagePing}; !equalStages(stages, want) {
		t.Fatalf("stages = %v, want %v", stages, want)
	}
	if env.eng.got.Net.Dial == nil {
		t.Fatal("engine got no dialer")
	}

	res, _ = env.svc.Test(ctx, TestRequest{Draft: &d, Secrets: Secrets{SSH: SSHSecrets{Password: ptr("wrong-ssh-pw")}}})
	if res.Err == nil || res.Err.Kind != engine.KindSSHAuth || strings.Contains(res.Err.Msg, "wrong-ssh-pw") {
		t.Fatalf("bad password: %+v", res.Err)
	}
}

func equalStages(a, b []Stage) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}

func TestTestStepsIncludeTLSWhenEnabled(t *testing.T) {
	env := newNetEnv(t)
	d := Connection{Name: "n", EngineID: "pg-like", Params: map[string]string{"host": "db"}, TLS: &TLSSettings{Mode: netpath.TLSRequire}}
	res, _ := env.svc.Test(context.Background(), TestRequest{Draft: &d})
	if res.Err != nil {
		t.Fatal(res.Err)
	}
	if len(res.Steps) != 3 || res.Steps[0].Stage != StageTLS || res.Steps[1].Stage != StageAuth || res.Steps[2].Stage != StagePing {
		t.Fatalf("steps = %+v", res.Steps)
	}
	if env.eng.got.Net.TLS.Mode != netpath.TLSRequire {
		t.Fatalf("engine TLS = %+v", env.eng.got.Net.TLS)
	}
}

func TestOpenReleasingClosesTunnel(t *testing.T) {
	env := newNetEnv(t)
	ctx := context.Background()
	d := env.draft()
	if _, err := env.svc.Test(ctx, TestRequest{Draft: &d, Secrets: Secrets{SSH: SSHSecrets{Password: ptr(nettest.Password)}}}); err != nil {
		t.Fatal(err)
	}
	var fp string
	res, _ := env.svc.Test(ctx, TestRequest{Draft: &d, Secrets: Secrets{SSH: SSHSecrets{Password: ptr(nettest.Password)}}})
	var unknown *netpath.HostKeyUnknownError
	if errors.As(res.Err, &unknown) {
		fp = unknown.Fingerprint
	}
	if err := env.svc.TrustHostKey(env.ssh.Host, env.ssh.Port, fp); err != nil {
		t.Fatal(err)
	}
	c, err := env.svc.CreateWith(ctx, d, Secrets{SSH: SSHSecrets{Password: ptr(nettest.Password)}})
	if err != nil {
		t.Fatal(err)
	}
	conn, _, release, err := env.svc.OpenReleasing(ctx, c.ID)
	if err != nil {
		t.Fatal(err)
	}
	if release == nil {
		t.Fatal("no release for a tunneled connection")
	}
	dial := env.eng.got.Net.Dial
	_ = conn.Close()
	release()
	if _, err := dial(ctx, "tcp", env.eng.target); err == nil {
		t.Fatal("tunnel still dials after release")
	}
	if _, _, err := env.svc.Open(ctx, c.ID); err == nil {
		t.Fatal("plain Open of a tunneled connection must refuse")
	}
}
