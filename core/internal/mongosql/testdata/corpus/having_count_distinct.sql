SELECT customer_id FROM orders GROUP BY customer_id HAVING COUNT(DISTINCT status) = 2 AND MIN(total) < 50
