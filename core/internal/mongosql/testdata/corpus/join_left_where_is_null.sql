SELECT c.name AS name FROM customers c LEFT JOIN orders o ON o.customer_id = c._id WHERE o._id IS NULL
