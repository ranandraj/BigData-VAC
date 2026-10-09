# AR INFOTEK Advanced Big Data & Real-Time E-Commerce Analytics VAC v13

## Final revised local lab package

This package implements the approved 2-day e-commerce Big Data use case from source ingestion through real-time processing, analytical storage, SQL analytics, dashboarding and workflow automation.

## Architecture

```text
PostgreSQL operational data
        |
     Debezium
        |
      Kafka <----- NiFi <----- CSV / JSON
        |
    Flink SQL
     /     \
 Metrics   Anomalies
    |          |
   Kafka ------+
        |
 Streamlit Kafka consumer
        |
     MongoDB
        |
 Real-time dashboard

Historical / analytical:

CSV / JSON -> HDFS Raw
                  |
             PostgreSQL
                  |
                Trino
                  |
       Iceberg + Parquet on HDFS
                  |
                Trino
                  |
       Analytics / Views / Reports

Automation:

Airflow -> validation -> analytical refresh -> schema evolution -> Trino views -> report
```

## v13 corrections and improvements

- Correct Flink 2.1 Kafka connector: `5.0.0-2.1`.
- Official Flink image `flink:2.1.1-scala_2.12`.
- No custom Flink Java build.
- No Maven build for Flink.
- Connector JAR is downloaded once to `flink-sql/lib` and mounted into JobManager, TaskManager and SQL Client.
- Streamlit is the only custom image and is rebuilt from the current source by the installer.
- Normal Compose startup uses `--no-build`.
- PostgreSQL is populated from the supplied e-commerce CSV and clickstream datasets during first initialization.
- HDFS receives the same raw CSV/JSON data for the historical/raw layer.
- Flink SQL now demonstrates filtering, mapping, normalization, event time, watermarking, tumbling windows, real-time KPIs and anomaly detection.
- Iceberg orders and clickstream tables use Parquet with hidden day partitions.
- Session 9 demonstrates Iceberg schema evolution using `sales_channel`.
- Airflow DAG performs real Trino validation, analytical refresh, schema evolution, analytics-view preparation and report generation.
- Airflow writes `reports/management_report.csv` to the host through a mounted folder.
- Final student workflow traces real e-commerce data through both real-time and analytical paths.

## Services

1. Hadoop NameNode
2. Hadoop DataNode 1
3. Hadoop DataNode 2
4. Hadoop DataNode 3
5. PostgreSQL
6. Apache Kafka
7. Debezium
8. Apache NiFi
9. Flink JobManager
10. Flink TaskManager
11. Flink SQL Client
12. MongoDB
13. Trino
14. Streamlit
15. Airflow

## First installation

Run from the extracted folder:

```powershell
.\INSTALL-BIGDATA-LAB.ps1
```

The installer:

1. Checks Windows prerequisites and Docker Desktop.
2. Downloads the correct Flink Kafka connector if missing and validates the JAR.
3. Builds the Streamlit image from the current source on each installer run; Docker layer caching speeds up repeat builds.
4. Pulls required service images sequentially and starts the stack with `docker-compose.exe up -d --no-build --pull never`.
5. Loads PostgreSQL operational and clickstream data on first initialization.
6. Loads the same raw data into HDFS.
7. Creates Kafka topics and registers Debezium.
8. Creates Parquet-backed Iceberg tables on HDFS.
9. Verifies the lab.

## Subsequent startup

If `.v13-initialized` exists, the installer skips the one-time data and analytical initialization.

```powershell
.\INSTALL-BIGDATA-LAB.ps1
```

The installer rebuilds the Streamlit image from the current package source on each run; Docker layer caching speeds up repeat builds. Flink is never custom-built.

## Flink connector

Required local file:

```text
flink-sql/lib/flink-sql-connector-kafka-5.0.0-2.1.jar
```

Official artifact URL:

https://repo.maven.apache.org/maven2/org/apache/flink/flink-sql-connector-kafka/5.0.0-2.1/flink-sql-connector-kafka-5.0.0-2.1.jar

## Real-time processing

Run:

```powershell
.\scripts\RUN-FLINK-SQL.ps1
```

Then publish events:

```powershell
.\scripts\GENERATE-CLICKSTREAM.ps1 -Count 300
```

Flink produces:

- `ecommerce-metrics`
- `ecommerce-anomalies`

Streamlit consumes these Kafka outputs and stores recent results in MongoDB.

## Day 2 analytics

```powershell
.\scripts\INIT-ANALYTICS.ps1
```

Analytical storage:

```text
HDFS
  |
Parquet
  |
Iceberg
  |
Trino
```

The orders table is partitioned using `day(order_date)`.

## Airflow

Open:

```text
http://localhost:8085
```

Trigger:

```text
ecommerce_end_to_end
```

The DAG performs actual work rather than placeholder print statements.

## Web interfaces

| Service | URL |
|---|---|
| HDFS | http://localhost:9870 |
| NiFi | https://localhost:8443/nifi |
| Debezium | http://localhost:8083 |
| Flink | http://localhost:8081 |
| Trino | http://localhost:8080 |
| Streamlit | http://localhost:8501 |
| Airflow | http://localhost:8085 |

## Student documentation

```text
docs/student-labs/LAB-ROADMAP-V13.md
docs/student-labs/STUDENT-LAB-GUIDE-V13.md
docs/student-labs/SESSION-01-ARCHITECTURE.md
docs/student-labs/SESSION-02-HDFS.md
docs/student-labs/SESSION-03-POSTGRESQL.md
docs/student-labs/SESSION-04-NIFI-V13.md
docs/student-labs/SESSION-05-KAFKA.md
docs/student-labs/SESSION-06-DEBEZIUM.md
docs/student-labs/SESSION-07-FLINK-SQL.md
docs/student-labs/SESSION-08-MONGODB-HDFS.md
docs/student-labs/SESSION-09-PARQUET-ICEBERG.md
docs/student-labs/SESSION-10-TRINO.md
docs/student-labs/SESSION-11-STREAMLIT.md
docs/student-labs/SESSION-12-AIRFLOW-INTEGRATION.md
```

## Validation

Run:

```powershell
.\scripts\VERIFY-ALL.ps1
```

The package is statically validated for Compose structure, Flink connector references, service count, PowerShell structure and documentation consistency. Full runtime validation requires Docker Desktop and Windows networking on the trainer machine.


### Docker Hub first-run pull behavior
The installer pre-pulls external registry images sequentially with retries before starting Compose. This reduces concurrent Docker Hub load and avoids repeated first-run TLS handshake failures. After successful pulls, Compose runs with `--pull never`.

### v13 clickstream loader fix
The PostgreSQL initialization script safely handles optional `order_id` and `amount` fields in clickstream JSON events. Non-order events omit these fields, so the loader now checks JSON properties explicitly instead of directly referencing missing PowerShell properties under strict mode.
