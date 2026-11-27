//go:build integration

package mongo_test

import (
	"context"
	"fmt"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/engine"
	"github.com/doubledare704/queravue/core/internal/engine/enginetest"
	"github.com/doubledare704/queravue/core/internal/engine/mongo"
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
	const database, collection = "queravue", "qv_perf_load"
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Minute)
	defer cancel()
	conn, err := mongo.New(mongo.VariantMongoDB).Connect(ctx, localConfig(), engine.Secret{})
	if err != nil {
		t.Fatal(err)
	}
	t.Cleanup(func() { _ = conn.Close() })
	drop := func() {
		if err := dropCollection(context.Background(), conn, database, collection); err != nil {
			t.Errorf("drop: %v", err)
		}
	}
	drop()
	t.Cleanup(drop)

	src := enginetest.NewRepeatingDocumentSource(perfDocumentBatch(), enginetest.LoadPerfRows)
	sampler := enginetest.StartRSSSampler(t)
	start := time.Now()
	stats, err := conn.(engine.DocumentLoader).LoadDocuments(ctx, database, collection, src)
	elapsed := time.Since(start)
	baseline, peak := sampler.Stop()
	if err != nil {
		t.Fatal(err)
	}
	rate := float64(stats.Rows) / elapsed.Seconds()
	t.Logf("mongo: %d documents in %d inserts, %.2fs, %.0f docs/s, RSS baseline %.1f MiB, peak %.1f MiB (+%.1f)",
		stats.Rows, stats.Batches, elapsed.Seconds(), rate, baseline, peak, peak-baseline)

	n, err := conn.(engine.DocumentStore).Count(ctx, database, collection, `{"_id":{"$exists":true}}`, 0)
	if err != nil || n.N != enginetest.LoadPerfRows {
		t.Errorf("%d documents stored (%v), want %d", n.N, err, enginetest.LoadPerfRows)
	}
	if rate < enginetest.LoadMongoMinRate {
		t.Errorf("%.0f docs/s is below the %d docs/s gate", rate, enginetest.LoadMongoMinRate)
	}
	if peak > baseline+enginetest.LoadRSSBudgetMiB {
		t.Errorf("RSS peak %.1f MiB exceeds baseline %.1f + %d MiB", peak, baseline, enginetest.LoadRSSBudgetMiB)
	}
}
