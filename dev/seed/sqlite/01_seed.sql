PRAGMA foreign_keys = ON;

CREATE TABLE authors (
  id INTEGER PRIMARY KEY,
  name TEXT NOT NULL,
  country TEXT,
  born DATE
);
CREATE TABLE books (
  id INTEGER PRIMARY KEY,
  author_id INTEGER NOT NULL REFERENCES authors(id) ON DELETE CASCADE,
  title TEXT NOT NULL,
  price REAL NOT NULL,
  published DATE,
  in_stock INTEGER NOT NULL DEFAULT 1
);
CREATE INDEX idx_books_author ON books(author_id);
CREATE TABLE sales (
  id INTEGER PRIMARY KEY,
  book_id INTEGER NOT NULL REFERENCES books(id),
  qty INTEGER NOT NULL,
  sold_at DATETIME NOT NULL
);
CREATE VIEW revenue_by_author AS
  SELECT a.name, ROUND(SUM(s.qty * b.price), 2) AS revenue
  FROM sales s JOIN books b ON b.id = s.book_id JOIN authors a ON a.id = b.author_id
  GROUP BY a.id;

INSERT INTO authors (name, country, born) VALUES
  ('Ursula K. Le Guin', 'US', '1929-10-21'),
  ('Stanislaw Lem', 'PL', '1921-09-12'),
  ('Octavia Butler', 'US', '1947-06-22'),
  ('Ivan Franko', 'UA', '1856-08-27'),
  ('Haruki Murakami', 'JP', '1949-01-12');

INSERT INTO books (author_id, title, price, published, in_stock) VALUES
  (1, 'The Dispossessed', 14.99, '1974-05-01', 1),
  (1, 'A Wizard of Earthsea', 11.50, '1968-11-01', 1),
  (2, 'Solaris', 12.00, '1961-01-01', 1),
  (2, 'The Cyberiad', 13.25, '1965-01-01', 0),
  (3, 'Kindred', 15.00, '1979-06-01', 1),
  (4, 'Zakhar Berkut', 9.99, '1883-01-01', 1),
  (5, 'Kafka on the Shore', 16.50, '2002-09-12', 1);

WITH RECURSIVE n(i) AS (SELECT 1 UNION ALL SELECT i + 1 FROM n WHERE i < 50000)
INSERT INTO sales (book_id, qty, sold_at)
SELECT 1 + i % 7, 1 + i % 5, datetime('2025-01-01', '+' || (i % 600) || ' days', '+' || (i % 1440) || ' minutes')
FROM n;
