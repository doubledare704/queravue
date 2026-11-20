SELECT c.name, SUM(o.total - o.discount) AS net FROM orders o JOIN customers c ON o.customer_id = c._id GROUP BY c.name
