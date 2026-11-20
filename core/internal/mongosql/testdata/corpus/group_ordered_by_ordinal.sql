SELECT customer_id, SUM(total) AS spent FROM orders GROUP BY customer_id ORDER BY 2 DESC, 1
