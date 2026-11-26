SELECT o.number, c.address.city FROM orders o JOIN customers c ON o.customer.id = c.ref.id
