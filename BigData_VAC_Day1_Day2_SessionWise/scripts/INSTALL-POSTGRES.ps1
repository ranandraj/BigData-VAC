$ErrorActionPreference="Stop"
Set-Location "$PSScriptRoot\.."
docker compose up -d postgres
docker compose ps
Write-Host "POSTGRES started."
