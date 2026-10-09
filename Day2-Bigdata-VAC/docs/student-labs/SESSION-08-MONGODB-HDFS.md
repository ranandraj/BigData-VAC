# Session 8 - MongoDB Recent Results & HDFS Historical Data

**Duration:** 60 minutes

## Objective

Verify that recent Flink results can be stored in MongoDB while historical source/stream data remains available in HDFS.

## 1. Verify MongoDB

```powershell
docker exec mongodb mongosh --quiet --eval "db.adminCommand('ping')"
```

## 2. Open the dashboard

```text
http://localhost:8501
```

The Streamlit dashboard consumes the Flink metrics and anomaly topics and stores the recent results in MongoDB collections.

## 3. Generate live events

```powershell
.\scripts\GENERATE-CLICKSTREAM.ps1 -Count 200
```

Refresh the dashboard.

## 4. Inspect MongoDB

```powershell
docker exec mongodb mongosh --quiet --eval "db=db.getSiblingDB('ecommerce_analytics'); printjson(db.realtime_metrics.find().sort({window_start:-1}).limit(5).toArray())"
```

Inspect alerts:

```powershell
docker exec mongodb mongosh --quiet --eval "db=db.getSiblingDB('ecommerce_analytics'); printjson(db.alerts.find().sort({event_time:-1}).limit(5).toArray())"
```

## 5. Verify HDFS historical data

```powershell
docker exec hdfs-namenode /opt/hadoop/bin/hdfs dfs -ls /ecommerce/raw
```

Inspect the clickstream file:

```powershell
docker exec hdfs-namenode /opt/hadoop/bin/hdfs dfs -cat /ecommerce/raw/clickstream.json | Select-Object -First 5
```

## Checkpoint

Explain why the lab uses:

- MongoDB for recent/processed results
- HDFS for distributed historical storage

## Evidence

Submit one MongoDB metrics document and one HDFS file listing.
