// Package shell runs mongosh-style JavaScript on an embedded goja runtime
// against a engine.ShellBackend. See docs/adr/0010-mongo-shell-runtime.md.
package shell

import (
	"context"
	"embed"
	"errors"
	"fmt"
	"sort"
	"strings"
	"sync"
	"time"
	"unicode/utf16"

	"github.com/dop251/goja"
	"github.com/dop251/goja/file"
	"github.com/dop251/goja/parser"

	"github.com/doubledare704/queravue/core/internal/engine"
)

//go:embed js/*.js
var preludeFiles embed.FS

// DefaultOutputCap is the default limit on printed text and materialised
// documents per Eval.
const DefaultOutputCap = 8 << 20

const (
	scriptName       = "shell"
	maxCallStack     = 1000
	defaultFetchPage = 50
)

// Options configures a Shell.
type Options struct {
	// Database is the initial value of `db`.
	Database string
	// Production gates destructive operations behind confirmation.
	Production bool
	// OutputCap bounds output per Eval in bytes. 0 means DefaultOutputCap;
	// negative means unlimited.
	OutputCap int64
	// Timeout bounds one Eval. 0 means no timeout.
	Timeout time.Duration
}

// Level is the console method behind a print line.
type Level string

// Print levels.
const (
	LevelLog   Level = "log"
	LevelInfo  Level = "info"
	LevelWarn  Level = "warn"
	LevelError Level = "error"
)

// ResultKind says what a Result holds.
type ResultKind int

// Result kinds.
const (
	ResultScalar ResultKind = iota + 1
	ResultDocument
	ResultWrite
	ResultCursor
)

// Handle identifies a replayable query for FetchCursor.
type Handle struct {
	ID   string
	Spec engine.CursorSpec
}

// Result is a value an Eval produced. Text is canonical EJSON.
type Result struct {
	Kind    ResultKind
	Text    string
	WriteOp string
	Cursor  *Handle
}

// Sink receives the output of an Eval, from the shell's own goroutine and one
// event at a time.
type Sink interface {
	Print(level Level, text string)
	Result(r Result)
}

// Shell is one mongosh-like session. Eval calls run one at a time.
type Shell struct {
	backend engine.ShellBackend
	opt     Options

	jobs   chan *job
	closed chan struct{}
	once   sync.Once

	mu     sync.Mutex
	cancel context.CancelFunc

	vm        *goja.Runtime
	classify  goja.Callable
	errFactor goja.Callable
	run       *runState
	live      map[string]engine.DocCursor
	nextLive  int

	handlesMu sync.Mutex
	handles   map[string]engine.CursorSpec
	nextH     int
}

type runState struct {
	ctx       context.Context
	confirmed bool
	sink      Sink
	out       int64
	abort     *Error
}

type job struct {
	ctx       context.Context
	code      string
	confirmed bool
	sink      Sink
	done      chan struct{}
	dur       time.Duration
	err       *Error
}

// New creates a shell and starts its goroutine. Call Close to stop it.
func New(backend engine.ShellBackend, opt Options) (*Shell, error) {
	if opt.OutputCap == 0 {
		opt.OutputCap = DefaultOutputCap
	}
	s := &Shell{
		backend: backend, opt: opt,
		jobs: make(chan *job), closed: make(chan struct{}),
		live: map[string]engine.DocCursor{}, handles: map[string]engine.CursorSpec{},
	}
	ready := make(chan error, 1)
	go s.loop(ready)
	if err := <-ready; err != nil {
		return nil, err
	}
	return s, nil
}

func (s *Shell) loop(ready chan<- error) {
	s.vm = goja.New()
	s.vm.SetMaxCallStackSize(maxCallStack)
	ready <- s.loadPrelude()
	for {
		select {
		case j := <-s.jobs:
			s.execute(j)
		case <-s.closed:
			s.closeLive()
			return
		}
	}
}

