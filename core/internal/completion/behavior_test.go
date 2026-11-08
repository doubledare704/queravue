package completion_test

import (
	"context"
	"math/rand"
	"strings"
	"testing"
	"time"

	"github.com/doubledare704/queravue/core/internal/completion"
	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

var allDialects = []sqlsplit.Dialect{sqlsplit.Postgres, sqlsplit.MySQL, sqlsplit.MSSQL, sqlsplit.SQLite}

func complete(t *testing.T, d sqlsplit.Dialect, marked string, opts ...func(*completion.Request)) completion.Result {
	t.Helper()
	text, cursor := splitCursor(marked)
	req := completion.Request{Dialect: d, Text: text, Cursor: cursor, MaxItems: 1000, Snapshot: snapshotFor(d)}
	for _, o := range opts {
		o(&req)
	}
	res, err := completion.Complete(context.Background(), req)
	if err != nil {
		t.Fatal(err)
	}
	return res
}

func TestCompleteReplaceRangeCoversTheWordUnderTheCursor(t *testing.T) {
	text, cursor := splitCursor("SELECT * FROM customers c WHERE c.na|me = 1")
	res, err := completion.Complete(context.Background(), completion.Request{Dialect: sqlsplit.Postgres, Text: text, Cursor: cursor, Snapshot: snapshotFor(sqlsplit.Postgres)})
	if err != nil {
		t.Fatal(err)
	}
	it := res.Items[0]
	if it.Label != "name" || text[it.ReplaceStart:it.ReplaceEnd] != "name" {
		t.Errorf("first item %q replaces %q, want name over name", it.Label, text[it.ReplaceStart:it.ReplaceEnd])
	}
}

func TestCompleteOffsetsAreUTF16(t *testing.T) {
	res := complete(t, sqlsplit.Postgres, "SELECT 'é😀', c.na| FROM customers c")
	it := res.Items[0]
	const prefix = "SELECT 'é😀', c."
	wantStart := len([]rune(prefix)) + 1
	if it.Label != "name" || it.ReplaceStart != wantStart || it.ReplaceEnd != wantStart+2 {
		t.Errorf("item %q range [%d,%d), want name [%d,%d)", it.Label, it.ReplaceStart, it.ReplaceEnd, wantStart, wantStart+2)
	}
}

func TestCompleteInsertTextQuotesOnlyWhenNeeded(t *testing.T) {
	tables := []*completion.Table{{Schema: "public", Name: "Mixed Case", Columns: cols("select:text plain:text MixedCol:text")}}
	snap := completion.NewSnapshot([]string{"public"}, tables)
	tests := []struct {
		d      sqlsplit.Dialect
		marked string
		want   map[string]string
	}{
		{sqlsplit.Postgres, `SELECT * FROM |`, map[string]string{"Mixed Case": `"Mixed Case"`}},
		{sqlsplit.Postgres, `SELECT m.| FROM "Mixed Case" m`, map[string]string{"select": `"select"`, "plain": "plain", "MixedCol": `"MixedCol"`}},
		{sqlsplit.MySQL, "SELECT m.| FROM `Mixed Case` m", map[string]string{"select": "`select`", "plain": "plain", "MixedCol": "MixedCol"}},
		{sqlsplit.MSSQL, `SELECT m.| FROM [Mixed Case] m`, map[string]string{"select": "[select]", "plain": "plain"}},
		{sqlsplit.SQLite, `SELECT m.| FROM "Mixed Case" m`, map[string]string{"select": `"select"`, "plain": "plain"}},
		{sqlsplit.Postgres, `SELECT * FROM "Mix|`, map[string]string{"Mixed Case": `"Mixed Case"`}},
		{sqlsplit.MySQL, "SELECT * FROM `Mix|", map[string]string{"Mixed Case": "`Mixed Case`"}},
		{sqlsplit.MSSQL, `SELECT * FROM [Mix|`, map[string]string{"Mixed Case": "[Mixed Case]"}},
	}
	for _, tc := range tests {
		res := complete(t, tc.d, tc.marked, func(r *completion.Request) { r.Snapshot = snap })
		got := map[string]string{}
		for _, it := range res.Items {
			got[it.Label] = it.InsertText
		}
		for label, want := range tc.want {
			if got[label] != want {
				t.Errorf("%v %q: insert for %s = %q, want %q", tc.d, tc.marked, label, got[label], want)
			}
		}
	}
}

func TestCompleteQuotedPrefixReplacesFromTheQuote(t *testing.T) {
	text, cursor := splitCursor(`SELECT * FROM "cus|`)
	res, err := completion.Complete(context.Background(), completion.Request{Dialect: sqlsplit.Postgres, Text: text, Cursor: cursor, Snapshot: snapshotFor(sqlsplit.Postgres)})
	if err != nil {
		t.Fatal(err)
	}
	var it completion.Item
	for _, candidate := range res.Items {
		if candidate.Label == "customers" {
			it = candidate
		}
	}
	if it.Label != "customers" || it.InsertText != `"customers"` || text[it.ReplaceStart:it.ReplaceEnd] != `"cus` {
		t.Errorf("item %+v replaces %q", it, text[it.ReplaceStart:it.ReplaceEnd])
	}
}

func TestCompleteSortKeysAreAscendingInResultOrder(t *testing.T) {
	res := complete(t, sqlsplit.Postgres, "SELECT | FROM orders o JOIN customers c ON c.id = o.customer_id")
	for i := 1; i < len(res.Items); i++ {
		if res.Items[i-1].SortKey > res.Items[i].SortKey {
			t.Fatalf("sort keys out of order at %d: %q > %q", i, res.Items[i-1].SortKey, res.Items[i].SortKey)
		}
	}
}

func TestCompleteMaxItemsCutsAndFlagsIncomplete(t *testing.T) {
	res := complete(t, sqlsplit.Postgres, "SELECT | FROM customers", func(r *completion.Request) { r.MaxItems = 5 })
	if len(res.Items) != 5 || !res.Incomplete {
		t.Errorf("items = %d, incomplete = %v; want 5, true", len(res.Items), res.Incomplete)
	}
	all := complete(t, sqlsplit.Postgres, "SELECT c.| FROM customers c")
	if all.Incomplete {
		t.Error("a short list must not be flagged incomplete")
	}
}

func TestCompleteReportsCatalogState(t *testing.T) {
	text, cursor := splitCursor("SELECT * FROM |")
	res, err := completion.Complete(context.Background(), completion.Request{Dialect: sqlsplit.Postgres, Text: text, Cursor: cursor})
	if err != nil {
		t.Fatal(err)
	}
	if res.State != completion.StateCold || len(res.Items) == 0 {
		t.Errorf("without a catalog: state %v, %d items; want cold with keywords", res.State, len(res.Items))
	}
	if ready := complete(t, sqlsplit.Postgres, "SELECT * FROM |"); ready.State != completion.StateReady {
		t.Errorf("state = %v, want ready", ready.State)
	}
}

func TestCompleteHonoursCancellation(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	_, err := completion.Complete(ctx, completion.Request{Dialect: sqlsplit.Postgres, Text: "SELECT ", Cursor: 7, Snapshot: snapshotFor(sqlsplit.Postgres)})
	if err == nil {
		t.Error("a cancelled context must stop completion")
	}
}

func TestCompleteBoostsRecentlyUsedNames(t *testing.T) {
	rec := completion.NewRecency()
	withRecency := func(r *completion.Request) { r.Recency = rec }
	before := complete(t, sqlsplit.Postgres, "SELECT * FROM |", withRecency)
	if before.Items[0].Label != "categories" {
		t.Fatalf("baseline first = %q", before.Items[0].Label)
	}
	complete(t, sqlsplit.Postgres, "SELECT * FROM products p WHERE p.name = 'x'|", withRecency)
	after := complete(t, sqlsplit.Postgres, "SELECT * FROM |", withRecency)
	if after.Items[0].Label != "products" {
		t.Errorf("first after use = %q, want products", after.Items[0].Label)
	}
	prefixed := complete(t, sqlsplit.Postgres, "SELECT * FROM c|", withRecency)
	if prefixed.Items[0].Label == "products" {
		t.Error("recency must not outrank a prefix match")
	}
}

func TestMatchClassesRankPrefixBeforeWordBeforeFuzzy(t *testing.T) {
	tables := []*completion.Table{
		{Schema: "public", Name: "invoice_items"},
		{Schema: "public", Name: "item"},
		{Schema: "public", Name: "xitemx"},
		{Schema: "public", Name: "ingredient_team_xs"},
		{Schema: "public", Name: "userAccounts"},
	}
	snap := completion.NewSnapshot([]string{"public"}, tables)
	opt := func(r *completion.Request) { r.Snapshot = snap }
	if got := labels(complete(t, sqlsplit.Postgres, "SELECT * FROM item|", opt).Items)[:3]; strings.Join(got, ",") != "item,invoice_items,xitemx" {
		t.Errorf("item ranking = %v", got)
	}
	if got := labels(complete(t, sqlsplit.Postgres, "SELECT * FROM ua|", opt).Items)[0]; got != "userAccounts" {
		t.Errorf("camelCase initials: first = %q", got)
	}
	if got := labels(complete(t, sqlsplit.Postgres, "SELECT * FROM ii|", opt).Items)[0]; got != "invoice_items" {
		t.Errorf("underscore words: first = %q", got)
	}
}

func TestAnalyzeNeverFailsOnRandomInput(t *testing.T) {
	alphabet := []string{"SELECT", "FROM", "WHERE", "JOIN", "ON", "(", ")", ",", ".", "'", `"`, "`", "[", "]", "--", "/*", "*/", "WITH", "AS", "UNION", "INSERT", "INTO", "UPDATE", "SET", "x", "o", " ", "\n", "é", "$$", ";", "*", "=", "1"}
	rng := rand.New(rand.NewSource(1))
	for i := 0; i < 3000; i++ {
		var b strings.Builder
		for n := rng.Intn(30); n > 0; n-- {
			b.WriteString(alphabet[rng.Intn(len(alphabet))])
		}
		text := b.String()
		for _, d := range allDialects {
			res, err := completion.Complete(context.Background(), completion.Request{Dialect: d, Text: text, Cursor: rng.Intn(len(text) + 2), Snapshot: snapshotFor(d)})
			if err != nil {
				t.Fatalf("%q: %v", text, err)
			}
			_ = res
		}
	}
}

func FuzzCompleteNeverPanics(f *testing.F) {
	for _, seed := range []string{"SELECT c.| FROM customers c", "WITH a AS (SELECT", "((((", "'", "INSERT INTO t (", "é😀"} {
		f.Add(seed, 3)
	}
	f.Fuzz(func(t *testing.T, text string, cursor int) {
		for _, d := range allDialects {
			if _, err := completion.Complete(context.Background(), completion.Request{Dialect: d, Text: text, Cursor: cursor, Snapshot: snapshotFor(d)}); err != nil {
				t.Fatal(err)
			}
		}
	})
}

func TestRecencyIgnoresOldUse(t *testing.T) {
	rec := completion.NewRecency()
	rec.Touch("products")
	rec.SetClock(func() time.Time { return time.Now().Add(2 * time.Hour) })
	res := complete(t, sqlsplit.Postgres, "SELECT * FROM |", func(r *completion.Request) { r.Recency = rec })
	if res.Items[0].Label != "categories" {
		t.Errorf("old use boosted %q", res.Items[0].Label)
	}
}
