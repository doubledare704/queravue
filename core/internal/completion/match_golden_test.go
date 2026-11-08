package completion

import (
	"encoding/json"
	"flag"
	"os"
	"testing"
)

var updateMatchGolden = flag.Bool("update-match", false, "rewrite testdata/match_cases.json")

type matchCase struct {
	Prefix string `json:"prefix"`
	Name   string `json:"name"`
	Class  int    `json:"class"`
}

var matchInputs = [][2]string{
	{"", "anything"}, {"ord", "orders"}, {"ORD", "orders"}, {"oi", "order_items"}, {"oi", "OrderItems"}, {"ci", "customer_id"},
	{"id", "customer_id"}, {"cid", "customer_id"}, {"item", "order_items"}, {"ordit", "order_items"}, {"ot", "order_items"},
	{"xyz", "orders"}, {"rdr", "orders"}, {"sku", "items.[].sku"}, {"city", "address.city"}, {"ac", "address.city"},
	{"$g", "$gt"}, {"gt", "$gt"}, {"na", "name"}, {"ame", "name"}, {"nme", "name"}, {"nmx", "name"}, {"é", "école"},
	{"ab1", "ab12"}, {"a1", "ab12"}, {"UP", "updatedAt"}, {"ua", "updatedAt"}, {"at", "updatedAt"}, {"created", "createdAt"},
	{"cra", "createdAt"}, {"x", ""}, {"name", "name"}, {"names", "name"},
}

func TestMatchNameAgreesWithTheSharedGolden(t *testing.T) {
	var got []matchCase
	for _, in := range matchInputs {
		class, ok := matchName(in[0], in[1])
		if !ok {
			class = -1
		}
		got = append(got, matchCase{in[0], in[1], class})
	}
	const path = "testdata/match_cases.json"
	if *updateMatchGolden {
		b, err := json.MarshalIndent(got, "", "  ")
		if err != nil {
			t.Fatal(err)
		}
		if err := os.MkdirAll("testdata", 0o750); err != nil {
			t.Fatal(err)
		}
		if err := os.WriteFile(path, append(b, '\n'), 0o600); err != nil {
			t.Fatal(err)
		}
		return
	}
	raw, err := os.ReadFile(path)
	if err != nil {
		t.Fatal(err)
	}
	var want []matchCase
	if err := json.Unmarshal(raw, &want); err != nil {
		t.Fatal(err)
	}
	if len(want) != len(got) {
		t.Fatalf("golden has %d cases, test has %d; run go test -update-match", len(want), len(got))
	}
	for i := range got {
		if got[i] != want[i] {
			t.Errorf("case %d = %+v, golden %+v", i, got[i], want[i])
		}
	}
}
