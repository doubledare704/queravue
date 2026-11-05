// Deterministic ~5,000-line SQL script mixing DDL, CTEs, joins, comments,
// strings and numbers.
String buildSqlSample({int lines = 5000}) {
  final out = <String>[];
  var i = 0;
  while (out.length < lines) {
    switch (i % 4) {
      case 0:
        out.addAll([
          '-- table $i: orders partition',
          'CREATE TABLE IF NOT EXISTS sales.orders_$i (',
          '  id            BIGSERIAL PRIMARY KEY,',
          "  customer_id   BIGINT NOT NULL REFERENCES crm.customers(id),",
          "  status        TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','paid','void')),",
          '  amount        NUMERIC(12, 2) NOT NULL DEFAULT 0.00,',
          '  created_at    TIMESTAMPTZ NOT NULL DEFAULT now()',
          ');',
          'CREATE INDEX orders_${i}_customer_idx ON sales.orders_$i (customer_id, created_at DESC);',
          '',
        ]);
      case 1:
        out.addAll([
          '/* monthly revenue report #$i',
          '   multi-line comment */',
          'WITH monthly AS (',
          "  SELECT date_trunc('month', o.created_at) AS month,",
          '         c.region,',
          '         sum(o.amount) AS revenue,',
          '         count(DISTINCT o.customer_id) AS buyers',
          '    FROM sales.orders_${i - 1} o',
          '    JOIN crm.customers c ON c.id = o.customer_id',
          "   WHERE o.status = 'paid' AND o.created_at >= now() - INTERVAL '1 year'",
          '   GROUP BY 1, 2',
          ')',
          'SELECT month, region, revenue, buyers,',
          '       revenue / NULLIF(buyers, 0) AS arpu,',
          '       lag(revenue) OVER (PARTITION BY region ORDER BY month) AS prev',
          '  FROM monthly',
          ' ORDER BY month DESC, revenue DESC',
          ' LIMIT ${100 + i};',
          '',
        ]);
      case 2:
        out.addAll([
          'INSERT INTO crm.customers (id, name, email, region, score) VALUES',
          for (var k = 0; k < 6; k++)
            "  (${i * 10 + k}, 'Customer ${i * 10 + k}', 'c${i * 10 + k}@example.com', '${['eu', 'us', 'apac'][k % 3]}', ${(k * 7.5).toStringAsFixed(1)})${k == 5 ? ';' : ','}",
          '',
        ]);
      default:
        out.addAll([
          'UPDATE sales.orders_${i - 3} SET status = \'void\', amount = 0',
          ' WHERE id IN (SELECT id FROM sales.orders_${i - 3} WHERE amount < 0) -- fix negatives',
          'RETURNING id, status;',
          'DELETE FROM audit.log WHERE created_at < now() - INTERVAL \'90 days\';',
          '',
        ]);
    }
    i++;
  }
  return out.take(lines).join('\n');
}

/// Stand-in for core-provided completions (schema-aware), returned async.
Future<List<String>> fakeCompletions(String prefix) async {
  await Future<void>.delayed(const Duration(milliseconds: 5));
  const words = [
    'SELECT', 'FROM', 'WHERE', 'JOIN', 'GROUP BY', 'ORDER BY', 'LIMIT',
    'customers', 'customer_id', 'created_at', 'crm.customers', 'sales.orders_1',
    'status', 'amount', 'region', 'revenue',
  ];
  final p = prefix.toLowerCase();
  return words.where((w) => w.toLowerCase().startsWith(p) && w.length > p.length).toList();
}
