package rediscli_test

import (
	"errors"
	"reflect"
	"testing"

	"github.com/doubledare704/queravue/core/internal/rediscli"
)

func TestSplit(t *testing.T) {
	tests := []struct {
		name string
		line string
		want []string
	}{
		{"empty", "", nil},
		{"blank", "  \t ", nil},
		{"plain", "SET a b", []string{"SET", "a", "b"}},
		{"extra spaces", "  GET   key  ", []string{"GET", "key"}},
		{"double quotes keep spaces", `SET "a b" "c  d"`, []string{"SET", "a b", "c  d"}},
		{"empty quoted", `SET k ""`, []string{"SET", "k", ""}},
		{"escapes", `SET k "l1\nl2\t\"q\"\\"`, []string{"SET", "k", "l1\nl2\t\"q\"\\"}},
		{"hex", `SET k "\x00\xffA"`, []string{"SET", "k", "\x00\xffA"}},
		{"bad hex is literal letter", `SET k "\xZZ"`, []string{"SET", "k", "xZZ"}},
		{"single quotes are literal", `SET k 'a\nb'`, []string{"SET", "k", `a\nb`}},
		{"single quote escape", `SET k 'it\'s'`, []string{"SET", "k", "it's"}},
		{"newline separates", "PING\nPING", []string{"PING", "PING"}},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			got, err := rediscli.Split(tt.line)
			if err != nil {
				t.Fatal(err)
			}
			var gs []string
			for _, a := range got {
				gs = append(gs, string(a))
			}
			if !reflect.DeepEqual(gs, tt.want) {
				t.Fatalf("got %q want %q", gs, tt.want)
			}
		})
	}
}

func TestSplitErrors(t *testing.T) {
	for _, line := range []string{`SET "a`, `SET 'a`, `SET "a"b`, `SET a"b"`, `SET 'a'b`} {
		if _, err := rediscli.Split(line); !errors.Is(err, rediscli.ErrUnbalancedQuotes) {
			t.Errorf("%q: err = %v", line, err)
		}
	}
}
