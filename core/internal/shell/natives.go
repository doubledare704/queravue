package shell

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"encoding/json"
	"errors"
	"fmt"
	"strconv"
	"strings"
	"time"

	"github.com/dop251/goja"
	"go.mongodb.org/mongo-driver/v2/bson"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func (s *Shell) natives() *goja.Object {
	n := s.vm.NewObject()
	set := func(name string, fn any) { _ = n.Set(name, fn) }
	set("cmd", s.nativeCmd)
	set("cursorOpen", s.nativeCursorOpen)
	set("cursorNext", s.nativeCursorNext)
	set("cursorClose", s.nativeCursorClose)
	set("print", s.nativePrint)
	set("gate", s.nativeGate)
	set("sleep", s.nativeSleep)
	set("newOid", func() string { return bson.NewObjectID().Hex() })
	set("newUUID", newUUID)
	set("defaultDatabase", func() string { return s.opt.Database })
	set("setErrorFactory", func(fn goja.Callable) { s.errFactor = fn })
	return n
}

func newUUID() string {
	var b [16]byte
	_, _ = rand.Read(b[:])
	b[6] = b[6]&0x0f | 0x40
	b[8] = b[8]&0x3f | 0x80
	return hex.EncodeToString(b[:])
}

func (s *Shell) throw(err error) {
	name, kind, code, msg := "MongoshRuntimeError", "", 0, err.Error()
	var ee *engine.Error
	if errors.As(err, &ee) {
		name, code, msg = "MongoServerError", ee.Code, ee.Msg
		switch ee.Kind {
		case engine.KindParse:
			name, kind = "MongoshInvalidInputError", "runtime"
		case engine.KindCanceled:
			kind = "canceled"
		case engine.KindTimeout:
			kind = "timeout"
		default:
			kind = "server"
		}
	}
	v, callErr := s.errFactor(goja.Undefined(), s.vm.ToValue(name), s.vm.ToValue(msg), s.vm.ToValue(code), s.vm.ToValue(kind))
	if callErr != nil {
		panic(s.vm.ToValue(msg))
	}
	panic(v)
}

func (s *Shell) nativeCmd(db, command string) string {
	out, err := s.backend.RunCommand(s.run.ctx, db, command)
	if err != nil {
		s.throw(err)
	}
	return out
}

type cursorSpecJSON struct {
	Kind       string `json:"kind"`
	Database   string `json:"database"`
	Collection string `json:"collection"`
	Filter     string `json:"filter"`
	Sort       string `json:"sort"`
	Projection string `json:"projection"`
	Hint       string `json:"hint"`
	Pipeline   string `json:"pipeline"`
	Skip       uint64 `json:"skip"`
	Limit      uint64 `json:"limit"`
	BatchSize  int    `json:"batchSize"`
	MaxTimeMS  uint32 `json:"maxTimeMS"`
}

func parseSpec(text string) (engine.CursorSpec, error) {
	var j cursorSpecJSON
	if err := json.Unmarshal([]byte(text), &j); err != nil {
		return engine.CursorSpec{}, fmt.Errorf("shell: cursor spec: %w", err)
	}
	kind := engine.CursorFind
	if j.Kind == "aggregate" {
		kind = engine.CursorAggregate
	}
	return engine.CursorSpec{
		Kind: kind, Database: j.Database, Collection: j.Collection, Filter: j.Filter, Sort: j.Sort,
		Projection: j.Projection, Hint: j.Hint, Pipeline: j.Pipeline, Skip: j.Skip, Limit: j.Limit,
		BatchSize: j.BatchSize, MaxTimeMS: j.MaxTimeMS,
	}, nil
}

func (s *Shell) nativeCursorOpen(specText string) string {
	spec, err := parseSpec(specText)
	if err != nil {
		s.throw(err)
	}
	cur, err := s.backend.OpenCursor(s.run.ctx, spec)
	if err != nil {
		s.throw(err)
	}
	s.nextLive++
	id := "live" + strconv.Itoa(s.nextLive)
	s.live[id] = cur
	return id
}

