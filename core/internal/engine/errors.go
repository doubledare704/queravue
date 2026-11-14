package engine

import (
	"context"
	"crypto/tls"
	"crypto/x509"
	"errors"
	"fmt"
	"net"
	"os"
	"strings"
	"syscall"

	"github.com/doubledare704/queravue/core/internal/netpath"
)

// Kind classifies an engine error so the UI can show a friendly message.
type Kind int

// Error kinds; they mirror queravue.v1.ErrorKind.
const (
	KindUnknown Kind = iota
	KindAuth
	KindNetwork
	KindTLS
	KindNotFound
	KindTimeout
	KindInvalidConfig
	// KindSQL: the server rejected a statement (syntax error, constraint...).
	KindSQL
	// KindCanceled: the statement was cancelled by the caller.
	KindCanceled
	// KindConnectionLost: the connection broke while a statement ran.
	KindConnectionLost
	// KindParse: filter, sort, projection or a document is not valid EJSON.
	KindParse
	// KindConflict: the stored document differs from the expected one.
	KindConflict
	// KindConfirmationRequired: a destructive write on a production
	// connection lacks the confirmation flag.
	KindConfirmationRequired
	// KindUnsupported: the server does not support the operation.
	KindUnsupported
	// KindServer: the server rejected an operation that is not a statement
	// (document engines: duplicate key, validation failure, ...).
	KindServer
	// KindSSHHostKeyUnknown: the bastion's host key is not trusted yet.
	KindSSHHostKeyUnknown
	// KindSSHHostKeyChanged: the bastion's host key differs from the trusted one.
	KindSSHHostKeyChanged
	// KindSSHAuth: the bastion rejected the credentials.
	KindSSHAuth
	// KindTunnelLost: the SSH tunnel dropped after it was established.
	KindTunnelLost
)

// String implements fmt.Stringer.
func (k Kind) String() string {
	switch k {
	case KindAuth:
		return "auth"
	case KindNetwork:
		return "network"
	case KindTLS:
		return "tls"
	case KindNotFound:
		return "not_found"
	case KindTimeout:
		return "timeout"
	case KindInvalidConfig:
		return "invalid_config"
	case KindSQL:
		return "sql"
	case KindCanceled:
		return "canceled"
	case KindConnectionLost:
		return "connection_lost"
	case KindParse:
		return "parse"
	case KindConflict:
		return "conflict"
	case KindConfirmationRequired:
		return "confirmation_required"
	case KindUnsupported:
		return "unsupported"
	case KindServer:
		return "server"
	case KindSSHHostKeyUnknown:
		return "ssh_host_key_unknown"
	case KindSSHHostKeyChanged:
		return "ssh_host_key_changed"
	case KindSSHAuth:
		return "ssh_auth"
	case KindTunnelLost:
		return "tunnel_lost"
	default:
		return "unknown"
	}
}

// Error is a classified engine failure. Its message never contains secrets:
// engines build it from driver errors with Redact applied.
type Error struct {
	Kind   Kind
	Engine string
	Op     string
	// Msg is the user-facing detail.
	Msg string
	// Err is the underlying cause, kept for errors.Is/As. Its text is not
	// used in Error() so a driver cannot leak secrets through it.
	Err error
	// Position is where in the statement text the server located the error:
	// a 1-based character (rune) offset, or 0 if unknown. Only set for
	// KindSQL errors.
	Position int
	// Code is the server's numeric error code, or 0 if it gave none.
	Code int
	// Current is the stored canonical EJSON document for KindConflict; nil if
	// it was deleted.
	Current *string
	// Input names the request input a KindParse error refers to.
	Input Input
	// DocumentIndex is the index of the failing document in a multi-document
	// request, or -1 if not applicable (zero value 0 means index 0 only for
	// KindParse with HasIndex).
	DocumentIndex int
	// HasIndex reports whether DocumentIndex is set.
	HasIndex bool
}

// Input names which request input a parse error refers to.
type Input int

