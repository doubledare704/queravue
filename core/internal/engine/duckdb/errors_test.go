package duckdb

import (
	"context"
	"errors"
	"strings"
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func driverError(message string) error { return errors.New(message) }

func TestClassify(t *testing.T) {
	tests := []struct {
		name string
		err  error
		want engine.Kind
	}{
		{"syntax", driverError("Parser Error: syntax error at or near \"selec\""), engine.KindSQL},
		{"missing table", driverError("Catalog Error: Table with name x does not exist!"), engine.KindSQL},
		{"conversion", driverError("Conversion Error: Could not convert string 'a' to INT32"), engine.KindSQL},
		{"constraint", driverError("Constraint Error: Duplicate key \"id: 1\" violates primary key constraint"), engine.KindSQL},
		{"interrupt", driverError("INTERRUPT Error: Interrupted!"), engine.KindCanceled},
		{"context", context.Canceled, engine.KindCanceled},
		{"missing file", driverError(`IO Error: Cannot open file "/x/a.duckdb": No such file or directory`), engine.KindNotFound},
		{"missing read-only", driverError(`IO Error: Cannot open database "/x/a.duckdb" in read-only mode: database does not exist`), engine.KindNotFound},
		{"not a database", driverError(`IO Error: The file "/x/a.duckdb" exists, but it is not a valid DuckDB database file!`), engine.KindInvalidConfig},
		{"read-only write", driverError(`Invalid Input Error: Cannot execute statement of type "CREATE" on database "x" which is attached in read-only mode!`), engine.KindAuth},
		{"other settings", driverError("Connection Error: Can't open a connection to same database file with a different configuration than existing connections"), engine.KindInvalidConfig},
	}
	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			if got := classify("op", tt.err); got.Kind != tt.want {
				t.Errorf("kind = %v, want %v", got.Kind, tt.want)
			}
		})
	}
}

func TestClassifyFileLockedIsTypedAndExplained(t *testing.T) {
	raw := driverError(`IO Error: Could not set lock on file "/data/a.duckdb": Conflicting lock is held in /usr/bin/duckdb (PID 4242) by user me. See also https://duckdb.org/docs/connect/concurrency`)
	got := classify("connect", raw)
	if got.Kind != engine.KindTimeout || !errors.Is(got, ErrFileLocked) {
		t.Fatalf("kind = %v, locked = %v", got.Kind, errors.Is(got, ErrFileLocked))
	}
	for _, want := range []string{"locked by another process", "one writer", "read-only", "PID 4242"} {
		if !strings.Contains(got.Msg, want) {
			t.Errorf("message %q lacks %q", got.Msg, want)
		}
	}
	if strings.Contains(got.Msg, "https://") {
		t.Errorf("message keeps the docs link: %q", got.Msg)
	}
}

func TestDescriptorReportsNoNetworkPath(t *testing.T) {
	d := descriptor()
	if d.SupportsSSH || d.SupportsTLS {
		t.Errorf("a file engine reports SSH %v / TLS %v", d.SupportsSSH, d.SupportsTLS)
	}
	if err := d.Validate(engine.Config{EngineID: ID, Params: map[string]string{ParamPath: MemoryPath}}); err != nil {
		t.Errorf("memory config: %v", err)
	}
}
