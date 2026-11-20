//go:build integration

package mongosql

import (
	"context"
	"database/sql"
	"fmt"
	"math"
	"slices"
	"strconv"
	"strings"
	"testing"

	"go.mongodb.org/mongo-driver/v2/bson"
	mdb "go.mongodb.org/mongo-driver/v2/mongo"
	_ "modernc.org/sqlite"
)

type fixtureTable struct {
	name    string
	columns []string
	rows    [][]any
}

var differentialFixture = []fixtureTable{
	{name: "customers", columns: []string{"_id", "name", "city", "tier", "age", "active"}, rows: [][]any{
		{1, "Ann", "Kyiv", "gold", 34, true},
		{2, "Bob", "Lviv", "silver", 28, true},
		{3, "Cid", "Kyiv", "silver", 45, false},
		{4, "Dan", "Odesa", "bronze", 52, true},
		{5, "Eve", "Lviv", "gold", 31, true},
		{6, "Fay", "Kharkiv", "bronze", 23, false},
		{7, "Gus", "Kyiv", "bronze", 39, true},
		{8, "Hal", "Odesa", "silver", 41, false},
	}},
	{name: "orders", columns: []string{"_id", "customer_id", "status", "total", "discount", "qty"}, rows: [][]any{
		{101, 1, "paid", 120, 10, 3},
		{102, 1, "paid", 80, 0, 2},
		{103, 2, "shipped", 200, 20, 5},
		{104, 2, "paid", 45, 5, 1},
		{105, 3, "cancelled", 60, 0, 2},
		{106, 4, "paid", 300, 30, 6},
		{107, 4, "shipped", 150, 15, 4},
		{108, 5, "paid", 95, 5, 2},
		{109, 5, "pending", 20, 0, 1},
		{110, 6, "pending", 75, 0, 3},
		{111, 7, "paid", 180, 18, 4},
		{112, 7, "shipped", 110, 11, 2},
		{113, 1, "shipped", 70, 7, 2},
		{114, 3, "paid", 130, 13, 3},
		{115, 6, "cancelled", 40, 0, 1},
		{116, 2, "paid", 90, 9, 2},
	}},
	{name: "order_lines", columns: []string{"_id", "order_id", "sku", "price", "qty"}, rows: [][]any{
		{1, 101, "A1", 10.5, 2},
		{2, 101, "B2", 20.0, 1},
		{3, 102, "A1", 10.5, 2},
		{4, 103, "C3", 40.25, 5},
		{5, 104, "B2", 20.0, 1},
		{6, 106, "D4", 5.5, 4},
		{7, 106, "E5", 99.0, 1},
		{8, 107, "A1", 10.5, 3},
		{9, 108, "F6", 15.75, 2},
		{10, 111, "C3", 40.25, 1},
		{11, 112, "D4", 5.5, 6},
		{12, 114, "B2", 20.0, 2},
	}},
	{name: "products", columns: []string{"_id", "sku", "name", "category", "price", "stock"}, rows: [][]any{
		{1, "A1", "Widget", "tools", 10.5, 100},
		{2, "B2", "Gadget", "tools", 20.0, 50},
		{3, "C3", "Doohickey", "toys", 40.25, 10},
		{4, "D4", "Gizmo", "toys", 5.5, 200},
		{5, "E5", "Thing", "misc", 99.0, 5},
		{6, "F6", "Whatsit", "misc", 15.75, 0},
	}},
}

func loadFixtureIntoSQLite(t *testing.T) *sql.DB {
	t.Helper()
	db, err := sql.Open("sqlite", ":memory:")
	if err != nil {
		t.Fatal(err)
	}
	db.SetMaxOpenConns(1)
	t.Cleanup(func() { _ = db.Close() })
	if _, err := db.Exec("PRAGMA case_sensitive_like = ON"); err != nil {
		t.Fatal(err)
	}
	for _, table := range differentialFixture {
		if _, err := db.Exec(fmt.Sprintf("CREATE TABLE %s (%s)", table.name, strings.Join(table.columns, ", "))); err != nil {
			t.Fatal(err)
		}
		insert := fmt.Sprintf("INSERT INTO %s VALUES (%s)", table.name, strings.TrimSuffix(strings.Repeat("?,", len(table.columns)), ","))
		for _, row := range table.rows {
			if _, err := db.Exec(insert, row...); err != nil {
				t.Fatal(err)
			}
		}
	}
	return db
}

