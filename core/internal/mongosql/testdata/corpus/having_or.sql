SELECT status, COUNT(*) AS n, SUM(total) AS s FROM orders GROUP BY status HAVING COUNT(*) = 1 OR SUM(total) > 400
