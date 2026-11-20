SELECT o.number AS num, o.total, o.customer.name
FROM orders o
WHERE o.status IN ('paid', 'shipped')
  AND o.total BETWEEN 100 AND 500
  AND o.customer.email LIKE '%@example.com'
  AND o.cancelled IS NULL
ORDER BY o.total DESC, num
LIMIT 50 OFFSET 100
