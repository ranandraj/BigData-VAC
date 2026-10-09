# Session 10 - Trino Distributed SQL Analytics

**Duration:** 75 minutes

## Objective

Use Trino to answer e-commerce business questions over the Iceberg analytical tables.

## 1. Check Trino

```powershell
docker exec trino trino --server http://localhost:8080 --execute "SELECT 1"
```

## 2. List tables

```powershell
docker exec trino trino --server http://localhost:8080 --catalog iceberg --schema ecommerce --execute "SHOW TABLES"
```

## 3. Revenue by status

```sql
SELECT status,
       COUNT(*) AS orders,
       ROUND(SUM(total_amount), 2) AS revenue
FROM iceberg.ecommerce.orders
GROUP BY status
ORDER BY revenue DESC;
```

## 4. Top customers

```sql
SELECT c.customer_id,
       c.name,
       COUNT(o.order_id) AS orders,
       ROUND(SUM(o.total_amount),2) AS revenue
FROM iceberg.ecommerce.customers c
JOIN iceberg.ecommerce.orders o
  ON c.customer_id = o.customer_id
GROUP BY c.customer_id, c.name
ORDER BY revenue DESC
LIMIT 10;
```

## 5. Product performance

```sql
SELECT p.product_name,
       p.category,
       SUM(oi.quantity) AS units_sold,
       ROUND(SUM(oi.quantity * oi.unit_price),2) AS gross_sales
FROM iceberg.ecommerce.order_items oi
JOIN iceberg.ecommerce.products p
  ON oi.product_id = p.product_id
GROUP BY p.product_name, p.category
ORDER BY gross_sales DESC
LIMIT 10;
```

## 6. Average order value

```sql
SELECT ROUND(AVG(total_amount),2) AS average_order_value
FROM iceberg.ecommerce.orders;
```

## 7. Student challenge

Write one SQL query that answers:

> Which customer city generated the highest order revenue?

Then write a second query:

> Which product category sold the most units?

## Checkpoint

Explain the difference between:

- PostgreSQL query
- Trino query
- Kafka event
- Flink streaming query

## Evidence

Submit three business SQL queries and their results.
