//go:build duckdb

package engines

import "testing"

func TestDuckDBIsRegisteredWithItsBuildTag(t *testing.T) {
	reg, err := Registry()
	if err != nil {
		t.Fatal(err)
	}
	if _, ok := reg.Get("duckdb"); !ok {
		t.Fatal("duckdb is not registered")
	}
}
