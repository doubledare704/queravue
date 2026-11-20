SELECT c.name AS customer, SUM(l.price * l.qty) AS spend FROM orders o JOIN customers c ON o.customer_id = c._id JOIN order_lines l ON l.order_id = o._id GROUP BY c.name
