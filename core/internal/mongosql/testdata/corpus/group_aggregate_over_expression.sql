SELECT status, SUM(total - discount) AS net FROM orders GROUP BY status
