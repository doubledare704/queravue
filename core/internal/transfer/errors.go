// Package transfer moves rows and documents between files and engines for the
// import and export RPCs (ADR 0024). It holds no gRPC types.
package transfer

import (
	"context"
	"errors"
	"fmt"

	"github.com/doubledare704/queravue/core/internal/dataformat"
	"github.com/doubledare704/queravue/core/internal/engine"
)

// ErrorKind classifies a transfer failure the user can act on.
type ErrorKind int

// Error kinds, mirroring queravue.v1.TransferErrorKind.
const (
	KindServer ErrorKind = iota
	KindParse
	KindMapping
	KindConstraint
	KindConfirmationRequired
	KindAuth
	KindNetwork
	KindTimeout
	KindCanceled
	KindUnsupported
)

// Error is a typed failure. Message never holds secrets or row data.
type Error struct {
	Kind    ErrorKind
	Message string
}

func (e *Error) Error() string { return e.Message }

func newError(kind ErrorKind, format string, args ...any) *Error {
	return &Error{Kind: kind, Message: fmt.Sprintf(format, args...)}
}

// Classify turns any error from a reader, loader or engine into a typed error.
func Classify(err error) *Error {
	var typed *Error
	var parse *dataformat.ParseError
	var engineErr *engine.Error
	switch {
	case err == nil:
		return nil
	case errors.As(err, &typed):
		return typed
	case errors.Is(err, context.Canceled):
		return newError(KindCanceled, "the operation was cancelled")
	case errors.Is(err, context.DeadlineExceeded):
		return newError(KindTimeout, "the operation timed out")
	case errors.As(err, &parse):
		return newError(KindParse, "line %d, column %d: %v", parse.Line, parse.Column, parse.Err)
	case errors.As(err, &engineErr):
		return &Error{Kind: kindOfEngine(engineErr.Kind), Message: engineErr.Msg}
	}
	return newError(KindServer, "operation failed")
}

func kindOfEngine(k engine.Kind) ErrorKind {
	switch k {
	case engine.KindAuth, engine.KindSSHAuth:
		return KindAuth
	case engine.KindNetwork, engine.KindConnectionLost, engine.KindTunnelLost, engine.KindTLS,
		engine.KindSSHHostKeyUnknown, engine.KindSSHHostKeyChanged:
		return KindNetwork
	case engine.KindTimeout:
		return KindTimeout
	case engine.KindCanceled:
		return KindCanceled
	case engine.KindConstraint:
		return KindConstraint
	case engine.KindConfirmationRequired:
		return KindConfirmationRequired
	case engine.KindUnsupported:
		return KindUnsupported
	case engine.KindParse:
		return KindParse
	case engine.KindNotFound:
		return KindMapping
	}
	return KindServer
}
