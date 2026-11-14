package redis

import (
	"context"
	"errors"
	"strings"

	goredis "github.com/redis/go-redis/v9"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func classify(id, op string, err error, secret engine.Secret) *engine.Error {
	e := &engine.Error{Kind: engine.KindUnknown, Engine: id, Op: op, Msg: engine.Redact(err.Error(), secret), Err: err}
	if kind := engine.ClassifyCommon(err); kind != engine.KindUnknown && !isServerReply(err) {
		e.Kind = kind
		return e
	}
	switch {
	case errors.Is(err, context.Canceled):
		e.Kind = engine.KindCanceled
	case isServerReply(err):
		e.Kind = classifyReply(err.Error())
	case errors.Is(err, goredis.ErrClosed):
		e.Kind = engine.KindConnectionLost
	}
	return e
}

func isServerReply(err error) bool {
	var re goredis.Error
	return errors.As(err, &re)
}

func classifyReply(msg string) engine.Kind {
	upper := strings.ToUpper(msg)
	switch {
	case strings.HasPrefix(upper, "WRONGPASS"), strings.HasPrefix(upper, "NOAUTH"),
		strings.Contains(upper, "INVALID PASSWORD"):
		return engine.KindAuth
	case strings.Contains(upper, "UNKNOWN COMMAND"), strings.Contains(upper, "UNKNOWN SUBCOMMAND"):
		return engine.KindUnsupported
	case strings.Contains(upper, "NO SUCH KEY"):
		return engine.KindNotFound
	}
	return engine.KindServer
}
