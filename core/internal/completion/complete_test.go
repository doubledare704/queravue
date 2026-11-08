package completion_test

import (
	"context"
	"slices"
	"testing"

	"github.com/doubledare704/queravue/core/internal/completion"
	"github.com/doubledare704/queravue/core/internal/sqlsplit"
)

type completeCase struct {
	name  string
	d     sqlsplit.Dialect
	sql   string
	top   []string
	has   []string
	lacks []string
	empty bool
}

func labels(items []completion.Item) []string {
	out := make([]string, len(items))
	for i, it := range items {
		out[i] = it.Label
	}
	return out
}

func snapshotFor(d sqlsplit.Dialect) *completion.Snapshot {
	switch d {
	case sqlsplit.MSSQL:
		return shopSnapshot("dbo", "audit")
	case sqlsplit.SQLite:
		return shopSnapshot("main")
	case sqlsplit.MySQL:
		return shopSnapshot("shop")
	}
	return shopSnapshot("public", "audit")
}

func TestCompleteRanksByContext(t *testing.T) {
	const (
		pg     = sqlsplit.Postgres
		mysql  = sqlsplit.MySQL
		mssql  = sqlsplit.MSSQL
		sqlite = sqlsplit.SQLite
	)
	customerCols := []string{"created_at", "email", "id", "name"}
	orderCols := []string{"created_at", "customer_id", "id", "status", "total"}
	tests := []completeCase{
		{name: "select list shows scope table then its columns", d: pg, sql: "SELECT | FROM customers", top: []string{"customers", "created_at", "email", "id", "name"}},
		{name: "alias dot lists columns", d: pg, sql: "SELECT c.| FROM customers c", top: customerCols},
		{name: "alias dot with prefix", d: pg, sql: "SELECT c.na| FROM customers c", top: []string{"name"}},
		{name: "from lists default schema tables first", d: pg, sql: "SELECT * FROM |", top: []string{"categories", "customer_order_summary_view", "customers", "order_items", "orders", "products"}, has: []string{"audit.log", "audit"}},
		{name: "from prefix", d: pg, sql: "SELECT * FROM cu|", top: []string{"customer_order_summary_view", "customers"}},
		{name: "from word-initials match", d: pg, sql: "SELECT * FROM oi|", top: []string{"order_items"}},
		{name: "join lists tables", d: pg, sql: "SELECT * FROM customers c JOIN |", has: []string{"orders", "products"}},
		{name: "on clause qualified", d: pg, sql: "SELECT * FROM customers c JOIN orders o ON c.id = o.|", top: orderCols},
		{name: "on clause shows both aliases first", d: pg, sql: "SELECT * FROM customers c JOIN orders o ON |", top: []string{"c", "o"}},
		{name: "where with AS alias", d: pg, sql: "SELECT * FROM customers AS c WHERE c.|", top: customerCols},
		{name: "where unqualified starts with alias", d: pg, sql: "SELECT * FROM customers c WHERE |", top: []string{"c"}},
		{name: "group by", d: pg, sql: "SELECT count(*) FROM orders GROUP BY |", top: []string{"orders", "created_at", "customer_id", "id", "status", "total"}},
		{name: "order by", d: pg, sql: "SELECT * FROM orders ORDER BY |", top: []string{"orders", "created_at", "customer_id"}},
		{name: "order by select alias", d: pg, sql: "SELECT customer_id, count(*) AS n FROM orders GROUP BY customer_id ORDER BY n|", has: []string{"n"}},
		{name: "insert column list", d: pg, sql: "INSERT INTO customers (|", top: customerCols},
		{name: "insert column list after comma", d: pg, sql: "INSERT INTO customers (id, |", top: customerCols},
		{name: "insert target", d: pg, sql: "INSERT INTO |", top: []string{"categories", "customer_order_summary_view", "customers"}},
		{name: "update set", d: pg, sql: "UPDATE customers SET |", top: []string{"customers"}, has: []string{"name", "email"}},
		{name: "update where", d: pg, sql: "UPDATE customers SET name = 'x' WHERE |", top: []string{"customers"}},
		{name: "delete where", d: pg, sql: "DELETE FROM orders WHERE |", top: []string{"orders"}, has: []string{"status"}},
		{name: "delete from tables", d: pg, sql: "DELETE FROM |", has: []string{"orders"}},
		{name: "cte name and derived columns", d: pg, sql: "WITH recent AS (SELECT id, total FROM orders) SELECT | FROM recent", top: []string{"recent", "id", "total"}},
		{name: "cte alias dot", d: pg, sql: "WITH recent AS (SELECT id, total FROM orders) SELECT r.| FROM recent r", top: []string{"id", "total"}},
		{name: "cte explicit columns", d: pg, sql: "WITH recent(a, b) AS (SELECT id, total FROM orders) SELECT r.| FROM recent r", top: []string{"a", "b"}},
		{name: "cte star expands", d: pg, sql: "WITH recent AS (SELECT * FROM orders) SELECT r.| FROM recent r", top: orderCols},
		{name: "cte offered in from", d: pg, sql: "WITH recent AS (SELECT id FROM orders) SELECT * FROM |", top: []string{"recent"}},
		{name: "second cte", d: pg, sql: "WITH a AS (SELECT id FROM orders), b AS (SELECT name FROM customers) SELECT x.| FROM b x", top: []string{"name"}},
		{name: "subquery alias columns", d: pg, sql: "SELECT * FROM (SELECT id, name FROM customers) t WHERE t.|", top: []string{"id", "name"}},
		{name: "subquery AS alias renamed column", d: pg, sql: "SELECT * FROM (SELECT id, name AS n FROM customers) AS t WHERE t.|", top: []string{"id", "n"}},
		{name: "subquery star", d: pg, sql: "SELECT * FROM (SELECT * FROM products) p WHERE p.|", top: []string{"category_id", "id", "name", "price"}},
		{name: "unknown qualifier gives nothing", d: pg, sql: "SELECT x.| FROM customers c", empty: true},
		{name: "schema dot lists its tables", d: pg, sql: "SELECT public.| FROM customers", has: []string{"customers"}, lacks: []string{"log", "audit.log"}},
		{name: "from schema dot", d: pg, sql: "SELECT * FROM audit.|", top: []string{"log"}},
		{name: "from schema dot prefix", d: pg, sql: "SELECT * FROM public.cu|", top: []string{"customer_order_summary_view", "customers"}},
		{name: "schema.table.column", d: pg, sql: "SELECT public.customers.| FROM public.customers", top: customerCols},
		{name: "table name as qualifier", d: pg, sql: "SELECT customers.| FROM customers", top: customerCols},
		{name: "table qualifier not yet in FROM", d: pg, sql: "SELECT customers.|", top: customerCols},
		{name: "quoted qualifier", d: pg, sql: `SELECT "customers".| FROM customers`, top: customerCols},
		{name: "case-insensitive table and column", d: pg, sql: "SELECT * FROM Customers c WHERE c.NA|", top: []string{"name"}},
		{name: "lowercase keywords", d: pg, sql: "select * from customers where |", top: []string{"customers"}},
		{name: "keyword prefix", d: pg, sql: "SEL|", top: []string{"SELECT"}},
		{name: "statement start keywords first", d: pg, sql: "|", top: []string{"ALTER TABLE", "BEGIN", "COMMIT"}},
		{name: "keyword insert into", d: pg, sql: "ins|", top: []string{"INSERT INTO"}},
		{name: "nested subquery scope", d: pg, sql: "SELECT * FROM customers c WHERE c.id IN (SELECT customer_id FROM orders WHERE |", top: []string{"c", "orders"}},
		{name: "correlated outer alias", d: pg, sql: "SELECT * FROM customers c WHERE EXISTS (SELECT 1 FROM orders o WHERE o.customer_id = c.|", top: customerCols},
		{name: "scalar subquery in select", d: pg, sql: "SELECT (SELECT max(total) FROM orders o WHERE o.|) FROM customers", top: orderCols},
		{name: "self join aliases", d: pg, sql: "SELECT * FROM customers c1 JOIN customers c2 ON c1.id = c2.|", top: customerCols},
		{name: "comma join", d: pg, sql: "SELECT * FROM orders o, customers c WHERE o.customer_id = c.|", top: customerCols},
		{name: "using clause", d: pg, sql: "SELECT * FROM customers c LEFT JOIN orders o USING (|", top: []string{"c", "o"}},
		{name: "inside string literal", d: pg, sql: "SELECT * FROM customers c WHERE c.name LIKE 'a|", empty: true},
		{name: "inside line comment", d: pg, sql: "SELECT * FROM customers -- co|", empty: true},
		{name: "inside block comment", d: pg, sql: "SELECT /* co| */ 1", empty: true},
		{name: "after AND", d: pg, sql: "SELECT * FROM customers c WHERE c.id = 1 AND |", top: []string{"c"}},
		{name: "middle of select list", d: pg, sql: "SELECT |, name FROM customers", top: []string{"customers"}},
		{name: "second join alias", d: pg, sql: "SELECT id, | FROM orders o JOIN customers c ON c.id = o.customer_id", top: []string{"c", "o"}},
		{name: "unparsable select degrades to tables", d: pg, sql: "SELECT ((( FROM |", has: []string{"customers"}},
		{name: "from without select", d: pg, sql: "FROM |", has: []string{"customers"}},
		{name: "garbage degrades to keywords and tables", d: pg, sql: "GARBAGE ++ | ;;", has: []string{"customers", "SELECT"}},
		{name: "order by qualified", d: pg, sql: "SELECT * FROM orders o WHERE o.status = 'x' ORDER BY o.|", top: orderCols},
		{name: "third join", d: pg, sql: "SELECT o.id FROM orders o INNER JOIN order_items i ON i.order_id = o.id INNER JOIN products p ON p.id = i.|", top: []string{"order_id", "product_id", "quantity", "unit_price"}},
		{name: "update from join", d: pg, sql: "UPDATE orders o SET status = 'x' FROM customers c WHERE o.customer_id = c.|", top: customerCols},
		{name: "insert select inner scope", d: pg, sql: "INSERT INTO orders (customer_id) SELECT | FROM customers", top: []string{"customers"}},
		{name: "union second branch", d: pg, sql: "SELECT * FROM customers UNION SELECT * FROM orders o WHERE o.|", top: orderCols},
		{name: "union first branch not polluted", d: pg, sql: "SELECT | FROM customers UNION SELECT * FROM orders", top: []string{"customers"}, lacks: []string{"total"}},
		{name: "select list qualified second item", d: pg, sql: "SELECT c.name, o.| FROM customers c JOIN orders o ON o.customer_id = c.id", top: orderCols},
		{name: "view columns", d: pg, sql: "SELECT * FROM customer_order_summary_view v WHERE v.|", top: []string{"customer_id", "order_count"}},
		{name: "lateral derived star", d: pg, sql: "SELECT * FROM customers c JOIN LATERAL (SELECT * FROM orders o WHERE o.customer_id = c.id) x ON true WHERE x.|", top: orderCols},
		{name: "postgres keyword", d: pg, sql: "SELECT * FROM customers WHERE name ILI|", top: []string{"ILIKE"}},
		{name: "postgres function", d: pg, sql: "SELECT date_tr|", top: []string{"DATE_TRUNC"}},
		{name: "create table position offers tables", d: pg, sql: "CREATE TABLE |", has: []string{"customers"}},
		{name: "drop table position offers tables", d: pg, sql: "DROP TABLE |", has: []string{"orders"}},
		{name: "mysql backtick qualifier", d: mysql, sql: "SELECT `c`.| FROM customers `c`", top: customerCols},
		{name: "mysql from schema", d: mysql, sql: "SELECT * FROM shop.|", has: []string{"customers"}},
		{name: "mysql where alias", d: mysql, sql: "SELECT * FROM customers c WHERE c.|", top: customerCols},
		{name: "mysql keyword", d: mysql, sql: "SELECT * FROM customers ORDER BY name LIM|", top: []string{"LIMIT"}},
		{name: "mysql function", d: mysql, sql: "SELECT IFN|", top: []string{"IFNULL"}},
		{name: "mysql dash comment", d: mysql, sql: "SELECT 1 -- com|", empty: true},
		{name: "mysql hash comment", d: mysql, sql: "SELECT 1 # com|", empty: true},
		{name: "mssql bracket qualifier", d: mssql, sql: "SELECT [c].| FROM [dbo].[customers] [c]", top: customerCols},
		{name: "mssql top clause", d: mssql, sql: "SELECT TOP 10 | FROM customers", top: []string{"customers"}},
		{name: "mssql schema dot", d: mssql, sql: "SELECT * FROM dbo.|", has: []string{"customers"}, lacks: []string{"log"}},
		{name: "mssql cross apply keyword", d: mssql, sql: "SELECT * FROM customers c CROSS AP|", has: []string{"CROSS APPLY"}},
		{name: "mssql function", d: mssql, sql: "SELECT ISN|", top: []string{"ISNULL"}},
		{name: "mssql default schema tables unqualified", d: mssql, sql: "SELECT * FROM |", top: []string{"categories", "customer_order_summary_view", "customers"}},
		{name: "sqlite schema dot", d: sqlite, sql: "SELECT * FROM main.|", has: []string{"customers"}},
		{name: "sqlite as alias", d: sqlite, sql: "SELECT c.| FROM customers AS c", top: customerCols},
		{name: "sqlite function", d: sqlite, sql: "SELECT json_ex|", top: []string{"JSON_EXTRACT"}},
		{name: "sqlite insert or replace columns", d: sqlite, sql: "INSERT OR REPLACE INTO customers (|", top: customerCols},
		{name: "sqlite glob where", d: sqlite, sql: "SELECT * FROM customers WHERE name GLOB 'a*' AND |", top: []string{"customers"}},
		{name: "sqlite quoted qualifier", d: sqlite, sql: `SELECT "c".| FROM customers "c"`, top: customerCols},
	}
	if len(tests) < 80 {
		t.Fatalf("only %d cases; the plan requires at least 80", len(tests))
	}
	for _, tc := range tests {
		t.Run(tc.name, func(t *testing.T) {
			text, cursor := splitCursor(tc.sql)
			res, err := completion.Complete(context.Background(), completion.Request{
				Dialect: tc.d, Text: text, Cursor: cursor, MaxItems: 1000, Snapshot: snapshotFor(tc.d),
			})
			if err != nil {
				t.Fatal(err)
			}
			got := labels(res.Items)
			if tc.empty {
				if len(got) != 0 {
					t.Fatalf("items = %v, want none", got[:min(len(got), 8)])
				}
				return
			}
			if len(tc.top) > 0 {
				if len(got) < len(tc.top) || !slices.Equal(got[:len(tc.top)], tc.top) {
					t.Errorf("top = %v, want %v", got[:min(len(got), len(tc.top)+2)], tc.top)
				}
			}
			for _, want := range tc.has {
				if !slices.Contains(got, want) {
					t.Errorf("missing %q in %v", want, got[:min(len(got), 12)])
				}
			}
			for _, bad := range tc.lacks {
				if slices.Contains(got, bad) {
					t.Errorf("unexpected %q", bad)
				}
			}
		})
	}
}
