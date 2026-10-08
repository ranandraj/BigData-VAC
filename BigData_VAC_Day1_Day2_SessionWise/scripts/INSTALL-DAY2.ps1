$ErrorActionPreference="Stop"
Set-Location "$PSScriptRoot\.."
Write-Host "=== DAY 2: BIG DATA ANALYTICS + DASHBOARD + REPORTING ===" -ForegroundColor Cyan
docker compose stop nifi debezium
docker compose up -d namenode datanode1 datanode2 datanode3 postgres kafka flink-jobmanager flink-taskmanager mongodb trino streamlit airflow
& "$PSScriptRoot\VERIFY-DAY2.ps1"
