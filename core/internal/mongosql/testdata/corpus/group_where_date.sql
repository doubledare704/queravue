SELECT status, COUNT(*) AS n FROM orders WHERE created >= DATE '2024-01-01' GROUP BY status
