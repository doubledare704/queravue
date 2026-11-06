-- Queravue seed data for MySQL / MariaDB / TiDB, mirroring seed/postgres.
-- Loaded automatically on first start of the mysql and mariadb services
-- (docker-entrypoint-initdb.d). For tidb run: mysql -h127.0.0.1 -P4000 -uroot < seed/tidb/01_schema.sql

CREATE DATABASE IF NOT EXISTS queravue;
USE queravue;

DROP VIEW IF EXISTS customer_order_summary_view;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS logs_no_pk;
DROP TABLE IF EXISTS `пользователи`;
DROP TABLE IF EXISTS `café`;
DROP TABLE IF EXISTS million_items;
DROP TABLE IF EXISTS type_samples;

-- 1. Customers (single PK)
CREATE TABLE customers (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP
);

INSERT INTO customers (name, email) VALUES
    ('Alice Smith', 'alice@example.com'),
    ('Bob Jones', 'bob@example.com'),
    ('Charlie Brown', 'charlie@example.com');

-- 2. Orders (FK to customers)
CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    customer_id INT NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);

INSERT INTO orders (customer_id, total_amount) VALUES
    (1, 149.99),
    (1, 49.50),
    (2, 299.00);

-- 3. Composite PK table with FKs
CREATE TABLE order_items (
    order_id INT NOT NULL,
    item_id INT NOT NULL,
    product_name TEXT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    unit_price DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (order_id, item_id),
    CONSTRAINT fk_items_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
);

INSERT INTO order_items (order_id, item_id, product_name, quantity, unit_price) VALUES
    (1, 1, 'Mechanical Keyboard', 1, 120.00),
    (1, 2, 'Keycap Set', 1, 29.99),
    (2, 1, 'Mousepad', 1, 49.50),
    (3, 1, 'Monitor Stand', 1, 299.00);

-- 4. Table without a primary key (read-only in UI)
CREATE TABLE logs_no_pk (
    logged_at TIMESTAMP NULL DEFAULT CURRENT_TIMESTAMP,
    level VARCHAR(20) NOT NULL,
    message TEXT NOT NULL
);

INSERT INTO logs_no_pk (level, message) VALUES
    ('INFO', 'System started'),
    ('WARN', 'High memory pressure'),
    ('INFO', 'Backup completed');

-- 5. Standard view
CREATE VIEW customer_order_summary_view AS
SELECT c.id AS customer_id,
       c.name AS customer_name,
       COUNT(o.id) AS total_orders,
       COALESCE(SUM(o.total_amount), 0.00) AS spent
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.name;

-- 6. Unicode table and column names
CREATE TABLE `пользователи` (
    `ид` INT AUTO_INCREMENT PRIMARY KEY,
    `имя` TEXT NOT NULL,
    `город` TEXT
) DEFAULT CHARSET = utf8mb4;

INSERT INTO `пользователи` (`имя`, `город`) VALUES
    ('Олексій', 'Київ'),
    ('Марія', 'Львів');

CREATE TABLE `café` (
    `id` INT AUTO_INCREMENT PRIMARY KEY,
    `nom` TEXT NOT NULL,
    `spécialité` TEXT
) DEFAULT CHARSET = utf8mb4;

INSERT INTO `café` (`nom`, `spécialité`) VALUES
    ('Café de Flore', 'Croissant'),
    ('Les Deux Magots', 'Espresso');

-- 7. Type samples: the MySQL types that need care when mapping to values.
CREATE TABLE type_samples (
    id INT AUTO_INCREMENT PRIMARY KEY,
    flag TINYINT(1) NOT NULL DEFAULT 0,
    big_unsigned BIGINT UNSIGNED NOT NULL,
    price DECIMAL(20, 4) NOT NULL,
    dt DATETIME NULL,
    ts TIMESTAMP NULL,
    bits BIT(8) NULL,
    doc JSON NULL,
    blob_data BLOB NULL,
    note VARCHAR(50) NULL
) DEFAULT CHARSET = utf8mb4;

INSERT INTO type_samples (flag, big_unsigned, price, dt, ts, bits, doc, blob_data, note) VALUES
    (1, 18446744073709551615, 12345678.9012, '2026-01-02 03:04:05', '2026-01-02 03:04:05', b'10100101', '{"a": [1, 2]}', X'00FF10', 'max unsigned'),
    (0, 0, 0.0001, NULL, NULL, NULL, NULL, NULL, NULL);

-- 8. 1M row table with an index on val for performance testing
CREATE TABLE million_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    val INT NOT NULL,
    label VARCHAR(40) NOT NULL,
    KEY idx_million_items_val (val)
);

CREATE TABLE digits (d INT NOT NULL);
INSERT INTO digits (d) VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9);

INSERT INTO million_items (val, label)
SELECT n, CONCAT('item ', n) FROM (
    SELECT d1.d + d2.d * 10 + d3.d * 100 + d4.d * 1000 + d5.d * 10000 + d6.d * 100000 + 1 AS n
    FROM digits d1, digits d2, digits d3, digits d4, digits d5, digits d6
) t ORDER BY n;

DROP TABLE digits;
ANALYZE TABLE million_items;
