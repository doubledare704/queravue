SELECT status, SUM(total) AS s FROM orders WHERE total > 50 GROUP BY status
