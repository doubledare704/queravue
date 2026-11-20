SELECT o._id AS order_id, c._id AS cid FROM orders o JOIN customers c ON o.customer_id = c._id AND c.age > o.qty * 10
