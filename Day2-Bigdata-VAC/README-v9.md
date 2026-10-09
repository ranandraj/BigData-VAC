# AR INFOTEK Big Data VAC v11 - Clean E-Commerce Big Data Lab

## Flink implementation: SQL Client

This revision replaces the previous custom Java/Maven Flink application with Flink SQL Client.

### End-to-end flow

```text
Historical CSV/JSON -> NiFi -> HDFS
PostgreSQL -> Debezium -> Kafka <- Clickstream
                         |
                         v
                 Flink SQL Job
                  /          \
                 v            v
       ecommerce-metrics   ecommerce-anomalies
                 \            /
                  \          /
                     Kafka
                       |
                 Streamlit
                       |
                    MongoDB
                       |
              Streamlit / Reports

HDFS -> Parquet -> Iceberg -> Trino -> Streamlit
Airflow -> workflow automation
```

## Main changes from the previous revision

- Standard Flink 2.1.1 Session Cluster.
- Flink SQL Client added as a dedicated service.
- Kafka SQL connector included in the Flink image.
- Real-time processing defined in `sql/flink/ecommerce-realtime.sql`.
- No Maven installation.
- No Java Flink application compilation.
- No custom Flink application JAR.
- SQL job produces `ecommerce-metrics` and `ecommerce-anomalies` Kafka topics.
- Existing Streamlit consumes those topics and stores results in MongoDB.

## Installation

1. Start Docker Desktop using the WSL2/Linux-container backend.
2. Open Administrator PowerShell.
3. Run:

```powershell
./INSTALL-BIGDATA-LAB.ps1
```

4. Submit the real-time Flink SQL job:

```powershell
./scripts/RUN-FLINK-SQL.ps1
```

5. Verify:

```powershell
./scripts/VERIFY-FLINK-SQL.ps1
```

6. Publish test events:

```powershell
./scripts/PUBLISH-SAMPLE-EVENTS.ps1
```

## Services and URLs

HDFS: http://localhost:9870
NiFi: https://localhost:8443/nifi
Debezium: http://localhost:8083
Flink: http://localhost:8081
Trino: http://localhost:8080
Iceberg Hadoop Catalog: http://localhost:8181
: http://localhost:9001
Streamlit: http://localhost:8501
Airflow: http://localhost:8085

## Flink SQL

Main SQL file:

`sql/flink/ecommerce-realtime.sql`

The SQL job performs:

- Kafka event ingestion
- JSON parsing
- event-time processing
- 5-second watermark
- one-minute tumbling windows
- total events
- orders/minute
- revenue
- active users
- cart events
- product views
- completed payments
- high-value order detection at amount >= 50000

The high-value rule is intentionally simple and deterministic for the workshop.
