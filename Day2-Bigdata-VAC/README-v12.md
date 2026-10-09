# AR INFOTEK Big Data VAC v13 - Clean Working Lab

## Approved 2-Day VAC

**Advanced Big Data Engineering & Real-Time E-Commerce Analytics**

This package is designed for the approved 2-day college VAC. It provides a preconfigured local Docker environment so students can focus on practical Big Data work rather than software installation.

## Important v13 design decisions

- No MinIO
- No separate lakehouse service or lakehouse build
- No Iceberg REST service
- No Analytics Writer service
- No custom Java Flink application
- No Maven Flink build
- Standard Apache Flink 2.1.1 image
- Flink SQL Client for real-time processing
- Kafka SQL connector supplied once as a local JAR and mounted into Flink
- Streamlit dashboard is the only custom application image and is built only if its image is missing
- Windows prerequisite checks are idempotent
- Existing Docker images are not rebuilt during normal installation
- Normal startup always uses `--no-build`
- Initial data initialization is protected by `.v13-initialized`

Apache Flink documents the Session Cluster + SQL Client pattern and requires the Kafka connector dependency in the cluster and SQL Client. The v13 package supplies that connector as a local file rather than downloading it inside a Docker build. Apache Flink Docker documentation: https://nightlies.apache.org/flink/flink-docs-release-2.1/docs/deployment/resource-providers/standalone/docker/

## Installation

Run PowerShell as Administrator if prompted:

```powershell
.\INSTALL-BIGDATA-LAB.ps1
```

The installer:

1. Checks Windows features.
2. Enables WSL / Virtual Machine Platform only if they are not already enabled.
3. Verifies Docker Desktop and Docker Compose.
4. Downloads the Flink Kafka SQL connector only if the local JAR is missing.
5. Builds Streamlit only if the Streamlit image does not already exist.
6. Starts the complete stack with `docker-compose up -d --no-build`.
7. Initializes data only on the first successful installation.
8. Verifies the environment.

## Repeat run

Running the installer again should not rebuild Flink and should not re-enable already enabled Windows features.

For a normal restart:

```powershell
.\scripts\START-LAB.ps1
```

## Flink SQL

```powershell
.\scripts\RUN-FLINK-SQL.ps1
```

Flink Web UI:

```text
http://localhost:8081
```

## Main services

| Service | URL |
|---|---|
| HDFS NameNode | http://localhost:9870 |
| NiFi | https://localhost:8443/nifi |
| Debezium | http://localhost:8083 |
| Flink | http://localhost:8081 |
| Trino | http://localhost:8080 |
| Streamlit | http://localhost:8501 |
| Airflow | http://localhost:8085 |

## Student documentation

See:

```text
docs/student-labs/
```

Each session has its own practical guide. Start with:

```text
docs/student-labs/LAB-ROADMAP-V13.md
docs/student-labs/STUDENT-LAB-GUIDE-V13.md
```

## Reset

Do not use reset during normal teaching.

```powershell
.\scripts\RESET-LAB.ps1
```

Use reset only when the trainer intentionally wants a fresh environment.
