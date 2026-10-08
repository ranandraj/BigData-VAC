$ErrorActionPreference="Continue"
Set-Location "$PSScriptRoot\.."
Write-Host "=== DAY 1 VERIFICATION ===" -ForegroundColor Cyan
docker compose ps
Write-Host "`n--- HDFS NameNode / DataNode Status ---" -ForegroundColor Cyan
$nn = docker inspect -f '{{.State.Status}}' hdfs-namenode 2>$null
if ($nn -eq 'running') {
    docker exec hdfs-namenode /opt/hadoop/bin/hdfs dfsadmin -report
    docker exec hdfs-namenode /opt/hadoop/bin/hdfs dfs -ls -R /ecommerce
} else {
    Write-Host "HDFS NameNode is not running. Showing logs:" -ForegroundColor Red
    docker compose logs --tail=100 namenode
}
Write-Host "`n--- PostgreSQL ---" -ForegroundColor Cyan
docker exec ecommerce-postgres pg_isready -U ecommerce -d ecommerce
Write-Host "`n--- Kafka Topics ---" -ForegroundColor Cyan
docker exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:29092 --list
Write-Host "`nURLs" -ForegroundColor Cyan
Write-Host "HDFS:     http://localhost:9870"
Write-Host "Debezium: http://localhost:8083"
Write-Host "NiFi:     https://localhost:8443/nifi"
Write-Host "Flink:    http://localhost:8081"
