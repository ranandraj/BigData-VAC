$ErrorActionPreference="Stop"
Set-Location "$PSScriptRoot\.."
docker compose up -d trino
docker compose ps
Write-Host "TRINO started."
