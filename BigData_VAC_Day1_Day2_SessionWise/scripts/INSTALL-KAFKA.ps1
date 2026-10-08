$ErrorActionPreference="Stop"
Set-Location "$PSScriptRoot\.."
docker compose up -d kafka
docker compose ps
Write-Host "KAFKA started."
