# AR INFOTEK Big Data VAC v13

# Hands-On Lab: Dashboard Data Ingestion and Validation

**Purpose:** Run the local e-commerce data pipeline, populate the
Streamlit dashboard, and validate every data source used by the
dashboard.

**Environment:** Windows PowerShell, Docker Desktop, and the extracted
`v13work` directory.

## 1. Dashboard data architecture

The dashboard does not read everything from Kafka. It combines
operational data, analytical data, and real-time streaming results.

``` text
PostgreSQL operational tables
        |
        | Trino catalog: postgresql, schema: public
        v
Operational dashboard panels
(KPIs, sales, products, orders, customers, funnel, report)

CSV / JSON source files --> HDFS raw layer
        |
PostgreSQL operational data
        |
scripts/INIT-ANALYTICS.ps1
        v
Iceberg tables + Parquet data on HDFS
        |
        | Trino catalog: iceberg, schema: ecommerce
        v
Sales Channel panel (after schema evolution)

data/clickstream.json
        |
        | scripts/GENERATE-CLICKSTREAM.ps1
        v
Kafka topic: ecommerce-events
        |
        v
Flink SQL job
        |                         |
        v                         v
Kafka: ecommerce-metrics    Kafka: ecommerce-anomalies
        \                         /
         \                       /
          Streamlit Kafka consumer
                     |
                     v
MongoDB: ecommerce_analytics
  - realtime_metrics
  - alerts
                     |
                     v
          Real-Time Dashboard panels
```

### Dashboard panel to source mapping

  -----------------------------------------------------------------------------------------
  Dashboard panel         Source                  Validation target
  ----------------------- ----------------------- -----------------------------------------
  Total Orders            PostgreSQL through      `postgresql.public.orders`
                          Trino                   

  Revenue                 PostgreSQL through      `postgresql.public.orders.total_amount`
                          Trino                   

  Customers               PostgreSQL through      `postgresql.public.customers`
                          Trino                   

  Average Order Value     PostgreSQL through      `postgresql.public.orders`
                          Trino                   

  Sales Analytics         PostgreSQL through      `postgresql.public.orders` grouped by
                          Trino                   `order_date`

  Top Products            PostgreSQL through      `postgresql.public.order_items` joined to
                          Trino                   `postgresql.public.products`

  Order Status            PostgreSQL through      `postgresql.public.orders.status`
                          Trino                   

  Customer Analytics      PostgreSQL through      `postgresql.public.customers` joined to
                          Trino                   `postgresql.public.orders`

  Order Conversion Funnel PostgreSQL through      `postgresql.public.clickstream_events`
                          Trino                   

  Management Report       PostgreSQL through      `postgresql.public.orders` grouped by
  Snapshot                Trino                   status

  Sales Channel           Iceberg through Trino   `iceberg.ecommerce.orders`; requires the
                                                  `sales_channel` schema-evolution step

  Real-Time Analytics     MongoDB, populated from `ecommerce_analytics.realtime_metrics`
  from Flink              Kafka output topics     

  Alerts / High-Value     MongoDB, populated from `ecommerce_analytics.alerts`
  Orders                  Kafka output topics     
  -----------------------------------------------------------------------------------------

## 2. Prerequisites and working directory

Open PowerShell in the extracted package's `v13work` directory. Confirm
the expected files exist:

``` powershell
Test-Path .\docker-compose.yml
Test-Path .\streamlit\app.py
Test-Path .\scripts\RUN-FLINK-SQL.ps1
Test-Path .\scripts\GENERATE-CLICKSTREAM.ps1
Test-Path .\scripts\INIT-ANALYTICS.ps1
```

All results should be `True`.

Check service status:

``` powershell
docker compose ps
```

If the lab has not been initialized, follow the package's
`README-v13.md` and run its installation/initialization procedure first.
Do not run reset scripts or delete Docker volumes during this validation
lab.

## 3. Validate PostgreSQL operational data

The dashboard's main panels query Trino's `postgresql` catalog, which
connects to the PostgreSQL database.

### 3.1 Check PostgreSQL container

``` powershell
docker exec ecommerce-postgres pg_isready -U ecommerce -d ecommerce
```

