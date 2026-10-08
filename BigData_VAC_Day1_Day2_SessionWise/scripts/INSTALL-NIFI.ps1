$ErrorActionPreference="Stop"
Set-Location "$PSScriptRoot\.."
docker compose up -d nifi
docker compose ps
Write-Host "NIFI started."
