SELECT a.name AS first, b.name AS second FROM customers a JOIN customers b ON a.city = b.city AND a._id < b._id
