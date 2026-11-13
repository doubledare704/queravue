package diagram

import (
	"testing"

	"github.com/doubledare704/queravue/core/internal/engine"
)

func path(p string, frequency float64, types ...engine.FieldType) engine.FieldPathStat {
	return engine.FieldPathStat{Path: p, Frequency: frequency, Types: types}
}

func typed(name string, count uint32) engine.FieldType {
	return engine.FieldType{Type: name, Count: count}
}

func shopSamples() ([]engine.SchemaObject, map[string]engine.FieldPathSample) {
	objects := []engine.SchemaObject{
		{Name: "categories", Type: engine.ObjectTypeCollection},
		{Name: "customers", Type: engine.ObjectTypeCollection, EstimatedRows: 40},
		{Name: "order_totals", Type: engine.ObjectTypeView},
		{Name: "orders", Type: engine.ObjectTypeCollection},
		{Name: "products", Type: engine.ObjectTypeCollection},
		{Name: "empty", Type: engine.ObjectTypeCollection},
	}
	samples := map[string]engine.FieldPathSample{
		"categories": {Paths: []engine.FieldPathStat{
			path("_id", 1, typed("objectId", 10)),
			path("parent_category_id", 0.5, typed("objectId", 5)),
		}},
		"customers": {Paths: []engine.FieldPathStat{
			path("name", 1, typed("string", 10)),
			path("_id", 1, typed("objectId", 10)),
			path("email", 0.8, typed("string", 8)),
		}},
		"order_totals": {Paths: []engine.FieldPathStat{
			path("_id", 1, typed("objectId", 3)),
			path("customerId", 1, typed("objectId", 3)),
		}},
		"orders": {Paths: []engine.FieldPathStat{
			path("_id", 1, typed("objectId", 10)),
			path("customerId", 1, typed("objectId", 10)),
			path("items", 1, typed("array", 10)),
			path("items.[]", 1, typed("object", 10)),
			path("items.[].product_id", 1, typed("string", 10)),
			path("items.[].categoryIds.[]", 0.4, typed("objectId", 4)),
			path("status", 1, typed("string", 10)),
			path("note", 0.2, typed("string", 1), typed("null", 1)),
			path("shipper", 0.3, typed("objectId", 3)),
			path("emptyId", 0.3, typed("objectId", 3)),
		}},
		"products": {Paths: []engine.FieldPathStat{
			path("_id", 1, typed("string", 10)),
			path("customer", 0.5, typed("string", 5)),
		}},
	}
	return objects, samples
}

func tableNamed(g *Graph, name string) Table {
	for _, t := range g.Tables {
		if t.Name == name {
			return t
		}
	}
	return Table{}
}

func TestInferColumnsComeFromTheSample(t *testing.T) {
	g := Infer(shopSamples())
	customers := tableNamed(g, "customers")
	var names []string
	for _, c := range customers.Columns {
		names = append(names, c.Name)
	}
	if want := []string{"_id", "name", "email"}; !equal(names, want) {
		t.Errorf("columns = %v, want %v", names, want)
	}
	id, email := customers.Columns[0], customers.Columns[2]
	if id.PrimaryKeyOrder != 1 || id.Nullable || id.TypeName != "objectId" {
		t.Errorf("_id = %+v", id)
	}
	if !email.Nullable || email.PrimaryKeyOrder != 0 {
		t.Errorf("email seen in 80%% of documents = %+v", email)
	}
	if customers.EstimatedRows != 40 || customers.Type != engine.ObjectTypeCollection {
		t.Errorf("object fields lost: %+v", customers)
	}
	note := tableNamed(g, "orders").Columns
	for _, c := range note {
		if c.Name == "note" && (c.TypeName != "string" || !c.Nullable) {
			t.Errorf("note = %+v, want string and nullable", c)
		}
	}
	if empty := tableNamed(g, "empty"); len(empty.Columns) != 0 || len(empty.Relations) != 0 {
		t.Errorf("an unsampled collection = %+v", empty)
	}
}

