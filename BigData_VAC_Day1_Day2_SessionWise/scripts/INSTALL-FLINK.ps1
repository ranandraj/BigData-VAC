$ErrorActionPreference="Stop"
Set-Location "$PSScriptRoot\.."
docker compose up -d flink-jobmanager flink-taskmanager
docker compose ps
Write-Host "FLINK started."
