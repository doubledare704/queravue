package completion

import (
	"context"
	"errors"
	"slices"
	"strings"
	"testing"
	"unicode/utf16"

	"github.com/doubledare704/queravue/core/internal/engine"
)

type fakeMongoSource struct {
	collections []string
	sample      engine.FieldPathSample
	notReady    bool
	failPaths   bool
}

func (f fakeMongoSource) Collections(context.Context, string) ([]string, error) {
	return f.collections, nil
}

func (f fakeMongoSource) FieldPaths(context.Context, string, string) (engine.FieldPathSample, bool, error) {
	if f.failPaths {
		return engine.FieldPathSample{}, false, errors.New("boom")
	}
	return f.sample, !f.notReady, nil
}

func stat(path string, freq float64, types ...string) engine.FieldPathStat {
	s := engine.FieldPathStat{Path: path, Frequency: freq}
	for i, t := range types {
		s.Types = append(s.Types, engine.FieldType{Type: t, Count: uint32(10 - i)})
	}
	return s
}

func testSource() fakeMongoSource {
	return fakeMongoSource{
		collections: []string{"users", "orders", "order-items", "stats"},
		sample: engine.FieldPathSample{Paths: []engine.FieldPathStat{
			stat("_id", 1, "objectId"), stat("name", 1, "string"), stat("age", 0.9, "int", "string"),
			stat("address", 0.8, "object"), stat("address.city", 0.8, "string"), stat("tags", 0.5, "array"), stat("tags.[]", 0.5, "string"),
			stat("items", 0.4, "array"), stat("items.[]", 0.4, "object"), stat("items.[].sku", 0.4, "string"), stat("items.[].qty", 0.3, "int"),
		}},
	}
}

func completeAt(t *testing.T, shell bool, marked string, src MongoSource) (Result, string) {
	t.Helper()
	text := strings.Replace(marked, "|", "", 1)
	before, _, _ := strings.Cut(marked, "|")
	cursor := len(utf16.Encode([]rune(before)))
	res, err := CompleteMongo(context.Background(), MongoRequest{
		Shell: shell, Text: text, Cursor: cursor, Database: "app", Collection: "users", Source: src,
	})
	if err != nil {
		t.Fatalf("CompleteMongo(%q): %v", marked, err)
	}
	return res, text
}

func labels(res Result) []string {
	out := make([]string, len(res.Items))
	for i, it := range res.Items {
		out[i] = it.Label
	}
	return out
}

func find(res Result, label string) (Item, bool) {
	for _, it := range res.Items {
		if it.Label == label {
			return it, true
		}
	}
	return Item{}, false
}

