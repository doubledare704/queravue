SELECT status, COUNT(*), SUM(total), AVG(total) FROM orders GROUP BY status