func (s *Shell) nativeCursorNext(id string, n int, retain bool) []any {
	cur, ok := s.live[id]
	if !ok {
		return []any{"[]", true}
	}
	var sb strings.Builder
	sb.WriteByte('[')
	done := false
	for i := 0; i < max(n, 1); i++ {
		doc, more, err := cur.Next(s.run.ctx)
		if err != nil {
			s.nativeCursorClose(id)
			s.throw(err)
		}
		if !more {
			done = true
			break
		}
		if i > 0 {
			sb.WriteByte(',')
		}
		sb.WriteString(doc)
		if retain && !s.account(len(doc)) {
			break
		}
	}
	sb.WriteByte(']')
	if done {
		s.nativeCursorClose(id)
	}
	return []any{sb.String(), done}
}

func (s *Shell) nativeCursorClose(id string) {
	if cur, ok := s.live[id]; ok {
		_ = cur.Close()
		delete(s.live, id)
	}
}

func (s *Shell) closeLive() {
	for id := range s.live {
		s.nativeCursorClose(id)
	}
}

func (s *Shell) nativePrint(level, text string) {
	if !s.account(len(text) + 1) {
		return
	}
	s.run.sink.Print(Level(level), text)
}

func (s *Shell) nativeGate(operation string, always bool) {
	if s.run.confirmed || (!always && !s.opt.Production) {
		return
	}
	s.abortWith(&Error{Kind: KindConfirmationRequired, Operation: operation,
		Message: "confirmation required: " + operation})
}

func (s *Shell) nativeSleep(ms float64) {
	select {
	case <-time.After(time.Duration(ms * float64(time.Millisecond))):
	case <-s.run.ctx.Done():
	}
}

func (s *Shell) registerHandle(specText string) (*Handle, error) {
	spec, err := parseSpec(specText)
	if err != nil {
		return nil, err
	}
	s.handlesMu.Lock()
	defer s.handlesMu.Unlock()
	s.nextH++
	id := "cursor" + strconv.Itoa(s.nextH)
	s.handles[id] = spec
	return &Handle{ID: id, Spec: spec}, nil
}

// FetchCursor replays the query behind a cursor handle, skipping skip
// documents and returning at most limit (default 50), and passes the
// documents to emit in batches. It does not use the script runtime, so it can
// run while an Eval is in progress.
func (s *Shell) FetchCursor(ctx context.Context, id string, skip uint64, limit int, emit func(offset uint64, docs []engine.Document, done bool) error) error {
	s.handlesMu.Lock()
	spec, ok := s.handles[id]
	s.handlesMu.Unlock()
	if !ok {
		return &engine.Error{Kind: engine.KindNotFound, Engine: "shell", Op: "fetch cursor", Msg: "cursor handle not found"}
	}
	if limit <= 0 {
		limit = defaultFetchPage
	}
	want := uint64(limit)
	if spec.Limit > 0 {
		if skip >= spec.Limit {
			return emit(0, nil, true)
		}
		want = min(want, spec.Limit-skip)
	}
	spec.Skip += skip
	spec.Limit = want
	cur, err := s.backend.OpenCursor(ctx, spec)
	if err != nil {
		return err
	}
	defer func() { _ = cur.Close() }()

	var (
		batch  []engine.Document
		size   int
		offset uint64
	)
	flush := func(done bool) error {
		if len(batch) == 0 && !done {
			return nil
		}
		err := emit(offset, batch, done)
		offset += uint64(len(batch))
		batch, size = nil, 0
		return err
	}
	for {
		doc, more, err := cur.Next(ctx)
		if err != nil {
			return err
		}
		if !more {
			return flush(true)
		}
		batch = append(batch, doc)
		size += len(doc)
		if len(batch) >= engine.MaxDocBatch || size >= engine.MaxDocBatchBytes {
			if err := flush(false); err != nil {
				return err
			}
		}
	}
}
