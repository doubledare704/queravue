SELECT c._id AS cid, o._id AS order_id, l._id AS line_id FROM customers c LEFT JOIN orders o ON o.customer_id = c._id LEFT JOIN order_lines l ON l.order_id = o._id
