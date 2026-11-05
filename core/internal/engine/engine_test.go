package engine_test

import (
	"encoding/json"
	"errors"
	"fmt"
	"log/slog"
	"strings"
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/engines"
)

func TestSecretNeverPrints(t *testing.T) {
	s := engine.NewSecret("hunter2")
	var logBuf strings.Builder
	slog.New(slog.NewTextHandler(&logBuf, nil)).Info("x", "secret", s)
	js, _ := json.Marshal(struct{ S engine.Secret }{s})
	outputs := []string{
		fmt.Sprint(s), fmt.Sprintf("%v %+v %#v %s %q %x", s, s, s, s, s, s),
		string(js), logBuf.String(),
	}
	for _, out := range outputs {
		if strings.Contains(out, "hunter2") {
			t.Errorf("secret leaked: %s", out)
		}
	}
	if s.Reveal() != "hunter2" {
		t.Error("Reveal")
	}
}

func TestRedact(t *testing.T) {
	got := engine.Redact("user u pw hunter2 again hunter2", engine.NewSecret("hunter2"), engine.Secret{})
	if strings.Contains(got, "hunter2") {
		t.Errorf("Redact = %q", got)
	}
}

func TestErrorIs(t *testing.T) {
	cause := errors.New("cause")
	err := fmt.Errorf("wrap: %w", &engine.Error{Kind: engine.KindAuth, Engine: "postgres", Op: "connect", Msg: "bad", Err: cause})
	if !errors.Is(err, &engine.Error{Kind: engine.KindAuth}) {
		t.Error("Is by kind")
	}
	if errors.Is(err, &engine.Error{Kind: engine.KindNetwork}) {
		t.Error("Is wrong kind")
	}
	if !errors.Is(err, cause) {
		t.Error("Unwrap")
	}
	if engine.KindOf(err) != engine.KindAuth || engine.KindOf(cause) != engine.KindUnknown {
		t.Error("KindOf")
	}
}

func TestDescriptorValidate(t *testing.T) {
	d := engine.Descriptor{ID: "x", Fields: []engine.FieldSpec{
		{Key: "host", Label: "Host", Kind: engine.FieldText, Required: true},
		{Key: "port", Label: "Port", Kind: engine.FieldInteger, Required: true, Default: "1"},
		{Key: "mode", Label: "Mode", Kind: engine.FieldSelect, Options: []string{"a", "b"}},
		{Key: "pw", Label: "Password", Kind: engine.FieldPassword, Required: true},
	}}
	tests := []struct {
		params map[string]string
		ok     bool
	}{
		{map[string]string{"host": "h"}, true},
		{map[string]string{}, false},
		{map[string]string{"host": "h", "port": "x"}, false},
		{map[string]string{"host": "h", "mode": "c"}, false},
		{map[string]string{"host": "h", "mode": "b"}, true},
	}
	for _, tt := range tests {
		err := d.Validate(engine.Config{Params: tt.params})
		if (err == nil) != tt.ok {
			t.Errorf("Validate(%v) = %v, want ok=%v", tt.params, err, tt.ok)
		}
	}
	if d.KnownKey("pw") || !d.KnownKey("host") || d.KnownKey("nope") {
		t.Error("KnownKey")
	}
}

// Every built-in engine declares connect, and each capability it declares
// maps to an interface its Conn type implements.
func TestBuiltinRegistry(t *testing.T) {
	reg, err := engines.Registry()
	if err != nil {
		t.Fatal(err)
	}
	ids := map[string]bool{}
	for _, e := range reg.List() {
		d := e.Descriptor()
		ids[d.ID] = true
		if !d.HasCapability(engine.CapConnect) {
			t.Errorf("%s lacks connect", d.ID)
		}
		for _, c := range d.Capabilities {
			if c == engine.CapConnect {
				continue
			}
			if _, ok := engine.CapabilityInterfaces[c]; !ok {
				t.Errorf("%s declares %q with no interface mapping", d.ID, c)
			}
		}
		pw := 0
		for _, f := range d.Fields {
			if f.Kind == engine.FieldPassword {
				pw++
			}
		}
		if pw > 1 {
			t.Errorf("%s has %d password fields", d.ID, pw)
		}
	}
	for _, want := range []string{"postgres", "cockroachdb", "sqlite"} {
		if !ids[want] {
			t.Errorf("missing engine %s", want)
		}
	}
	if _, err := engine.NewRegistry(engines.All()[0], engines.All()[0]); err == nil {
		t.Error("duplicate id must fail")
	}
}
