-- Queravue seed data for CockroachDB, derived from seed/postgres.
-- CockroachDB has no init directory; load it with:
--   docker exec -i queravue-dev-cockroachdb-1 ./cockroach sql --insecure < dev/seed/cockroachdb/01_schema.sql

CREATE DATABASE IF NOT EXISTS queravue;
USE queravue;
-- SERIAL defaults to unique_rowid() (huge, non-sequential ids) otherwise.
SET serial_normalization = sql_sequence;


-- Drop existing test objects if present
DROP MATERIALIZED VIEW IF EXISTS monthly_sales_matview CASCADE;
DROP VIEW IF EXISTS customer_order_summary_view CASCADE;
DROP TABLE IF EXISTS order_items CASCADE;
DROP TABLE IF EXISTS orders CASCADE;
DROP TABLE IF EXISTS customers CASCADE;
DROP TABLE IF EXISTS logs_no_pk CASCADE;
DROP TABLE IF EXISTS "пользователи" CASCADE;
DROP TABLE IF EXISTS "café" CASCADE;
DROP TABLE IF EXISTS million_items CASCADE;

-- 1. Customers (single PK)
CREATE TABLE customers (
    id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO customers (name, email) VALUES
    ('Alice Smith', 'alice@example.com'),
    ('Bob Jones', 'bob@example.com'),
    ('Charlie Brown', 'charlie@example.com');

-- 2. Orders (FK to customers)
CREATE TABLE orders (
    id SERIAL PRIMARY KEY,
    customer_id INT NOT NULL REFERENCES customers(id) ON DELETE CASCADE,
    total_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO orders (customer_id, total_amount) VALUES
    (1, 149.99),
    (1, 49.50),
    (2, 299.00);

-- 3. Composite PK table with FKs
CREATE TABLE order_items (
    order_id INT NOT NULL REFERENCES orders(id) ON DELETE CASCADE,
    item_id INT NOT NULL,
    product_name TEXT NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    unit_price NUMERIC(10, 2) NOT NULL,
    PRIMARY KEY (order_id, item_id)
);

INSERT INTO order_items (order_id, item_id, product_name, quantity, unit_price) VALUES
    (1, 1, 'Mechanical Keyboard', 1, 120.00),
    (1, 2, 'Keycap Set', 1, 29.99),
    (2, 1, 'Mousepad', 1, 49.50),
    (3, 1, 'Monitor Stand', 1, 299.00);

-- 4. Table without a primary key (read-only in UI)
CREATE TABLE logs_no_pk (
    logged_at TIMESTAMPTZ DEFAULT NOW(),
    level VARCHAR(20) NOT NULL,
    message TEXT NOT NULL
);

INSERT INTO logs_no_pk (level, message) VALUES
    ('INFO', 'System started'),
    ('WARN', 'High memory pressure'),
    ('INFO', 'Backup completed');

-- 5. Standard View
CREATE VIEW customer_order_summary_view AS
SELECT c.id AS customer_id,
       c.name AS customer_name,
       COUNT(o.id) AS total_orders,
       COALESCE(SUM(o.total_amount), 0.00) AS spent
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.name;

-- 6. Materialized View
CREATE MATERIALIZED VIEW monthly_sales_matview AS
SELECT DATE_TRUNC('month', created_at) AS month,
       COUNT(*) AS order_count,
       SUM(total_amount) AS total_revenue
FROM orders
GROUP BY DATE_TRUNC('month', created_at);

-- 7. Unicode table and column names
CREATE TABLE "пользователи" (
    "ид" SERIAL PRIMARY KEY,
    "имя" TEXT NOT NULL,
    "город" TEXT
);

INSERT INTO "пользователи" ("имя", "город") VALUES
    ('Олексій', 'Київ'),
    ('Марія', 'Львів');

CREATE TABLE "café" (
    "id" SERIAL PRIMARY KEY,
    "nom" TEXT NOT NULL,
    "spécialité" TEXT
);

INSERT INTO "café" ("nom", "spécialité") VALUES
    ('Café de Flore', 'Croissant'),
    ('Les Deux Magots', 'Espresso');

-- 8. 1M row table with index on val for performance testing
CREATE TABLE million_items (
    id SERIAL PRIMARY KEY,
    val INT NOT NULL,
    label TEXT NOT NULL
);

CREATE INDEX idx_million_items_val ON million_items(val);

INSERT INTO million_items (val, label)
SELECT i, 'item ' || i
FROM generate_series(1, 1000000) AS s(i);

CREATE STATISTICS million_items_stats FROM million_items;