func TestMongoShellCompletion(t *testing.T) {
	src := testSource()
	tests := []struct {
		name      string
		text      string
		wantFirst string
		want      []string
		notWant   []string
	}{
		{"db members", "db.|", "", []string{"users", "orders", "getCollection", "runCommand"}, nil},
		{"collection prefix", "db.us|", "users", nil, []string{"orders"}},
		{"collection methods", "db.users.|", "", []string{"find", "insertOne", "aggregate"}, []string{"users", "sort"}},
		{"method prefix", "db.users.fi|", "find", []string{"findOne"}, []string{"insertOne"}},
		{"get collection call", `db.getCollection("users").|`, "", []string{"find"}, nil},
		{"bracket access", `db["order-items"].|`, "", []string{"find"}, nil},
		{"cursor methods after find", "db.users.find({}).|", "", []string{"sort", "limit", "skip", "toArray"}, []string{"insertOne"}},
		{"cursor method prefix after chain", "db.users.find().sort({ a: 1 }).li|", "limit", nil, nil},
		{"aggregate returns a cursor", "db.users.aggregate([]).|", "", []string{"toArray"}, nil},
		{"no members after insertOne", "db.users.insertOne({}).|", "", nil, []string{"find", "sort"}},
		{"unknown object has no members", "other.|", "", nil, []string{"find"}},
		{"filter keys", "db.users.find({ |", "", []string{"name", "age", "address.city", "tags", "items.sku", "$and", "$or"}, []string{"tags.[]", "items.[].sku", "$gt"}},
		{"filter key prefix", "db.users.find({ na|", "name", nil, nil},
		{"filter key after comma", `db.users.find({ name: "x", a|`, "age", []string{"address", "address.city"}, nil},
		{"dotted key prefix", "db.users.find({ address.ci|", "address.city", nil, nil},
		{"operator keys", "db.users.find({ age: { |", "", []string{"$gt", "$in", "$exists", "$elemMatch"}, []string{"name", "$and"}},
		{"operator prefix", "db.users.find({ age: { $g|", "$gt", []string{"$gte"}, []string{"$lt"}},
		{"logical array element is a filter", "db.users.find({ $or: [ { |", "", []string{"name", "age"}, nil},
		{"second logical element", "db.users.find({ $or: [ { a: 1 }, { na|", "name", nil, nil},
		{"elemMatch keys are relative", "db.users.find({ items: { $elemMatch: { |", "", []string{"sku", "qty", "$gt"}, []string{"name", "items.sku"}},
		{"scalar array elemMatch has operators only", "db.users.find({ tags: { $elemMatch: { |", "", []string{"$gt", "$eq"}, []string{"name"}},
		{"not value position", "db.users.find({ name: |", "", nil, []string{"name", "$gt"}},
		{"projection keys", "db.users.find({ a: 1 }, { |", "", []string{"name", "age"}, []string{"$and", "$gt"}},
		{"findOne projection", "db.users.findOne({}, { na|", "name", nil, nil},
		{"update operators", "db.users.updateOne({ a: 1 }, { |", "", []string{"$set", "$inc", "$push"}, []string{"name", "$and"}},
		{"update set fields", "db.users.updateOne({ a: 1 }, { $set: { |", "", []string{"name", "address.city"}, []string{"$set"}},
		{"update filter arg", "db.users.updateOne({ |", "", []string{"name", "$and"}, []string{"$set"}},
		{"stage operators", "db.users.aggregate([ { |", "", []string{"$match", "$group", "$lookup"}, []string{"name"}},
		{"second stage", "db.users.aggregate([ { $match: { a: 1 } }, { $so|", "$sort", nil, nil},
		{"match fields", "db.users.aggregate([ { $match: { |", "", []string{"name", "$or"}, []string{"$match"}},
		{"match operators", "db.users.aggregate([ { $match: { age: { |", "", []string{"$gt"}, []string{"name"}},
		{"match logical", "db.users.aggregate([ { $match: { $or: [ { na|", "name", nil, nil},
		{"project fields", "db.users.aggregate([ { $project: { |", "", []string{"name", "age"}, []string{"$and"}},
		{"group id", "db.users.aggregate([ { $group: { |", "", []string{"_id"}, []string{"name"}},
		{"group accumulators", `db.users.aggregate([ { $group: { _id: "$a", total: { |`, "", []string{"$sum", "$avg"}, []string{"name"}},
		{"lookup keys", "db.users.aggregate([ { $lookup: { |", "", []string{"from", "localField", "foreignField", "as"}, []string{"name"}},
		{"sort cursor method fields", "db.users.find().sort({ |", "", []string{"name", "age"}, []string{"$and"}},
		{"globals", "d|", "db", nil, nil},
		{"constructors", "ObjectI|", "ObjectId", nil, nil},
		{"inside string value", `db.users.find({ name: "ab|`, "", nil, []string{"name"}},
		{"inside line comment", "// db.us|", "", nil, []string{"users"}},
		{"inside block comment", "/* db.us|", "", nil, []string{"users"}},
		{"after closed string", `db.users.find({ "name"|`, "", nil, []string{"name"}},
		{"unbalanced earlier text", `db.users.find({ a: ) } ] { na|`, "", nil, nil},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			res, _ := completeAt(t, true, tc.text, src)
			got := labels(res)
			if tc.wantFirst != "" && (len(got) == 0 || got[0] != tc.wantFirst) {
				t.Errorf("first = %v, want %q", firstN(got, 5), tc.wantFirst)
			}
			for _, w := range tc.want {
				if !slices.Contains(got, w) {
					t.Errorf("missing %q in %v", w, firstN(got, 12))
				}
			}
			for _, w := range tc.notWant {
				if slices.Contains(got, w) {
					t.Errorf("unexpected %q in %v", w, firstN(got, 12))
				}
			}
		})
	}
}

func firstN(s []string, n int) []string { return s[:min(n, len(s))] }

