SELECT o._id AS order_id, c.name AS customer FROM orders o JOIN customers c ON o.customer_id = c._id WHERE c.city = 'Kyiv'
