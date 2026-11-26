SELECT address.city AS city, COUNT(*) AS n FROM users GROUP BY address.city
