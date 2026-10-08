$ErrorActionPreference="Stop"
Set-Location "$PSScriptRoot\.."
Write-Host "=== DAY 1 INITIALIZATION ===" -ForegroundColor Cyan

$deadline=(Get-Date).AddSeconds(180)
while((Get-Date)-lt $deadline){
  $status=docker inspect -f '{{.State.Status}}' hdfs-namenode 2>$null
  if($status -eq 'running'){
    docker exec hdfs-namenode bash -lc "su -s /bin/bash hadoop -c '/opt/hadoop/bin/hdfs dfs -ls /' >/dev/null 2>&1"
    if($LASTEXITCODE -eq 0){break}
  }
  Start-Sleep 5
}
if((Get-Date)-ge $deadline){docker compose logs --tail=120 namenode; throw "HDFS NameNode did not become ready."}

docker exec hdfs-namenode /opt/hadoop/bin/hdfs dfsadmin -report | Select-String "Live datanodes (3)" | Out-Null
if($LASTEXITCODE -ne 0){ docker compose logs --tail=160 datanode1 datanode2 datanode3; throw "HDFS DataNodes are not live; refusing to upload data." }
docker exec hdfs-namenode bash -lc "su -s /bin/bash hadoop -c '/opt/hadoop/bin/hdfs dfs -mkdir -p /ecommerce/raw /ecommerce/historical'"
if($LASTEXITCODE -ne 0){throw "Unable to create HDFS directories."}
foreach($f in @("customers.csv","products.csv","orders.csv")){
  docker cp ".\data\$f" hdfs-namenode:/tmp/$f
  docker exec hdfs-namenode bash -lc "su -s /bin/bash hadoop -c '/opt/hadoop/bin/hdfs dfs -put -f /tmp/$f /ecommerce/raw/'"
  if($LASTEXITCODE -ne 0){throw "Unable to upload $f to HDFS."}
}
foreach($t in @("ecommerce-events","ecommerce-orders","ecommerce-payments","ecommerce-cdc")){
  docker exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:29092 --create --if-not-exists --topic $t --partitions 3 --replication-factor 1
  if($LASTEXITCODE -ne 0){throw "Unable to create Kafka topic $t."}
}
Write-Host "Day 1 initialization completed." -ForegroundColor Green
