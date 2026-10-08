# AR INFOTEK Big Data VAC Lab - Day 1 / Day 2

This package is designed for college lab computers with limited RAM. It does NOT start the whole ecosystem simultaneously.

## Step 0: Standalone pre-flight

Run:
```text
PRE-FLIGHT-CHECK.cmd
```

The checker validates Windows, WSL, Virtual Machine Platform, CPU firmware virtualization, CPU/RAM/disk, hypervisor launch mode, Docker/Compose/Engine, Docker memory, winget, and all lab ports. The main installer can repair WSL and Virtual Machine Platform automatically when run as Administrator.

## Day 1

Start:
- HDFS: NameNode + 3 DataNodes
- PostgreSQL
- Kafka
- Debezium
- NiFi
- Flink JobManager + TaskManager

Run:
```powershell
.\scripts\INSTALL-DAY1.ps1
```

After the class:
```powershell
.\scripts\STOP-DAY1.ps1
```

## Day 2

Day 2 stops the Day 1 ingestion-only services:
- NiFi
- Debezium

It keeps:
- HDFS
- PostgreSQL
- Kafka
- Flink

It starts:
- MongoDB
- Trino
- Streamlit
- Airflow

Run:
```powershell
.\scripts\INSTALL-DAY2.ps1
```

After the class:
```powershell
.\scripts\STOP-DAY2.ps1
```

## Individual component installation

Each major ecosystem component also has a separate installer in `scripts`.

## Complete setup

`INSTALL-BIGDATA-LAB.ps1` first enables/repairs WSL 2 and Virtual Machine Platform, configures hypervisor launch, checks firmware virtualization, installs Docker Desktop if required, and starts Day 1. Day 2 is intentionally started separately.

## URLs

HDFS: http://localhost:9870
Flink: http://localhost:8081
NiFi: https://localhost:8443/nifi
Debezium: http://localhost:8083
Trino: http://localhost:8080
Streamlit: http://localhost:8501
Airflow: http://localhost:8085
PostgreSQL: localhost:5432
Kafka: localhost:9092
MongoDB: localhost:27017

## Hardware guidance

16 GB RAM: use Day 1/Day 2 staged mode.
32 GB RAM: preferred.
4+ logical CPU cores recommended.
80+ GB free disk preferred.

This is a local teaching environment. HDFS DataNodes are containers on one physical PC.


## HDFS startup fix v3
NameNode and DataNode startup now uses explicit HADOOP_HOME/HADOOP_CONF_DIR, non-interactive first-run NameNode formatting, and an HTTP/process readiness check. If startup fails, run `./scripts/DIAGNOSE-HDFS.ps1`.

## HDFS FIX v4
This release fixes Apache Hadoop container startup when `su` resets PATH and the `hdfs` command is not found. All container startup and verification paths use `/opt/hadoop/bin/hdfs` explicitly and set Hadoop environment variables. The installer fails fast with diagnostics if the Hadoop executable is missing.

## HDFS startup behavior
Day 1 now waits for all three HDFS DataNodes to register with the NameNode before copying CSV files. If a DataNode exits or does not register within 180 seconds, the installer prints the HDFS report and DataNode logs and stops instead of attempting uploads prematurely.


HDFS networking fix: DataNodes connect to the NameNode using namenode:8020. The NameNode RPC bind address is not advertised as 0.0.0.0.
