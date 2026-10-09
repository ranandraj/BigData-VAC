# AR INFOTEK Big Data & E-Commerce VAC v13
# Detailed Student Laboratory Guide

This guide is the student-facing practical manual for the approved 2-day VAC.

## How to use this guide

Every session follows:

```text
Understand -> Observe -> Perform -> Validate -> Troubleshoot -> Submit Evidence
```

Students should capture screenshots or command output at each checkpoint. The trainer can use those checkpoints for practical assessment.

## Lab Credentials

| Service | Value |
|---|---|
| PostgreSQL database | `ecommerce` |
| PostgreSQL user | `ecommerce` |
| PostgreSQL password | `ecommerce` |
| Kafka internal broker | `kafka:29092` |
| Kafka host broker | `localhost:9092` |
| NiFi username | `admin` |
| NiFi password | `BigDataLab123!` |

## Safety Rules

1. Do not delete shared datasets.
2. Do not change service ports.
3. Do not change passwords.
4. Before `UPDATE` or `DELETE`, run the equivalent `SELECT` first.
5. Verify every operation.
6. Record errors before asking the trainer.
7. Do not stop shared services unless instructed.
8. Work inside the supplied lab directories.
9. Do not run `RESET-LAB.ps1` during a student session unless the trainer explicitly instructs you.
10. Use your assigned team/student folder where the activity requires a local file.

## Final Practical Evidence

Each student/team should be able to demonstrate:

- HDFS directories and uploaded e-commerce data
- PostgreSQL tables and sample queries
- A working NiFi ingestion flow
- Kafka topics, partitions and messages
- Debezium CDC event in Kafka
- Flink SQL job in the Flink Web UI
- Real-time metrics and high-value-order alerts
- MongoDB recent analytics results
- HDFS historical data
- Parquet-backed Iceberg analytical tables
- Trino business queries
- Streamlit dashboard
- Airflow DAG and successful task execution
- Complete end-to-end data flow
