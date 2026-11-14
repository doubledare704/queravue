package rediscli_test

import (
	"testing"

	"github.com/doubledare704/queravue/core/internal/rediscli"
)

func args(s ...string) [][]byte {
	out := make([][]byte, len(s))
	for i, a := range s {
		out[i] = []byte(a)
	}
	return out
}

func TestInspect(t *testing.T) {
	tests := []struct {
		name string
		in   [][]byte
		want rediscli.Verdict
	}{
		{"empty", nil, rediscli.Verdict{}},
		{"get", args("get", "k"), rediscli.Verdict{}},
		{"keys", args("keys", "*"), rediscli.Verdict{Keys: true}},
		{"blpop", args("BLPOP", "l", "0"), rediscli.Verdict{Blocking: true}},
		{"subscribe", args("subscribe", "c"), rediscli.Verdict{Blocking: true}},
		{"monitor", args("MONITOR"), rediscli.Verdict{Blocking: true}},
		{"xread plain", args("XREAD", "STREAMS", "s", "0"), rediscli.Verdict{}},
		{"xread block", args("XREAD", "block", "0", "STREAMS", "s", "$"), rediscli.Verdict{Blocking: true}},
		{"flushall", args("FLUSHALL"), rediscli.Verdict{ConfirmOperation: "FLUSHALL on every database"}},
		{"flushdb", args("flushdb"), rediscli.Verdict{ConfirmOperation: "FLUSHDB on the selected database"}},
		{"del one", args("DEL", "a"), rediscli.Verdict{}},
		{"del many", args("DEL", "a", "b", "c"), rediscli.Verdict{ConfirmOperation: "DEL 3 keys"}},
		{"config get", args("CONFIG", "GET", "*"), rediscli.Verdict{}},
		{"config set", args("config", "set", "maxmemory", "1"), rediscli.Verdict{ConfirmOperation: "CONFIG SET"}},
		{"shutdown", args("SHUTDOWN", "NOSAVE"), rediscli.Verdict{ConfirmOperation: "SHUTDOWN of the server"}},
		{"debug", args("DEBUG", "sleep", "0"), rediscli.Verdict{ConfirmOperation: "DEBUG SLEEP"}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := rediscli.Inspect(tt.in); got != tt.want {
				t.Fatalf("got %+v want %+v", got, tt.want)
			}
		})
	}
}
