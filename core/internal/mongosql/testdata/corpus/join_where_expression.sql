SELECT o._id AS order_id FROM orders o JOIN customers c ON o.customer_id = c._id WHERE o.total - o.discount > c.age
