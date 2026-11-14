package netpath

import (
	"crypto/ecdsa"
	"crypto/elliptic"
	"crypto/rand"
	"crypto/tls"
	"crypto/x509"
	"crypto/x509/pkix"
	"encoding/pem"
	"math/big"
	"net"
	"os"
	"path/filepath"
	"testing"
	"time"
)

type pki struct {
	dir      string
	caFile   string
	caCert   *x509.Certificate
	caKey    *ecdsa.PrivateKey
	serial   int64
	serverTC tls.Certificate
}

func newPKI(t *testing.T) *pki {
	t.Helper()
	p := &pki{dir: t.TempDir()}
	p.caKey, _ = ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	tmpl := &x509.Certificate{
		SerialNumber: big.NewInt(1), Subject: pkix.Name{CommonName: "test ca"},
		NotBefore: time.Now().Add(-time.Hour), NotAfter: time.Now().Add(time.Hour),
		IsCA: true, BasicConstraintsValid: true, KeyUsage: x509.KeyUsageCertSign,
	}
	der, err := x509.CreateCertificate(rand.Reader, tmpl, tmpl, &p.caKey.PublicKey, p.caKey)
	if err != nil {
		t.Fatal(err)
	}
	p.caCert, _ = x509.ParseCertificate(der)
	p.caFile = filepath.Join(p.dir, "ca.pem")
	writePEM(t, p.caFile, "CERTIFICATE", der)
	p.serverTC = p.issue(t, "db.example.test", x509.ExtKeyUsageServerAuth)
	return p
}

func (p *pki) issue(t *testing.T, name string, usage x509.ExtKeyUsage) tls.Certificate {
	t.Helper()
	p.serial++
	key, _ := ecdsa.GenerateKey(elliptic.P256(), rand.Reader)
	tmpl := &x509.Certificate{
		SerialNumber: big.NewInt(100 + p.serial), Subject: pkix.Name{CommonName: name}, DNSNames: []string{name},
		NotBefore: time.Now().Add(-time.Hour), NotAfter: time.Now().Add(time.Hour),
		ExtKeyUsage: []x509.ExtKeyUsage{usage}, KeyUsage: x509.KeyUsageDigitalSignature,
	}
	der, err := x509.CreateCertificate(rand.Reader, tmpl, p.caCert, &key.PublicKey, p.caKey)
	if err != nil {
		t.Fatal(err)
	}
	return tls.Certificate{Certificate: [][]byte{der}, PrivateKey: key}
}

func (p *pki) writeClient(t *testing.T, name string) (certFile, keyFile string) {
	t.Helper()
	c := p.issue(t, name, x509.ExtKeyUsageClientAuth)
	keyDER, _ := x509.MarshalPKCS8PrivateKey(c.PrivateKey)
	certFile, keyFile = filepath.Join(p.dir, name+".crt"), filepath.Join(p.dir, name+".key")
	writePEM(t, certFile, "CERTIFICATE", c.Certificate[0])
	writePEM(t, keyFile, "PRIVATE KEY", keyDER)
	return certFile, keyFile
}

func writePEM(t *testing.T, path, typ string, der []byte) {
	t.Helper()
	if err := os.WriteFile(path, pem.EncodeToMemory(&pem.Block{Type: typ, Bytes: der}), 0o600); err != nil {
		t.Fatal(err)
	}
}

func handshake(t *testing.T, serverCfg *tls.Config, client *tls.Config) error {
	t.Helper()
	l, err := tls.Listen("tcp", "127.0.0.1:0", serverCfg)
	if err != nil {
		t.Fatal(err)
	}
	defer l.Close()
	go func() {
		c, err := l.Accept()
		if err != nil {
			return
		}
		defer c.Close()
		if c.(*tls.Conn).Handshake() == nil {
			_, _ = c.Write([]byte("x"))
		}
	}()
	c, err := tls.DialWithDialer(&net.Dialer{Timeout: 2 * time.Second}, "tcp", l.Addr().String(), client)
	if err != nil {
		return err
	}
	defer c.Close()
	_ = c.SetReadDeadline(time.Now().Add(2 * time.Second))
	_, err = c.Read(make([]byte, 1))
	return err
}