Expected: PostgreSQL reports that it is accepting connections.

### 3.2 Check row counts

``` powershell
docker exec ecommerce-postgres psql -U ecommerce -d ecommerce -c "SELECT 'customers' AS table_name, count(*) AS rows FROM customers UNION ALL SELECT 'products', count(*) FROM products UNION ALL SELECT 'orders', count(*) FROM orders UNION ALL SELECT 'order_items', count(*) FROM order_items UNION ALL SELECT 'payments', count(*) FROM payments UNION ALL SELECT 'clickstream_events', count(*) FROM clickstream_events ORDER BY table_name;"
```

Record the row counts. Counts can vary if the lab data has been
modified.

### 3.3 Validate dashboard KPIs directly in PostgreSQL

``` powershell
docker exec ecommerce-postgres psql -U ecommerce -d ecommerce -c "SELECT count(*) AS total_orders, round(sum(total_amount),2) AS revenue, count(DISTINCT customer_id) AS customers, round(avg(total_amount),2) AS average_order_value FROM orders;"
```

These values should agree with the dashboard's KPI cards, subject to
formatting/rounding.

## 4. Validate Trino operational catalog

### 4.1 Check Trino API

``` powershell
Invoke-RestMethod http://localhost:8080/v1/info
```

### 4.2 List PostgreSQL schemas and tables through Trino

``` powershell
docker exec streamlit python -c "from trino.dbapi import connect; c=connect(host='trino',port=8080,user='lab',catalog='postgresql',schema='public'); q=c.cursor(); q.execute('SHOW SCHEMAS FROM postgresql'); print('SCHEMAS:',q.fetchall()); q.execute('SHOW TABLES FROM postgresql.public'); print('TABLES:',q.fetchall())"
```

The `public` schema should include tables such as `customers`,
`products`, `orders`, `order_items`, `payments`, and
`clickstream_events`.

### 4.3 Verify the KPI query through Trino

``` powershell
docker exec streamlit python -c "from trino.dbapi import connect; c=connect(host='trino',port=8080,user='lab',catalog='postgresql',schema='public'); q=c.cursor(); q.execute('SELECT count(*) total_orders, round(sum(total_amount),2) revenue, count(DISTINCT customer_id) customers, round(avg(total_amount),2) aov FROM orders'); print(q.fetchall())"
```

If this fails, troubleshoot PostgreSQL and Trino before testing the
dashboard.

## 5. Validate HDFS raw data

The lab copies source CSV/JSON files into HDFS for the raw/historical
path.

``` powershell
docker exec hdfs-namenode /opt/hadoop/bin/hdfs dfs -ls /ecommerce/raw
```

Expected files include source datasets such as customers, products,
orders, order items, payments, and clickstream JSON.

Inspect a small sample:

``` powershell
docker exec hdfs-namenode /opt/hadoop/bin/hdfs dfs -cat /ecommerce/raw/clickstream.json
```

If output is long, stop it with `Ctrl+C`. HDFS raw files are not read
directly by most dashboard panels; they are part of the historical/raw
data path.

## 6. Validate Iceberg analytical tables

The Sales Channel dashboard panel uses `iceberg.ecommerce.orders`, while
the main operational panels use `postgresql.public`.

### 6.1 Initialize or refresh analytical tables

Run from `v13work`:

``` powershell
.\scripts\INIT-ANALYTICS.ps1
```

This creates Iceberg tables and refreshes their contents from the
PostgreSQL source into Parquet-backed tables stored on HDFS. It deletes
and reloads the listed Iceberg tables, so do not run it if you need to
preserve manual changes to those tables.

### 6.2 List Iceberg schemas and tables

``` powershell
docker exec streamlit python -c "from trino.dbapi import connect; c=connect(host='trino',port=8080,user='lab',catalog='iceberg',schema='ecommerce'); q=c.cursor(); q.execute('SHOW SCHEMAS FROM iceberg'); print('SCHEMAS:',q.fetchall()); q.execute('SHOW TABLES FROM iceberg.ecommerce'); print('TABLES:',q.fetchall())"
```

