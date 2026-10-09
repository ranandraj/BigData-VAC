# Day 2 Setup

Day 2 uses MongoDB, HDFS, Parquet, Apache Iceberg, Trino, Streamlit and Airflow.

No MinIO or Iceberg REST service is used. Iceberg tables use HDFS as the data warehouse with PostgreSQL storing Iceberg catalog metadata.

Run:

```powershell
.\scripts\INSTALL-DAY2.ps1
```

Prepare analytical tables:

```powershell
.\scripts\INIT-ANALYTICS.ps1
```
