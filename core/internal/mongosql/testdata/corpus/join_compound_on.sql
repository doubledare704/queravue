SELECT o._id AS order_id, l._id AS line_id FROM orders o JOIN order_lines l ON l.order_id = o._id AND l.qty > 1
