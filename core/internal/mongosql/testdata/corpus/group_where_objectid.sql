SELECT status, COUNT(*) AS n FROM orders WHERE customer_id = OBJECTID('507f1f77bcf86cd799439011') GROUP BY status
