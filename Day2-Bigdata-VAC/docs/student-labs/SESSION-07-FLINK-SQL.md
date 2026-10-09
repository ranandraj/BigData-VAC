# Session 7 - Apache Flink SQL Real-Time E-Commerce Analytics

**Duration:** 75 minutes

## Objective

Use the standard Flink Session Cluster and Flink SQL Client to process Kafka events without Java, Maven or a custom Flink application.

## 1. Start Flink

```powershell
.\scripts\START-LAB.ps1
```

Open:

```text
http://localhost:8081
```

Confirm one JobManager and one TaskManager are available.

## 2. Start the SQL job

```powershell
.\scripts\RUN-FLINK-SQL.ps1
```

The SQL file creates:

- Kafka source table
- Metrics sink
- Anomaly sink
- One-minute event-time aggregation
- High-value-order detection

## 3. Inspect the job

Open the Flink Web UI and identify:

- Job status
- Source operator
- Window aggregation
- Kafka sinks
- Parallelism

## 4. Generate events

```powershell
.\scripts\GENERATE-CLICKSTREAM.ps1 -Count 200
```

## 5. Read metrics

```powershell
docker exec kafka /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka:29092 --topic ecommerce-metrics --from-beginning --max-messages 10
```

Expected fields include:

```text
window_start
window_end
total_events
orders_per_minute
revenue
active_users
cart_events
product_views
completed_payments
```

## 6. Read anomaly output

```powershell
docker exec kafka /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka:29092 --topic ecommerce-anomalies --from-beginning --max-messages 10
```

High-value order threshold:

```text
amount >= 50000
```

## 7. Student SQL inspection

Start an interactive SQL client:

```powershell
docker-compose.exe run --rm --no-deps --pull never --entrypoint /docker-entrypoint.sh sql-client bin/sql-client.sh -f /opt/sql/ecommerce-realtime.sql
```

Then run:

```sql
SHOW TABLES;
```

Students should inspect the supplied SQL file and identify:

- `CREATE TABLE`
- Kafka connector
- JSON format
- watermark
- `TUMBLE`
- `GROUP BY`
- anomaly filter

Exit:

```sql
EXIT;
```

## Checkpoint

Explain:

1. Why Kafka is the input stream.
2. Why event time is used.
3. Why a watermark is defined.
4. What a one-minute tumbling window does.
5. How a high-value order is detected.

## Evidence

Screenshot the Flink job and one metrics message.
