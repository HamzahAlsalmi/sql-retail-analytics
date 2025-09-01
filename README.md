# SQL Retail Analytics

A simple SQL project analyzing a fictional retail dataset.  
Includes schema, sample data, and queries to answer key business questions.

---

## Highlights
- Data modeling with customers, orders, products, regions, and order_items
- Business questions answered with joins, aggregates, and CTEs
- Screenshot-ready queries for your portfolio

---

## Files
- `schema.sql` — database tables  
- `seed.sql` — sample data  
- `queries/analysis.sql` — example analysis queries  

---

## How to Run (SQLite)

```bash
# 1) Create and load the database
sqlite3 retail.db < schema.sql
sqlite3 retail.db < seed.sql

# 2) (Option A) Run all sample queries and export to CSV
sqlite3 -header -csv retail.db < queries/analysis.sql > results.csv

# 2) (Option B) Open an interactive shell for screenshots
sqlite3 retail.db
.headers on
.mode box
SELECT COUNT(*) AS customers FROM customers;
SELECT COUNT(*) AS orders FROM orders;
Tip: Use .mode box (or .mode column) for nice terminal screenshots.

Questions Answered
Top customers by lifetime revenue

Monthly revenue trend

Top products by revenue (and % of total)

Average order value by region

Revenue lost to discounts

Screenshots
SQLite overview



Top products by revenue



Project Structure
pgsql
Copy code
sql-retail-analytics/
├─ schema.sql
├─ seed.sql
├─ queries/
│  └─ analysis.sql
└─ images/
   ├─ overview.png
   └─ top_products.png
Notes
SQLite-first. For Postgres, switch date columns to DATE and use a surrogate BIGSERIAL for order_items.line_id.

Local files like retail.db, backups, and .DS_Store should be in .gitignore.

License
MIT — use, learn, and adapt freely.
