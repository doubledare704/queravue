SELECT tier, AVG(age) AS mean_age FROM customers WHERE age BETWEEN 25 AND 50 GROUP BY tier ORDER BY tier
