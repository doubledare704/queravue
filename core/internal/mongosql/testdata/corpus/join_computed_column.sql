SELECT o._id AS order_id, o.total - o.discount AS net, c.name AS customer FROM orders o JOIN customers c ON o.customer_id = c._id
