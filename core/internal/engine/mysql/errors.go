package mysql

import (
	"database/sql/driver"
	"errors"
	"strings"

	drv "github.com/go-sql-driver/mysql"

	"github.com/doubledare704/queravue/core/internal/engine"
)

// Server error numbers we map. See
// https://dev.mysql.com/doc/mysql-errors/8.4/en/server-error-reference.html.
const (
	errDBAccessDenied  = 1044
	errAccessDenied    = 1045
	errUnknownDB       = 1049
	errTooManyConns    = 1040
	errHostNotAllowed  = 1130
	errQueryInterrupt  = 1317
	errMaxExecTime     = 3024 // MySQL max_execution_time
	errMaxStatementMS  = 1969 // MariaDB max_statement_time
	errConnKilled      = 1927
	errServerGoneAway  = 2006
	errServerLost      = 2013
	errLockWaitTimeout = 1205
)

var errorKinds = map[uint16]engine.Kind{
	errDBAccessDenied: engine.KindAuth,
	errAccessDenied:   engine.KindAuth,
	errHostNotAllowed: engine.KindAuth,
	errUnknownDB:      engine.KindNotFound,
	errTooManyConns:   engine.KindNetwork,
	errMaxExecTime:    engine.KindTimeout,
	errMaxStatementMS: engine.KindTimeout,
}

// classify turns a driver error into a typed *engine.Error with a message
// free of secrets.
func classify(id, op string, err error, secret engine.Secret) *engine.Error {
	kind := engine.KindUnknown
	msg := err.Error()
	var me *drv.MySQLError
	if errors.As(err, &me) {
		if k, ok := errorKinds[me.Number]; ok {
			kind = k
		}
		msg = me.Message
	} else {
		kind = engine.ClassifyCommon(err)
	}
	if kind == engine.KindUnknown {
		switch {
		case strings.Contains(msg, "TLS") || strings.Contains(msg, "tls:") || strings.Contains(msg, "x509"):
			kind = engine.KindTLS
		case errors.Is(err, drv.ErrInvalidConn) || errors.Is(err, driver.ErrBadConn):
			kind, msg = engine.KindConnectionLost, "connection lost"
		}
	}
	return &engine.Error{Kind: kind, Engine: id, Op: op, Msg: engine.Redact(msg, secret), Err: err}
}
