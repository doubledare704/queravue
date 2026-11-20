SELECT customer_id, SUM(total) AS spent FROM orders GROUP BY customer_id ORDER BY customer_id LIMIT 3 OFFSET 2
