-- Retail Analytics schema (ANSI-friendly for SQLite/Postgres)

DROP TABLE IF EXISTS order_items;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS products;
DROP TABLE IF EXISTS customers;
DROP TABLE IF EXISTS regions;

CREATE TABLE regions (
  region_id   INTEGER PRIMARY KEY,
  region_name TEXT NOT NULL
);

CREATE TABLE customers (
  customer_id INTEGER PRIMARY KEY,
  first_name  TEXT NOT NULL,
  last_name   TEXT NOT NULL,
  email       TEXT UNIQUE NOT NULL,
  join_date   DATE NOT NULL,
  region_id   INTEGER REFERENCES regions(region_id)
);

CREATE TABLE products (
  product_id  INTEGER PRIMARY KEY,
  product_name TEXT NOT NULL,
  category     TEXT NOT NULL,
  unit_cost    NUMERIC NOT NULL CHECK (unit_cost >= 0)
);

CREATE TABLE orders (
  order_id    INTEGER PRIMARY KEY,
  customer_id INTEGER NOT NULL REFERENCES customers(customer_id),
  order_date  DATE NOT NULL,
  region_id   INTEGER REFERENCES regions(region_id)
);

CREATE TABLE order_items (
  order_id    INTEGER NOT NULL REFERENCES orders(order_id),
  product_id  INTEGER NOT NULL REFERENCES products(product_id),
  unit_price  NUMERIC NOT NULL CHECK (unit_price >= 0),
  quantity    INTEGER NOT NULL CHECK (quantity > 0),
  discount    NUMERIC NOT NULL DEFAULT 0 CHECK (discount >= 0 AND discount <= 1),
  PRIMARY KEY (order_id, product_id)
);
