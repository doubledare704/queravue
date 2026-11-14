-- Queravue seed for ClickHouse, mirroring seed/mysql. Loaded on first start of the
-- clickhouse service. To reload into a running one:
--   docker compose -f dev/docker-compose.yml exec -T clickhouse clickhouse-client --user queravue --password queravue --multiquery < dev/seed/clickhouse/01_schema.sql

CREATE DATABASE IF NOT EXISTS queravue;

DROP VIEW IF EXISTS queravue.customer_order_summary_view;
DROP VIEW IF EXISTS queravue.orders_by_customer_mv;
DROP TABLE IF EXISTS queravue.orders_by_customer;
DROP TABLE IF EXISTS queravue.order_items;
DROP TABLE IF EXISTS queravue.orders;
DROP TABLE IF EXISTS queravue.customers;
DROP TABLE IF EXISTS queravue.logs_no_pk;
DROP TABLE IF EXISTS queravue.million_items;
DROP TABLE IF EXISTS queravue.type_samples;

CREATE TABLE queravue.customers (
    id UInt32,
    name String,
    email String,
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree ORDER BY id;

INSERT INTO queravue.customers (id, name, email) VALUES
    (1, 'Alice Smith', 'alice@example.com'),
    (2, 'Bob Jones', 'bob@example.com'),
    (3, 'Charlie Brown', 'charlie@example.com');

CREATE TABLE queravue.orders (
    id UInt32,
    customer_id UInt32,
    total_amount Decimal(10, 2) DEFAULT 0,
    created_at DateTime DEFAULT now()
) ENGINE = MergeTree ORDER BY id;

INSERT INTO queravue.orders (id, customer_id, total_amount) VALUES
    (1, 1, 149.99),
    (2, 1, 49.50),
    (3, 2, 299.00);

CREATE TABLE queravue.order_items (
    order_id UInt32,
    item_id UInt32,
    product_name String,
    quantity UInt32 DEFAULT 1,
    unit_price Decimal(10, 2)
) ENGINE = MergeTree ORDER BY (order_id, item_id);

INSERT INTO queravue.order_items (order_id, item_id, product_name, quantity, unit_price) VALUES
    (1, 1, 'Mechanical Keyboard', 1, 120.00),
    (1, 2, 'Keycap Set', 1, 29.99),
    (2, 1, 'Mousepad', 1, 49.50),
    (3, 1, 'Monitor Stand', 1, 299.00);

CREATE TABLE queravue.logs_no_pk (
    logged_at DateTime DEFAULT now(),
    level LowCardinality(String),
    message String
) ENGINE = MergeTree ORDER BY tuple();

INSERT INTO queravue.logs_no_pk (level, message) VALUES
    ('INFO', 'System started'),
    ('WARN', 'High memory pressure'),
    ('INFO', 'Backup completed');

CREATE VIEW queravue.customer_order_summary_view AS
SELECT c.id AS customer_id,
       c.name AS customer_name,
       count(o.id) AS total_orders,
       sum(o.total_amount) AS spent
FROM queravue.customers AS c
LEFT JOIN queravue.orders AS o ON o.customer_id = c.id
GROUP BY c.id, c.name;

CREATE TABLE queravue.orders_by_customer (
    customer_id UInt32,
    orders UInt64,
    spent Decimal(38, 2)
) ENGINE = SummingMergeTree ORDER BY customer_id;

CREATE MATERIALIZED VIEW queravue.orders_by_customer_mv TO queravue.orders_by_customer AS
SELECT customer_id, count() AS orders, sum(total_amount) AS spent
FROM queravue.orders GROUP BY customer_id;

CREATE TABLE queravue.million_items (
    id UInt32,
    val UInt32,
    label String
) ENGINE = MergeTree ORDER BY id;

INSERT INTO queravue.million_items
SELECT number + 1, number + 1, concat('item ', toString(number + 1)) FROM numbers(1000000);

CREATE TABLE queravue.type_samples (
    id UInt32,
    flag Bool,
    big_unsigned UInt64,
    wide Int128,
    price Decimal(20, 4),
    maybe Nullable(Int32),
    tag LowCardinality(String),
    tags Array(String),
    pair Tuple(a Int32, b String),
    attrs Map(String, UInt32),
    dt DateTime64(3, 'Europe/Kyiv'),
    guid UUID,
    ip4 IPv4,
    ip6 IPv6,
    status Enum8('new' = 1, 'done' = 2),
    note Nullable(String)
) ENGINE = MergeTree PARTITION BY toYYYYMM(dt) ORDER BY id;

INSERT INTO queravue.type_samples VALUES
    (1, true, 18446744073709551615, 170141183460469231731687303715884105727, 12345678.9012, 7, 'alpha',
     ['x', 'y'], (1, 'one'), map('k', 2), '2026-01-02 03:04:05.678', '12345678-9abc-def0-0123-456789abcdef',
     '192.168.0.1', '2001:db8::1', 'done', 'full row'),
    (2, false, 0, -1, -0.0001, NULL, 'beta', [], (0, ''), map(), '2026-01-02 03:04:05.678', '00000000-0000-0000-0000-000000000000',
     '0.0.0.0', '::', 'new', NULL);
