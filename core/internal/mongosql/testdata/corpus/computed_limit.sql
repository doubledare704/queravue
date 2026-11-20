SELECT _id, total - discount AS net FROM orders ORDER BY net, _id LIMIT 5
