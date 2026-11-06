package mssql

import (
	"database/sql/driver"
	"errors"
	"strings"

	mssqldb "github.com/microsoft/go-mssqldb"

	"github.com/doubledare704/queravue/core/internal/engine"
)

// Server error numbers we map.
const (
	errLoginFailed    = 18456
	errCannotOpenDB   = 4060
	errLoginDisabled  = 18470
	errPasswordExpire = 18487
	errPermission     = 229
	errTimeout        = -2 // client timeout
)

var errorKinds = map[int32]engine.Kind{
	errLoginFailed:    engine.KindAuth,
	errLoginDisabled:  engine.KindAuth,
	errPasswordExpire: engine.KindAuth,
	errPermission:     engine.KindAuth,
	errCannotOpenDB:   engine.KindNotFound,
	errTimeout:        engine.KindTimeout,
}

// classify turns a driver error into a typed *engine.Error with a message
// free of secrets.
func classify(id, op string, err error, secret engine.Secret) *engine.Error {
	kind := engine.KindUnknown
	msg := err.Error()
	var se mssqldb.Error
	var sp *mssqldb.Error
	switch {
	case errors.As(err, &se):
		if k, ok := errorKinds[se.Number]; ok {
			kind = k
		}
		msg = se.Message
	case errors.As(err, &sp) && sp != nil:
		if k, ok := errorKinds[sp.Number]; ok {
			kind = k
		}
		msg = sp.Message
	default:
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
