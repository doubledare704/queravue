//go:build integration

package mongosql

import (
	"context"
	"slices"
	"strings"
	"testing"

	"go.mongodb.org/mongo-driver/v2/bson"
	mdb "go.mongodb.org/mongo-driver/v2/mongo"

	queravuev1 "github.com/doubledare704/queravue/core/internal/gen/queravue/v1"
)

func loadSemanticsFixture(t *testing.T, db *mdb.Database) {
	t.Helper()
	insert := func(collection string, docs ...any) {
		if _, err := db.Collection(collection).InsertMany(context.Background(), docs); err != nil {
			t.Fatal(err)
		}
	}
	insert("people",
		bson.D{{Key: "_id", Value: int32(1)}, {Key: "name", Value: "ann"}, {Key: "age", Value: int32(40)}, {Key: "tags", Value: bson.A{"a", "b"}}, {Key: "note", Value: nil}},
		bson.D{{Key: "_id", Value: int32(2)}, {Key: "name", Value: "bob"}, {Key: "age", Value: "40"}},
		bson.D{{Key: "_id", Value: int32(3)}, {Key: "name", Value: "cy_d"}, {Key: "age", Value: int32(25)}, {Key: "tags", Value: bson.A{"c"}}, {Key: "note", Value: "x"}},
		bson.D{{Key: "_id", Value: int32(4)}, {Key: "name", Value: "cyxd"}, {Key: "age", Value: int32(30)}, {Key: "tags", Value: bson.A{}}, {Key: "note", Value: "y"}},
		bson.D{{Key: "_id", Value: int32(5)}, {Key: "name", Value: "CYXD"}, {Key: "age", Value: nil}, {Key: "tags", Value: bson.A{"a"}}, {Key: "note", Value: ""}},
		bson.D{{Key: "_id", Value: int32(6)}},
	)
	insert("numbers",
		bson.D{{Key: "_id", Value: int32(1)}, {Key: "v", Value: int32(5)}},
		bson.D{{Key: "_id", Value: int32(2)}, {Key: "v", Value: nil}},
		bson.D{{Key: "_id", Value: int32(3)}},
	)
	insert("left_keys",
		bson.D{{Key: "_id", Value: int32(1)}, {Key: "k", Value: nil}},
		bson.D{{Key: "_id", Value: int32(2)}, {Key: "k", Value: int32(7)}},
	)
	insert("right_keys",
		bson.D{{Key: "_id", Value: int32(10)}, {Key: "k", Value: nil}},
		bson.D{{Key: "_id", Value: int32(11)}},
		bson.D{{Key: "_id", Value: int32(12)}, {Key: "k", Value: int32(7)}},
	)
}

func idsOf(t *testing.T, docs []bson.D, key string) []int32 {
	t.Helper()
	ids := make([]int32, len(docs))
	for i, doc := range docs {
		value, ok := documentValue(doc, key)
		if !ok {
			t.Fatalf("document %v has no %q", doc, key)
		}
		n, isInt := value.(int32)
		if !isInt {
			t.Fatalf("%q is %T, want int32", key, value)
		}
		ids[i] = n
	}
	return ids
}

func hasWarning(resp *queravuev1.TranslateMongoSqlResponse, kind warningKind) bool {
	return slices.ContainsFunc(resp.GetWarnings(), func(w *queravuev1.MongoSqlWarning) bool {
		return w.GetMessage() == warningMessages[kind]
	})
}

type semanticCase struct {
	name     string
	sql      string
	wantIDs  []int32
	idColumn string
	warns    []warningKind
}

