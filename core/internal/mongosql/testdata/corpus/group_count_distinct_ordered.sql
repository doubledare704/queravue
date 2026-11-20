SELECT customer_id, COUNT(DISTINCT status) AS kinds FROM orders GROUP BY customer_id ORDER BY kinds DESC, customer_id
