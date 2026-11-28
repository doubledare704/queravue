package transfer

import (
	"cmp"
	"context"
	"errors"
	"fmt"
	"slices"
	"time"

	"github.com/doubledare704/queravue/core/internal/dataformat"
)

// ErrorPolicy says what a bad row does.
type ErrorPolicy int

// Error policies.
const (
	PolicyStop ErrorPolicy = iota
	PolicySkip
)

// DefaultMaxRowErrors is how many bad rows SKIP tolerates when none is set.
const DefaultMaxRowErrors = 1000

// RowError is one rejected row. Line is 1-based.
type RowError struct {
	Line    uint64
	Column  string
	Message string
}

type problem struct {
	kind    ErrorKind
	column  string
	message string
}

type itemReader[In any] interface {
	Next(ctx context.Context) ([]In, error)
	Lines() []int64
}

var errSourceStopped = errors.New("transfer: import stopped at a bad row")

// pipeline is the batch source a loader pulls from. It converts each record,
// applies the error policy and remembers the batch in flight, so a failed
// batch can be retried row by row.
type pipeline[In, Out any] struct {
	reader    itemReader[In]
	convert   func(In) (Out, *problem)
	policy    ErrorPolicy
	maxErrors int
	report    func(delivered uint64) error

	delivered       uint64
	deliveredBefore uint64
	inflight        []Out
	inflightLines   []int64
	skipped         uint64
	rowErrors       []RowError
	failure         *Error
	stopAfterBatch  bool
	lastReport      time.Time
}

func (p *pipeline[In, Out]) Next(ctx context.Context) ([]Out, error) {
	if p.stopAfterBatch {
		return nil, errSourceStopped
	}
	if time.Since(p.lastReport) >= progressInterval {
		p.lastReport = time.Now()
		if err := p.report(p.delivered); err != nil {
			return nil, err
		}
	}
	for {
		items, err := p.reader.Next(ctx)
		if len(items) == 0 {
			if err == nil {
				continue
			}
			var parse *dataformat.ParseError
			if errors.As(err, &parse) {
				if p.reject(parse.Line, problem{KindParse, "", fmt.Sprintf("column %d: %v", parse.Column, parse.Err)}) {
					return nil, errSourceStopped
				}
				continue
			}
			return nil, err
		}
		lines := p.reader.Lines()
		out := make([]Out, 0, len(items))
		outLines := make([]int64, 0, len(items))
		for i, item := range items {
			converted, bad := p.convert(item)
			if bad != nil {
				if p.reject(lines[i], *bad) {
					p.stopAfterBatch = true
					break
				}
				continue
			}
			out = append(out, converted)
			outLines = append(outLines, lines[i])
		}
		if len(out) == 0 {
			if p.stopAfterBatch {
				return nil, errSourceStopped
			}
			continue
		}
		p.inflight, p.inflightLines = out, outLines
		p.deliveredBefore = p.delivered
		p.delivered += uint64(len(out))
		return out, nil
	}
}

func (p *pipeline[In, Out]) reject(line int64, bad problem) (stop bool) {
	row := RowError{Line: uint64(max(line, 0)), Column: bad.column, Message: bad.message}
	if p.policy != PolicySkip {
		p.rowErrors = append(p.rowErrors, row)
		p.failure = newError(bad.kind, "line %d: %s", line, bad.message)
		return true
	}
	if p.skipped >= uint64(p.maxErrors) { //nolint:gosec // maxErrors is positive
		p.failure = newError(bad.kind, "stopped: more than %d rows were rejected", p.maxErrors)
		return true
	}
	p.skipped++
	p.rowErrors = append(p.rowErrors, row)
	return false
}

func (p *pipeline[In, Out]) result(committed uint64, loadErr error) Result {
	res := Result{Committed: committed, Skipped: p.skipped, RowErrors: p.rowErrors}
	defer func() {
		slices.SortStableFunc(res.RowErrors, func(a, b RowError) int { return cmp.Compare(a.Line, b.Line) })
	}()
	switch {
	case p.failure != nil:
		res.Err = p.failure
	case loadErr != nil:
		res.Err = Classify(loadErr)
		if res.Err.Kind == KindConstraint && len(p.inflightLines) > 0 {
			first, last := p.inflightLines[0], p.inflightLines[len(p.inflightLines)-1]
			res.RowErrors = append(res.RowErrors, RowError{Line: uint64(max(first, 0)), Message: res.Err.Message})
			res.Err = newError(KindConstraint, "a row between lines %d and %d was rejected: %s", first, last, res.Err.Message)
		}
	}
	return res
}

func (p *pipeline[In, Out]) inflightCopy() ([]Out, []int64) {
	return slices.Clone(p.inflight), slices.Clone(p.inflightLines)
}

// Result is how an import ended.
type Result struct {
	Committed uint64
	Skipped   uint64
	RowErrors []RowError
	Err       *Error
}
