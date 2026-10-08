Set-Location "$PSScriptRoot\.."; docker compose up -d namenode datanode1 datanode2 datanode3 postgres kafka debezium nifi flink-jobmanager flink-taskmanager; docker compose ps
