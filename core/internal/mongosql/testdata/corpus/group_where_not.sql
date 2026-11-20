SELECT tier, COUNT(*) AS n FROM customers WHERE NOT city = 'Kyiv' GROUP BY tier