func loadFixtureIntoMongo(t *testing.T, db *mdb.Database) {
	t.Helper()
	ctx := context.Background()
	for _, table := range differentialFixture {
		docs := make([]any, len(table.rows))
		for i, row := range table.rows {
			doc := bson.D{}
			for j, column := range table.columns {
				value := row[j]
				if n, ok := value.(int); ok {
					value = int32(n)
				}
				doc = append(doc, bson.E{Key: column, Value: value})
			}
			docs[i] = doc
		}
		if _, err := db.Collection(table.name).InsertMany(ctx, docs); err != nil {
			t.Fatal(err)
		}
	}
}

func runOnSQLite(db *sql.DB, query string) ([]string, [][]string, error) {
	rows, err := db.Query(query)
	if err != nil {
		return nil, nil, err
	}
	defer func() { _ = rows.Close() }()
	columns, err := rows.Columns()
	if err != nil {
		return nil, nil, err
	}
	var out [][]string
	for rows.Next() {
		values := make([]any, len(columns))
		pointers := make([]any, len(columns))
		for i := range values {
			pointers[i] = &values[i]
		}
		if err := rows.Scan(pointers...); err != nil {
			return nil, nil, err
		}
		row := make([]string, len(columns))
		for i, v := range values {
			row[i] = normalizeCell(v)
		}
		out = append(out, row)
	}
	return columns, out, rows.Err()
}

func normalizeCell(v any) string {
	switch n := v.(type) {
	case nil:
		return "NULL"
	case int:
		return numberCell(float64(n))
	case int32:
		return numberCell(float64(n))
	case int64:
		return numberCell(float64(n))
	case float64:
		return numberCell(n)
	case bool:
		if n {
			return numberCell(1)
		}
		return numberCell(0)
	case string:
		return "s:" + n
	case []byte:
		return "s:" + string(n)
	}
	return fmt.Sprintf("unexpected %T:%v", v, v)
}

func numberCell(f float64) string {
	return "n:" + strconv.FormatFloat(math.Round(f*1e6)/1e6, 'f', -1, 64)
}

// A missing key and a NULL are the same cell: LEFT JOIN rows without a match
// carry no key in MongoDB and a NULL in SQL.
func mongoRows(columns []string, docs []bson.D) ([][]string, error) {
	out := make([][]string, len(docs))
	for i, doc := range docs {
		for _, e := range doc {
			if !slices.Contains(columns, e.Key) {
				return nil, fmt.Errorf("document %v has key %q, which the SQL result does not have", doc, e.Key)
			}
		}
		row := make([]string, len(columns))
		for j, column := range columns {
			value, _ := documentValue(doc, column)
			row[j] = normalizeCell(value)
		}
		out[i] = row
	}
	return out, nil
}

func sortedRowKeys(rows [][]string) []string {
	keys := make([]string, len(rows))
	for i, row := range rows {
		keys[i] = strings.Join(row, "\x1f")
	}
	slices.Sort(keys)
	return keys
}

func TestIntegrationDifferentialAgainstSQLite(t *testing.T) {
	cases := readComparableCases(t)
	lite := loadFixtureIntoSQLite(t)
	mongoDB := connectMongo(t, "queravue_mongosql_differential")
	loadFixtureIntoMongo(t, mongoDB)

	for _, c := range cases {
		t.Run(c.name, func(t *testing.T) {
			columns, want, err := runOnSQLite(lite, c.sql)
			if err != nil {
				t.Fatalf("sqlite: %v\n%s", err, c.sql)
			}
			docs, resp := translateAndRun(t, mongoDB, c.sql)
			got, err := mongoRows(columns, docs)
			if err != nil {
				t.Fatalf("%v\nSQL: %s\nMQL: %s", err, c.sql, resp.GetShellCode())
			}
			if len(want) == 0 && !strings.Contains(c.name, "empty") && !strings.Contains(c.name, "null_check") && !strings.Contains(c.name, "is_null") && !strings.Contains(c.name, "unmatched") {
				t.Fatalf("the fixture returns no rows for %s: the case proves nothing", c.name)
			}
			if c.ordered {
				if !slices.Equal(sortedRowKeys(want), sortedRowKeys(got)) || !slices.EqualFunc(want, got, slices.Equal[[]string]) {
					t.Fatalf("ordered rows differ\nSQL: %s\nMQL: %s\nsqlite: %v\nmongo:  %v", c.sql, resp.GetShellCode(), want, got)
				}
				return
			}
			if !slices.Equal(sortedRowKeys(want), sortedRowKeys(got)) {
				t.Fatalf("rows differ\nSQL: %s\nMQL: %s\nsqlite: %v\nmongo:  %v", c.sql, resp.GetShellCode(), want, got)
			}
		})
	}
}
