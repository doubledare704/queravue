SELECT city, COUNT(*) AS n FROM customers GROUP BY city HAVING city <> 'Kyiv' AND COUNT(*) >= 2
