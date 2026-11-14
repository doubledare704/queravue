//go:build !duckdb

package engines

import "testing"

func TestDuckDBIsNotRegisteredWithoutItsBuildTag(t *testing.T) {
	for _, e := range All() {
		if e.Descriptor().ID == "duckdb" {
			t.Fatal("the default build registers duckdb")
		}
	}
}
