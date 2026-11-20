SELECT c.city AS city, COUNT(*) AS n, SUM(o.total) AS revenue FROM orders o JOIN customers c ON o.customer_id = c._id GROUP BY c.city