func TestIntegrationSemanticsAgainstServer(t *testing.T) {
	db := connectMongo(t, "queravue_mongosql_semantics")
	loadSemanticsFixture(t, db)

	cases := []semanticCase{
		{name: "is null matches null and missing", sql: "SELECT _id FROM people WHERE note IS NULL ORDER BY _id", wantIDs: []int32{1, 2, 6}, warns: []warningKind{warnNullMatchesMissing}},
		{name: "is not null skips null and missing", sql: "SELECT _id FROM people WHERE note IS NOT NULL ORDER BY _id", wantIDs: []int32{3, 4, 5}},
		{name: "equals matches any array element", sql: "SELECT _id FROM people WHERE tags = 'a' ORDER BY _id", wantIDs: []int32{1, 5}, warns: []warningKind{warnArrayEquality}},
		{name: "in matches any array element", sql: "SELECT _id FROM people WHERE tags IN ('b', 'c') ORDER BY _id", wantIDs: []int32{1, 3}, warns: []warningKind{warnArrayEquality}},
		{name: "greater than skips other BSON types", sql: "SELECT _id FROM people WHERE age > 30 ORDER BY _id", wantIDs: []int32{1}, warns: []warningKind{warnTypeBrackets}},
		{name: "less than skips strings and null", sql: "SELECT _id FROM people WHERE age < 100 ORDER BY _id", wantIDs: []int32{1, 3, 4}, warns: []warningKind{warnTypeBrackets}},
		{name: "not equal matches null and missing", sql: "SELECT _id FROM people WHERE name <> 'ann' ORDER BY _id", wantIDs: []int32{2, 3, 4, 5, 6}, warns: []warningKind{warnNegationMatchesMissing}},
		{name: "not in matches missing", sql: "SELECT _id FROM people WHERE name NOT IN ('ann', 'bob') ORDER BY _id", wantIDs: []int32{3, 4, 5, 6}, warns: []warningKind{warnNegationMatchesMissing}},
		{name: "like underscore is a wildcard", sql: "SELECT _id FROM people WHERE name LIKE 'cy_d' ORDER BY _id", wantIDs: []int32{3, 4}, warns: []warningKind{warnLikeRegex}},
		{name: "like escaped underscore is literal", sql: `SELECT _id FROM people WHERE name LIKE 'cy\_d' ORDER BY _id`, wantIDs: []int32{3}, warns: []warningKind{warnLikeRegex}},
		{name: "like is anchored", sql: "SELECT _id FROM people WHERE name LIKE 'cy' ORDER BY _id", wantIDs: nil, warns: []warningKind{warnLikeRegex}},
		{name: "like prefix", sql: "SELECT _id FROM people WHERE name LIKE 'cy%' ORDER BY _id", wantIDs: []int32{3, 4}},
		{name: "like escapes regex metacharacters", sql: "SELECT _id FROM people WHERE name LIKE 'a.n' ORDER BY _id", wantIDs: nil},
		{name: "like is case sensitive", sql: "SELECT _id FROM people WHERE name LIKE 'CY%' ORDER BY _id", wantIDs: []int32{5}},
		{name: "ilike adds the i option", sql: "SELECT _id FROM people WHERE name ILIKE 'cy_d' ORDER BY _id", wantIDs: []int32{3, 4, 5}, warns: []warningKind{warnLikeRegex}},
		{name: "not like matches missing", sql: "SELECT _id FROM people WHERE name NOT LIKE 'cy%' ORDER BY _id", wantIDs: []int32{1, 2, 5, 6}, warns: []warningKind{warnNegationMatchesMissing}},
		{name: "order by sorts null and missing first", sql: "SELECT _id FROM people ORDER BY note, _id", wantIDs: []int32{1, 2, 6, 5, 3, 4}, warns: []warningKind{warnNullsSortFirst}},
		{name: "order by descending sorts null and missing last", sql: "SELECT _id FROM people ORDER BY note DESC, _id", wantIDs: []int32{4, 3, 5, 1, 2, 6}, warns: []warningKind{warnNullsSortFirst}},
		{name: "expression comparison ranks null below numbers", sql: "SELECT _id FROM numbers WHERE v * 2 < 100 ORDER BY _id", wantIDs: []int32{1, 2, 3}, warns: []warningKind{warnExpressionNullOrdering, warnArithmetic}},
		{name: "expression null check covers missing", sql: "SELECT _id FROM numbers WHERE v * 2 IS NULL ORDER BY _id", wantIDs: []int32{2, 3}, warns: []warningKind{warnNullMatchesMissing}},
		{name: "join matches null keys with missing keys", sql: "SELECT l._id AS left_id, r._id AS right_id FROM left_keys l JOIN right_keys r ON l.k = r.k ORDER BY l._id, r._id", wantIDs: []int32{1, 1, 2}, idColumn: "left_id", warns: []warningKind{warnJoinNullKey}},
		{name: "compound join warns about older servers and does not match missing keys", sql: "SELECT l._id AS left_id FROM left_keys l JOIN right_keys r ON l.k = r.k AND r._id > 10 ORDER BY l._id", wantIDs: []int32{2}, idColumn: "left_id", warns: []warningKind{warnCompoundJoin}},
	}
	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			docs, resp := translateAndRun(t, db, c.sql)
			idColumn := c.idColumn
			if idColumn == "" {
				idColumn = "_id"
			}
			if got := idsOf(t, docs, idColumn); !slices.Equal(got, nilToEmpty(c.wantIDs)) {
				t.Errorf("ids = %v, want %v\nMQL: %s", got, c.wantIDs, resp.GetShellCode())
			}
			for _, kind := range c.warns {
				if !hasWarning(resp, kind) {
					t.Errorf("missing warning %q in %v", warningMessages[kind], resp.GetWarnings())
				}
			}
		})
	}
}

func nilToEmpty(ids []int32) []int32 {
	if ids == nil {
		return []int32{}
	}
	return ids
}

