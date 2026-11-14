package oracle

import (
	"errors"
	"strings"

	"github.com/sijms/go-ora/v2/network"

	"github.com/doubledare704/queravue/core/internal/engine"
)

const (
	oraCanceled        = 1013
	oraInvalidLogin    = 1017
	oraAccountLocked   = 28000
	oraPasswordExpired = 28001
	oraNoSuchObject    = 942
	oraNoListener      = 12541
	oraUnknownService  = 12514
	oraUnknownSID      = 12505
	oraConnectTimeout  = 12170
	oraTNSNoHost       = 12545
	oraNotLoggedOn     = 1012
	oraSessionKilled   = 28
	oraEndOfChannel    = 3113
	oraNotConnected    = 3114
)

var errorKinds = map[int]engine.Kind{
	oraCanceled:        engine.KindCanceled,
	oraInvalidLogin:    engine.KindAuth,
	oraAccountLocked:   engine.KindAuth,
	oraPasswordExpired: engine.KindAuth,
	oraNoSuchObject:    engine.KindNotFound,
	oraNoListener:      engine.KindNetwork,
	oraUnknownService:  engine.KindNotFound,
	oraUnknownSID:      engine.KindNotFound,
	oraConnectTimeout:  engine.KindTimeout,
	oraTNSNoHost:       engine.KindNetwork,
	oraNotLoggedOn:     engine.KindConnectionLost,
	oraSessionKilled:   engine.KindConnectionLost,
	oraEndOfChannel:    engine.KindConnectionLost,
	oraNotConnected:    engine.KindConnectionLost,
}

// classify turns a driver error into a typed *engine.Error with a message
// free of secrets.
func classify(op string, err error, secret engine.Secret) *engine.Error {
	var oe *network.OracleError
	if errors.As(err, &oe) && oe != nil {
		e := &engine.Error{Kind: engine.KindSQL, Engine: ID, Op: op, Msg: engine.Redact(oe.Error(), secret), Err: err, Code: oe.ErrCode}
		if k, ok := errorKinds[oe.ErrCode]; ok {
			e.Kind = k
		}
		if e.Kind == engine.KindSQL && oe.ErrPos() > 0 {
			e.Position = oe.ErrPos()
		}
		return e
	}
	kind := engine.ClassifyCommon(err)
	msg := err.Error()
	if kind == engine.KindUnknown {
		low := strings.ToLower(msg)
		switch {
		case strings.Contains(low, "certificate") || strings.Contains(low, "tls") || strings.Contains(low, "x509"):
			kind = engine.KindTLS
		case strings.Contains(low, "connection refused") || strings.Contains(low, "no such host") || strings.Contains(low, "i/o timeout"):
			kind = engine.KindNetwork
		}
	}
	return &engine.Error{Kind: kind, Engine: ID, Op: op, Msg: engine.Redact(msg, secret), Err: err}
}
