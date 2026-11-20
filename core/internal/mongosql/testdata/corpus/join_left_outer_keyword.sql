SELECT c._id AS cid, o._id AS order_id FROM customers c LEFT OUTER JOIN orders o ON o.customer_id = c._id
