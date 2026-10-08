$ErrorActionPreference="Stop"
Set-Location "$PSScriptRoot\.."
docker compose up -d mongodb
docker compose ps
Write-Host "MONGODB started."
