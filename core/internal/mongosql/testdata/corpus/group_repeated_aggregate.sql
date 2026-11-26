SELECT status, SUM(total) AS a, SUM(total) AS b FROM orders GROUP BY status
