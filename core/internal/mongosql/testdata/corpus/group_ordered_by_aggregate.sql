SELECT status, COUNT(*) AS n FROM orders GROUP BY status ORDER BY COUNT(*) DESC, status