Expected schema: `ecommerce`. Expected tables include `customers`,
`products`, `orders`, `order_items`, `payments`, and
`clickstream_events`.

### 6.3 Compare PostgreSQL and Iceberg order counts

``` powershell
docker exec streamlit python -c "from trino.dbapi import connect; c=connect(host='trino',port=8080,user='lab',catalog='postgresql',schema='public'); q=c.cursor(); q.execute('SELECT count(*) FROM orders'); print('PostgreSQL orders:',q.fetchone()[0]); q=connect(host='trino',port=8080,user='lab',catalog='iceberg',schema='ecommerce').cursor(); q.execute('SELECT count(*) FROM orders'); print('Iceberg orders:',q.fetchone()[0])"
```

The counts should match immediately after a successful refresh, assuming
no source changes occur during the check.

### 6.4 Sales Channel panel requirement

The package's Sales Channel panel queries `sales_channel` from
`iceberg.ecommerce.orders`. The initial analytical table definition does
not include that column. Run the Session 9 schema-evolution step or the
configured Airflow workflow that adds and populates `sales_channel`.
Until then, the dashboard is designed to show an informational message
in that panel.

Do not assume that creating the Iceberg table alone adds
`sales_channel`.

## 7. Validate Kafka topics

### 7.1 List topics

``` powershell
docker exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:29092 --list
```

For the real-time dashboard, these topics are important:

-   `ecommerce-events`: input events published by the generator.
-   `ecommerce-metrics`: one-minute KPI output from Flink.
-   `ecommerce-anomalies`: high-value order alerts from Flink.

### 7.2 Check that input events can be published

The supplied generator reads lines from `data\clickstream.json` and
publishes them to `ecommerce-events`:

``` powershell
.\scripts\GENERATE-CLICKSTREAM.ps1 -Count 20
```

Expected: `Published 20 clickstream events.`

### 7.3 Inspect messages in a Kafka topic

Run this in a separate PowerShell window. It prints up to five messages
and exits after the timeout:

``` powershell
docker exec kafka /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka:29092 --topic ecommerce-events --from-beginning --max-messages 5 --timeout-ms 10000
```

For output topics, use:

``` powershell
docker exec kafka /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka:29092 --topic ecommerce-metrics --max-messages 5 --timeout-ms 10000
```

``` powershell
docker exec kafka /opt/kafka/bin/kafka-console-consumer.sh --bootstrap-server kafka:29092 --topic ecommerce-anomalies --max-messages 5 --timeout-ms 10000
```

The output topics may be empty until the Flink job is running and the
input topic receives suitable events. A console consumer started with
`--from-beginning` is for inspection only; it does not populate MongoDB.

## 8. Start and validate Flink SQL

### 8.1 Start the Flink job

``` powershell
.\scripts\RUN-FLINK-SQL.ps1
```

The script starts the Flink services, submits
`sql\flink\ecommerce-realtime.sql`, and checks for a running job.

### 8.2 Check Flink UI and REST status

Open:

``` text
http://localhost:8081
```

Or run:

``` powershell
Invoke-RestMethod http://localhost:8081/overview
Invoke-RestMethod http://localhost:8081/jobs/overview
```

At least one job should be in `RUNNING` state for real-time processing.

### 8.3 Publish deterministic sample events

The sample publisher includes an `order_created` event with amount
`75000`, which is above the Flink SQL anomaly threshold of `50000`.

``` powershell
.\scripts\PUBLISH-SAMPLE-EVENTS.ps1
```

Check the Flink UI and the Kafka output topics after publishing. The
sample timestamps are fixed in the supplied script, so if event-time
windows are late relative to the current watermark, use fresh events
from the generator or update the sample event timestamps before
repeating the test.

## 9. Validate MongoDB

MongoDB stores the recent results consumed from Kafka by Streamlit. The
dashboard's consumer writes to database `ecommerce_analytics` and
collections `realtime_metrics` and `alerts`.

### 9.1 Check MongoDB availability

``` powershell
docker exec mongodb mongosh --quiet --eval "db.adminCommand('ping')"
```

Expected: `{ ok: 1 }` or an equivalent successful ping response.

### 9.2 Count documents in the dashboard collections

