package results

import (
	"errors"
	"fmt"
	"log/slog"
	"math/rand/v2"
	"os"
	"path/filepath"
	"strconv"
	"testing"

	"google.golang.org/protobuf/proto"

	"github.com/doubledare704/queravue/core/internal/engine"
	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

func intRow(i int) *queravuev1.Row {
	return &queravuev1.Row{Values: []*queravuev1.Value{
		ValueToProto(engine.Int(int64(i))), ValueToProto(engine.Text("row-" + strconv.Itoa(i))),
	}}
}

func rowsRange(from, to int) []*queravuev1.Row {
	var out []*queravuev1.Row
	for i := from; i < to; i++ {
		out = append(out, intRow(i))
	}
	return out
}

func newMgr(t *testing.T, capBytes int64) *Manager {
	t.Helper()
	m, err := NewManager(t.TempDir(), capBytes, slog.New(slog.DiscardHandler))
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(m.Shutdown)
	return m
}

func checkRow(t *testing.T, r *queravuev1.Row, i int) {
	t.Helper()
	if got := r.GetValues()[0].GetIntValue(); got != int64(i) {
		t.Fatalf("row %d has id %d", i, got)
	}
}

func TestSpoolRandomAccess(t *testing.T) {
	m := newMgr(t, 0)
	_, s, err := m.Create("s1")
	if err != nil {
		t.Fatal(err)
	}
	const total = 100_000 + 123
	for i := 0; i < total; i += 500 {
		if err := s.Append(rowsRange(i, min(i+500, total))); err != nil {
			t.Fatal(err)
		}
	}
	if err := s.Finish(); err != nil {
		t.Fatal(err)
	}
	if n, done, trunc := s.State(); n != total || !done || trunc {
		t.Fatalf("state = %d %v %v", n, done, trunc)
	}
	rng := rand.New(rand.NewPCG(1, 2))
	for range 300 {
		off := rng.IntN(total)
		lim := 1 + rng.IntN(1500)
		rows, err := s.ReadRows(uint64(off), lim)
		if err != nil {
			t.Fatal(err)
		}
		want := min(lim, total-off)
		if len(rows) != want {
			t.Fatalf("ReadRows(%d,%d) = %d rows, want %d", off, lim, len(rows), want)
		}
		for j, r := range rows {
			checkRow(t, r, off+j)
		}
	}
	if rows, _ := s.ReadRows(total, 10); len(rows) != 0 {
		t.Error("read past the end returned rows")
	}
}

func TestSpoolReadsPendingWhileWriting(t *testing.T) {
	m := newMgr(t, 0)
	_, s, _ := m.Create("s1")
	_ = s.Append(rowsRange(0, 700)) // one page flushed + 200 pending
	rows, err := s.ReadRows(450, 100)
	if err != nil || len(rows) != 100 {
		t.Fatalf("rows=%d err=%v", len(rows), err)
	}
	checkRow(t, rows[0], 450)
	checkRow(t, rows[99], 549)
	if s.Total() != 700 {
		t.Errorf("Total = %d", s.Total())
	}
}

func TestSpoolCap(t *testing.T) {
	m := newMgr(t, 20_000) // a few pages
	_, s, _ := m.Create("s1")
	var err error
	appended := 0
	for i := 0; i < 100 && err == nil; i++ {
		err = s.Append(rowsRange(i*500, (i+1)*500))
		appended++
	}
	if !errors.Is(err, ErrFull) {
		t.Fatalf("err = %v, want ErrFull after %d appends", err, appended)
	}
	if err := s.Append(rowsRange(0, 1)); !errors.Is(err, ErrFull) {
		t.Errorf("append after full: %v", err)
	}
	n, done, trunc := s.State()
	if !done || !trunc || n == 0 {
		t.Errorf("state = %d %v %v", n, done, trunc)
	}
	if s.Size() < 20_000 || s.Size() > 20_000+10_000 {
		t.Errorf("size = %d, want just over the cap", s.Size())
	}
	// Rows written before the cap stay readable.
	rows, err := s.ReadRows(0, 10)
	if err != nil || len(rows) != 10 {
		t.Errorf("read after cap: %d %v", len(rows), err)
	}
}

func TestSpoolCleanup(t *testing.T) {
	base := t.TempDir()
	m, err := NewManager(base, 0, slog.New(slog.DiscardHandler))
	if err != nil {
		t.Fatal(err)
	}
	id1, s1, _ := m.Create("a")
	_, s2, _ := m.Create("a")
	id3, s3, _ := m.Create("b")
	for _, s := range []*Spool{s1, s2, s3} {
		_ = s.Append(rowsRange(0, 600))
	}
	files := func() int {
		g, _ := filepath.Glob(filepath.Join(base, strconv.Itoa(os.Getpid()), "*.spool"))
		return len(g)
	}
	if files() != 3 {
		t.Fatalf("files = %d", files())
	}
	m.Close(id1)
	if files() != 2 {
		t.Errorf("after Close: files = %d", files())
	}
	if _, err := m.Get(id1); !errors.Is(err, ErrNotFound) {
		t.Errorf("Get closed: %v", err)
	}
	if _, err := s1.ReadRows(0, 1); !errors.Is(err, ErrClosed) {
		t.Errorf("ReadRows closed: %v", err)
	}
	m.Close(id1) // idempotent
	m.CloseSession("a")
	if files() != 1 || m.Len() != 1 {
		t.Errorf("after CloseSession: files=%d len=%d", files(), m.Len())
	}
	if _, err := m.Get(id3); err != nil {
		t.Errorf("session b result gone: %v", err)
	}
	m.Shutdown()
	if _, err := os.Stat(filepath.Join(base, strconv.Itoa(os.Getpid()))); !errors.Is(err, os.ErrNotExist) {
		t.Errorf("spool dir remains: %v", err)
	}
}

func TestSweep(t *testing.T) {
	base := t.TempDir()
	dead := filepath.Join(base, "999999999") // no such pid
	live := filepath.Join(base, strconv.Itoa(os.Getppid()))
	for _, d := range []string{dead, live} {
		if err := os.MkdirAll(d, 0o700); err != nil {
			t.Fatal(err)
		}
		_ = os.WriteFile(filepath.Join(d, "x.spool"), []byte("x"), 0o600)
	}
	other := filepath.Join(base, "not-a-pid")
	_ = os.MkdirAll(other, 0o700)
	m, err := NewManager(base, 0, slog.New(slog.DiscardHandler))
	if err != nil {
		t.Fatal(err)
	}
	defer m.Shutdown()
	if _, err := os.Stat(dead); !errors.Is(err, os.ErrNotExist) {
		t.Error("stale dir not swept")
	}
	if _, err := os.Stat(live); err != nil {
		t.Error("live process dir was removed")
	}
	if _, err := os.Stat(other); err != nil {
		t.Error("non-pid dir was removed")
	}
}

func TestSpoolBoundedMemory(t *testing.T) {
	m := newMgr(t, 0)
	_, s, _ := m.Create("s")
	for i := 0; i < 20_000; i += 500 {
		_ = s.Append(rowsRange(i, i+500))
	}
	s.mu.RLock()
	defer s.mu.RUnlock()
	if len(s.pending) >= PageRows {
		t.Errorf("pending = %d", len(s.pending))
	}
	if len(s.pages) != 40 {
		t.Errorf("pages = %d", len(s.pages))
	}
}

func TestValueRoundTrip(t *testing.T) {
	vals := []engine.Value{
		engine.Null(), engine.Bool(true), engine.Int(-5), engine.Float(1.25), engine.Decimal("1.10"),
		engine.Text("x"), engine.Bytes([]byte{1, 2}), engine.JSON("{}"), engine.UUID("u"),
		engine.Array([]engine.Value{engine.Int(1), engine.Null(), engine.Array(nil)}),
	}
	for _, v := range vals {
		p := ValueToProto(v)
		b, err := proto.Marshal(p)
		if err != nil {
			t.Fatal(err)
		}
		var q queravuev1.Value
		if err := proto.Unmarshal(b, &q); err != nil {
			t.Fatal(err)
		}
		back := ValueFromProto(&q)
		if fmt.Sprintf("%+v", back) != fmt.Sprintf("%+v", v) && (v.Kind != engine.VArray || back.Kind != engine.VArray || len(back.Array) != len(v.Array)) {
			t.Errorf("round trip %+v -> %+v", v, back)
		}
	}
}
