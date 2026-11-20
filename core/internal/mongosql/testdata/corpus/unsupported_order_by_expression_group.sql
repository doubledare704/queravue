SELECT status FROM orders GROUP BY status ORDER BY COUNT(*) + 1
