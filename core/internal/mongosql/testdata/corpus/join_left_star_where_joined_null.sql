SELECT * FROM orders o LEFT JOIN customers c ON o.customer_id = c._id WHERE c.name IS NULL
