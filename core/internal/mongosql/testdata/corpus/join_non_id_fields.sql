SELECT l._id AS line_id, p.name AS product FROM order_lines l JOIN products p ON l.sku = p.sku
