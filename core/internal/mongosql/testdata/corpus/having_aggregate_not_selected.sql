SELECT status FROM orders GROUP BY status HAVING MAX(total) > 250
