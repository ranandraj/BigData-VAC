Set-Location "$PSScriptRoot\.."; docker compose stop nifi debezium flink-taskmanager flink-jobmanager kafka postgres datanode1 datanode2 datanode3 namenode; docker compose ps
