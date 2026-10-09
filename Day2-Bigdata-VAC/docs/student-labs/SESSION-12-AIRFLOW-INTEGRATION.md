# Session 12 - Airflow Workflow Automation & Final E-Commerce Integration

**Duration:** 75 minutes

## Objective

Use Apache Airflow to execute a real analytical workflow instead of placeholder tasks. The DAG validates the source services, refreshes partitioned Iceberg/Parquet tables, applies schema evolution, prepares Trino analytics views and generates a management report.

Airflow TaskFlow uses Python functions decorated as tasks and builds task dependencies from the function calls. urlApache Airflow TaskFlow documentationhttps://airflow.apache.org/docs/apache-airflow/stable/core-concepts/taskflow.html

## 1. Open Airflow

```text
http://localhost:8085
```

Find:

```text
ecommerce_end_to_end
```

The DAG is manual by design. Trigger it from the Airflow UI.

## 2. Understand the actual workflow

```text
Verify Sources
      ↓
Refresh Iceberg / Parquet
      ↓
Schema Evolution
      ↓
Prepare Trino Analytics
      ↓
Generate Management Report
```

## 3. Trigger the DAG

In Airflow:

1. Open `ecommerce_end_to_end`.
2. Trigger a manual run.
3. Open Graph view.
4. Watch each task change from queued/running to success.
5. Open task logs.

## 4. Verify source validation

The first task checks:

- Trino
- Debezium
- Flink JobManager
- PostgreSQL e-commerce order data

The DAG does not replace the streaming Flink job. It validates that the real-time platform is available before refreshing analytical data.

## 5. Verify analytical refresh

The refresh task:

```text
PostgreSQL orders
       ↓
Trino
       ↓
Iceberg orders
       ↓
Parquet files
       ↓
HDFS
```

The orders table remains partitioned by `day(order_date)`.

## 6. Verify schema evolution

The DAG checks whether `sales_channel` exists.

If it does not exist, Airflow executes:

```sql
ALTER TABLE iceberg.ecommerce.orders
ADD COLUMN sales_channel VARCHAR;
```

It then populates the field and continues the workflow.

## 7. Verify analytics views

The DAG creates:

```text
daily_sales
customer_sales
realtime_funnel
```

Query them through Trino:

```powershell
docker exec trino trino --server http://localhost:8080 --catalog iceberg --schema ecommerce --execute "SELECT * FROM daily_sales ORDER BY order_date"
```

```powershell
docker exec trino trino --server http://localhost:8080 --catalog iceberg --schema ecommerce --execute "SELECT * FROM customer_sales ORDER BY revenue DESC LIMIT 10"
```

## 8. Verify management report

The final Airflow task creates:

```text
reports/management_report.csv
```

It contains:

- order status
- order count
- revenue
- average order value

## 9. Complete end-to-end demonstration

### Real-time path

```text
E-commerce event
      ↓
Kafka
      ↓
Flink SQL
      ↓
Metrics / anomaly topics
      ↓
Streamlit Kafka consumer
      ↓
MongoDB
      ↓
Streamlit dashboard
```

### Historical and analytical path

```text
CSV / JSON + PostgreSQL
          ↓
        HDFS raw
          ↓
PostgreSQL operational data
          ↓
       Trino load
          ↓
Iceberg + Parquet on HDFS
          ↓
        Trino SQL
          ↓
   Analytics / Reports
```

### Workflow path

```text
Airflow
   ↓
Validation
   ↓
Analytical refresh
   ↓
Schema evolution
   ↓
Trino views
   ↓
Management report
```

## 10. Final integration test

### Start or verify the real-time Flink job

```powershell
.\scripts\RUN-FLINK-SQL.ps1
```

### Generate live events

```powershell
.\scripts\GENERATE-CLICKSTREAM.ps1 -Count 300
```

### Check Flink

```text
http://localhost:8081
```

Confirm the streaming job is running.

### Check MongoDB results

```powershell
docker exec mongodb mongosh --quiet --eval "db=db.getSiblingDB('ecommerce_analytics'); print('metrics=' + db.realtime_metrics.countDocuments()); print('alerts=' + db.alerts.countDocuments())"
```

### Check Trino

```powershell
docker exec trino trino --server http://localhost:8080 --catalog iceberg --schema ecommerce --execute "SELECT COUNT(*) orders, ROUND(SUM(total_amount),2) revenue FROM orders"
```

### Run Airflow

Trigger `ecommerce_end_to_end` and wait for all tasks to succeed.

### Check dashboard

```text
http://localhost:8501
```

The dashboard should show both:

- historical analytical KPIs from Trino
- real-time Flink metrics from MongoDB

## 11. Final student challenge: trace one order

Each team must select an order ID and explain where it appears in the system:

```text
PostgreSQL orders
      ↓
Debezium CDC
      ↓
Kafka CDC topic
      ↓
Kafka event stream
      ↓
Flink processing
      ↓
MongoDB / Streamlit real-time result
```

Then explain the analytical representation:

```text
PostgreSQL / HDFS
      ↓
Parquet
      ↓
Iceberg
      ↓
Trino
      ↓
Dashboard / Report
```

## Final evidence

Submit:

- Architecture diagram
- HDFS raw and analytical screenshots
- PostgreSQL query output
- NiFi flow screenshot
- Kafka topic/consumer output
- Debezium CDC output
- Flink Web UI screenshot
- MongoDB metric and alert counts
- Iceberg partitioned table definition
- Schema evolution before/after output
- Trino analytics query
- Streamlit dashboard screenshot
- Airflow DAG Graph view
- Airflow successful run screenshot
- Generated `management_report.csv`
