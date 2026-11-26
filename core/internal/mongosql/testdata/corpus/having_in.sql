SELECT status, COUNT(*) AS n FROM orders GROUP BY status HAVING COUNT(*) IN (1, 2)