func TestMongoKeyInsertTextAndRange(t *testing.T) {
	src := testSource()
	tests := []struct {
		name       string
		shell      bool
		text       string
		label      string
		wantInsert string
		wantStart  int
		wantEnd    int
	}{
		{"plain identifier stays bare in the shell", true, "db.users.find({ na|", "name", "name", 16, 18},
		{"dotted path is quoted in the shell", true, "db.users.find({ ad|", "address.city", `"address.city"`, 16, 18},
		{"operator is bare in the shell", true, "db.users.find({ age: { $g|", "$gt", "$gt", 23, 25},
		{"typed quote is kept", true, `db.users.find({ "na|`, "name", `"name"`, 16, 19},
		{"auto-closed quote is replaced", true, `db.users.find({ "na|"`, "name", `"name"`, 16, 20},
		{"query bar always quotes", false, "{ na|", "name", `"name"`, 2, 4},
		{"query bar operator is quoted", false, `{ "age": { $g|`, "$gt", `"$gt"`, 11, 13},
		{"hyphenated collection uses getCollection", true, "db.order|", "order-items", `getCollection("order-items")`, 3, 8},
		{"collection named like a db method uses getCollection", true, "db.sta|", "stats", `getCollection("stats")`, 3, 6},
		{"method has no parentheses", true, "db.users.fi|", "find", "find", 9, 11},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			res, _ := completeAt(t, tc.shell, tc.text, src)
			it, ok := find(res, tc.label)
			if !ok {
				t.Fatalf("no %q in %v", tc.label, firstN(labels(res), 10))
			}
			if it.InsertText != tc.wantInsert || it.ReplaceStart != tc.wantStart || it.ReplaceEnd != tc.wantEnd {
				t.Errorf("insert %q [%d,%d), want %q [%d,%d)", it.InsertText, it.ReplaceStart, it.ReplaceEnd, tc.wantInsert, tc.wantStart, tc.wantEnd)
			}
		})
	}
}

func TestMongoQueryBarCompletion(t *testing.T) {
	src := testSource()
	tests := []struct {
		name    string
		text    string
		want    []string
		notWant []string
	}{
		{"root keys", "{ |", []string{"name", "address.city", "$and"}, []string{"$gt"}},
		{"operator object", `{ "age": { |`, []string{"$gt", "$in"}, []string{"name"}},
		{"logical element", `{ "$or": [ { |`, []string{"name"}, nil},
		{"empty text", "|", nil, []string{"name"}},
		{"value position", `{ "name": |`, nil, []string{"name"}},
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			res, _ := completeAt(t, false, tc.text, src)
			got := labels(res)
			for _, w := range tc.want {
				if !slices.Contains(got, w) {
					t.Errorf("missing %q in %v", w, firstN(got, 12))
				}
			}
			for _, w := range tc.notWant {
				if slices.Contains(got, w) {
					t.Errorf("unexpected %q", w)
				}
			}
		})
	}
}

func TestMongoFieldsRankByFrequencyThenName(t *testing.T) {
	res, _ := completeAt(t, true, "db.users.find({ |", testSource())
	var fields []string
	for _, it := range res.Items {
		if it.Kind == KindField {
			fields = append(fields, it.Label)
		}
	}
	want := []string{"_id", "name", "age", "address", "address.city", "tags", "items", "items.sku", "items.qty"}
	if !slices.Equal(fields, want) {
		t.Errorf("fields = %v, want %v", fields, want)
	}
}

func TestMongoFieldDetailShowsTypesAndFrequency(t *testing.T) {
	res, _ := completeAt(t, true, "db.users.find({ a|", testSource())
	it, _ := find(res, "age")
	if it.Detail != "int|string · 90%" || it.Kind != KindField {
		t.Errorf("age = %+v", it)
	}
	op, _ := find(res, "$and")
	if op.Kind != KindOperator || op.Detail == "" {
		t.Errorf("$and = %+v", op)
	}
}

func TestMongoPrefixDollarRanksOperatorsFirst(t *testing.T) {
	res, _ := completeAt(t, true, "db.users.find({ $|", testSource())
	if len(res.Items) == 0 || res.Items[0].Kind != KindOperator {
		t.Errorf("items = %v", firstN(labels(res), 5))
	}
}

func TestMongoWithoutSampleStillOffersOperators(t *testing.T) {
	for name, src := range map[string]fakeMongoSource{
		"not ready": {notReady: true},
		"failed":    {failPaths: true},
	} {
		t.Run(name, func(t *testing.T) {
			res, _ := completeAt(t, true, "db.users.find({ |", src)
			if _, ok := find(res, "$and"); !ok {
				t.Errorf("no operators in %v", labels(res))
			}
			if _, ok := find(res, "name"); ok {
				t.Error("fields must not appear without a sample")
			}
			if res.Incomplete != (name == "not ready") {
				t.Errorf("Incomplete = %v", res.Incomplete)
			}
		})
	}
}

func TestMongoUnknownCollectionOffersNoFields(t *testing.T) {
	text := "coll.find({ |"
	res, err := CompleteMongo(context.Background(), MongoRequest{Shell: true, Text: strings.Replace(text, "|", "", 1), Cursor: strings.Index(text, "|"), Source: testSource()})
	if err != nil {
		t.Fatal(err)
	}
	if _, ok := find(res, "name"); ok {
		t.Error("fields offered without a collection")
	}
}

