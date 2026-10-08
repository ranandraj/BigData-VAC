$ErrorActionPreference="Stop"
Set-Location "$PSScriptRoot\.."
docker compose up -d streamlit
docker compose ps
Write-Host "STREAMLIT started."