func TestInferRelationsFromNamesAndTypes(t *testing.T) {
	g := Infer(shopSamples())
	type edge struct {
		from, column, to string
		confidence       float64
	}
	var got []edge
	for _, tb := range g.Tables {
		for _, r := range tb.Relations {
			if !r.Inferred || r.Name != "" || len(r.ReferencedColumns) != 1 || r.ReferencedColumns[0] != "_id" {
				t.Errorf("%s relation not marked inferred to _id: %+v", tb.Name, r)
			}
			got = append(got, edge{tb.Name, r.Columns[0], r.ReferencedTable, r.Confidence})
		}
	}
	want := []edge{
		{"categories", "parent_category_id", "categories", 0.7},
		{"order_totals", "customerId", "customers", 0.9},
		{"orders", "customerId", "customers", 0.9},
		{"orders", "items.[].product_id", "products", 0.6},
		{"orders", "items.[].categoryIds.[]", "categories", 0.9},
		{"orders", "emptyId", "empty", 0.5},
	}
	if len(got) != len(want) {
		t.Fatalf("relations = %+v\nwant %+v", got, want)
	}
	for i := range want {
		if got[i] != want[i] {
			t.Errorf("relation %d = %+v, want %+v", i, got[i], want[i])
		}
	}
}

func TestReferenceStem(t *testing.T) {
	tests := []struct {
		path  string
		stem  string
		named bool
	}{
		{"customerId", "customer", true},
		{"customer_id", "customer", true},
		{"customerID", "customer", true},
		{"tagIds.[]", "tag", true},
		{"tag_ids", "tag", true},
		{"customer._id", "customer", true},
		{"lines.[].sku", "sku", false},
		{"_id", "", false},
		{"Id", "Id", false},
	}
	for _, tt := range tests {
		stem, named := referenceStem(tt.path)
		if stem != tt.stem || named != tt.named {
			t.Errorf("referenceStem(%q) = %q, %v; want %q, %v", tt.path, stem, named, tt.stem, tt.named)
		}
	}
}

func TestTargetLookupNeedsOneMatch(t *testing.T) {
	objects := []engine.SchemaObject{
		{Name: "person"}, {Name: "boxes"}, {Name: "boxs"}, {Name: "statuses"},
		{Name: "companies"}, {Name: "Order-Lines"}, {Name: "report", Type: engine.ObjectTypeView},
	}
	idx := newTargetIndex(objects, nil)
	tests := []struct {
		stem, want string
	}{
		{"person", "person"},
		{"persons", "person"},
		{"box", ""},
		{"boxes", "boxes"},
		{"company", "companies"},
		{"orderLine", "Order-Lines"},
		{"order_line", "Order-Lines"},
		{"report", ""},
		{"status", "statuses"},
		{"shipper", ""},
	}
	for _, tt := range tests {
		got, ok := idx.lookup(tt.stem)
		if got.collection != tt.want || ok != (tt.want != "") {
			t.Errorf("lookup(%q) = %q, %v; want %q", tt.stem, got.collection, ok, tt.want)
		}
	}
}

func TestLookupByLastWordsOnlyForIDNames(t *testing.T) {
	idx := newTargetIndex([]engine.SchemaObject{{Name: "categories"}, {Name: "users"}}, nil)
	tests := []struct {
		stem      string
		named     bool
		want      string
		shortened bool
	}{
		{"parent_category", true, "categories", true},
		{"createdByUser", true, "users", true},
		{"ownerUser", false, "", false},
		{"user", false, "users", false},
	}
	for _, tt := range tests {
		got, shortened, ok := idx.lookupByLastWords(tt.stem, tt.named)
		if got.collection != tt.want || shortened != tt.shortened || ok != (tt.want != "") {
			t.Errorf("lookupByLastWords(%q, %v) = %q, %v, %v", tt.stem, tt.named, got.collection, shortened, ok)
		}
	}
	if words := nameWords("parent_categoryID-x"); !equal(words, []string{"parent", "category", "ID", "x"}) {
		t.Errorf("nameWords = %v", words)
	}
}

func TestSampleSizeOf(t *testing.T) {
	for requested, want := range map[uint32]uint32{0: 100, 1: 1, 250: 250, 1000: 1000, 50_000: 1000} {
		if got := SampleSizeOf(requested); got != want {
			t.Errorf("SampleSizeOf(%d) = %d, want %d", requested, got, want)
		}
	}
}

func equal(a, b []string) bool {
	if len(a) != len(b) {
		return false
	}
	for i := range a {
		if a[i] != b[i] {
			return false
		}
	}
	return true
}
