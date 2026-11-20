SELECT city, SUM(age) AS total_age, COUNT(DISTINCT tier) AS tiers FROM customers GROUP BY city
