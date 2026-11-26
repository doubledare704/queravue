SELECT tier, COUNT(*) AS n FROM customers WHERE name LIKE 'A%' OR name LIKE '%e' GROUP BY tier
