package connections

import (
	"context"
	"errors"
	"fmt"
	"os"
	"strings"
	"sync/atomic"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/secrets"
)

// fakeEngine records the secret it was given and fails on demand.
type fakeEngine struct {
	gotSecret atomic.Value // string
	failWith  error
	block     bool
}

func (f *fakeEngine) Descriptor() engine.Descriptor {
	return engine.Descriptor{
		ID: "fake", DisplayName: "Fake", Family: "fake", SupportsURI: true,
		Fields: []engine.FieldSpec{
			{Key: "host", Label: "Host", Kind: engine.FieldText, Required: true},
			{Key: "password", Label: "Password", Kind: engine.FieldPassword},
		},
		Capabilities: []engine.Capability{engine.CapConnect},
	}
}

func (f *fakeEngine) ParseURI(uri string) (engine.Config, engine.Secret, error) {
	host, pw, _ := strings.Cut(strings.TrimPrefix(uri, "fake://"), ":")
	return engine.Config{EngineID: "fake", Params: map[string]string{"host": host}}, engine.NewSecret(pw), nil
}

func (f *fakeEngine) Connect(ctx context.Context, _ engine.Config, s engine.Secret) (engine.Conn, error) {
	f.gotSecret.Store(s.Reveal())
	if f.block {
		<-ctx.Done()
		return nil, &engine.Error{Kind: engine.KindNetwork, Engine: "fake", Op: "connect", Msg: "dial: " + ctx.Err().Error(), Err: ctx.Err()}
	}
	if f.failWith != nil {
		return nil, f.failWith
	}
	return fakeConn{}, nil
}

type fakeConn struct{}

func (fakeConn) Ping(context.Context) error { return nil }
func (fakeConn) ServerInfo(context.Context) (engine.ServerInfo, error) {
	return engine.ServerInfo{Product: "Fake", Version: "1.0"}, nil
}
func (fakeConn) Close() error { return nil }

type testEnv struct {
	svc     *Service
	secrets *secrets.Memory
	engine  *fakeEngine
	store   *FileStore
}

func newEnv(t *testing.T) testEnv {
	t.Helper()
	fe := &fakeEngine{}
	reg, err := engine.NewRegistry(fe)
	if err != nil {
		t.Fatal(err)
	}
	mem := secrets.NewMemory()
	store := NewFileStore(t.TempDir())
	n := 0
	svc := NewService(reg, store, mem,
		WithIDs(func() string { n++; return fmt.Sprintf("id%d", n) }),
		WithClock(func() time.Time { return time.Date(2026, 11, 5, 0, 0, 0, 0, time.UTC) }))
	return testEnv{svc, mem, fe, store}
}

func newTestService(t *testing.T, store *FileStore) *Service {
	t.Helper()
	reg, err := engine.NewRegistry(&fakeEngine{})
	if err != nil {
		t.Fatal(err)
	}
	return NewService(reg, store, secrets.NewMemory())
}

func ptr(s string) *string { return &s }

func TestCreateKeepsPasswordOutOfFile(t *testing.T) {
	env := newEnv(t)
	ctx := t.Context()
	const pw = "s3cr3t-Pa55word!"
	c, err := env.svc.Create(ctx, Connection{
		Name: " Local ", EngineID: "fake", Folder: "/Work//",
		// A buggy client putting the password in params must not leak it.
		Params: map[string]string{"host": "h", "password": pw, "bogus": "x"},
	}, ptr(pw))
	if err != nil {
		t.Fatal(err)
	}
	if c.ID != "id1" || c.Name != "Local" || c.Folder != "Work" || !c.HasPassword() {
		t.Errorf("created = %+v", c)
	}
	if _, ok := c.Params["password"]; ok {
		t.Error("password kept in params")
	}
	if _, ok := c.Params["bogus"]; ok {
		t.Error("unknown param kept")
	}

	raw, err := os.ReadFile(env.store.Path())
	if err != nil {
		t.Fatal(err)
	}
	if strings.Contains(string(raw), pw) {
		t.Fatalf("connections.json contains the password:\n%s", raw)
	}
	if !strings.Contains(string(raw), `"secretRef": "conn/id1"`) {
		t.Errorf("secret ref missing:\n%s", raw)
	}
	if got, _ := env.secrets.Get("conn/id1"); got != pw {
		t.Errorf("keychain = %q", got)
	}

	// Survives a "restart": a new service on the same file and keychain.
	reg, _ := engine.NewRegistry(env.engine)
	again := NewService(reg, NewFileStore(strings.TrimSuffix(env.store.Path(), "/"+FileName)), env.secrets)
	list, err := again.List(ctx)
	if err != nil || len(list) != 1 || list[0].ID != "id1" {
		t.Fatalf("reload = %v, %v", list, err)
	}
	res, err := again.Test(ctx, TestRequest{ID: "id1"})
	if err != nil || res.Err != nil {
		t.Fatalf("Test after reload = %+v, %v", res, err)
	}
	if env.engine.gotSecret.Load() != pw {
		t.Error("Test did not use keychain password")
	}
}

