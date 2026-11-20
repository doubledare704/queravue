SELECT customer_id, SUM(total) AS spent FROM orders GROUP BY customer_id HAVING SUM(total) >= 200
