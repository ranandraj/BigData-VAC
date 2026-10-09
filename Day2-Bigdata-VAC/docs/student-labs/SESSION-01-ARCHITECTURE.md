# Session 1 - Distributed Big Data & E-Commerce Architecture

**Duration:** 45 minutes

## Objective

Understand the complete e-commerce Big Data flow and explain the role of every technology used in the 2-day lab.

## Student hands-on

### Task 1: Draw the architecture

Draw this without copying the slide:

```text
PostgreSQL -> Debezium -> Kafka -> Flink SQL -> Kafka metrics/alerts -> MongoDB -> Streamlit
CSV/JSON -> NiFi -> Kafka/HDFS
HDFS -> Parquet -> Iceberg -> Trino -> Analytics
Airflow -> Workflow automation
```

### Task 2: Classify data

Classify these as structured, semi-structured or event data:

- customers.csv
- products.csv
- orders.csv
- clickstream.json
- product_view
- cart_added
- payment_completed

### Task 3: Verify services

```powershell
.\scripts\STATUS-LAB.ps1
```

Open:

- HDFS: http://localhost:9870
- NiFi: https://localhost:8443/nifi
- Flink: http://localhost:8081

### Task 4: Technology role test

Complete this table in your notebook:

| Technology | Role |
|---|---|
| PostgreSQL | |
| HDFS | |
| NiFi | |
| Kafka | |
| Debezium | |
| Flink SQL | |
| MongoDB | |
| Trino | |
| Streamlit | |
| Airflow | |

## Checkpoint

Explain the difference between:

1. PostgreSQL and HDFS
2. Kafka and PostgreSQL
3. Debezium and Kafka
4. Flink and Kafka
5. MongoDB and HDFS

## Evidence

Submit the architecture diagram and completed technology-role table.
