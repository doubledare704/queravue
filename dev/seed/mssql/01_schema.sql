-- Queravue seed data for SQL Server, mirroring seed/postgres.
-- Run by the one-shot compose service:
--   docker compose -f dev/docker-compose.yml --profile seed up mssql-seed
-- (or sqlcmd -S localhost -U sa -C -i dev/seed/mssql/01_schema.sql)
SET NOCOUNT ON;
GO
IF DB_ID(N'queravue') IS NULL CREATE DATABASE queravue;
GO
USE queravue;
GO
DROP VIEW IF EXISTS customer_order_summary_view;
DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS logs_no_pk;
DROP TABLE IF EXISTS [пользователи];
DROP TABLE IF EXISTS [café];
DROP TABLE IF EXISTS million_items;
DROP TABLE IF EXISTS type_samples;
GO

-- 1. Customers (single PK)
CREATE TABLE customers (
    id INT IDENTITY(1,1) PRIMARY KEY,
    name NVARCHAR(100) NOT NULL,
    email NVARCHAR(150) NOT NULL UNIQUE,
    created_at DATETIMEOFFSET NULL DEFAULT SYSDATETIMEOFFSET()
);
INSERT INTO customers (name, email) VALUES
    (N'Alice Smith', N'alice@example.com'),
    (N'Bob Jones', N'bob@example.com'),
    (N'Charlie Brown', N'charlie@example.com');

-- 2. Orders (FK to customers)
CREATE TABLE orders (
    id INT IDENTITY(1,1) PRIMARY KEY,
    customer_id INT NOT NULL,
    total_amount DECIMAL(10, 2) NOT NULL DEFAULT 0.00,
    created_at DATETIMEOFFSET NULL DEFAULT SYSDATETIMEOFFSET(),
    CONSTRAINT fk_orders_customer FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);
INSERT INTO orders (customer_id, total_amount) VALUES (1, 149.99), (1, 49.50), (2, 299.00);

-- 3. Composite PK table with FKs
CREATE TABLE order_items (
    order_id INT NOT NULL,
    item_id INT NOT NULL,
    product_name NVARCHAR(MAX) NOT NULL,
    quantity INT NOT NULL DEFAULT 1,
    unit_price DECIMAL(10, 2) NOT NULL,
    PRIMARY KEY (order_id, item_id),
    CONSTRAINT fk_items_order FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE
);
INSERT INTO order_items (order_id, item_id, product_name, quantity, unit_price) VALUES
    (1, 1, N'Mechanical Keyboard', 1, 120.00),
    (1, 2, N'Keycap Set', 1, 29.99),
    (2, 1, N'Mousepad', 1, 49.50),
    (3, 1, N'Monitor Stand', 1, 299.00);

-- 4. Table without a primary key (read-only in UI)
CREATE TABLE logs_no_pk (
    logged_at DATETIMEOFFSET NULL DEFAULT SYSDATETIMEOFFSET(),
    level NVARCHAR(20) NOT NULL,
    message NVARCHAR(MAX) NOT NULL
);
INSERT INTO logs_no_pk (level, message) VALUES
    (N'INFO', N'System started'), (N'WARN', N'High memory pressure'), (N'INFO', N'Backup completed');
GO

-- 5. Standard view (CREATE VIEW must be the only statement in its batch)
CREATE VIEW customer_order_summary_view AS
SELECT c.id AS customer_id,
       c.name AS customer_name,
       COUNT(o.id) AS total_orders,
       COALESCE(SUM(o.total_amount), 0.00) AS spent
FROM customers c
LEFT JOIN orders o ON o.customer_id = c.id
GROUP BY c.id, c.name;
GO

-- 6. Unicode table and column names
CREATE TABLE [пользователи] (
    [ид] INT IDENTITY(1,1) PRIMARY KEY,
    [имя] NVARCHAR(MAX) NOT NULL,
    [город] NVARCHAR(MAX)
);
INSERT INTO [пользователи] ([имя], [город]) VALUES (N'Олексій', N'Київ'), (N'Марія', N'Львів');
CREATE TABLE [café] (
    [id] INT IDENTITY(1,1) PRIMARY KEY,
    [nom] NVARCHAR(MAX) NOT NULL,
    [spécialité] NVARCHAR(MAX)
);
INSERT INTO [café] ([nom], [spécialité]) VALUES (N'Café de Flore', N'Croissant'), (N'Les Deux Magots', N'Espresso');

-- 7. Type samples: the SQL Server types that need care when mapping to values.
CREATE TABLE type_samples (
    id INT IDENTITY(1,1) PRIMARY KEY,
    guid UNIQUEIDENTIFIER NULL,
    amount MONEY NULL,
    price DECIMAL(20, 4) NULL,
    dto DATETIMEOFFSET(3) NULL,
    dt2 DATETIME2(3) NULL,
    ver ROWVERSION,
    big NVARCHAR(MAX) NULL,
    doc XML NULL,
    bin VARBINARY(MAX) NULL,
    flag BIT NULL
);
INSERT INTO type_samples (guid, amount, price, dto, dt2, big, doc, bin, flag) VALUES
    ('12345678-9ABC-DEF0-0123-456789ABCDEF', 922337203685477.5807, 12345678.9012,
     '2026-01-02 03:04:05.678 +02:00', '2026-01-02 03:04:05.678', REPLICATE(CAST(N'ж' AS NVARCHAR(MAX)), 10000),
     '<a><b>1</b></a>', 0x00FF10, 1),
    (NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);
GO

-- 8. 1M row table with an index on val for performance testing
CREATE TABLE million_items (
    id INT IDENTITY(1,1) PRIMARY KEY,
    val INT NOT NULL,
    label NVARCHAR(40) NOT NULL
);
CREATE INDEX idx_million_items_val ON million_items(val);
GO
WITH digits AS (SELECT d FROM (VALUES (0),(1),(2),(3),(4),(5),(6),(7),(8),(9)) v(d))
INSERT INTO million_items (val, label)
SELECT n, CONCAT(N'item ', n) FROM (
    SELECT d1.d + d2.d * 10 + d3.d * 100 + d4.d * 1000 + d5.d * 10000 + d6.d * 100000 + 1 AS n
    FROM digits d1, digits d2, digits d3, digits d4, digits d5, digits d6
) t ORDER BY n;
GO
UPDATE STATISTICS million_items;
GO
