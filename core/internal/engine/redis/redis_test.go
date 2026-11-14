package redis

import (
	"context"
	"errors"
	"math/big"
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func TestParseURI(t *testing.T) {
	cfg, secret, err := New(VariantRedis).ParseURI("rediss://app:s3cret@cache.example.com:6380/3")
	if err != nil {
		t.Fatal(err)
	}
	want := map[string]string{ParamMode: ModeStandalone, ParamTLS: "true", ParamHosts: "cache.example.com:6380", ParamUsername: "app", ParamDatabase: "3"}
	for k, v := range want {
		if cfg.Params[k] != v {
			t.Errorf("%s = %q, want %q", k, cfg.Params[k], v)
		}
	}
	if secret.Reveal() != "s3cret" {
		t.Error("password lost")
	}
	for _, p := range cfg.Params {
		if p == "s3cret" {
			t.Fatal("password leaked into params")
		}
	}
	for _, bad := range []string{"http://x", "redis://h/abc", "::"} {
		if _, _, err := New(VariantRedis).ParseURI(bad); engine.KindOf(err) != engine.KindInvalidConfig {
			t.Errorf("%q: err = %v", bad, err)
		}
	}
}

func TestDescriptorAndTopologyValidation(t *testing.T) {
	d := New(VariantValkey).Descriptor()
	if d.ID != IDValkey || !d.HasCapability(engine.CapKeyValueStore) || !d.SupportsSSH || !d.SupportsTLS {
		t.Fatalf("descriptor = %+v", d)
	}
	tests := []struct {
		name   string
		params map[string]string
		ok     bool
	}{
		{"standalone", map[string]string{ParamHosts: "h"}, true},
		{"sentinel without master", map[string]string{ParamMode: ModeSentinel, ParamHosts: "a,b"}, false},
		{"sentinel", map[string]string{ParamMode: ModeSentinel, ParamHosts: "a,b", ParamMasterName: "m"}, true},
		{"cluster db", map[string]string{ParamMode: ModeCluster, ParamHosts: "a", ParamDatabase: "2"}, false},
		{"bad db", map[string]string{ParamHosts: "a", ParamDatabase: "x"}, false},
	}
	for _, tt := range tests {
		_, err := newTopology(engine.Config{Params: tt.params}, ID)
		if (err == nil) != tt.ok {
			t.Errorf("%s: err = %v", tt.name, err)
		}
	}
	topo, _ := newTopology(engine.Config{Params: map[string]string{ParamHosts: "a, b:7000"}}, ID)
	if len(topo.addrs) != 2 || topo.addrs[0] != "a:6379" || topo.addrs[1] != "b:7000" {
		t.Errorf("addrs = %v", topo.addrs)
	}
}

func TestParseServerInfo(t *testing.T) {
	redisInfo := "# Server\r\nredis_version:7.4.12\r\nredis_mode:standalone\r\n"
	if got := parseServerInfo(redisInfo, VariantRedis); got.Product != "Redis" || got.Version != "7.4.12" {
		t.Errorf("redis = %+v", got)
	}
	valkeyInfo := "redis_version:7.2.4\r\nserver_name:valkey\r\nvalkey_version:8.1.1\r\n"
	if got := parseServerInfo(valkeyInfo, VariantRedis); got.Product != "Valkey" || got.Version != "8.1.1" {
		t.Errorf("valkey = %+v", got)
	}
}

func TestClassify(t *testing.T) {
	secret := engine.NewSecret("hunter2")
	tests := []struct {
		err  error
		want engine.Kind
	}{
		{errors.New("WRONGPASS invalid username-password pair"), engine.KindUnknown},
		{context.Canceled, engine.KindCanceled},
		{context.DeadlineExceeded, engine.KindTimeout},
	}
	for _, tt := range tests {
		if got := classify(ID, "op", tt.err, secret).Kind; got != tt.want {
			t.Errorf("%v: kind = %v, want %v", tt.err, got, tt.want)
		}
	}
	for msg, want := range map[string]engine.Kind{
		"WRONGPASS invalid username-password pair": engine.KindAuth,
		"NOAUTH Authentication required.":          engine.KindAuth,
		"ERR unknown command 'JSON.GET'":           engine.KindUnsupported,
		"ERR no such key":                          engine.KindNotFound,
		"NOPERM this user has no permissions":      engine.KindServer,
		"WRONGTYPE Operation against a key":        engine.KindServer,
	} {
		if got := classifyReply(msg); got != want {
			t.Errorf("%q: %v, want %v", msg, got, want)
		}
	}
	e := classify(ID, "op", errors.New("failed with hunter2"), secret)
	if e.Msg != "failed with [REDACTED]" {
		t.Errorf("secret not redacted: %q", e.Msg)
	}
}

func TestConvertReply(t *testing.T) {
	budget := 100
	got, err := convertReply([]any{int64(1), "a", nil, 1.5, true, big.NewInt(7), map[any]any{"b": int64(2), "a": int64(1)}}, false, &budget)
	if err != nil {
		t.Fatal(err)
	}
	kinds := []engine.ReplyKind{engine.ReplyInteger, engine.ReplyString, engine.ReplyNil, engine.ReplyDouble, engine.ReplyBoolean, engine.ReplyString, engine.ReplyMap}
	if got.Kind != engine.ReplyArray || len(got.Items) != len(kinds) {
		t.Fatalf("reply = %+v", got)
	}
	for i, k := range kinds {
		if got.Items[i].Kind != k {
			t.Errorf("item %d kind = %v, want %v", i, got.Items[i].Kind, k)
		}
	}
	m := got.Items[6]
	if string(m.Entries[0].Key.Bytes) != "a" || string(m.Entries[1].Key.Bytes) != "b" {
		t.Errorf("map not sorted: %+v", m.Entries)
	}
	set, _ := convertReply([]any{"x"}, true, &budget)
	if set.Kind != engine.ReplySet {
		t.Errorf("set kind = %v", set.Kind)
	}
}

func TestConvertReplyBudget(t *testing.T) {
	budget := 3
	if _, err := convertReply([]any{"a", "b", "c", "d"}, false, &budget); err == nil {
		t.Fatal("expected a too-large error")
	}
}

func TestAdjacentStreamID(t *testing.T) {
	tests := []struct {
		id      string
		reverse bool
		want    string
		ok      bool
	}{
		{"10-5", false, "10-6", true},
		{"10-5", true, "10-4", true},
		{"10-0", true, "9-18446744073709551615", true},
		{"0-0", true, "", false},
		{"10-18446744073709551615", false, "11-0", true},
		{"junk", false, "", false},
	}
	for _, tt := range tests {
		got, ok := adjacentStreamID(tt.id, tt.reverse)
		if got != tt.want || ok != tt.ok {
			t.Errorf("%s reverse=%v: %q %v, want %q %v", tt.id, tt.reverse, got, ok, tt.want, tt.ok)
		}
	}
}

func TestIncompleteRuneTail(t *testing.T) {
	euro := []byte("€")
	tests := []struct {
		name string
		in   []byte
		want int
	}{
		{"ascii", []byte("abc"), 0},
		{"complete rune", append([]byte("a"), euro...), 0},
		{"cut after one byte", append([]byte("a"), euro[:1]...), 1},
		{"cut after two bytes", append([]byte("a"), euro[:2]...), 2},
		{"binary", []byte{0xff, 0xfe}, 0},
		{"empty", nil, 0},
	}
	for _, tt := range tests {
		if got := incompleteRuneTail(tt.in); got != tt.want {
			t.Errorf("%s: %d, want %d", tt.name, got, tt.want)
		}
	}
}
