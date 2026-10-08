# Session 2 - HDFS

## Objective
Understand NameNode, DataNodes, blocks, replication and HDFS file operations.

## Start
```powershell
.\scripts\session\01-START-HDFS.ps1
```

## Student tasks
```powershell
docker exec hdfs-namenode /opt/hadoop/bin/hdfs dfsadmin -report
docker exec hdfs-namenode /opt/hadoop/bin/hdfs dfs -ls /
docker exec hdfs-namenode /opt/hadoop/bin/hdfs dfs -ls /ecommerce
docker exec hdfs-namenode /opt/hadoop/bin/hdfs dfs -ls /ecommerce/raw
docker exec hdfs-namenode /opt/hadoop/bin/hdfs dfs -cat /ecommerce/raw/orders.csv
docker exec hdfs-namenode /opt/hadoop/bin/hdfs dfs -mkdir -p /ecommerce/students/<ROLLNO>
```

Explain before continuing: Why is the NameNode different from a DataNode? What is a block? Why is data distributed?
