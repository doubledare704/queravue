package transfer

import (
	"context"
	"errors"
	"io"
	"strconv"
	"strings"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

const scriptReadBytes = 256 << 10

const utf8BOM = "\xef\xbb\xbf"

// ScriptResult is how a SQL script import ended.
type ScriptResult struct {
	Committed  uint64
	Statements uint64
	Line       uint64
	Err        *Error
}

// ScriptRunner executes a SQL script statement by statement as it arrives.
type ScriptRunner struct {
	Executor          engine.Executor
	Dialect           sqlsplit.Dialect
	MaxStatementBytes int
	BytesRead         func() uint64
	Progress          func(committed, bytesRead uint64) error
	AfterStatement    func(sql string)
}

type discardRows struct{}

func (discardRows) Columns([]engine.Column) error { return nil }
func (discardRows) Batch([][]engine.Value) error  { return nil }

// Run stops at the first failing statement and reports its line.
func (s *ScriptRunner) Run(ctx context.Context, src io.Reader) ScriptResult {
	limit := s.MaxStatementBytes
	if limit <= 0 {
		limit = 64 << 20
	}
	var res ScriptResult
	var pending, delim string
	line := uint64(1)
	buf := make([]byte, scriptReadBytes)
	lastReport := time.Now()
	for eof := false; !eof; {
		n, err := src.Read(buf)
		eof = errors.Is(err, io.EOF)
		if err != nil && !eof {
			res.Err = Classify(err)
			return res
		}
		pending += string(buf[:n])
		if res.Statements == 0 && line == 1 {
			pending = strings.TrimPrefix(pending, utf8BOM)
		}
		done, consumed, next := sqlsplit.SplitPrefix(s.Dialect, pending, delim, eof)
		for _, r := range done {
			stmtLine := line + uint64(strings.Count(pending[:r.Start], "\n")) //nolint:gosec // count is non-negative
			sum, execErr := s.Executor.Execute(ctx, engine.Statement{SQL: r.Text(pending)}, discardRows{})
			if execErr != nil {
				res.Line = stmtLine
				res.Err = Classify(execErr)
				res.Err.Message = "statement at line " + strconv.FormatUint(stmtLine, 10) + ": " + res.Err.Message
				return res
			}
			res.Statements++
			if s.AfterStatement != nil {
				s.AfterStatement(r.Text(pending))
			}
			res.Committed += uint64(max(sum.RowsAffected, 0))
			if time.Since(lastReport) >= progressInterval {
				lastReport = time.Now()
				if err := s.Progress(res.Committed, s.BytesRead()); err != nil {
					res.Err = Classify(err)
					return res
				}
			}
		}
		line += uint64(strings.Count(pending[:consumed], "\n")) //nolint:gosec // count is non-negative
		pending, delim = pending[consumed:], next
		if len(pending) > limit {
			trimmed := strings.TrimLeft(pending, " \t\r\n")
			res.Line = line + uint64(strings.Count(pending[:len(pending)-len(trimmed)], "\n")) //nolint:gosec // count is non-negative
			res.Err = newError(KindParse, "statement at line %d is larger than %d bytes", res.Line, limit)
			return res
		}
		if err := ctx.Err(); err != nil {
			res.Err = Classify(err)
			return res
		}
	}
	return res
}
