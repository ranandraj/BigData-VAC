$ErrorActionPreference='Stop'
Set-Location "$PSScriptRoot\.."
$dc=(Get-Command docker-compose.exe -ErrorAction Stop).Source
& $dc ps
Write-Host 'HDFS:'
& docker.exe exec hdfs-namenode /opt/hadoop/bin/hdfs dfsadmin -report
Write-Host 'HDFS raw/analytical paths:'
& docker.exe exec hdfs-namenode /opt/hadoop/bin/hdfs dfs -ls /ecommerce/raw
& docker.exe exec hdfs-namenode /opt/hadoop/bin/hdfs dfs -ls /ecommerce/iceberg
Write-Host 'PostgreSQL row counts:'
& docker.exe exec ecommerce-postgres psql -U ecommerce -d ecommerce -c "SELECT 'customers' table_name,count(*) rows FROM customers UNION ALL SELECT 'products',count(*) FROM products UNION ALL SELECT 'orders',count(*) FROM orders UNION ALL SELECT 'order_items',count(*) FROM order_items UNION ALL SELECT 'payments',count(*) FROM payments UNION ALL SELECT 'clickstream_events',count(*) FROM clickstream_events ORDER BY table_name;"
Write-Host 'Kafka:'
& docker.exe exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:29092 --list
Write-Host 'Debezium:'
try { Invoke-RestMethod http://localhost:8083/connectors } catch { Write-Host 'Debezium API not ready' -ForegroundColor Yellow }
Write-Host 'Flink:'
try { Invoke-RestMethod http://localhost:8081/overview | ConvertTo-Json -Compress } catch { Write-Host 'Flink Web UI not ready' -ForegroundColor Yellow }
Write-Host 'Trino:'
try { Invoke-RestMethod http://localhost:8080/v1/info | ConvertTo-Json -Compress } catch { Write-Host 'Trino API not ready' -ForegroundColor Yellow }
Write-Host 'MongoDB:'
& docker.exe exec mongodb mongosh --quiet --eval "db.adminCommand('ping')"
Write-Host 'Airflow:'
try { Invoke-WebRequest -UseBasicParsing http://localhost:8085/health | Select-Object -ExpandProperty Content } catch { Write-Host 'Airflow UI not ready' -ForegroundColor Yellow }
Write-Host 'URLs: HDFS 9870 | NiFi 8443 | Kafka 9092 | Debezium 8083 | Flink 8081 | Trino 8080 | Streamlit 8501 | Airflow 8085'
