package postgres

import (
	"errors"
	"strings"
	"time"

	"github.com/jackc/pgx/v5/pgconn"

	"github.com/doubledare704/queravue/core/internal/engine"
)

const closeTimeout = 2 * time.Second

// SQLSTATE classes we map. See
// https://www.postgresql.org/docs/current/errcodes-appendix.html.
var sqlStateKinds = map[string]engine.Kind{
	"28000": engine.KindAuth,     // invalid_authorization_specification
	"28P01": engine.KindAuth,     // invalid_password
	"42501": engine.KindAuth,     // insufficient_privilege
	"3D000": engine.KindNotFound, // invalid_catalog_name (database does not exist)
	"57014": engine.KindTimeout,  // query_canceled (statement timeout)
	"53300": engine.KindNetwork,  // too_many_connections
	"57P03": engine.KindNetwork,  // cannot_connect_now (server starting up)
}

// classify turns a pgx error into a typed *engine.Error with a message free of
// secrets.
func classify(id, op string, err error, secret engine.Secret) error {
	kind := engine.KindUnknown
	msg := err.Error()

	var pgErr *pgconn.PgError
	if errors.As(err, &pgErr) {
		if k, ok := sqlStateKinds[pgErr.Code]; ok {
			kind = k
		}
		msg = pgErr.Message
	} else {
		kind = engine.ClassifyCommon(err)
		msg = trimConnectPrefix(msg)
	}
	if kind == engine.KindUnknown && (strings.Contains(msg, "server refused TLS connection") ||
		strings.Contains(msg, "SSL is not enabled on the server")) {
		kind = engine.KindTLS
	}
	return &engine.Error{Kind: kind, Engine: id, Op: op, Msg: engine.Redact(msg, secret), Err: err}
}

// trimConnectPrefix drops pgconn's "failed to connect to `user=... database=...`:"
// prefix; the UI already knows which connection it tested.
func trimConnectPrefix(msg string) string {
	if !strings.HasPrefix(msg, "failed to connect to `") {
		return msg
	}
	if i := strings.Index(msg, "`:"); i >= 0 {
		return strings.TrimSpace(msg[i+2:])
	}
	return msg
}
