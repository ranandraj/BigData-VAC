$ErrorActionPreference='Continue'; Set-Location "$PSScriptRoot\..\.."
Write-Host '=== SESSION 8: INTEGRATION CHECK ===' -ForegroundColor Cyan
$names=@('hdfs-namenode','hdfs-datanode1','hdfs-datanode2','hdfs-datanode3','ecommerce-postgres','kafka','debezium','nifi','flink-jobmanager','flink-taskmanager','mongodb')
foreach($n in $names){$s=docker inspect -f '{{.State.Status}}' $n 2>$null; if($s -eq 'running'){Write-Host "[OK] $n" -ForegroundColor Green}else{Write-Host "[--] $n : $s" -ForegroundColor Yellow}}
Write-Host ''
Write-Host 'Debezium connector:'
try { (Invoke-RestMethod http://localhost:8083/connectors/ecommerce-postgres/status).tasks | Format-Table state,id } catch { Write-Host 'Connector not reachable.' -ForegroundColor Yellow }
Write-Host ''
Write-Host 'HDFS:'
docker exec hdfs-namenode /opt/hadoop/bin/hdfs dfsadmin -report 2>$null | Select-String 'Live datanodes|Dead datanodes'
Write-Host 'Kafka topics:'
docker exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:29092 --list 2>$null
