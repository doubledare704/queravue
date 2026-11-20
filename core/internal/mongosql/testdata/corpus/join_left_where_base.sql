SELECT c._id AS cid, o._id AS order_id FROM customers c LEFT JOIN orders o ON o.customer_id = c._id WHERE c.tier = 'bronze'
