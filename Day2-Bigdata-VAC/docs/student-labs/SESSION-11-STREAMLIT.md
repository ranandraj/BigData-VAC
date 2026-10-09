# Session 11 - Streamlit E-Commerce Analytics Dashboard

**Duration:** 90 minutes

## Objective

Use the supplied Streamlit application to present operational, analytical and real-time e-commerce results.

## 1. Open dashboard

```text
http://localhost:8501
```

## 2. Verify system status

The dashboard reads operational order, product, customer and clickstream data from `postgresql.public`. The Sales Channel panel reads the Iceberg table after analytical initialization and schema evolution.

The dashboard should show connection status for:

- Trino
- MongoDB

## 3. Inspect KPI cards

Identify:

- Total Orders
- Revenue
- Customers
- Average Order Value

Verify one KPI manually with Trino.

Example:

```sql
SELECT COUNT(*) AS total_orders,
       ROUND(SUM(total_amount),2) AS revenue,
       COUNT(DISTINCT customer_id) AS customers,
       ROUND(AVG(total_amount),2) AS aov
FROM postgresql.public.orders;
```

## 4. Sales analytics

Inspect the revenue trend and compare it with the Trino query results.

## 5. Product analytics

Identify the top products and compare the displayed result with a Trino query.

## 6. Customer analytics

Find the highest-revenue customer and verify it using SQL.

## 7. Real-time Flink analytics

Start the Flink job if it is not already running:

```powershell
.\scripts\RUN-FLINK-SQL.ps1
```

Generate events:

```powershell
.\scripts\GENERATE-CLICKSTREAM.ps1 -Count 300
```

Refresh the dashboard.

Observe:

- Orders per minute
- Revenue
- Active users
- Cart events
- High-value order alerts

## 8. Funnel analysis

Inspect:

```text
Product View -> Cart -> Checkout -> Order -> Payment
```

Discuss which event counts are higher/lower and why.

## 9. Student task

Choose one dashboard number and trace it backwards:

```text
Dashboard
   ↓
SQL / MongoDB
   ↓
Trino / Flink
   ↓
Iceberg / Kafka
   ↓
Source data
```

## Checkpoint

Demonstrate one historical KPI and one live Flink KPI.

## Evidence

Submit a dashboard screenshot and the SQL used to verify one KPI.
