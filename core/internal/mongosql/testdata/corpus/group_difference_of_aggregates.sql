SELECT status, SUM(total) - SUM(discount) AS net FROM orders GROUP BY status
