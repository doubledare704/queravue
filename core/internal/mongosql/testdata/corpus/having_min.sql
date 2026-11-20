SELECT customer_id FROM orders GROUP BY customer_id HAVING MIN(total) < 50
