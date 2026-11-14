package duckdb

import (
	"context"
	"errors"
	"strings"

	"github.com/doubledare704/queravue/core/internal/engine"
)

// ErrFileLocked means another process holds the database file. DuckDB allows
// one writing process; see docs/engines/duckdb.md.
var ErrFileLocked = errors.New("duckdb: database file is locked by another process")

// classify maps DuckDB errors, which carry their category as a message
// prefix ("Catalog Error: ..."), to engine error kinds.
func classify(op string, err error) *engine.Error {
	msg := err.Error()
	low := strings.ToLower(msg)
	e := &engine.Error{Engine: ID, Op: op, Err: err, Msg: msg}
	switch {
	case errors.Is(err, context.Canceled), strings.Contains(msg, "INTERRUPT Error"):
		e.Kind, e.Msg = engine.KindCanceled, "statement cancelled"
	case errors.Is(err, context.DeadlineExceeded):
		e.Kind = engine.KindTimeout
	case strings.Contains(low, "could not set lock on file"), strings.Contains(low, "conflicting lock is held"),
		strings.Contains(low, "being used by another process"):
		e.Kind = engine.KindTimeout
		e.Err = errors.Join(ErrFileLocked, err)
		e.Msg = lockedMessage(msg)
	case strings.Contains(low, "different configuration than existing connections"):
		e.Kind = engine.KindInvalidConfig
		e.Msg = "this file is already open in Queravue with other settings (read-only vs read-write); close that connection first"
	case strings.Contains(low, "not a valid duckdb database file"), strings.Contains(low, "unsupported duckdb storage version"):
		e.Kind = engine.KindInvalidConfig
	case strings.Contains(low, "no such file or directory"), strings.Contains(low, "database does not exist"):
		e.Kind = engine.KindNotFound
	case strings.Contains(low, "permission denied"), strings.Contains(low, "read-only mode"):
		e.Kind = engine.KindAuth
	case strings.Contains(low, "out of memory error"):
		e.Kind = engine.KindServer
	case isStatementError(msg):
		e.Kind = engine.KindSQL
	default:
		e.Kind = engine.ClassifyCommon(err)
	}
	return e
}

var statementErrorPrefixes = []string{
	"Parser Error", "Binder Error", "Catalog Error", "Conversion Error", "Constraint Error", "Invalid Input Error",
	"Dependency Error", "Not implemented Error", "Out of Range Error", "Invalid Error", "Transaction Error",
	"Serialization Error", "Sequence Error", "Syntax Error", "Mismatch Type Error", "Expression Error",
}

func isStatementError(msg string) bool {
	for _, p := range statementErrorPrefixes {
		if strings.Contains(msg, p+":") {
			return true
		}
	}
	return false
}

func lockedMessage(raw string) string {
	detail := strings.TrimPrefix(raw, "IO Error: ")
	if i := strings.Index(raw, "Could not set lock"); i >= 0 {
		detail = raw[i:]
	}
	if i := strings.Index(detail, " See also"); i >= 0 {
		detail = detail[:i]
	}
	return "the database file is locked by another process; DuckDB allows one writer at a time. Close the other application, or open the file read-only if nothing is writing to it (" + strings.TrimSpace(detail) + ")"
}
