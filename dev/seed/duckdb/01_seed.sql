CREATE SEQUENCE customers_id_seq;
CREATE TABLE customers (
    id INTEGER PRIMARY KEY DEFAULT nextval('customers_id_seq'),
    name VARCHAR NOT NULL,
    email VARCHAR UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT now()
);
INSERT INTO customers (name, email) VALUES
    ('Alice Smith', 'alice@example.com'),
    ('Bob Jones', 'bob@example.com'),
    ('Charlie Brown', 'charlie@example.com');

CREATE SEQUENCE orders_id_seq;
CREATE TABLE orders (
    id INTEGER PRIMARY KEY DEFAULT nextval('orders_id_seq'),
    customer_id INTEGER NOT NULL REFERENCES customers (id),
    total_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMPTZ DEFAULT now()
);
INSERT INTO orders (customer_id, total_amount) VALUES (1, 149.99), (1, 49.50), (2, 299.00);

CREATE TABLE order_items (
    order_id INTEGER NOT NULL REFERENCES orders (id),
    item_id INTEGER NOT NULL,
    product_name VARCHAR NOT NULL,
    quantity INTEGER NOT NULL DEFAULT 1,
    unit_price DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (order_id, item_id)
);
INSERT INTO order_items VALUES
    (1, 1, 'Mechanical Keyboard', 1, 120.00),
    (1, 2, 'Keycap Set', 1, 29.99),
    (2, 1, 'Mousepad', 1, 49.50),
    (3, 1, 'Monitor Stand', 1, 299.00);

CREATE TABLE logs_no_pk (
    logged_at TIMESTAMPTZ DEFAULT now(),
    level VARCHAR NOT NULL,
    message VARCHAR NOT NULL
);
INSERT INTO logs_no_pk (level, message) VALUES
    ('INFO', 'System started'),
    ('WARN', 'High memory pressure'),
    ('INFO', 'Backup completed');

CREATE VIEW customer_order_summary_view AS
SELECT c.id AS customer_id,
       c.name AS customer_name,
       COUNT(o.id) AS total_orders,
       COALESCE(SUM(o.total_amount), 0.00) AS spent
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.name;

CREATE TABLE million_items (
    id INTEGER PRIMARY KEY,
    val INTEGER NOT NULL,
    payload VARCHAR NOT NULL
);
INSERT INTO million_items SELECT i, i, 'item-' || i::VARCHAR FROM range(1, 1000001) AS t(i);