func TestMongoOffsetsAreUTF16(t *testing.T) {
	res, text := completeAt(t, true, `db.users.find({ "😀": 1, na|`, testSource())
	it, ok := find(res, "name")
	if !ok {
		t.Fatalf("no name in %v", labels(res))
	}
	units := utf16.Encode([]rune(text))
	if string(utf16.Decode(units[it.ReplaceStart:it.ReplaceEnd])) != "na" {
		t.Errorf("replace [%d,%d) covers %q", it.ReplaceStart, it.ReplaceEnd, string(utf16.Decode(units[it.ReplaceStart:it.ReplaceEnd])))
	}
}

func TestMongoTextAfterCursorIsIgnored(t *testing.T) {
	res, _ := completeAt(t, true, "db.users.find({ na| : 1 })", testSource())
	if got := labels(res); len(got) == 0 || got[0] != "name" {
		t.Errorf("items = %v", firstN(got, 5))
	}
}

func TestMongoMaxItemsCutsTheList(t *testing.T) {
	text := "db.users.find({ "
	res, err := CompleteMongo(context.Background(), MongoRequest{Shell: true, Text: text, Cursor: len(text), MaxItems: 3, Collection: "users", Source: testSource()})
	if err != nil || len(res.Items) != 3 || !res.Incomplete {
		t.Errorf("items = %d incomplete = %v err = %v", len(res.Items), res.Incomplete, err)
	}
}

func TestMongoCancelledContextReturnsAnError(t *testing.T) {
	ctx, cancel := context.WithCancel(context.Background())
	cancel()
	text := "db.users.find({ "
	if _, err := CompleteMongo(ctx, MongoRequest{Shell: true, Text: text, Cursor: len(text), Source: testSource()}); err == nil {
		t.Error("want an error")
	}
}

func TestMongoCompletionSurvivesArbitraryText(t *testing.T) {
	pieces := []string{"db", ".", "users", "find", "(", ")", "{", "}", "[", "]", ",", ":", `"`, "'", "$or", "name", " ", "\n", "//", "/*", "😀", "/", "1", "getCollection", "$"}
	state := uint64(7)
	next := func(n int) int {
		state = state*6364136223846793005 + 1442695040888963407
		return int(state>>33) % n
	}
	for i := 0; i < 3000; i++ {
		var b strings.Builder
		for j := next(14); j >= 0; j-- {
			b.WriteString(pieces[next(len(pieces))])
		}
		text := b.String()
		units := utf16.Encode([]rune(text))
		cursor := next(len(units) + 1)
		if cursor > 0 && cursor < len(units) && utf16.IsSurrogate(rune(units[cursor])) && units[cursor] >= 0xDC00 {
			cursor--
		}
		for _, shell := range []bool{true, false} {
			res, err := CompleteMongo(context.Background(), MongoRequest{Shell: shell, Text: text, Cursor: cursor, Collection: "users", Source: testSource()})
			if err != nil {
				t.Fatalf("%q @%d: %v", text, cursor, err)
			}
			for _, it := range res.Items {
				if it.ReplaceStart > it.ReplaceEnd || it.ReplaceEnd > len(units) {
					t.Fatalf("%q @%d: bad range [%d,%d) for %q", text, cursor, it.ReplaceStart, it.ReplaceEnd, it.Label)
				}
			}
		}
	}
}

func FuzzCompleteMongo(f *testing.F) {
	for _, s := range []string{"db.users.find({ na", `{ "a": { $`, "db.", "db.users.aggregate([ { $match: { "} {
		f.Add(s, uint8(len(s)))
	}
	f.Fuzz(func(t *testing.T, text string, at uint8) {
		units := utf16.Encode([]rune(text))
		cursor := int(at) % (len(units) + 1)
		res, err := CompleteMongo(context.Background(), MongoRequest{Shell: at%2 == 0, Text: text, Cursor: cursor, Collection: "users", Source: testSource()})
		if err != nil {
			t.Fatal(err)
		}
		for _, it := range res.Items {
			if it.ReplaceStart > it.ReplaceEnd || it.ReplaceEnd > len(units) {
				t.Fatalf("bad range [%d,%d) in %q", it.ReplaceStart, it.ReplaceEnd, text)
			}
		}
	})
}

func BenchmarkCompleteMongoFilterKeys(b *testing.B) {
	src := testSource()
	for i := range 2000 {
		src.sample.Paths = append(src.sample.Paths, stat("deep.level"+strings.Repeat("x", i%5)+".field"+string(rune('a'+i%26))+strings.Repeat("y", i%7), 0.1, "string"))
	}
	text := "db.users.find({ status: 'x', na"
	b.ReportAllocs()
	for b.Loop() {
		if _, err := CompleteMongo(context.Background(), MongoRequest{Shell: true, Text: text, Cursor: len(text), Collection: "users", Source: src}); err != nil {
			b.Fatal(err)
		}
	}
}
