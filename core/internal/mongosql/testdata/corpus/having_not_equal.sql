SELECT status, COUNT(*) AS n FROM orders GROUP BY status HAVING COUNT(*) <> 4
