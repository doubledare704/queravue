//go:build integration

package postgres

import (
	"context"
	"net"
	"os"
	"strconv"
	"strings"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
)

// Uses the postgres service from dev/docker-compose.yml. Override with
// PG_HOST, PG_PORT, PG_USER, PG_PASSWORD, PG_DB.
func pgParams() (map[string]string, engine.Secret) {
	get := func(k, def string) string {
		if v := os.Getenv(k); v != "" {
			return v
		}
		return def
	}
	return map[string]string{
		ParamHost:     get("PG_HOST", "127.0.0.1"),
		ParamPort:     get("PG_PORT", "5432"),
		ParamUser:     get("PG_USER", "queravue"),
		ParamDatabase: get("PG_DB", "queravue"),
		ParamSSLMode:  "disable",
	}, engine.NewSecret(get("PG_PASSWORD", "queravue"))
}

func with(p map[string]string, k, v string) map[string]string {
	out := map[string]string{}
	for kk, vv := range p {
		out[kk] = vv
	}
	out[k] = v
	return out
}

func connectPG(ctx context.Context, params map[string]string, s engine.Secret) (engine.Conn, error) {
	return New(VariantPostgres).Connect(ctx, engine.Config{EngineID: IDPostgres, Params: params}, s)
}

func TestIntegrationConnect(t *testing.T) {
	params, secret := pgParams()
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()
	c, err := connectPG(ctx, params, secret)
	if err != nil {
		t.Fatalf("connect: %v (is `make db-up` running?)", err)
	}
	defer func() { _ = c.Close() }()
	if err := c.Ping(ctx); err != nil {
		t.Fatal(err)
	}
	info, err := c.ServerInfo(ctx)
	if err != nil {
		t.Fatal(err)
	}
	if info.Product != "PostgreSQL" || !strings.HasPrefix(info.Version, "17.") {
		t.Errorf("info = %+v", info)
	}
}

func TestIntegrationErrors(t *testing.T) {
	params, secret := pgParams()
	// A port nothing listens on.
	lis, err := net.Listen("tcp", "127.0.0.1:0")
	if err != nil {
		t.Fatal(err)
	}
	closedPort := lis.Addr().(*net.TCPAddr).Port
	_ = lis.Close()

	wrongPW := engine.NewSecret("definitely-wrong-pw")
	tests := []struct {
		name    string
		params  map[string]string
		secret  engine.Secret
		timeout time.Duration
		want    engine.Kind
	}{
		{"wrong password", params, wrongPW, 10 * time.Second, engine.KindAuth},
		{"unknown user", with(params, ParamUser, "nobody_here"), secret, 10 * time.Second, engine.KindAuth},
		{"unknown database", with(params, ParamDatabase, "no_such_db"), secret, 10 * time.Second, engine.KindNotFound},
		{"closed port", with(params, ParamPort, strconv.Itoa(closedPort)), secret, 10 * time.Second, engine.KindNetwork},
		{"unresolvable host", with(params, ParamHost, "no-such-host.invalid"), secret, 10 * time.Second, engine.KindNetwork},
		// TEST-NET-1 is not routable, so the dial hangs until the deadline.
		{"blackhole", with(params, ParamHost, "192.0.2.1"), secret, 300 * time.Millisecond, engine.KindTimeout},
		{"tls required", with(params, ParamSSLMode, "require"), secret, 10 * time.Second, engine.KindTLS},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			ctx, cancel := context.WithTimeout(context.Background(), tt.timeout)
			defer cancel()
			c, err := connectPG(ctx, tt.params, tt.secret)
			if err == nil {
				_ = c.Close()
				t.Fatal("want error")
			}
			if k := engine.KindOf(err); k != tt.want {
				t.Errorf("kind = %v, want %v: %v", k, tt.want, err)
			}
			// The dev password equals the user name, so only the unique wrong
			// password can be checked for leaks.
			if strings.Contains(err.Error(), wrongPW.Reveal()) {
				t.Errorf("error leaks password: %v", err)
			}
		})
	}
}
