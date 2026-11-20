SELECT status, SUM(total) * 1.0 / COUNT(*) AS mean FROM orders GROUP BY status
