SELECT status, AVG(total) AS mean FROM orders GROUP BY status HAVING AVG(total) BETWEEN 50 AND 150