func (s *Shell) loadPrelude() (err error) {
	defer func() {
		if r := recover(); r != nil {
			err = fmt.Errorf("shell: load prelude: %v", r)
		}
	}()
	entries, err := preludeFiles.ReadDir("js")
	if err != nil {
		return fmt.Errorf("shell: read prelude: %w", err)
	}
	names := make([]string, 0, len(entries))
	for _, e := range entries {
		names = append(names, e.Name())
	}
	sort.Strings(names)
	var src strings.Builder
	src.WriteString("(function (N) {\n")
	for _, n := range names {
		b, err := preludeFiles.ReadFile("js/" + n)
		if err != nil {
			return fmt.Errorf("shell: read prelude %s: %w", n, err)
		}
		src.Write(b)
		src.WriteString("\n")
	}
	src.WriteString("})")
	prog, err := goja.Compile("prelude", src.String(), false)
	if err != nil {
		return fmt.Errorf("shell: compile prelude: %w", err)
	}
	fn, err := s.vm.RunProgram(prog)
	if err != nil {
		return fmt.Errorf("shell: load prelude: %w", err)
	}
	call, ok := goja.AssertFunction(fn)
	if !ok {
		return errors.New("shell: prelude is not a function")
	}
	classify, err := call(s.vm.GlobalObject(), s.natives())
	if err != nil {
		return fmt.Errorf("shell: init prelude: %w", err)
	}
	s.classify, ok = goja.AssertFunction(classify)
	if !ok {
		return errors.New("shell: prelude did not return classify")
	}
	return nil
}

// Eval runs code and sends output to sink. confirmed lets gated operations
// through. It returns the run time and a typed error, if any.
func (s *Shell) Eval(ctx context.Context, code string, confirmed bool, sink Sink) (time.Duration, *Error) {
	j := &job{ctx: ctx, code: code, confirmed: confirmed, sink: sink, done: make(chan struct{})}
	select {
	case s.jobs <- j:
	case <-s.closed:
		return 0, &Error{Kind: KindRuntime, Message: "shell is closed"}
	case <-ctx.Done():
		return 0, contextError(ctx)
	}
	<-j.done
	return j.dur, j.err
}

// Cancel interrupts the running Eval, if any.
func (s *Shell) Cancel() {
	s.mu.Lock()
	defer s.mu.Unlock()
	if s.cancel != nil {
		s.cancel()
	}
}

// Close stops the shell and releases its cursors.
func (s *Shell) Close() {
	s.once.Do(func() {
		s.Cancel()
		close(s.closed)
	})
}

func contextError(ctx context.Context) *Error {
	if errors.Is(ctx.Err(), context.DeadlineExceeded) {
		return &Error{Kind: KindTimeout, Message: "script timed out"}
	}
	return &Error{Kind: KindCanceled, Message: "script canceled"}
}

func (s *Shell) execute(j *job) {
	started := time.Now()
	defer close(j.done)
	defer func() { j.dur = time.Since(started) }()

	ctx, cancel := context.WithCancel(j.ctx)
	if s.opt.Timeout > 0 {
		var tcancel context.CancelFunc
		ctx, tcancel = context.WithTimeout(ctx, s.opt.Timeout)
		defer tcancel()
	}
	defer cancel()
	s.mu.Lock()
	s.cancel = cancel
	s.mu.Unlock()

	s.run = &runState{ctx: ctx, confirmed: j.confirmed, sink: j.sink}
	s.vm.ClearInterrupt()
	stopped := make(chan struct{})
	finished := make(chan struct{})
	go func() {
		defer close(stopped)
		select {
		case <-ctx.Done():
			s.vm.Interrupt("canceled")
		case <-finished:
		}
	}()
	defer func() {
		close(finished)
		<-stopped
	}()
	defer func() {
		if r := recover(); r != nil {
			j.err = &Error{Kind: KindRuntime, Message: fmt.Sprintf("internal shell error: %v", r)}
		}
	}()
	j.err = s.evaluate(ctx, j.code)
}

func (s *Shell) evaluate(ctx context.Context, code string) *Error {
	src := rewriteShellLines(code)
	prog, err := goja.Compile(scriptName, src, false)
	if err != nil {
		return syntaxError(err, src)
	}
	v, err := s.vm.RunProgram(prog)
	if err == nil {
		err = s.emitResult(v)
	}
	if err == nil {
		return nil
	}
	return s.runtimeError(ctx, err, src)
}

