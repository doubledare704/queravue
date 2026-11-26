SELECT status, COUNT(*) AS n FROM orders GROUP BY status HAVING NOT COUNT(*) > 2