func TestCreateValidation(t *testing.T) {
	env := newEnv(t)
	for name, c := range map[string]Connection{
		"no name":        {EngineID: "fake", Params: map[string]string{"host": "h"}},
		"unknown engine": {Name: "x", EngineID: "nope"},
		"missing host":   {Name: "x", EngineID: "fake"},
	} {
		if _, err := env.svc.Create(t.Context(), c, nil); engine.KindOf(err) != engine.KindInvalidConfig {
			t.Errorf("%s: err = %v", name, err)
		}
	}
	if env.secrets.Len() != 0 {
		t.Error("failed create stored a secret")
	}
}

func TestUpdatePasswordSemantics(t *testing.T) {
	env := newEnv(t)
	ctx := t.Context()
	c, _ := env.svc.Create(ctx, Connection{Name: "x", EngineID: "fake", Params: map[string]string{"host": "h"}}, ptr("one"))

	c.Name = "renamed"
	c, err := env.svc.Update(ctx, c, nil, false)
	if err != nil || !c.HasPassword() || c.Name != "renamed" {
		t.Fatalf("keep: %+v %v", c, err)
	}
	if got, _ := env.secrets.Get("conn/id1"); got != "one" {
		t.Errorf("kept = %q", got)
	}

	c, _ = env.svc.Update(ctx, c, ptr("two"), false)
	if got, _ := env.secrets.Get("conn/id1"); got != "two" || !c.HasPassword() {
		t.Errorf("replaced = %q", got)
	}

	c, _ = env.svc.Update(ctx, c, nil, true)
	if c.HasPassword() || env.secrets.Len() != 0 {
		t.Errorf("clear: %+v, %d secrets", c, env.secrets.Len())
	}

	if _, err := env.svc.Update(ctx, Connection{ID: "missing", Name: "x", EngineID: "fake", Params: map[string]string{"host": "h"}}, nil, false); !errors.Is(err, ErrNotFound) {
		t.Errorf("update missing = %v", err)
	}
}

func TestDeleteRemovesSecret(t *testing.T) {
	env := newEnv(t)
	ctx := t.Context()
	c, _ := env.svc.Create(ctx, Connection{Name: "x", EngineID: "fake", Params: map[string]string{"host": "h"}}, ptr("pw"))
	if err := env.svc.Delete(ctx, c.ID); err != nil {
		t.Fatal(err)
	}
	if env.secrets.Len() != 0 {
		t.Error("secret not deleted")
	}
	if err := env.svc.Delete(ctx, c.ID); !errors.Is(err, ErrNotFound) {
		t.Errorf("second delete = %v", err)
	}
	if _, err := env.svc.Get(ctx, c.ID); !errors.Is(err, ErrNotFound) {
		t.Errorf("get deleted = %v", err)
	}
}

func TestListSorted(t *testing.T) {
	env := newEnv(t)
	ctx := t.Context()
	for _, c := range []Connection{
		{Name: "b", Folder: "Work"}, {Name: "A", Folder: "Work"}, {Name: "z"},
	} {
		c.EngineID, c.Params = "fake", map[string]string{"host": "h"}
		if _, err := env.svc.Create(ctx, c, nil); err != nil {
			t.Fatal(err)
		}
	}
	list, _ := env.svc.List(ctx)
	var got []string
	for _, c := range list {
		got = append(got, c.Folder+"/"+c.Name)
	}
	if strings.Join(got, ",") != "/z,Work/A,Work/b" {
		t.Errorf("order = %v", got)
	}
}