``` powershell
docker exec mongodb mongosh --quiet --eval "db=db.getSiblingDB('ecommerce_analytics'); print('realtime_metrics count:',db.realtime_metrics.countDocuments({})); print('alerts count:',db.alerts.countDocuments({}));"
```

### 9.3 Inspect recent metric documents

``` powershell
docker exec mongodb mongosh --quiet --eval "db=db.getSiblingDB('ecommerce_analytics'); printjson(db.realtime_metrics.find({}, {_id:0}).sort({window_start:-1}).limit(5).toArray())"
```

### 9.4 Inspect recent alerts

``` powershell
docker exec mongodb mongosh --quiet --eval "db=db.getSiblingDB('ecommerce_analytics'); printjson(db.alerts.find({}, {_id:0}).sort({event_time:-1}).limit(5).toArray())"
```

### Important consumer behavior in this package

The Streamlit app starts a Kafka consumer with
`auto_offset_reset='latest'` and a short `consumer_timeout_ms=300`. The
consumer runs when Streamlit executes the dashboard script. It is
intended to consume new output messages, not backfill all historical
Kafka records.

For a reliable hands-on sequence:

1.  Start the Flink job and confirm it is `RUNNING`.
2.  Open the Streamlit dashboard at `http://localhost:8501`.
3.  Keep the dashboard active.
4.  Publish new events with
    `.\scripts\GENERATE-CLICKSTREAM.ps1 -Count 300`.
5.  Refresh the dashboard and inspect MongoDB collection
    counts/documents.
6.  If no new MongoDB documents appear, inspect Kafka output topics
    first, then the Streamlit logs:

``` powershell
docker logs --tail 100 streamlit
```

Then inspect Flink:

``` powershell
docker logs --tail 100 flink-jobmanager
docker logs --tail 100 flink-taskmanager
```

If Kafka has output messages but MongoDB stays empty, the
Kafka-to-Streamlit consumer path needs investigation. If Kafka output
topics are empty, investigate the Flink job and input events first.

## 10. Validate Debezium CDC separately

Debezium is part of the operational change-data-capture path, but it is
not the direct data source for the dashboard panels listed above. The
current dashboard reads operational data through Trino and real-time
aggregates through MongoDB.

Check the connector list:

``` powershell
Invoke-RestMethod http://localhost:8083/connectors
```

Check connector status:

``` powershell
Invoke-RestMethod http://localhost:8083/connectors/ecommerce-postgres/status
```

Confirm the connector and task status are `RUNNING`. To test CDC, update
an existing PostgreSQL order, then inspect the configured Debezium
topic. Do not confuse the Debezium CDC topics with `ecommerce-events`,
which is the Flink SQL input topic used by this dashboard's real-time
analytics path.

## 11. Open the dashboard and validate each panel

Open:

``` text
http://localhost:8501
```

Expected connection indicators:

-   **Trino: Connected**
-   **MongoDB: Connected**

Then validate panels:

1.  Compare KPI cards against the Trino KPI query in Section 4.
2.  Check Sales Analytics against
    `SELECT order_date, SUM(total_amount), COUNT(*) FROM postgresql.public.orders GROUP BY order_date`.
3.  Confirm Top Products and Customer Analytics return rows.
4.  Confirm Order Status returns status counts.
5.  Confirm the conversion funnel returns event counts from
    `clickstream_events`.
6.  Check the Sales Channel panel only after Iceberg schema evolution
    has been completed.
7.  Check real-time charts after Kafka output messages are visible and
    MongoDB contains metric documents.
8.  Check Alerts after an event with `order_created` amount at least
    `50000` has been processed by Flink.

## 12. End-to-end validation checklist

Use this checklist during the practical.

-   [ ] Docker services are running and healthy.
-   [ ] PostgreSQL is accepting connections.
-   [ ] PostgreSQL tables contain data.
-   [ ] Trino API responds.
-   [ ] `postgresql.public` schemas and tables are visible through
    Trino.
-   [ ] Dashboard KPI SQL query succeeds through Trino.
-   [ ] HDFS `/ecommerce/raw` contains the source files.
-   [ ] Iceberg `ecommerce` schema and tables exist after
    initialization.
