package clickhouse

import (
	"database/sql/driver"
	"errors"
	"strings"

	chdriver "github.com/ClickHouse/clickhouse-go/v2"

	"github.com/doubledare704/queravue/core/internal/engine"
)

const (
	codeUnknownUser          = 192
	codeWrongPassword        = 193
	codeRequiredPassword     = 194
	codeAccessDenied         = 497
	codeAuthenticationFailed = 516
	codeUnknownTable         = 60
	codeUnknownDatabase      = 81
	codeTimeoutExceeded      = 159
	codeSocketTimeout        = 209
	codeAborted              = 236
	codeQueryWasCancelled    = 394
)

var exceptionKinds = map[int32]engine.Kind{
	codeUnknownUser:          engine.KindAuth,
	codeWrongPassword:        engine.KindAuth,
	codeRequiredPassword:     engine.KindAuth,
	codeAccessDenied:         engine.KindAuth,
	codeAuthenticationFailed: engine.KindAuth,
	codeUnknownTable:         engine.KindNotFound,
	codeUnknownDatabase:      engine.KindNotFound,
	codeTimeoutExceeded:      engine.KindTimeout,
	codeSocketTimeout:        engine.KindTimeout,
	codeAborted:              engine.KindCanceled,
	codeQueryWasCancelled:    engine.KindCanceled,
}

func classify(id, op string, err error, secret engine.Secret) *engine.Error {
	var kind engine.Kind
	msg := err.Error()
	var ex *chdriver.Exception
	if errors.As(err, &ex) {
		kind = engine.KindSQL
		if k, ok := exceptionKinds[ex.Code]; ok {
			kind = k
		}
		msg = ex.Message
	} else {
		kind = engine.ClassifyCommon(err)
	}
	if kind == engine.KindUnknown {
		low := strings.ToLower(msg)
		switch {
		case strings.Contains(low, "certificate") || strings.Contains(low, "tls") || strings.Contains(low, "x509"):
			kind = engine.KindTLS
		case errors.Is(err, driver.ErrBadConn):
			kind, msg = engine.KindConnectionLost, "connection lost"
		}
	}
	return &engine.Error{Kind: kind, Engine: id, Op: op, Msg: engine.Redact(msg, secret), Err: err}
}
