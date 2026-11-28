//go:build duckdb

package transfer

import (
	"reflect"
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func TestUniqueColumnNames(t *testing.T) {
	cols := func(names ...string) []engine.Column {
		out := make([]engine.Column, len(names))
		for i, n := range names {
			out[i].Name = n
		}
		return out
	}
	cases := []struct {
		in, want []string
	}{
		{[]string{"id", "ID", "Id"}, []string{"id", "ID_2", "Id_3"}},
		{[]string{"", "a"}, []string{"column_1", "a"}},
		{[]string{"a", "a", "a_2"}, []string{"a", "a_3", "a_2"}},
	}
	for _, tc := range cases {
		if got := uniqueColumnNames(cols(tc.in...)); !reflect.DeepEqual(got, tc.want) {
			t.Errorf("%q -> %q, want %q", tc.in, got, tc.want)
		}
	}
}
