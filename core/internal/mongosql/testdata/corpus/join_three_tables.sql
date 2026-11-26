SELECT o._id AS order_id, c.name AS customer, p.name AS product FROM orders o JOIN customers c ON o.customer_id = c._id JOIN order_lines l ON l.order_id = o._id JOIN products p ON l.sku = p.sku
