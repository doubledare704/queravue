SELECT * FROM orders o JOIN customers c ON o.customer_id = c._id AND c.deleted_at = NULL
