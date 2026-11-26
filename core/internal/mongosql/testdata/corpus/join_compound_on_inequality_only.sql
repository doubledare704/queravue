SELECT a._id AS low, b._id AS high FROM customers a JOIN customers b ON a._id < b._id AND b._id <= 3
