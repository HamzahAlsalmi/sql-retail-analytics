-- ANALYSIS QUERIES


-- 1) Lifetime revenue by customer with first and most recent order
WITH order_revenue AS (
  SELECT
    o.customer_id,
    SUM( (oi.unit_price * oi.quantity) * (1 - oi.discount) ) AS revenue
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  GROUP BY o.customer_id
),
first_last AS (
  SELECT customer_id,
         MIN(order_date) AS first_order_date,
         MAX(order_date) AS last_order_date
  FROM orders
  GROUP BY customer_id
)
SELECT
  c.customer_id,
  c.first_name || ' ' || c.last_name AS customer_name,
  fr.first_order_date,
  fr.last_order_date,
  ROUND(orv.revenue, 2) AS lifetime_revenue
FROM customers c
JOIN order_revenue orv ON orv.customer_id = c.customer_id
JOIN first_last fr ON fr.customer_id = c.customer_id
ORDER BY lifetime_revenue DESC
LIMIT 10;

-- 2) Monthly revenue trend with MoM growth
WITH monthly AS (
  SELECT
    strftime('%Y-%m', o.order_date) AS ym,            -- Use TO_CHAR(o.order_date,'YYYY-MM') on Postgres
    SUM( (oi.unit_price * oi.quantity) * (1 - oi.discount) ) AS revenue
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  GROUP BY 1
)
SELECT
  ym,
  ROUND(revenue, 2) AS revenue,
  ROUND( (revenue - LAG(revenue) OVER (ORDER BY ym)) / NULLIF(LAG(revenue) OVER (ORDER BY ym), 0) * 100, 2) AS mom_growth_pct
FROM monthly
ORDER BY ym;

-- 3) Product revenue ranking and % of total
WITH product_rev AS (
  SELECT
    p.product_id, p.product_name, p.category,
    SUM( (oi.unit_price * oi.quantity) * (1 - oi.discount) ) AS revenue
  FROM products p
  JOIN order_items oi ON oi.product_id = p.product_id
  JOIN orders o ON o.order_id = oi.order_id
  GROUP BY 1,2,3
),
tot AS (SELECT SUM(revenue) AS total_rev FROM product_rev)
SELECT
  product_id, product_name, category,
  ROUND(revenue,2) AS revenue,
  ROUND( revenue / (SELECT total_rev FROM tot) * 100, 2) AS pct_of_total,
  RANK() OVER (ORDER BY revenue DESC) AS rev_rank
FROM product_rev
ORDER BY rev_rank
LIMIT 15;

-- 4) AOV by region and month
WITH order_totals AS (
  SELECT
    o.order_id, o.region_id, strftime('%Y-%m', o.order_date) AS ym,
    SUM( (oi.unit_price * oi.quantity) * (1 - oi.discount) ) AS order_total
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  GROUP BY 1,2,3
)
SELECT
  r.region_name,
  ym,
  ROUND(AVG(order_total), 2) AS aov
FROM order_totals ot
JOIN regions r ON r.region_id = ot.region_id
GROUP BY 1,2
ORDER BY r.region_name, ym;

-- 5) Repeat purchase rate
WITH orders_per_customer AS (
  SELECT customer_id, COUNT(*) AS n_orders
  FROM orders
  GROUP BY 1
)
SELECT
  ROUND( SUM(CASE WHEN n_orders >= 2 THEN 1 ELSE 0 END) * 1.0 / COUNT(*), 3) AS repeat_purchase_rate
FROM orders_per_customer;

-- 6) Simple cohort retention (first-order month vs subsequent order months, rolling 6 months)
WITH first_order AS (
  SELECT customer_id, MIN(order_date) AS first_date
  FROM orders
  GROUP BY 1
),
orders_enriched AS (
  SELECT
    o.customer_id,
    o.order_date,
    strftime('%Y-%m', (SELECT first_date FROM first_order f WHERE f.customer_id=o.customer_id)) AS cohort,
    CAST((julianday(o.order_date) - julianday((SELECT first_date FROM first_order f WHERE f.customer_id=o.customer_id))) / 30 AS INT) AS months_since_first
  FROM orders o
)
SELECT cohort,
       months_since_first,
       COUNT(DISTINCT customer_id) AS active_customers
FROM orders_enriched
WHERE months_since_first BETWEEN 0 AND 6
GROUP BY 1,2
ORDER BY cohort, months_since_first;

-- 7) Contribution margin estimate
WITH line_calc AS (
  SELECT
    p.product_id, p.product_name, strftime('%Y-%m', o.order_date) AS ym,
    SUM( (oi.unit_price * oi.quantity) * (1 - oi.discount) ) AS revenue,
    SUM( p.unit_cost * oi.quantity ) AS cost
  FROM order_items oi
  JOIN products p ON p.product_id = oi.product_id
  JOIN orders o ON o.order_id = oi.order_id
  GROUP BY 1,2,3
)
SELECT
  product_id, product_name, ym,
  ROUND(revenue,2) AS revenue,
  ROUND(cost,2) AS cost,
  ROUND(revenue - cost,2) AS margin,
  ROUND( (revenue - cost) / NULLIF(revenue,0) * 100, 2) AS margin_pct
FROM line_calc
ORDER BY ym, margin_pct DESC;

-- 8) Basket analysis: average distinct products per order
SELECT
  ROUND(AVG(cnt), 2) AS avg_distinct_products_per_order
FROM (
  SELECT order_id, COUNT(DISTINCT product_id) AS cnt
  FROM order_items
  GROUP BY order_id
);

-- 9) Discounts: revenue lost by month and region
WITH no_disc AS (
  SELECT r.region_name, strftime('%Y-%m', o.order_date) AS ym,
         SUM(oi.unit_price * oi.quantity) AS no_discount_revenue
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN regions r ON r.region_id = o.region_id
  GROUP BY 1,2
),
with_disc AS (
  SELECT r.region_name, strftime('%Y-%m', o.order_date) AS ym,
         SUM( (oi.unit_price * oi.quantity) * (1 - oi.discount) ) AS net_revenue
  FROM orders o
  JOIN order_items oi ON oi.order_id = o.order_id
  JOIN regions r ON r.region_id = o.region_id
  GROUP BY 1,2
)
SELECT w.region_name, w.ym,
       ROUND(n.no_discount_revenue - w.net_revenue, 2) AS revenue_lost_to_discounts
FROM with_disc w
JOIN no_disc n ON n.region_name=w.region_name AND n.ym=w.ym
ORDER BY w.region_name, w.ym;

-- 10) Data quality checks
-- a) Orphan foreign keys (should be zero rows)
SELECT oi.order_id
FROM order_items oi
LEFT JOIN orders o ON o.order_id = oi.order_id
WHERE o.order_id IS NULL;

-- b) Negative quantities (should be zero rows)
SELECT *
FROM order_items
WHERE quantity <= 0;

-- c) Orders outside 2024 (should be zero rows)
SELECT *
FROM orders
WHERE order_date < DATE '2024-01-01' OR order_date > DATE '2024-12-31';

-- Notes for PostgreSQL users:
-- Replace strftime('%Y-%m', col) with TO_CHAR(col, 'YYYY-MM')
-- Replace julianday(date) with EXTRACT(EPOCH FROM date)::numeric/86400.0 and adjust arithmetic
