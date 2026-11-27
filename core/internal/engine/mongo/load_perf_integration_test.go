//go:build integration

package mongo

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/enginetest"
)

const perfDocsPerBatch = 5_000

func perfDocumentBatch() []engine.Document {
	docs := make([]engine.Document, perfDocsPerBatch)
	for i := range docs {
		docs[i] = fmt.Sprintf(`{"customer":"customer %d","amount":{"$numberDecimal":"%d.%02d"},"created":{"$date":{"$numberLong":"%d"}},"active":%t,"tags":["alpha","beta"],"payload":"a payload of about forty characters"}`,
			i, i, i%100, 1700000000000+int64(i)*1000, i%2 == 0)
	}
	return docs
}

// LOAD_PERF=1 go test -tags=integration -run TestIntegrationLoadDocumentsPerf -v ./internal/engine/mongo/
func TestIntegrationLoadDocumentsPerf(t *testing.T) {
	enginetest.SkipUnlessLoadPerf(t)
	c := connect(t)
	const collection = "qv_perf_load"
	client, err := c.live("perf")
	if err != nil {
		t.Fatal(err)
	}
	coll := client.Database("queravue").Collection(collection)
	_ = coll.Drop(context.Background())
	t.Cleanup(func() { _ = coll.Drop(context.Background()) })

	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
	defer cancel()
	src := enginetest.NewRepeatingDocumentSource(perfDocumentBatch(), enginetest.LoadPerfRows)
	sampler := enginetest.StartRSSSampler(t)
	start := time.Now()
	stats, err := c.LoadDocuments(ctx, "queravue", collection, src)
	elapsed := time.Since(start)
	baseline, peak := sampler.Stop()
	if err != nil {
		t.Fatal(err)
	}
	rate := float64(stats.Rows) / elapsed.Seconds()
	t.Logf("mongo: %d documents in %d inserts, %.2fs, %.0f docs/s, RSS baseline %.1f MiB, peak %.1f MiB (+%.1f)",
		stats.Rows, stats.Batches, elapsed.Seconds(), rate, baseline, peak, peak-baseline)

	n, err := coll.CountDocuments(ctx, struct{}{})
	if err != nil || n != enginetest.LoadPerfRows {
		t.Errorf("%d documents stored (%v), want %d", n, err, enginetest.LoadPerfRows)
	}
	if rate < enginetest.LoadMongoMinRate {
		t.Errorf("%.0f docs/s is below the %d docs/s gate", rate, enginetest.LoadMongoMinRate)
	}
	if peak > baseline+enginetest.LoadRSSBudgetMiB {
		t.Errorf("RSS peak %.1f MiB exceeds baseline %.1f + %d MiB", peak, baseline, enginetest.LoadRSSBudgetMiB)
	}
}
