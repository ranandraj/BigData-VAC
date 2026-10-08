$ErrorActionPreference='Stop'; Set-Location "$PSScriptRoot\.."
Write-Host '=== AR INFOTEK BIG DATA VAC v7 - TRAINER BASE SETUP ===' -ForegroundColor Cyan
Write-Host 'This is the trainer/lab-admin setup. It pulls/builds the lab images without executing the student sessions.' -ForegroundColor Yellow

docker compose pull namenode datanode1 datanode2 datanode3 postgres kafka debezium nifi mongodb trino airflow
if($LASTEXITCODE -ne 0){ throw 'Docker image pull failed.' }
docker compose build flink-jobmanager flink-taskmanager
if($LASTEXITCODE -ne 0){ throw 'Flink image build failed.' }
Write-Host 'Base images are ready. Use the session scripts during the workshop.' -ForegroundColor Green
