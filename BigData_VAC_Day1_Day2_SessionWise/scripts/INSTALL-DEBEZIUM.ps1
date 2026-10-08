$ErrorActionPreference="Stop"
Set-Location "$PSScriptRoot\.."
docker compose up -d debezium
docker compose ps
Write-Host "DEBEZIUM started."
