SELECT c._id AS cid, COUNT(o._id) AS orders FROM customers c LEFT JOIN orders o ON o.customer_id = c._id GROUP BY c._id
