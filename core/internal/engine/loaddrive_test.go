package engine_test

import (
	"context"
	"errors"
	"io"
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
)

type scriptedSource struct {
	batches [][]int
	failAt  int
	failErr error
	onNext  func(i int)
	i       int
}

func (s *scriptedSource) next(context.Context) ([]int, error) {
	i := s.i
	s.i++
	if s.onNext != nil {
		s.onNext(i)
	}
	if s.failErr != nil && i == s.failAt {
		return nil, s.failErr
	}
	if i >= len(s.batches) {
		return nil, io.EOF
	}
	return s.batches[i], nil
}

func driveScripted(ctx context.Context, src *scriptedSource, commit engine.BatchCommitter[[]int]) (engine.LoadStats, error) {
	return engine.DriveLoad(ctx, "fake", "load", src.next, func(b []int) int { return len(b) }, commit)
}

func commitAll(_ context.Context, b []int) (engine.LoadStats, error) {
	return engine.LoadStats{Rows: uint64(len(b)), Batches: 1}, nil
}

func TestDriveLoadCommitsEveryBatchUntilEOF(t *testing.T) {
	src := &scriptedSource{batches: [][]int{{1, 2}, {}, {3}}}
	stats, err := driveScripted(context.Background(), src, commitAll)
	if err != nil || stats.Rows != 3 || stats.Batches != 2 {
		t.Fatalf("stats = %+v, err = %v", stats, err)
	}
}

func TestDriveLoadEmptySource(t *testing.T) {
	stats, err := driveScripted(context.Background(), &scriptedSource{}, commitAll)
	if err != nil || stats != (engine.LoadStats{}) {
		t.Fatalf("stats = %+v, err = %v", stats, err)
	}
}

func TestDriveLoadSourceErrorKeepsCommittedStats(t *testing.T) {
	boom := errors.New("bad line 7")
	src := &scriptedSource{batches: [][]int{{1, 2}, {3, 4}, {5}}, failAt: 2, failErr: boom}
	stats, err := driveScripted(context.Background(), src, commitAll)
	if !errors.Is(err, boom) || stats.Rows != 4 || stats.Batches != 2 {
		t.Fatalf("stats = %+v, err = %v", stats, err)
	}
}

func TestDriveLoadCommitErrorKeepsPartialStats(t *testing.T) {
	violation := &engine.Error{Kind: engine.KindConstraint}
	calls := 0
	commit := func(_ context.Context, b []int) (engine.LoadStats, error) {
		calls++
		if calls == 2 {
			return engine.LoadStats{Rows: 1, Batches: 0}, violation
		}
		return engine.LoadStats{Rows: uint64(len(b)), Batches: 1}, nil
	}
	src := &scriptedSource{batches: [][]int{{1, 2}, {3, 4}, {5}}}
	stats, err := driveScripted(context.Background(), src, commit)
	if engine.KindOf(err) != engine.KindConstraint || stats.Rows != 3 || stats.Batches != 1 || calls != 2 {
		t.Fatalf("stats = %+v, calls = %d, err = %v", stats, calls, err)
	}
}

func TestDriveLoadCancelStopsBeforeCommittingPulledBatch(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	src := &scriptedSource{batches: [][]int{{1}, {2}, {3}, {4}}, onNext: func(i int) {
		if i == 2 {
			cancel()
		}
	}}
	stats, err := driveScripted(ctx, src, commitAll)
	if engine.KindOf(err) != engine.KindCanceled || !errors.Is(err, context.Canceled) || stats.Rows != 2 {
		t.Fatalf("stats = %+v, err = %v", stats, err)
	}
}

func TestDriveLoadSourceReturningContextErrorIsCancel(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	src := &scriptedSource{batches: [][]int{{1}}, failAt: 1, failErr: context.Canceled, onNext: func(i int) {
		if i == 1 {
			cancel()
		}
	}}
	stats, err := driveScripted(ctx, src, commitAll)
	if engine.KindOf(err) != engine.KindCanceled || stats.Rows != 1 {
		t.Fatalf("stats = %+v, err = %v", stats, err)
	}
}

func TestDriveLoadRecoversPanic(t *testing.T) {
	commit := func(context.Context, []int) (engine.LoadStats, error) { panic("boom") }
	_, err := driveScripted(context.Background(), &scriptedSource{batches: [][]int{{1}}}, commit)
	if engine.KindOf(err) != engine.KindUnknown || err == nil {
		t.Fatalf("err = %v", err)
	}
}