-   [ ] PostgreSQL and Iceberg order counts match after refresh.
-   [ ] Kafka input and output topics exist.
-   [ ] Flink job is `RUNNING`.
-   [ ] New clickstream events appear on `ecommerce-events`.
-   [ ] Flink produces messages to `ecommerce-metrics`.
-   [ ] Flink produces anomaly messages to `ecommerce-anomalies` when
    test data qualifies.
-   [ ] MongoDB ping succeeds.
-   [ ] MongoDB `realtime_metrics` contains documents.
-   [ ] MongoDB `alerts` contains documents after a qualifying
    high-value event.
-   [ ] Streamlit shows Trino and MongoDB as connected.
-   [ ] Dashboard operational panels show results.
-   [ ] Real-time metrics and alerts show results after ingestion.
-   [ ] Sales Channel works after its Iceberg schema-evolution step.
-   [ ] Debezium connector and task report `RUNNING` (if validating
    CDC).

## 13. Troubleshooting guide

  ----------------------------------------------------------------------------------------------------------------------------
  Symptom                 Check first                             Next action
  ----------------------- --------------------------------------- ------------------------------------------------------------
  Trino shows             Is the query using the intended         Use `postgresql.public` for operational tables; run
  `SCHEMA_NOT_FOUND` for  catalog?                                `INIT-ANALYTICS.ps1` for Iceberg tables.
  `ecommerce`                                                     

  Trino connected, but    Test the SQL against                    Verify table and column names.
  operational panel fails `postgresql.public`                     

  Sales Channel shows an  Does `iceberg.ecommerce.orders` contain Complete Session 9 schema evolution or run the configured
  informational message   `sales_channel`?                        Airflow workflow.

  Flink UI has no running `http://localhost:8081/jobs/overview`   Re-run `RUN-FLINK-SQL.ps1` and inspect its output/logs.
  job                                                             

  Input Kafka topic has   `ecommerce-events` consumer             Run `GENERATE-CLICKSTREAM.ps1`.
  no messages                                                     

  Input topic has         Flink job status and logs               Check SQL job failures, event timestamps, and source schema.
  messages but output                                             
  topics do not                                                   

  Kafka output has        Streamlit logs and consumer group       Keep the dashboard active, publish fresh messages, refresh,
  messages but MongoDB    behavior                                and re-check.
  collections are empty                                           

  MongoDB is connected    Collection counts                       Confirm Flink output topics have new messages and the
  but real-time panels                                            consumer has processed them.
  are empty                                                       

  Dashboard file changes  Container's `/app/app.py`               Rebuild the Streamlit image:
  are not reflected                                               `docker compose up -d --build --force-recreate streamlit`.
  ----------------------------------------------------------------------------------------------------------------------------

## 14. Student submission evidence

Submit:

1.  Screenshot of the Streamlit dashboard showing Trino and MongoDB
    connection status.
2.  PostgreSQL KPI query and its result.
3.  Trino operational catalog table listing.
4.  HDFS raw data listing.
5.  Iceberg table listing and PostgreSQL-versus-Iceberg order counts.
6.  Flink jobs overview showing a running job.
7.  Kafka output topic message samples.
8.  MongoDB `realtime_metrics` document.
9.  MongoDB `alerts` document after a qualifying event, if generated.
10. A short explanation tracing one displayed dashboard metric back to
    its source.

## 15. Key takeaway

-   **PostgreSQL via Trino:** main operational dashboard data.
-   **Iceberg via Trino:** analytical Sales Channel panel after schema
    evolution.
-   **Kafka:** transports incoming events to Flink and carries Flink's
    metric/anomaly outputs.
-   **Flink SQL:** calculates one-minute KPIs and flags high-value order
    events.
-   **MongoDB:** stores recent Flink metrics and alerts for the
    Streamlit real-time panels.
-   **HDFS:** stores raw and Iceberg/Parquet historical data.
-   **Debezium:** captures PostgreSQL changes for the CDC demonstration;
    it is not the direct query source for the current dashboard panels.

The lab should be considered fully validated only after both the
operational Trino queries and the real-time Kafka-to-Flink-to-MongoDB
path have been checked.
