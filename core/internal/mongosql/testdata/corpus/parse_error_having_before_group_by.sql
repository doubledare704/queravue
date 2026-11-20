SELECT status FROM orders HAVING COUNT(*) > 1 GROUP BY status