func TestTestDraftFallsBackToStoredPassword(t *testing.T) {
	env := newEnv(t)
	ctx := t.Context()
	c, _ := env.svc.Create(ctx, Connection{Name: "x", EngineID: "fake", Params: map[string]string{"host": "h"}}, ptr("stored"))

	draft := c
	draft.Params = map[string]string{"host": "other"}
	if res, _ := env.svc.Test(ctx, TestRequest{ID: c.ID, Draft: &draft}); res.Err != nil {
		t.Fatal(res.Err)
	}
	if env.engine.gotSecret.Load() != "stored" {
		t.Error("draft test did not fall back to stored password")
	}
	if _, _ = env.svc.Test(ctx, TestRequest{ID: c.ID, Draft: &draft, Password: ptr("typed")}); env.engine.gotSecret.Load() != "typed" {
		t.Error("explicit password not used")
	}
	if _, err := env.svc.Test(ctx, TestRequest{ID: "missing"}); !errors.Is(err, ErrNotFound) {
		t.Errorf("missing id = %v", err)
	}
}

func TestTestFailureIsTypedAndRedacted(t *testing.T) {
	env := newEnv(t)
	env.engine.failWith = errors.New("auth failed for password hunter2")
	draft := Connection{EngineID: "fake", Params: map[string]string{"host": "h"}}
	res, err := env.svc.Test(t.Context(), TestRequest{Draft: &draft, Password: ptr("hunter2")})
	if err != nil {
		t.Fatal(err)
	}
	if res.Err == nil || strings.Contains(res.Err.Error(), "hunter2") {
		t.Fatalf("res.Err = %v", res.Err)
	}

	env.engine.failWith = &engine.Error{Kind: engine.KindAuth, Engine: "fake", Op: "connect", Msg: "bad hunter2"}
	res, _ = env.svc.Test(t.Context(), TestRequest{Draft: &draft, Password: ptr("hunter2")})
	if res.Err.Kind != engine.KindAuth || strings.Contains(res.Err.Msg, "hunter2") {
		t.Errorf("typed = %+v", res.Err)
	}
}

func TestTestTimeout(t *testing.T) {
	env := newEnv(t)
	env.engine.block = true
	draft := Connection{EngineID: "fake", Params: map[string]string{"host": "h"}}
	start := time.Now()
	res, err := env.svc.Test(t.Context(), TestRequest{Draft: &draft, Timeout: time.Millisecond})
	if err != nil {
		t.Fatal(err)
	}
	if res.Err == nil || res.Err.Kind != engine.KindTimeout || !strings.Contains(res.Err.Msg, "timed out after 1s") {
		t.Fatalf("res.Err = %+v", res.Err)
	}
	if d := time.Since(start); d > 3*time.Second {
		t.Errorf("took %s; timeout not clamped to 1s", d)
	}
}

func TestTestCallerCancel(t *testing.T) {
	env := newEnv(t)
	env.engine.block = true
	ctx, cancel := context.WithCancel(t.Context())
	cancel()
	draft := Connection{EngineID: "fake", Params: map[string]string{"host": "h"}}
	if _, err := env.svc.Test(ctx, TestRequest{Draft: &draft}); !errors.Is(err, context.Canceled) {
		t.Fatalf("err = %v, want canceled", err)
	}
}

func TestClampTimeout(t *testing.T) {
	for in, want := range map[time.Duration]time.Duration{
		0: DefaultTestTimeout, time.Millisecond: MinTestTimeout, 5 * time.Second: 5 * time.Second, time.Hour: MaxTestTimeout,
	} {
		if got := ClampTimeout(in); got != want {
			t.Errorf("ClampTimeout(%s) = %s, want %s", in, got, want)
		}
	}
}

func TestParseURIUnknownEngine(t *testing.T) {
	env := newEnv(t)
	if _, _, err := env.svc.ParseURI("nope", "x"); engine.KindOf(err) != engine.KindInvalidConfig {
		t.Errorf("err = %v", err)
	}
	params, sec, err := env.svc.ParseURI("fake", "fake://h:pw")
	if err != nil || params["host"] != "h" || sec.Reveal() != "pw" {
		t.Errorf("parse = %v %v %v", params, sec, err)
	}
}
