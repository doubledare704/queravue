package api

import (
	"context"
	"errors"

	"github.com/doubledare704/queravue/core/internal/connections"
	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
	"github.com/doubledare704/queravue/core/internal/session"
)

func toAdminError(err error) *queravuev1.AdminError {
	var e *engine.Error
	if !errors.As(err, &e) {
		return &queravuev1.AdminError{Kind: queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_SERVER, Message: "operation failed"}
	}
	out := &queravuev1.AdminError{Kind: adminErrorKind(e.Kind), Message: e.Msg}
	if e.Kind == engine.KindParse && e.Input != engine.InputNone {
		p := uint32(max(e.Position, 0)) //nolint:gosec // clamped to >= 0
		out.Position = &p
	}
	return out
}

func adminErrorKind(k engine.Kind) queravuev1.AdminErrorKind {
	switch k {
	case engine.KindConfirmationRequired:
		return queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_CONFIRMATION_REQUIRED
	case engine.KindUnsupported:
		return queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_UNSUPPORTED
	case engine.KindParse, engine.KindInvalidConfig:
		return queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_INVALID
	case engine.KindNotFound:
		return queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_NOT_FOUND
	case engine.KindCanceled:
		return queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_CANCELED
	default:
		return queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_SERVER
	}
}

func adminInvalid(msg string) *queravuev1.AdminError {
	return &queravuev1.AdminError{Kind: queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_INVALID, Message: msg}
}

func adminConfirmation(operation, msg string) *queravuev1.AdminError {
	return &queravuev1.AdminError{Kind: queravuev1.AdminErrorKind_ADMIN_ERROR_KIND_CONFIRMATION_REQUIRED, Message: msg, Operation: operation}
}

func isProduction(ctx context.Context, connections *connections.Service, sess *session.Session) bool {
	if connections == nil || sess.ConnectionID == "" {
		return false
	}
	c, err := connections.Get(ctx, sess.ConnectionID)
	return err == nil && c.Production
}
