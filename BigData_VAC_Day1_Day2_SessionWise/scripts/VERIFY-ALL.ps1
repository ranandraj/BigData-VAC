Set-Location "$PSScriptRoot\.."
docker compose ps
Write-Host "HDFS:"; docker exec hdfs-namenode /opt/hadoop/bin/hdfs dfsadmin -report
Write-Host "PostgreSQL:"; docker exec ecommerce-postgres pg_isready -U ecommerce -d ecommerce
Write-Host "Kafka:"; docker exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:29092 --list
Write-Host "MongoDB:"; docker exec mongodb mongosh --quiet --eval "db.adminCommand('ping')"
Write-Host "URLs: HDFS 9870 | Flink 8081 | NiFi 8443 | Debezium 8083 | Trino 8080 | Streamlit 8501 | Airflow 8085"
