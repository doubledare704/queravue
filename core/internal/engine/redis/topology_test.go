package redis

import (
	"context"
	"crypto/tls"
	"net"
	"net/http"
	"net/http/httptest"
	"os"
	"path/filepath"
	"testing"
	"time"

	"encoding/pem"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/netpath"
)

func tlsServer(t *testing.T) (addr, caFile string) {
	t.Helper()
	srv := httptest.NewTLSServer(http.NotFoundHandler())
	t.Cleanup(srv.Close)
	caFile = filepath.Join(t.TempDir(), "ca.pem")
	pemBytes := pem.EncodeToMemory(&pem.Block{Type: "CERTIFICATE", Bytes: srv.Certificate().Raw})
	if err := os.WriteFile(caFile, pemBytes, 0o600); err != nil {
		t.Fatal(err)
	}
	return srv.Listener.Addr().String(), caFile
}

func TestDialerUsesSharedTLSBuilder(t *testing.T) {
	addr, caFile := tlsServer(t)
	ctx, cancel := context.WithTimeout(context.Background(), 5*time.Second)
	defer cancel()

	cfg := engine.Config{Net: engine.NetworkPath{TLS: netpath.TLSSettings{Mode: netpath.TLSVerifyFull, CAFile: caFile}}}
	dial, err := newDialer(cfg)
	if err != nil {
		t.Fatal(err)
	}
	conn, err := dial(ctx, "tcp", addr)
	if err != nil {
		t.Fatal(err)
	}
	if _, ok := conn.(*tls.Conn); !ok {
		t.Errorf("connection is %T, want TLS", conn)
	}
	_ = conn.Close()

	untrusted, _ := newDialer(engine.Config{Net: engine.NetworkPath{TLS: netpath.TLSSettings{Mode: netpath.TLSVerifyFull}}})
	if _, err := untrusted(ctx, "tcp", addr); err == nil {
		t.Error("an unknown CA must fail verification")
	}
}

func TestDialerLegacyParamsAndSessionDialer(t *testing.T) {
	addr, caFile := tlsServer(t)
	var dialed []string
	cfg := engine.Config{
		Params: map[string]string{ParamTLS: "true", ParamTLSCAFile: caFile},
		Net: engine.NetworkPath{Dial: func(ctx context.Context, network, a string) (net.Conn, error) {
			dialed = append(dialed, a)
			return (&net.Dialer{}).DialContext(ctx, network, a)
		}},
	}
	dial, err := newDialer(cfg)
	if err != nil {
		t.Fatal(err)
	}
	conn, err := dial(context.Background(), "tcp", addr)
	if err != nil {
		t.Fatal(err)
	}
	_ = conn.Close()
	if len(dialed) != 1 || dialed[0] != addr {
		t.Errorf("session dialer saw %v", dialed)
	}
}

func TestDialerPlainWhenTLSOff(t *testing.T) {
	l, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	defer func() { _ = l.Close() }()
	dial, err := newDialer(engine.Config{})
	if err != nil {
		t.Fatal(err)
	}
	conn, err := dial(context.Background(), "tcp", l.Addr().String())
	if err != nil {
		t.Fatal(err)
	}
	if _, ok := conn.(*tls.Conn); ok {
		t.Error("TLS is off but the connection is TLS")
	}
	_ = conn.Close()
}

func TestDialerBadCAFileIsInvalidConfig(t *testing.T) {
	_, err := New(VariantRedis).Connect(context.Background(), engine.Config{Params: map[string]string{
		ParamHosts: "127.0.0.1:1", ParamTLS: "true", ParamTLSCAFile: "/no/such/ca.pem",
	}}, engine.Secret{})
	if engine.KindOf(err) != engine.KindInvalidConfig {
		t.Fatalf("err = %v, want invalid_config", err)
	}
}
