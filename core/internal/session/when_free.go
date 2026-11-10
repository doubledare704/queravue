package session

import (
	"context"
	"errors"
	"fmt"
	"strings"
	"time"
)

const busyRetryDelay = 25 * time.Millisecond

// RunWhenFree runs f while holding the statement slot, waiting for a running
// statement to finish. Waiting stops when ctx ends.
func (s *Session) RunWhenFree(ctx context.Context, f func(context.Context) error) error {
	for {
		err := s.runInSlot(ctx, f)
		if err == nil || !isBusy(err) {
			return err
		}
		select {
		case <-time.After(busyRetryDelay):
		case <-ctx.Done():
			return fmt.Errorf("session: wait until free: %w", ctx.Err())
		}
	}
}

func (s *Session) runInSlot(ctx context.Context, f func(context.Context) error) error {
	runCtx, finish, err := s.Begin(ctx)
	if err != nil {
		return err
	}
	defer finish()
	return f(runCtx)
}

// A driver connection that serves another request answers "conn busy"; the
// schema browser reaches the connection without the statement slot.
func isBusy(err error) bool {
	return errors.Is(err, ErrBusy) || strings.Contains(err.Error(), "conn busy")
}
