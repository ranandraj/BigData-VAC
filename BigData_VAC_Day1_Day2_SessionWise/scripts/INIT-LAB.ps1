$ErrorActionPreference="Continue"
Set-Location "$PSScriptRoot\.."
Start-Sleep 20
docker exec hdfs-namenode /opt/hadoop/bin/hdfs dfs -mkdir -p /ecommerce/raw /ecommerce/historical
foreach($f in @("customers.csv","products.csv","orders.csv")){
 docker cp ".\data\$f" hdfs-namenode:/tmp/$f
 docker exec hdfs-namenode /opt/hadoop/bin/hdfs dfs -put -f "/tmp/$f" /ecommerce/raw/
}
foreach($t in @("ecommerce-events","ecommerce-orders","ecommerce-payments","ecommerce-cdc")){
 docker exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:29092 --create --if-not-exists --topic $t --partitions 3 --replication-factor 1
}
Write-Host "Initialization complete."
