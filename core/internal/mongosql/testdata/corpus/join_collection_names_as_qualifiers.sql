SELECT orders._id AS oid, customers.name AS customer FROM orders JOIN customers ON orders.customer_id = customers._id
