//go:build integration

package shell_test

import (
	"context"
	"os"
	"strings"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/mongo"
	"github.com/doubledare704/queravue/core/internal/shell"
)

// TestSmokeShellDocumentDB runs a short script on a DocumentDB-compatible
// server. QV_DOCDB_URI holds the connection URI (see `make test-docdb`).
func TestSmokeShellDocumentDB(t *testing.T) {
	uri := os.Getenv("QV_DOCDB_URI")
	if uri == "" {
		t.Skip("QV_DOCDB_URI not set")
	}
	e := mongo.New(mongo.VariantDocumentDB)
	cfg, secret, err := e.ParseURI(uri)
	if err != nil {
		t.Fatal(err)
	}
	ctx, cancel := context.WithTimeout(context.Background(), 2*time.Minute)
	defer cancel()
	conn, err := e.Connect(ctx, cfg, secret)
	if err != nil {
		t.Fatalf("connect: %v", err)
	}
	defer func() { _ = conn.Close() }()
	backend, ok := engine.As[engine.ShellBackend](conn)
	if !ok {
		t.Fatal("not a shell backend")
	}
	const db = "queravue_shell_smoke"
	dropDatabases(ctx, backend, db)
	t.Cleanup(func() { dropDatabases(context.Background(), backend, db) })

	sh, err := shell.New(backend, shell.Options{Database: db})
	if err != nil {
		t.Fatal(err)
	}
	defer sh.Close()
	tr := &transcript{shell: sh, ctx: ctx}
	script := `
db.t.insertMany([{_id: 1, k: "a", n: 1}, {_id: 2, k: "b", n: 2}, {_id: 3, k: "a", n: 3}]);
db.t.updateOne({_id: 1}, {$inc: {n: 10}});
db.t.deleteOne({_id: 2});
var grouped = db.t.aggregate([{$group: {_id: "$k", n: {$sum: "$n"}}}, {$sort: {_id: 1}}]).toArray();
print(db.t.countDocuments() + " " + db.t.find().sort({_id: 1}).toArray().map(function (d) { return d.n; }).join(",") + " " + grouped.length);`
	if _, evalErr := sh.Eval(ctx, script, true, tr); evalErr != nil {
		t.Fatalf("eval: %v", evalErr)
	}
	if got := strings.TrimSpace(tr.b.String()); got != "out: 2 11,3 1" {
		t.Fatalf("output %q", got)
	}
}
