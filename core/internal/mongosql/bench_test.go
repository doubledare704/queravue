package mongosql

import (
	"os"
	"path/filepath"
	"sort"
	"strings"
	"testing"
	"time"

	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

const maxLatencySamples = 1 << 20

func corpusByOutcome(tb testing.TB) map[string][]string {
	tb.Helper()
	files, err := filepath.Glob(filepath.Join("testdata", "corpus", "*.sql"))
	if err != nil {
		tb.Fatal(err)
	}
	groups := map[string][]string{}
	for _, file := range files {
		src, err := os.ReadFile(file)
		if err != nil {
			tb.Fatal(err)
		}
		sql := string(src)
		resp := Translate(corpusDatabase, sql)
		outcome := strings.ToLower(strings.TrimPrefix(resp.GetKind().String(), "MONGO_SQL_RESULT_KIND_"))
		if resp.GetError() != nil {
			outcome = "rejected"
		}
		groups[outcome] = append(groups[outcome], sql)
	}
	return groups
}

func percentile(sorted []time.Duration, p float64) float64 {
	return float64(sorted[int(float64(len(sorted)-1)*p)].Nanoseconds())
}

func BenchmarkTranslate(b *testing.B) {
	groups := corpusByOutcome(b)
	for _, outcome := range []string{
		strings.ToLower(strings.TrimPrefix(queravuev1.MongoSqlResultKind_MONGO_SQL_RESULT_KIND_FIND.String(), "MONGO_SQL_RESULT_KIND_")),
		strings.ToLower(strings.TrimPrefix(queravuev1.MongoSqlResultKind_MONGO_SQL_RESULT_KIND_AGGREGATE.String(), "MONGO_SQL_RESULT_KIND_")),
		"rejected",
	} {
		queries := groups[outcome]
		b.Run(outcome, func(b *testing.B) {
			samples := make([]time.Duration, 0, min(b.N*len(queries), maxLatencySamples))
			b.ResetTimer()
			for range b.N {
				for _, sql := range queries {
					start := time.Now()
					Translate(corpusDatabase, sql)
					if len(samples) < maxLatencySamples {
						samples = append(samples, time.Since(start))
					}
				}
			}
			b.StopTimer()
			sort.Slice(samples, func(i, j int) bool { return samples[i] < samples[j] })
			b.ReportMetric(percentile(samples, 0.50), "p50-ns/query")
			b.ReportMetric(percentile(samples, 0.95), "p95-ns/query")
			b.ReportMetric(float64(len(queries)), "queries")
		})
	}
}
