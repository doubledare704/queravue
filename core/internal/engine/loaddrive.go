package engine

import (
	"context"
	"errors"
	"fmt"
	"io"
	"log/slog"
	"runtime/debug"
)

// BatchCommitter commits one batch and returns what it committed. On error it
// still returns the stats of the part that did commit (zero for engines whose
// batch is atomic).
type BatchCommitter[B any] func(ctx context.Context, batch B) (LoadStats, error)

// DriveLoad is the loop every loader shares: pull a batch, check ctx, commit,
// repeat until the source returns io.EOF. It returns the committed stats
// together with any error, and turns a panic into an *Error.
func DriveLoad[B any](
	ctx context.Context, engineID, op string,
	next func(context.Context) (B, error),
	batchLen func(B) int,
	commit BatchCommitter[B],
) (stats LoadStats, err error) {
	defer func() {
		if r := recover(); r != nil {
			slog.Error(engineID+": load panic", "op", op, "panic", fmt.Sprint(r), "stack", string(debug.Stack()))
			err = &Error{Kind: KindUnknown, Engine: engineID, Op: op, Msg: "internal error while loading"}
		}
	}()
	for {
		if ctx.Err() != nil {
			return stats, LoadCanceled(ctx, engineID, op)
		}
		batch, srcErr := next(ctx)
		if errors.Is(srcErr, io.EOF) {
			return stats, nil
		}
		if srcErr != nil {
			if ctx.Err() != nil && (errors.Is(srcErr, context.Canceled) || errors.Is(srcErr, context.DeadlineExceeded)) {
				return stats, LoadCanceled(ctx, engineID, op)
			}
			return stats, fmt.Errorf("%s: %s: read source: %w", engineID, op, srcErr)
		}
		if batchLen(batch) == 0 {
			continue
		}
		if ctx.Err() != nil {
			return stats, LoadCanceled(ctx, engineID, op)
		}
		done, commitErr := commit(ctx, batch)
		stats.Rows += done.Rows
		stats.Batches += done.Batches
		if commitErr != nil {
			return stats, commitErr
		}
	}
}

// LoadCanceled is the error a loader returns when ctx ends between batches.
func LoadCanceled(ctx context.Context, engineID, op string) *Error {
	cause := ctx.Err()
	if errors.Is(cause, context.DeadlineExceeded) {
		return &Error{Kind: KindTimeout, Engine: engineID, Op: op, Msg: "load timed out", Err: cause}
	}
	return &Error{Kind: KindCanceled, Engine: engineID, Op: op, Msg: "load cancelled", Err: cause}
}
