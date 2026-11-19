SELECT * FROM orders WHERE customer_id IN (SELECT _id FROM customers)
