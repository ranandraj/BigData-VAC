# Session 2 - HDFS Distributed Storage

**Duration:** 60 minutes

## Objective

Create and validate an e-commerce HDFS directory structure, upload datasets and inspect distributed storage.

## 1. Open HDFS Web UI

Open:

```text
http://localhost:9870
```

Check that the NameNode is live and three DataNodes are visible.

## 2. Inspect HDFS from the container

```powershell
docker exec hdfs-namenode /opt/hadoop/bin/hdfs dfsadmin -report
```

Record the number of live DataNodes.

## 3. Create student directories

```powershell
docker exec hdfs-namenode /opt/hadoop/bin/hdfs dfs -mkdir -p /ecommerce/students

docker exec hdfs-namenode /opt/hadoop/bin/hdfs dfs -mkdir -p /ecommerce/students/<your-name>
```

Replace `<your-name>` with your assigned identifier.

## 4. Inspect supplied data

```powershell
docker exec hdfs-namenode /opt/hadoop/bin/hdfs dfs -ls /ecommerce/raw
```

Expected datasets include:

```text
customers.csv
products.csv
orders.csv
order_items.csv
payments.csv
clickstream.json
```

## 5. Upload a student copy

```powershell
docker cp .\data\orders.csv hdfs-namenode:/tmp/orders-student.csv

docker exec hdfs-namenode /opt/hadoop/bin/hdfs dfs -put -f /tmp/orders-student.csv /ecommerce/students/<your-name>/
```

Verify:

```powershell
docker exec hdfs-namenode /opt/hadoop/bin/hdfs dfs -ls /ecommerce/students/<your-name>
```

## 6. Read data

```powershell
docker exec hdfs-namenode /opt/hadoop/bin/hdfs dfs -cat /ecommerce/students/<your-name>/orders-student.csv
```

For a large file, use:

```powershell
docker exec hdfs-namenode /opt/hadoop/bin/hdfs dfs -cat /ecommerce/students/<your-name>/orders-student.csv | Select-Object -First 10
```

## 7. Test file operations

```powershell
docker exec hdfs-namenode /opt/hadoop/bin/hdfs dfs -mkdir -p /ecommerce/students/<your-name>/backup

docker exec hdfs-namenode /opt/hadoop/bin/hdfs dfs -cp /ecommerce/students/<your-name>/orders-student.csv /ecommerce/students/<your-name>/backup/
```

## Checkpoint

Answer:

- What does the NameNode store?
- Where is the actual file content stored?
- What is an HDFS block?
- Why are DataNodes separate from the NameNode?

## Evidence

Screenshot the HDFS Web UI and the `hdfs dfs -ls` output.