func TestTLSModes(t *testing.T) {
	p := newPKI(t)
	server := &tls.Config{Certificates: []tls.Certificate{p.serverTC}, MinVersion: tls.VersionTLS12}
	otherPKI := newPKI(t)

	cases := []struct {
		name    string
		s       TLSSettings
		host    string
		wantErr bool
	}{
		{"require accepts unknown CA", TLSSettings{Mode: TLSRequire}, "db.example.test", false},
		{"prefer accepts unknown CA", TLSSettings{Mode: TLSPrefer}, "db.example.test", false},
		{"verify-ca accepts wrong host name", TLSSettings{Mode: TLSVerifyCA, CAFile: p.caFile}, "other.example.test", false},
		{"verify-ca rejects unknown CA", TLSSettings{Mode: TLSVerifyCA, CAFile: otherPKI.caFile}, "db.example.test", true},
		{"verify-full accepts right host", TLSSettings{Mode: TLSVerifyFull, CAFile: p.caFile}, "db.example.test", false},
		{"verify-full rejects wrong host", TLSSettings{Mode: TLSVerifyFull, CAFile: p.caFile}, "other.example.test", true},
		{"server name override fixes host", TLSSettings{Mode: TLSVerifyFull, CAFile: p.caFile, ServerName: "db.example.test"}, "127.0.0.1", false},
		{"verify-full rejects unknown CA", TLSSettings{Mode: TLSVerifyFull, CAFile: otherPKI.caFile}, "db.example.test", true},
	}
	for _, tc := range cases {
		t.Run(tc.name, func(t *testing.T) {
			cfg, err := tc.s.Build(tc.host)
			if err != nil {
				t.Fatal(err)
			}
			if err := handshake(t, server, cfg); (err != nil) != tc.wantErr {
				t.Fatalf("handshake err = %v, wantErr %v", err, tc.wantErr)
			}
		})
	}
}

func TestTLSDisabledBuildsNothing(t *testing.T) {
	for _, m := range []TLSMode{TLSUnset, TLSDisable} {
		cfg, err := TLSSettings{Mode: m}.Build("h")
		if cfg != nil || err != nil {
			t.Fatalf("mode %d: %v %v", m, cfg, err)
		}
	}
}

func TestMutualTLSWithEncryptedKey(t *testing.T) {
	p := newPKI(t)
	pool := x509.NewCertPool()
	pool.AddCert(p.caCert)
	server := &tls.Config{
		Certificates: []tls.Certificate{p.serverTC}, ClientCAs: pool,
		ClientAuth: tls.RequireAndVerifyClientCert, MinVersion: tls.VersionTLS12,
	}
	certFile, keyFile := p.writeClient(t, "client")

	plain := TLSSettings{Mode: TLSVerifyFull, CAFile: p.caFile, ClientCert: certFile, ClientKey: keyFile}
	cfg, err := plain.Build("db.example.test")
	if err != nil {
		t.Fatal(err)
	}
	if err := handshake(t, server, cfg); err != nil {
		t.Fatalf("mTLS: %v", err)
	}

	noClient, _ := TLSSettings{Mode: TLSVerifyFull, CAFile: p.caFile}.Build("db.example.test")
	if err := handshake(t, server, noClient); err == nil {
		t.Fatal("server accepted a client without a certificate")
	}

	keyPEM, _ := os.ReadFile(keyFile)
	block, _ := pem.Decode(keyPEM)
	legacy, err := x509.EncryptPEMBlock(rand.Reader, "EC PRIVATE KEY", mustECDER(t, block), []byte("hunter2"), x509.PEMCipherAES256) //nolint:staticcheck // legacy format under test
	if err != nil {
		t.Fatal(err)
	}
	encFile := filepath.Join(p.dir, "client-enc.key")
	if err := os.WriteFile(encFile, pem.EncodeToMemory(legacy), 0o600); err != nil {
		t.Fatal(err)
	}
	enc := plain
	enc.ClientKey = encFile
	if _, err := enc.Build("db.example.test"); err == nil {
		t.Fatal("encrypted key without passphrase was accepted")
	}
	enc.KeyPassphrase = "wrong"
	if _, err := enc.Build("db.example.test"); err == nil {
		t.Fatal("wrong passphrase was accepted")
	}
	enc.KeyPassphrase = "hunter2"
	cfg, err = enc.Build("db.example.test")
	if err != nil {
		t.Fatal(err)
	}
	if err := handshake(t, server, cfg); err != nil {
		t.Fatalf("mTLS with encrypted key: %v", err)
	}
}

func mustECDER(t *testing.T, pkcs8Block *pem.Block) []byte {
	t.Helper()
	k, err := x509.ParsePKCS8PrivateKey(pkcs8Block.Bytes)
	if err != nil {
		t.Fatal(err)
	}
	der, err := x509.MarshalECPrivateKey(k.(*ecdsa.PrivateKey))
	if err != nil {
		t.Fatal(err)
	}
	return der
}

func TestTLSConfigErrorsHideSecrets(t *testing.T) {
	_, err := TLSSettings{Mode: TLSRequire, ClientCert: "/no/such", ClientKey: "/no/such", KeyPassphrase: "pp-secret"}.Build("h")
	if err == nil {
		t.Fatal("missing client files accepted")
	}
}