// Inputs of a document request.
const (
	InputNone Input = iota
	InputFilter
	InputSort
	InputProjection
	InputDocument
	InputValidator
)

// Error implements error.
func (e *Error) Error() string {
	return fmt.Sprintf("%s: %s: %s", e.Engine, e.Op, e.Msg)
}

// Unwrap returns the cause.
func (e *Error) Unwrap() error { return e.Err }

// Is matches another *Error with the same Kind, so callers can write
// errors.Is(err, &engine.Error{Kind: engine.KindAuth}).
func (e *Error) Is(target error) bool {
	var t *Error
	if !errors.As(target, &t) {
		return false
	}
	return t.Kind == e.Kind && (t.Engine == "" || t.Engine == e.Engine)
}

// Errorf builds an *Error without a cause.
func Errorf(kind Kind, engineID, op, format string, args ...any) *Error {
	return &Error{Kind: kind, Engine: engineID, Op: op, Msg: fmt.Sprintf(format, args...)}
}

// KindOf returns err's Kind, or KindUnknown.
func KindOf(err error) Kind {
	var e *Error
	if errors.As(err, &e) {
		return e.Kind
	}
	return KindUnknown
}

// ClassifyCommon recognises errors any network engine can produce: context
// deadlines, dial/DNS failures, refused connections, TLS and certificate
// errors, and missing files. It returns KindUnknown if none match.
func ClassifyCommon(err error) Kind {
	switch {
	case err == nil:
		return KindUnknown
	case kindOfNetpath(err) != KindUnknown:
		return kindOfNetpath(err)
	case errors.Is(err, context.DeadlineExceeded), errors.Is(err, os.ErrDeadlineExceeded):
		return KindTimeout
	case isTLS(err):
		return KindTLS
	case errors.Is(err, os.ErrNotExist):
		return KindNotFound
	}
	var nerr net.Error
	if errors.As(err, &nerr) && nerr.Timeout() {
		return KindTimeout
	}
	var dnsErr *net.DNSError
	var opErr *net.OpError
	switch {
	case errors.As(err, &dnsErr),
		errors.As(err, &opErr),
		errors.Is(err, syscall.ECONNREFUSED),
		errors.Is(err, syscall.ECONNRESET),
		errors.Is(err, syscall.EHOSTUNREACH),
		errors.Is(err, syscall.ENETUNREACH):
		return KindNetwork
	}
	return KindUnknown
}

func kindOfNetpath(err error) Kind {
	var (
		unknown *netpath.HostKeyUnknownError
		changed *netpath.HostKeyChangedError
		auth    *netpath.AuthError
		lost    *netpath.TunnelLostError
		cfg     *netpath.ConfigError
	)
	switch {
	case errors.As(err, &unknown):
		return KindSSHHostKeyUnknown
	case errors.As(err, &changed):
		return KindSSHHostKeyChanged
	case errors.As(err, &auth):
		return KindSSHAuth
	case errors.As(err, &lost):
		return KindTunnelLost
	case errors.As(err, &cfg):
		return KindInvalidConfig
	}
	return KindUnknown
}

func isTLS(err error) bool {
	var (
		recErr   tls.RecordHeaderError
		alertErr tls.AlertError
		certErr  *tls.CertificateVerificationError
		unkAuth  x509.UnknownAuthorityError
		hostErr  x509.HostnameError
		invalid  x509.CertificateInvalidError
	)
	return errors.As(err, &recErr) || errors.As(err, &alertErr) || errors.As(err, &certErr) ||
		errors.As(err, &unkAuth) || errors.As(err, &hostErr) || errors.As(err, &invalid) ||
		strings.Contains(err.Error(), "tls: ")
}

// Redact replaces every non-empty secret in msg with "[REDACTED]". It is a
// last line of defence for driver messages that might echo connection
// strings.
func Redact(msg string, secrets ...Secret) string {
	for _, s := range secrets {
		if s.IsZero() {
			continue
		}
		msg = strings.ReplaceAll(msg, s.Reveal(), "[REDACTED]")
	}
	return msg
}
