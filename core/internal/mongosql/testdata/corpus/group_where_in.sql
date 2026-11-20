SELECT city, COUNT(*) AS n FROM customers WHERE tier IN ('gold', 'silver') GROUP BY city
