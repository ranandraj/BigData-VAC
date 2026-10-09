$ErrorActionPreference='Stop'
Set-Location "$PSScriptRoot\.."
$dc=(Get-Command docker-compose.exe -ErrorAction Stop).Source
& $dc up -d --no-build --pull never namenode datanode1 datanode2 datanode3 postgres kafka debezium nifi mongodb trino streamlit airflow flink-jobmanager flink-taskmanager
Start-Sleep -Seconds 20

& docker.exe exec hdfs-namenode /opt/hadoop/bin/hdfs dfs -mkdir -p /ecommerce/raw /ecommerce/historical
foreach($f in @('customers.csv','products.csv','orders.csv','order_items.csv','payments.csv')){
    & docker.exe cp ".\data\$f" hdfs-namenode:/tmp/$f
    & docker.exe exec hdfs-namenode /opt/hadoop/bin/hdfs dfs -put -f "/tmp/$f" /ecommerce/raw/
}

# Load the same operational e-commerce dataset into PostgreSQL so the complete CDC and analytical path has real data.
& "$PSScriptRoot\LOAD-POSTGRES-DATA.ps1"
if($LASTEXITCODE -ne 0){ throw 'PostgreSQL data load failed.' }
& docker.exe cp ".\data\clickstream.json" hdfs-namenode:/tmp/clickstream.json
& docker.exe exec hdfs-namenode /opt/hadoop/bin/hdfs dfs -put -f /tmp/clickstream.json /ecommerce/raw/

foreach($t in @('ecommerce-events','ecommerce-orders','ecommerce-payments','ecommerce-cdc','ecommerce-metrics','ecommerce-anomalies','ecommerce.public.customers','ecommerce.public.products','ecommerce.public.orders','ecommerce.public.order_items','ecommerce.public.payments')){
    & docker.exe exec kafka /opt/kafka/bin/kafka-topics.sh --bootstrap-server kafka:29092 --create --if-not-exists --topic $t --partitions 3 --replication-factor 1
}

# Register/update PostgreSQL CDC connector.
Start-Sleep -Seconds 8
try {
    $payload=Get-Content .\config\debezium\postgres-connector.json -Raw
    $existing=@(Invoke-RestMethod -Uri http://localhost:8083/connectors -Method Get -ErrorAction Stop)
    if($existing -contains 'ecommerce-postgres'){
        $cfg=(ConvertFrom-Json $payload).config | ConvertTo-Json -Compress
        Invoke-RestMethod -Uri http://localhost:8083/connectors/ecommerce-postgres/config -Method Put -ContentType 'application/json' -Body $cfg | Out-Null
    } else {
        Invoke-RestMethod -Uri http://localhost:8083/connectors -Method Post -ContentType 'application/json' -Body $payload | Out-Null
    }
    Write-Host '[OK] Debezium PostgreSQL connector registered.' -ForegroundColor Green
} catch {
    Write-Host "[WARN] Debezium connector registration will need retry: $($_.Exception.Message)" -ForegroundColor Yellow
}

Write-Host '[OK] Base data, HDFS paths and Kafka topics initialized.' -ForegroundColor Green
