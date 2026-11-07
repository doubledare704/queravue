package mongo

import (
	"context"
	"errors"
	"strings"

	"go.mongodb.org/mongo-driver/v2/mongo"

	"github.com/doubledare704/queravue/core/internal/engine"
)

// Server error codes mapped to auth failures.
const (
	codeUnauthorized         = 13
	codeAuthenticationFailed = 18
	codeUserNotFound         = 11
	codeAtlasAuthFailed      = 8000
	codeCommandOnView        = 166
)

// classify turns a driver error into a typed *engine.Error whose message is
// free of the password (drivers sometimes echo URIs).
func classify(op string, err error, secret engine.Secret) *engine.Error {
	var typed *engine.Error
	if errors.As(err, &typed) {
		return typed
	}
	kind := engine.KindUnknown
	msg := err.Error()
	low := strings.ToLower(msg)

	var cmd mongo.CommandError
	var write mongo.WriteException
	var bulk mongo.BulkWriteException
	code := 0
	switch {
	case errors.As(err, &write) && len(write.WriteErrors) > 0:
		kind, msg, code = engine.KindServer, write.WriteErrors[0].Message, write.WriteErrors[0].Code
	case errors.As(err, &bulk) && len(bulk.WriteErrors) > 0:
		kind, msg, code = engine.KindServer, bulk.WriteErrors[0].Message, bulk.WriteErrors[0].Code
	case errors.Is(err, context.Canceled):
		kind, msg = engine.KindCanceled, "operation canceled"
	case errors.As(err, &cmd) && (cmd.Code == codeUnauthorized || cmd.Code == codeAuthenticationFailed ||
		cmd.Code == codeUserNotFound || cmd.Code == codeAtlasAuthFailed):
		kind, msg = engine.KindAuth, cmd.Message
	case strings.Contains(low, "auth error") || strings.Contains(low, "authentication failed") ||
		strings.Contains(low, "unable to authenticate"):
		kind = engine.KindAuth
	case strings.Contains(low, "x509") || strings.Contains(low, "tls:") || strings.Contains(low, "certificate"):
		kind = engine.KindTLS
	case strings.Contains(low, "server selection") &&
		(strings.Contains(low, "connection refused") || strings.Contains(low, "no such host")):
		kind = engine.KindNetwork
	case strings.Contains(low, "server selection"):
		kind, msg = engine.KindTimeout, "no suitable server found before the timeout; check host, port, replica set name and network"
	case mongo.IsTimeout(err), errors.Is(err, context.DeadlineExceeded):
		kind = engine.KindTimeout
	case mongo.IsNetworkError(err):
		kind = engine.KindNetwork
	case errors.As(err, &cmd) && cmd.Code == codeCommandOnView:
		kind = engine.KindUnsupported
	case mongo.IsDuplicateKeyError(err):
		kind = engine.KindServer
	default:
		if k := engine.ClassifyCommon(err); k != engine.KindUnknown {
			kind = k
		} else if errors.As(err, &cmd) {
			kind, msg = engine.KindServer, cmd.Message
		}
	}
	if code == 0 && cmd.Code != 0 {
		code = int(cmd.Code)
	}
	return &engine.Error{Kind: kind, Engine: ID, Op: op, Msg: engine.Redact(msg, secret), Err: err, Code: code}
}
