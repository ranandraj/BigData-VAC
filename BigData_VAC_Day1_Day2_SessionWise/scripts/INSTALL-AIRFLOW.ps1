$ErrorActionPreference="Stop"
Set-Location "$PSScriptRoot\.."
docker compose up -d airflow
docker compose ps
Write-Host "AIRFLOW started."
