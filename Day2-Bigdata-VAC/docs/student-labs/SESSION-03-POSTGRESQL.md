# Session 3 - PostgreSQL Operational E-Commerce Data

**Duration:** 60 minutes

## Objective

Query the operational e-commerce database and understand the source data that will later be captured by Debezium.

## 1. Connect to PostgreSQL

Use any PostgreSQL client or execute commands inside the container.

```powershell
docker exec -it ecommerce-postgres psql -U ecommerce -d ecommerce
```

## 2. List tables

```sql
\dt
```

Expected tables:

```text
customers
products
orders
order_items
payments
clickstream_events
```

## 3. Inspect row counts

```sql
SELECT 'customers' AS table_name, COUNT(*) FROM customers
UNION ALL SELECT 'products', COUNT(*) FROM products
UNION ALL SELECT 'orders', COUNT(*) FROM orders
UNION ALL SELECT 'order_items', COUNT(*) FROM order_items
UNION ALL SELECT 'payments', COUNT(*) FROM payments;
```

## 4. Query orders

```sql
SELECT order_id, customer_id, order_date, total_amount, status
FROM orders
ORDER BY total_amount DESC
LIMIT 10;
```

## 5. Sales calculation

```sql
SELECT status,
       COUNT(*) AS orders,
       SUM(total_amount) AS revenue
FROM orders
GROUP BY status
ORDER BY revenue DESC;
```

## 6. Join orders and customers

```sql
SELECT c.name, c.city, o.order_id, o.total_amount, o.status
FROM customers c
JOIN orders o ON o.customer_id = c.customer_id
ORDER BY o.total_amount DESC
LIMIT 10;
```

## 7. Perform a controlled change

Choose one order and first inspect it:

```sql
SELECT * FROM orders WHERE order_id = '<order-id>';
```

Then change only a safe field as instructed by the trainer, for example status:

```sql
UPDATE orders
SET status = 'PROCESSING'
WHERE order_id = '<order-id>';
```

Verify:

```sql
SELECT * FROM orders WHERE order_id = '<order-id>';
```

This change is used in the Debezium session.

Exit:

```sql
\q
```

## Checkpoint

Explain why PostgreSQL is called the operational source in this lab.

## Evidence

Submit the table list, row counts and one join query result.
