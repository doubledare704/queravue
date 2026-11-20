SELECT status FROM orders GROUP BY status HAVING SUM(total) > COUNT(*) * 100
