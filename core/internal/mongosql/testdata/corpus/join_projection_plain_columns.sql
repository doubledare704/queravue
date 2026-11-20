SELECT o._id AS order_id, o.total, c.city AS city FROM orders o JOIN customers c ON o.customer_id = c._id
