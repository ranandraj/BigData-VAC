# AR INFOTEK Big Data VAC v11 Changelog

## v11 Clean Fixed Version

### Removed

- MinIO
- Iceberg REST catalog service
- Separate lakehouse initialization service/build
- Analytics Writer service
- Custom Java Flink application
- Maven Flink build
- Custom Flink Docker image

### Flink changes

- Uses official `flink:2.1.1-scala_2.12` image.
- Uses Flink Session Cluster.
- Uses standard Flink SQL Client.
- Kafka SQL connector is supplied as a local JAR and mounted into JobManager, TaskManager and SQL Client.
- Flink is never built during normal installation.

### Installer changes

- Windows optional features are checked before enabling.
- Already-enabled WSL and Virtual Machine Platform are skipped.
- Existing Streamlit image is reused.
- Normal Compose startup uses `--no-build`.
- Initial lab initialization runs only once and creates `.v11-initialized` after successful completion.
- Existing connector JAR is reused and not downloaded again.

### Student documentation

Added separate detailed practical guides for all 12 sessions:

1. Architecture
2. HDFS
3. PostgreSQL
4. NiFi
5. Kafka
6. Debezium
7. Flink SQL
8. MongoDB and HDFS
9. Parquet and Iceberg
10. Trino
11. Streamlit
12. Airflow and final integration

### Approved 2-Day alignment

Day 1 focuses on distributed data foundation, multi-source ingestion, Kafka, CDC and real-time processing.

Day 2 focuses on real-time results, HDFS historical data, Parquet, Iceberg, Trino, Streamlit, Airflow and end-to-end integration.
