SELECT c.city AS city, COUNT(DISTINCT o.status) AS kinds FROM orders o JOIN customers c ON o.customer_id = c._id GROUP BY c.city
