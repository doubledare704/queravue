SELECT * FROM orders o JOIN customers c ON o.customer_id = c._id AND c.active = TRUE AND o.total > 10
