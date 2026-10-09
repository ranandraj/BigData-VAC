# Session 9 - Parquet, Apache Iceberg, Partitioning & Schema Evolution

**Duration:** 75 minutes

## Objective

Build and inspect Parquet-backed Iceberg analytical tables on HDFS, then demonstrate hidden partitioning and schema evolution using the e-commerce orders table.

## 1. Prepare analytical tables

```powershell
.\scripts\INIT-ANALYTICS.ps1
```

The setup creates:

```text
PostgreSQL operational tables
        ↓
Trino
        ↓
Apache Iceberg tables
        ↓
Parquet files on HDFS
```

## 2. Verify HDFS analytical storage

```powershell
docker exec hdfs-namenode /opt/hadoop/bin/hdfs dfs -ls -R /ecommerce/iceberg | Select-Object -First 40
```

## 3. Inspect the Iceberg orders table

```powershell
docker exec trino trino --server http://localhost:8080 --catalog iceberg --schema ecommerce --execute "SHOW CREATE TABLE orders"
```

Look for:

```text
format = PARQUET
partitioning = ARRAY['day(order_date)']
```

Iceberg uses hidden partitioning, so students query `order_date` normally without maintaining a separate partition column. urlApache Iceberg partitioning documentationhttps://iceberg.apache.org/docs/1.7.1/partitioning/

## 4. Query a partition-friendly workload

```powershell
docker exec trino trino --server http://localhost:8080 --catalog iceberg --schema ecommerce --execute "SELECT order_date, COUNT(*) orders, ROUND(SUM(total_amount),2) revenue FROM orders WHERE order_date >= DATE '2026-09-20' GROUP BY order_date ORDER BY order_date"
```

## 5. Demonstrate schema evolution

Before changing the schema:

```powershell
docker exec trino trino --server http://localhost:8080 --catalog iceberg --schema ecommerce --execute "DESCRIBE orders"
```

Add a business attribute:

```powershell
docker exec trino trino --server http://localhost:8080 --catalog iceberg --schema ecommerce --execute "ALTER TABLE orders ADD COLUMN sales_channel VARCHAR"
```

Verify:

```powershell
docker exec trino trino --server http://localhost:8080 --catalog iceberg --schema ecommerce --execute "DESCRIBE orders"
```

Populate the new field for the existing e-commerce data:

```powershell
docker exec trino trino --server http://localhost:8080 --catalog iceberg --schema ecommerce --execute "UPDATE orders SET sales_channel = CASE WHEN MOD(CAST(substr(order_id,2) AS BIGINT),3)=0 THEN 'WEB' WHEN MOD(CAST(substr(order_id,2) AS BIGINT),3)=1 THEN 'MOBILE' ELSE 'MARKETPLACE' END"
```

Verify:

```powershell
docker exec trino trino --server http://localhost:8080 --catalog iceberg --schema ecommerce --execute "SELECT sales_channel, COUNT(*) orders FROM orders GROUP BY sales_channel ORDER BY orders DESC"
```

Iceberg supports in-place schema evolution such as adding, dropping, renaming and reordering fields without rewriting existing data files. urlApache Iceberg schema evolution documentationhttps://iceberg.apache.org/docs/nightly/evolution/

## 6. Understand the layers

| Layer | Technology | Responsibility |
|---|---|---|
| Storage | HDFS | Distributed file storage |
| File format | Parquet | Columnar data files |
| Table format | Iceberg | Table metadata, snapshots and schema/partition management |
| Query engine | Trino | Distributed SQL analytics |

## 7. Student challenge

Create an analytical query that compares revenue by:

```text
order_date
sales_channel
status
```

Then explain how the logical query remains independent of the physical Iceberg partition layout.

## Checkpoint

Students must demonstrate:

- HDFS contains Iceberg/Parquet data.
- `orders` is partitioned by `day(order_date)`.
- `sales_channel` was added after the initial table creation.
- Existing order rows remain queryable after the schema change.

## Evidence

Submit:

- HDFS analytical directory screenshot
- `SHOW CREATE TABLE orders` output
- Before/after `DESCRIBE orders`
- `sales_channel` query output
- One partition-filtered revenue query
