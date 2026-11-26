SELECT status, COUNT(*) AS n FROM orders GROUP BY status ORDER BY n DESC, status
