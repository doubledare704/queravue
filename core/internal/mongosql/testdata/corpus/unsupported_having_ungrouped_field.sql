SELECT status, COUNT(*) AS n FROM orders GROUP BY status HAVING total > 5
