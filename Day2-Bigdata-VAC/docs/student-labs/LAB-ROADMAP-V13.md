# AR INFOTEK Advanced Big Data & Real-Time E-Commerce Analytics VAC v13
# Student Lab Roadmap

## Approved 2-Day Practical Sequence

The lab implements the approved Day 1 and Day 2 e-commerce use case with a preconfigured local Docker environment. Students perform configuration, commands, SQL, data-flow construction, validation, analytics and troubleshooting.

### Day 1: Distributed Data Foundation, Multi-Source Ingestion and Real-Time Streaming

| Session | Practical focus | Suggested time |
|---|---|---:|
| 1 | Distributed Big Data & E-Commerce Architecture | 45 min |
| 2 | HDFS Distributed Storage | 60 min |
| 3 | PostgreSQL Operational E-Commerce Data | 60 min |
| 4 | Apache NiFi Ingestion, Routing & Transformation | 75 min |
| 5 | Apache Kafka Event Streaming | 75 min |
| 6 | PostgreSQL CDC with Debezium | 60 min |
| 7 | Apache Flink SQL Real-Time Processing | 75 min |

### Day 2: Big Data Processing, Analytics, Dashboard and Reporting

| Session | Practical focus | Suggested time |
|---|---|---:|
| 8 | MongoDB Recent Results & HDFS Historical Data | 60 min |
| 9 | Parquet, Apache Iceberg, Partitioning & Schema Evolution | 75 min |
| 10 | Trino Distributed SQL Analytics | 75 min |
| 11 | Streamlit E-Commerce Dashboard | 90 min |
| 12 | Airflow Workflow Automation & Final Integration | 75 min |

## Complete E-Commerce Architecture

```text
                         E-COMMERCE SOURCES
                                  |
                    +-------------+-------------+
                    |                           |
             PostgreSQL                    CSV / JSON
                    |                           |
                 Debezium                      NiFi
                    |                           |
                    +-------------+-------------+
                                  |
                                Kafka
                                  |
                           +------+------+
                           |             |
                        Flink SQL     CDC/Event Topics
                           |
                +----------+----------+
                |                     |
          KPI Metrics             Anomalies
                |                     |
                +----------+----------+
                           |
                         Kafka
                           |
                      Streamlit Consumer
                           |
                        MongoDB
                           |
                    Real-Time Dashboard

HISTORICAL / ANALYTICAL PATH

CSV / JSON -> HDFS Raw
                  |
            PostgreSQL Source
                  |
                Trino
                  |
        Iceberg + Parquet on HDFS
                  |
                Trino
                  |
       Analytics / Views / Reports
                  |
             Streamlit Dashboard

WORKFLOW AUTOMATION

Airflow
   |
   +--> Validate sources
   +--> Refresh Iceberg / Parquet
   +--> Apply schema evolution
   +--> Prepare Trino views
   +--> Generate management report
```

## Approved Day 1 Coverage

- E-commerce Big Data Architecture
- Batch vs streaming concepts
- Structured, semi-structured and event data
- Distributed local lab architecture
- Hadoop HDFS NameNode, DataNodes, blocks and storage
- PostgreSQL operational source
- Historical CSV and JSON data
- NiFi FlowFiles, processors, queues, routing and transformation
- Kafka broker, topics, producers, consumers, partitions, offsets and consumer groups
- Clickstream and order events
- PostgreSQL CDC with Debezium
- Kafka CDC topics
- Flink SQL source, filtering, mapping and transformation
- Event-time processing and watermarks
- One-minute tumbling windows
- Orders/minute, revenue, active users, cart events, product views and completed payments
- High-value order anomaly detection

## Approved Day 2 Coverage

- MongoDB recent real-time results
- HDFS historical/raw data
- Parquet analytical storage
- Apache Iceberg table format
- Iceberg hidden partitioning
- Iceberg schema evolution
- Trino distributed SQL
- E-commerce revenue, customer, product, status and funnel analytics
- Streamlit management dashboard
- Airflow workflow automation
- Final real-time + historical analytical integration
- Management report generation

## Student Rule

Do not install or rebuild Hadoop, Kafka, Debezium, Flink, NiFi, PostgreSQL, MongoDB or Trino during the workshop. The trainer supplies the working environment. Students perform the practical configuration and validation activities described in the session guides.

## Common Commands

```powershell
.\scripts\STATUS-LAB.ps1
.\scripts\START-LAB.ps1
.\scripts\STOP-LAB.ps1
.\scripts\VERIFY-ALL.ps1
```

Flink SQL:

```powershell
.\scripts\RUN-FLINK-SQL.ps1
```

Generate live events:

```powershell
.\scripts\GENERATE-CLICKSTREAM.ps1 -Count 300
```

## Web Interfaces

- HDFS: http://localhost:9870
- NiFi: https://localhost:8443/nifi
- Debezium: http://localhost:8083
- Flink: http://localhost:8081
- Trino: http://localhost:8080
- Streamlit: http://localhost:8501
- Airflow: http://localhost:8085
