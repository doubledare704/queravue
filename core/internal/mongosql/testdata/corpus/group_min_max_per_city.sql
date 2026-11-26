SELECT city, MIN(age) AS youngest, MAX(age) AS oldest FROM customers GROUP BY city