func (s *Shell) emitResult(v goja.Value) error {
	res, err := s.classify(goja.Undefined(), v)
	if err != nil {
		return err
	}
	if res == nil || goja.IsUndefined(res) || goja.IsNull(res) {
		return nil
	}
	o := res.ToObject(s.vm)
	text := o.Get("text").String()
	switch o.Get("t").String() {
	case "cursor":
		h, err := s.registerHandle(text)
		if err != nil {
			return err
		}
		s.run.sink.Result(Result{Kind: ResultCursor, Cursor: h})
	case "write":
		if !s.account(len(text)) {
			return nil
		}
		s.run.sink.Result(Result{Kind: ResultWrite, Text: text, WriteOp: o.Get("op").String()})
	case "doc":
		if !s.account(len(text)) {
			return nil
		}
		s.run.sink.Result(Result{Kind: ResultDocument, Text: text})
	default:
		if !s.account(len(text)) {
			return nil
		}
		s.run.sink.Result(Result{Kind: ResultScalar, Text: text})
	}
	return nil
}

func (s *Shell) runtimeError(ctx context.Context, err error, src string) *Error {
	if s.run.abort != nil {
		return s.run.abort
	}
	if ctx.Err() != nil {
		e := contextError(ctx)
		return e
	}
	var ex *goja.Exception
	if !errors.As(err, &ex) {
		return &Error{Kind: KindRuntime, Message: err.Error()}
	}
	e := &Error{Kind: KindRuntime, Message: exceptionMessage(ex), Stack: ex.String()}
	if obj, ok := ex.Value().(*goja.Object); ok {
		if k := obj.Get("kind"); k != nil && !goja.IsUndefined(k) {
			e.Kind = kindFromName(k.String())
		}
	}
	for _, f := range ex.Stack() {
		if p := f.Position(); p.Filename == scriptName && p.Line > 0 {
			e.Line, e.Column = p.Line, utf16Column(src, p.Line, p.Column)
			break
		}
	}
	return e
}

func exceptionMessage(ex *goja.Exception) string {
	v := ex.Value()
	if obj, ok := v.(*goja.Object); ok {
		name, msg := obj.Get("name"), obj.Get("message")
		if name != nil && msg != nil && !goja.IsUndefined(msg) {
			return name.String() + ": " + msg.String()
		}
	}
	return v.String()
}

func kindFromName(n string) ErrorKind {
	switch n {
	case "server":
		return KindServer
	case "unsupported":
		return KindUnsupported
	case "timeout":
		return KindTimeout
	case "canceled":
		return KindCanceled
	}
	return KindRuntime
}

func syntaxError(err error, src string) *Error {
	e := &Error{Kind: KindSyntax, Message: err.Error()}
	var list parser.ErrorList
	var compiler *goja.CompilerSyntaxError
	var f *file.File
	var offset int
	switch {
	case errors.As(err, &list) && len(list) > 0:
		e.Message, f, offset = list[0].Message, list[0].File, list[0].Offset
	case errors.As(err, &compiler):
		e.Message, f, offset = compiler.Message, compiler.File, compiler.Offset
	}
	if f != nil {
		pos := f.Position(offset)
		e.Line, e.Column = pos.Line, utf16Column(src, pos.Line, pos.Column)
	}
	return e
}

// utf16Column converts goja's 1-based byte column on a line to UTF-16 units.
func utf16Column(src string, line, col int) int {
	lines := strings.Split(src, "\n")
	if line < 1 || line > len(lines) || col < 1 {
		return col
	}
	text := lines[line-1]
	if col-1 > len(text) {
		return col
	}
	return len(utf16.Encode([]rune(text[:col-1]))) + 1
}

func (s *Shell) account(n int) bool {
	s.run.out += int64(n)
	if s.opt.OutputCap > 0 && s.run.out > s.opt.OutputCap {
		s.abortWith(&Error{Kind: KindOutputLimit, Message: fmt.Sprintf("output exceeded the %d byte limit; use a cursor, limit() or forEach", s.opt.OutputCap)})
		return false
	}
	return true
}

func (s *Shell) abortWith(e *Error) {
	if s.run.abort == nil {
		s.run.abort = e
	}
	s.vm.Interrupt("abort")
}
