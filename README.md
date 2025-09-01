# SQL Retail Analytics

A simple SQL project analyzing a fictional retail dataset.  
Includes schema, sample data, and queries to answer key business questions.

---

## Files
- `schema.sql` → database tables  
- `seed.sql` → sample data  
- `queries/analysis.sql` → analysis queries  

---

## How to Run
```bash
# SQLite
sqlite3 retail.db < schema.sql
sqlite3 retail.db < seed.sql
sqlite3 -header -csv retail.db < queries/analysis.sql > results.csv
Insights
Queries cover:

Top customers & revenue trends

Product sales ranking

Average order value by region

Repeat purchases & retention

Discount impact

Purpose
Built as a portfolio project to showcase SQL skills in data modeling, joins, CTEs, and business analysis.


## SCREENSHOTS:
<img width="922" height="487" alt="Screenshot 2025-09-01 at 2 15 42 PM" src="https://github.com/user-attachments/assets/21e8791c-5e2e-4516-834d-a1c22ef47d6c" />
<img width="705" height="433" alt="Screenshot 2025-09-01 at 2 22 51 PM" src="https://github.com/user-attachments/assets/0b929fd1-fa90-4f5e-baac-d55a9f6c48f4" />