func TestIntegrationAggregateSemanticsAgainstServer(t *testing.T) {
	db := connectMongo(t, "queravue_mongosql_aggregate_semantics")
	loadSemanticsFixture(t, db)

	singleValue := func(t *testing.T, sql, column string) (any, *queravuev1.TranslateMongoSqlResponse) {
		t.Helper()
		docs, resp := translateAndRun(t, db, sql)
		if len(docs) != 1 {
			t.Fatalf("%s returned %d documents, want 1: %v", sql, len(docs), docs)
		}
		value, ok := documentValue(docs[0], column)
		if !ok {
			t.Fatalf("no %q in %v", column, docs[0])
		}
		return value, resp
	}

	t.Run("count of a field skips null and missing", func(t *testing.T) {
		value, resp := singleValue(t, "SELECT COUNT(note) AS n FROM people", "n")
		if value != int32(3) {
			t.Errorf("COUNT(note) = %v, want 3", value)
		}
		if !hasWarning(resp, warnCountNonNull) {
			t.Errorf("missing the COUNT(f) warning: %v", resp.GetWarnings())
		}
	})
	t.Run("count star counts every document", func(t *testing.T) {
		if value, _ := singleValue(t, "SELECT COUNT(*) AS n FROM people", "n"); value != int32(6) {
			t.Errorf("COUNT(*) = %v, want 6", value)
		}
	})
	t.Run("count distinct ignores null and missing", func(t *testing.T) {
		if value, _ := singleValue(t, "SELECT COUNT(DISTINCT note) AS n FROM people", "n"); value != int32(3) {
			t.Errorf("COUNT(DISTINCT note) = %v, want 3", value)
		}
	})
	t.Run("sum of strings is zero", func(t *testing.T) {
		value, resp := singleValue(t, "SELECT SUM(note) AS s FROM people", "s")
		if value != int32(0) {
			t.Errorf("SUM(note) = %v (%T), want 0", value, value)
		}
		if !hasWarning(resp, warnSumWithoutValues) {
			t.Errorf("missing the SUM warning: %v", resp.GetWarnings())
		}
	})
	t.Run("min and max skip null and missing", func(t *testing.T) {
		docs, _ := translateAndRun(t, db, "SELECT MIN(note) AS lo, MAX(note) AS hi FROM people")
		lo, _ := documentValue(docs[0], "lo")
		hi, _ := documentValue(docs[0], "hi")
		if lo != "" || hi != "y" {
			t.Errorf("MIN/MAX(note) = %v/%v, want an empty string and y", lo, hi)
		}
	})
	t.Run("aggregate over no documents returns no row", func(t *testing.T) {
		docs, resp := translateAndRun(t, db, "SELECT COUNT(*) AS n FROM people WHERE _id > 100")
		if len(docs) != 0 {
			t.Errorf("rows = %v, want none", docs)
		}
		if !hasWarning(resp, warnEmptyGlobalAggregate) {
			t.Errorf("missing the empty-aggregate warning: %v", resp.GetWarnings())
		}
	})
	t.Run("division always returns a double", func(t *testing.T) {
		value, resp := singleValue(t, "SELECT v / 2 AS half FROM numbers WHERE _id = 1", "half")
		if value != 2.5 {
			t.Errorf("5 / 2 = %v, want 2.5", value)
		}
		if !hasWarning(resp, warnArithmetic) {
			t.Errorf("missing the arithmetic warning: %v", resp.GetWarnings())
		}
	})
	t.Run("arithmetic on null or missing gives null", func(t *testing.T) {
		docs, _ := translateAndRun(t, db, "SELECT v + 1 AS next FROM numbers WHERE _id IN (2, 3)")
		for _, doc := range docs {
			if value, _ := documentValue(doc, "next"); value != nil {
				t.Errorf("v + 1 = %v, want null", value)
			}
		}
	})
	t.Run("group by puts null and missing in one group", func(t *testing.T) {
		docs, _ := translateAndRun(t, db, "SELECT note, COUNT(*) AS n FROM people GROUP BY note")
		counts := map[string]int32{}
		for _, doc := range docs {
			note, _ := documentValue(doc, "note")
			n, _ := documentValue(doc, "n")
			key := "null"
			if s, ok := note.(string); ok {
				key = "s:" + s
			}
			counts[key] += n.(int32)
		}
		if counts["null"] != 3 || len(docs) != 4 {
			t.Errorf("groups = %v (%d documents), want null and missing in a single group of 3", counts, len(docs))
		}
	})
	t.Run("distinct puts null and missing in one group", func(t *testing.T) {
		docs, _ := translateAndRun(t, db, "SELECT DISTINCT note FROM people")
		if len(docs) != 4 {
			t.Errorf("DISTINCT note returned %d documents, want 4 (null, missing, x, y, empty)", len(docs))
		}
	})
	t.Run("shell code runs the pipeline", func(t *testing.T) {
		_, resp := translateAndRun(t, db, "SELECT COUNT(*) AS n FROM people")
		if !strings.HasPrefix(resp.GetShellCode(), `db.getSiblingDB("queravue_mongosql_aggregate_semantics").people.aggregate([`) {
			t.Errorf("shell code = %s", resp.GetShellCode())
		}
	})
}
