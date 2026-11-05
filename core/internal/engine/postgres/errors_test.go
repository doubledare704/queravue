package postgres

import (
	"context"
	"crypto/x509"
	"errors"
	"fmt"
	"net"
	"strings"
	"syscall"
	"testing"

	"github.com/jackc/pgx/v5/pgconn"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func TestClassify(t *testing.T) {
	secret := engine.NewSecret("hunter2")
	tests := []struct {
		name string
		err  error
		want engine.Kind
	}{
		{"bad password", &pgconn.PgError{Code: "28P01", Message: "password authentication failed for user \"u\""}, engine.KindAuth},
		{"no such role", &pgconn.PgError{Code: "28000", Message: "role does not exist"}, engine.KindAuth},
		{"no such db", &pgconn.PgError{Code: "3D000", Message: "database \"x\" does not exist"}, engine.KindNotFound},
		{"wrapped pg error", fmt.Errorf("wrap: %w", &pgconn.PgError{Code: "28P01"}), engine.KindAuth},
		{"refused", &net.OpError{Op: "dial", Net: "tcp", Err: syscall.ECONNREFUSED}, engine.KindNetwork},
		{"dns", &net.DNSError{Err: "no such host", Name: "nope"}, engine.KindNetwork},
		{"deadline", fmt.Errorf("dial: %w", context.DeadlineExceeded), engine.KindTimeout},
		{"cert", x509.UnknownAuthorityError{}, engine.KindTLS},
		{"server no ssl", errors.New("server refused TLS connection"), engine.KindTLS},
		{"other", errors.New("boom"), engine.KindUnknown},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got := classify(IDPostgres, "connect", tt.err, secret)
			if k := engine.KindOf(got); k != tt.want {
				t.Errorf("kind = %v, want %v (%v)", k, tt.want, got)
			}
			if !errors.Is(got, tt.err) {
				t.Error("cause not preserved")
			}
		})
	}
}

func TestClassifyRedacts(t *testing.T) {
	err := classify(IDPostgres, "connect", errors.New("failed to connect to `user=u database=d`: bad password hunter2"), engine.NewSecret("hunter2"))
	if strings.Contains(err.Error(), "hunter2") {
		t.Errorf("leaked: %v", err)
	}
	if strings.Contains(err.Error(), "failed to connect to `") {
		t.Errorf("prefix not trimmed: %v", err)
	}
}
