SELECT o._id AS order_id, c.name AS customer FROM orders o JOIN customers c ON c._id = o.customer_id AND o.total > 100
