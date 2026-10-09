# AR INFOTEK Big Data VAC v13 Final Revised Installation Guide

## First run

Run from the extracted package folder:

```powershell
.\INSTALL-BIGDATA-LAB.ps1
```

The installer performs these steps in order:

1. Checks Windows prerequisites and Docker Desktop.
2. Downloads and validates the Flink Kafka SQL connector if it is not already present.
3. Builds the Streamlit image from the current `streamlit/Dockerfile` and `streamlit/app.py` source. Docker layer caching speeds up repeat builds.
4. Pulls required service images sequentially.
5. Starts all 15 services with `docker-compose.exe up -d --no-build`.
6. Loads the e-commerce datasets into PostgreSQL and HDFS on first initialization.
7. Initializes the analytical Iceberg/Parquet layer on first initialization.
8. Verifies the lab.

## Streamlit image behavior

The Streamlit image is **not included as a prebuilt image** in the ZIP.

The installer builds this versioned image from the package's current source:

```text
streamlit/Dockerfile + streamlit/app.py
        ↓
ar-infotek-bigdata-v13-streamlit:1.1
```

The installer rebuilds the Streamlit image on every run so a corrected `app.py` cannot be hidden by an older local image. Docker layer caching speeds up repeat builds.

## Flink connector

Required local file:

```text
flink-sql/lib/flink-sql-connector-kafka-5.0.0-2.1.jar
```

Official artifact:

```text
https://repo.maven.apache.org/maven2/org/apache/flink/flink-sql-connector-kafka/5.0.0-2.1/flink-sql-connector-kafka-5.0.0-2.1.jar
```

## Startup behavior

The installer deliberately uses:

```powershell
docker-compose.exe up -d --no-build
```

The `--no-build` option prevents Compose from attempting additional image builds during normal startup.

## Subsequent runs

If the Flink connector and `.v13-initialized` marker already exist, their download and data initialization are skipped. The Streamlit image is still rebuilt from the current source.

## Manual Streamlit rebuild

To intentionally rebuild the dashboard image:

```powershell
docker-compose.exe build streamlit
docker-compose.exe up -d --no-build --pull never streamlit
```

## Manual connector recovery

If the connector download fails, manually place:

```text
flink-sql-connector-kafka-5.0.0-2.1.jar
```

under:

```text
flink-sql/lib/
```

and rerun the installer.

## Important

Do not build Flink. v13 uses the official Flink image:

```text
flink:2.1.1-scala_2.12
```

The Kafka SQL connector is mounted into the JobManager, TaskManager and SQL Client.
