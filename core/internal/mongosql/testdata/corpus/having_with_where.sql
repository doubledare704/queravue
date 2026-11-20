SELECT customer_id, SUM(total) AS spent FROM orders WHERE status = 'paid' GROUP BY customer_id HAVING SUM(total) > 100
