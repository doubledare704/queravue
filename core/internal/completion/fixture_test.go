package completion_test

import (
	"fmt"
	"strings"
	"unicode/utf16"

	"github.com/doubledare704/queravue/core/internal/completion"
)

func cols(spec string) []completion.Column {
	var out []completion.Column
	for _, c := range strings.Fields(spec) {
		name, typ, _ := strings.Cut(c, ":")
		out = append(out, completion.Column{Name: name, Type: typ})
	}
	return out
}

func shopTables(schema string) []*completion.Table {
	return []*completion.Table{
		{Schema: schema, Name: "categories", Columns: cols("id:integer name:text")},
		{Schema: schema, Name: "customers", Columns: cols("id:integer name:text email:text created_at:timestamp")},
		{Schema: schema, Name: "order_items", Columns: cols("order_id:integer product_id:integer quantity:integer unit_price:numeric")},
		{Schema: schema, Name: "orders", Columns: cols("id:integer customer_id:integer status:text total:numeric created_at:timestamp")},
		{Schema: schema, Name: "products", Columns: cols("id:integer name:text price:numeric category_id:integer")},
		{Schema: schema, Name: "customer_order_summary_view", View: true, Columns: cols("customer_id:integer order_count:bigint")},
	}
}

func shopSnapshot(schema string, extra ...string) *completion.Snapshot {
	tables := shopTables(schema)
	schemas := []string{schema}
	for _, other := range extra {
		schemas = append(schemas, other)
		tables = append(tables, &completion.Table{Schema: other, Name: "log", Columns: cols("id:integer at:timestamp")})
	}
	return completion.NewSnapshot(schemas, tables)
}

func splitCursor(marked string) (string, int) {
	i := strings.IndexByte(marked, '|')
	if i < 0 {
		panic(fmt.Sprintf("no cursor marker in %q", marked))
	}
	text := marked[:i] + marked[i+1:]
	return text, len(utf16.Encode([]rune(marked[:i])))
}
