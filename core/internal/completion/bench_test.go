package completion_test

import (
	"context"
	"fmt"
	"slices"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/completion"
	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

var (
	domainWords = []string{"customer", "order", "invoice", "product", "payment", "shipment", "supplier", "employee", "account", "ticket", "campaign", "warehouse", "address", "contract", "session", "document", "category", "inventory", "refund", "review"}
	suffixWords = []string{"", "_item", "_line", "_history", "_log", "_status", "_note", "_tag", "_audit", "_archive", "_map", "_setting", "_event", "_detail", "_summary", "_type", "_group", "_rule", "_batch", "_queue", "_cache", "_draft", "_link", "_stat", "_config"}
	columnKinds = []string{"id:bigint", "name:text", "status:text", "created_at:timestamp", "updated_at:timestamp", "amount:numeric", "quantity:integer", "notes:text", "is_active:boolean", "code:varchar(32)", "email:text", "price:numeric", "owner_id:bigint", "parent_id:bigint", "sort_order:integer"}
)

func generatedCatalog(tables int) *completion.Snapshot {
	var out []*completion.Table
	for i := 0; len(out) < tables; i++ {
		name := domainWords[i%len(domainWords)] + suffixWords[(i/len(domainWords))%len(suffixWords)]
		if i >= len(domainWords)*len(suffixWords) {
			name = fmt.Sprintf("%s_%d", name, i)
		}
		t := &completion.Table{Schema: "public", Name: name, View: i%40 == 39}
		for k, c := range columnKinds {
			cname, typ, _ := cutColumn(c)
			if k > 0 && (i+k)%5 == 0 {
				continue
			}
			t.Columns = append(t.Columns, completion.Column{Name: cname, Type: typ})
		}
		t.Columns = append(t.Columns, completion.Column{Name: domainWords[(i+3)%len(domainWords)] + "_id", Type: "bigint"})
		out = append(out, t)
	}
	return completion.NewSnapshot([]string{"public", "audit", "staging"}, out)
}

func cutColumn(s string) (string, string, bool) {
	for i := 0; i < len(s); i++ {
		if s[i] == ':' {
			return s[:i], s[i+1:], true
		}
	}
	return s, "", false
}

var benchScenarios = []struct{ name, marked string }{
	{"select list empty", "SELECT | FROM customer c JOIN customer_item i ON i.owner_id = c.id JOIN order_line l ON l.owner_id = c.id"},
	{"alias columns", "SELECT c.| FROM customer c JOIN order_line l ON l.owner_id = c.id"},
	{"alias column prefix", "SELECT c.cre| FROM customer c JOIN order_line l ON l.owner_id = c.id"},
	{"from empty", "SELECT * FROM |"},
	{"from prefix", "SELECT * FROM inv|"},
	{"from word initials", "SELECT * FROM ci|"},
	{"where unqualified prefix", "SELECT * FROM customer c JOIN order_line l ON l.owner_id = c.id WHERE sta|"},
	{"keyword start", "sel|"},
	{"cte columns", "WITH r AS (SELECT id, amount FROM invoice) SELECT r.| FROM r"},
}

func BenchmarkCompleteOn500Tables(b *testing.B) {
	snap := generatedCatalog(500)
	for _, sc := range benchScenarios {
		text, cursor := splitCursor(sc.marked)
		req := completion.Request{Dialect: sqlsplit.Postgres, Text: text, Cursor: cursor, MaxItems: 200, Snapshot: snap, Recency: completion.NewRecency()}
		b.Run(sc.name, func(b *testing.B) {
			b.ReportAllocs()
			for i := 0; i < b.N; i++ {
				if _, err := completion.Complete(context.Background(), req); err != nil {
					b.Fatal(err)
				}
			}
		})
	}
}

func TestCompleteP95StaysUnderTenMillisecondsOn500Tables(t *testing.T) {
	if testing.Short() {
		t.Skip("timing test")
	}
	snap := generatedCatalog(500)
	columns := 0
	for _, tb := range snap.Tables() {
		columns += len(tb.Columns)
	}
	if columns < 6000 {
		t.Fatalf("catalog has %d columns, want about 7,500", columns)
	}
	const runs = 400
	for _, sc := range benchScenarios {
		text, cursor := splitCursor(sc.marked)
		req := completion.Request{Dialect: sqlsplit.Postgres, Text: text, Cursor: cursor, MaxItems: 200, Snapshot: snap, Recency: completion.NewRecency()}
		durations := make([]time.Duration, runs)
		for i := range durations {
			start := time.Now()
			if _, err := completion.Complete(context.Background(), req); err != nil {
				t.Fatal(err)
			}
			durations[i] = time.Since(start)
		}
		slices.Sort(durations)
		p95 := durations[runs*95/100]
		t.Logf("%-26s p50 %-10v p95 %v", sc.name, durations[runs/2], p95)
		if p95 > 10*time.Millisecond {
			t.Errorf("%s: p95 = %v, budget 10ms", sc.name, p95)
		}
	}
}
